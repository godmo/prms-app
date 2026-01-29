// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prmsapp/providers/selected_pc_provider.dart';
import 'package:prmsapp/services/mqtt_service.dart';
import 'package:prmsapp/widgets/binding_pc_card.dart';
import 'package:prmsapp/widgets/global_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

class PaggMaterialImportScan extends StatefulWidget {
  final GlobalKey<GlobalNavBarState>? navBarKey;
  final void Function({bool fromBindingCard})? onQRScanTab;
  const PaggMaterialImportScan({super.key, this.navBarKey, this.onQRScanTab});

  @override
  State<PaggMaterialImportScan> createState() => _PaggMaterialImportScanState();
}

class _PaggMaterialImportScanState extends State<PaggMaterialImportScan> {
  /// 控制相機掃描功能的控制器
  final MobileScannerController _scannerController = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    // 使用1080p解析度，以16:9比例顯示相機畫面，iphone上不需設定改為null
    cameraResolution: null,
    // 不指定formats參數，讓掃描器支援所有類型的條碼
  );

  // 分别为5个阶段的处理作业
  // User , Machine , New_PR, New_Tube
  String page_stage = "User"; // User , Machine  Complete
  //String p_user_id = "220653 / HHCHENX"; // 220653
  String p_user_id = ""; // 220653
  String p_machine_id = "";
  String scan_mode = "QRCode";
  // 三个条码变量
  String code1 = "";
  String code2 = "";
  String code3 = "";

  // 掃描緩衝機制 - 用於確保掃描結果的穩定性
  static const int _scanBufferSize = 5;
  final List<String> _code1Buffer = [];
  final List<String> _code2Buffer = [];
  final List<String> _code3Buffer = [];

  // QR码解析对象
  Map<String, dynamic>? qrcode_obj;

  // MQTT推送状态
  bool _isPushing = false;
  bool _isDisposed = false; // 追蹤 Widget 是否已釋放
  bool _isProcessing = false; // 防止重複處理掃描

  final Key _scannerVisibilityKey = UniqueKey();

  void _showPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.3,
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              Container(
                height: 40,
                color: CupertinoColors.systemGrey5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40), // 平衡左側空間
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'PC List',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: CupertinoColors.black,
                            shadows: [Shadow(color: CupertinoColors.systemGrey3.withOpacity(0.3), offset: const Offset(0, 1), blurRadius: 2)],
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.all(8),
                      minSize: 0,
                      onPressed: () {
                        // 顯示確認對話框
                        showCupertinoDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return CupertinoAlertDialog(
                              title: const Text('Clear PC List'),
                              content: const Text('Are you sure you want to clear all PC records?'),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text('Cancel'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  child: const Text('Clear'),
                                  onPressed: () {
                                    context.read<SelectedPCProvider>().clearAll();
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Icon(CupertinoIcons.clear_fill, color: CupertinoColors.systemRed, size: 20),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40.0,
                  onSelectedItemChanged: (int index) {
                    final pcList = context.read<SelectedPCProvider>().pcList;
                    context.read<SelectedPCProvider>().setSelectedPC(pcList[index]);
                  },
                  children:
                      context.read<SelectedPCProvider>().pcList.map((String pc) {
                        return Center(child: Text(pc, style: const TextStyle(fontSize: 16)));
                      }).toList(),
                ),
              ),
              SafeArea(
                minimum: EdgeInsets.only(bottom: 16), // 可視需要調整距離
                child: CupertinoButton(
                  child: const Text('Confirm'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 開啟QR掃描頁面 - 直接切換到 TabBar 的 Scan 頁籤
  void _navigateToQRScanTab(bool fromBindingCard) {
    scan_mode = "QRCode";
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    // 為 VisibilityDetector 新增一個唯一的 Key

    // Flutter 没有 afterLoad 生命周期，但可以用 addPostFrameCallback 实现类似效果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afterLoad();
    });

    // 添加MQTT连接状态监听
    MqttService().isConnected.addListener(_onMqttConnectionChanged);

    // 添加测试数据来展示条码UI效果
    // 你可以根据实际需要修改或删除这些测试数据
    setState(() {
      code1 = "";
      code2 = "";
      code3 = "";
    });
  }

  void _afterLoad() {
    _checkAndSwitchScanMode();
  }

  void _onMqttConnectionChanged() {
    if (mounted) {
      _checkAndSwitchScanMode();
    }
  }

  void _checkAndSwitchScanMode() {
    if (MqttService().isConnected.value == true) {
      setState(() {
        scan_mode = "BarCode";
      });
      debugPrint('MQTT已連接，自動切換到BarCode掃描模式');
    }
  }

  checkStage() {
    if (p_user_id.isNotEmpty && p_machine_id.isNotEmpty) {
      return true;
    } else {
      return false;
    }
  }

  /// 處理掃描結果，支援單次與連續模式，並彈出對話框或更新畫面
  void _handleScan(BarcodeCapture barcodes) {
    // 檢查 Widget 狀態
    if (_isDisposed || !mounted) return;

    // 防止重複處理
    if (_isProcessing) return;

    _isProcessing = true;

    try {
      for (final barcode in barcodes.barcodes) {
        if (barcode.rawValue != null) {
          // 清理掃描內容，移除換行符號和特殊字元
          final scanContent = barcode.rawValue!.trim().replaceAll(RegExp(r'[\r\n\t]'), '');
          debugPrint('掃描結果: $scanContent');

          if (scan_mode == "BarCode") {
            if (scanContent.isEmpty) {
              // 空掃描結果不處理
              return;
            } else {
              if (scanContent.startsWith("1")) {
                _addToBuffer(_code1Buffer, scanContent, 1);
                break;
              } else if (scanContent.startsWith("2")) {
                // 扫描结果长度大于10才加入缓冲区（不然会与 员工ID 混淆）
                if (scanContent.trim().length > 10) {
                  _addToBuffer(_code2Buffer, scanContent, 2);
                }
                break;
              } else if (scanContent.startsWith("3")) {
                _addToBuffer(_code3Buffer, scanContent, 3);
                break;
              }
            }
          } else if (scan_mode == "QRCode") {
            try {
              qrcode_obj = jsonDecode(scanContent);
              debugPrint('QR码解析成功: $qrcode_obj');

              // 根据QR码内容处理相应逻辑
              if (qrcode_obj != null) {
                final Map<String, dynamic> data = jsonDecode(scanContent);
                if (data.containsKey('topic')) {
                  final String newPC = data['topic'].toString();
                  if (mounted && !_isDisposed) {
                    context.read<SelectedPCProvider>().addPC(newPC);
                    debugPrint('[DEBUG] 已將 topic 加入 PC List: $newPC');
                    context.read<SelectedPCProvider>().setSelectedPC(newPC);
                    debugPrint('[DEBUG] 已將 topic 設為當前選擇: $newPC');
                    // 綁定成功後再背景重連 MQTT，不阻塞 UI
                    MqttService().connect();
                    // 切換回條碼掃描模式
                    scan_mode = "BarCode";
                  }
                  break;
                }
              }
            } catch (e) {
              debugPrint('QR码解析失败: $e');
              qrcode_obj = null;
            }
          }
        }
      }
    } finally {
      // 延遲重置處理標記，實現冷卻機制
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && !_isDisposed) {
          _isProcessing = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pcList = context.watch<SelectedPCProvider>().pcList;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: Stack(
        children: [
          // 背景浮水印
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.05, // 可依需求調整濃淡
                child: Image.asset('assets/icon/app_icon_vis4.png', width: screenWidth * 0.6, height: screenWidth * 0.6, fit: BoxFit.contain),
              ),
            ),
          ),
          // 原本的內容
          SafeArea(
            child: CustomScrollView(
              slivers: [
                //此元件在Android會有下拉到一半提前觸發的情況(我們目標是iphone與iOS體驗因此不做修改)
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    if (!MqttService().isConnected.value) {
                      await MqttService().connect();
                    }
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 6.0, // 增大垂直間距
                      horizontal: screenWidth * 0.06, // 增大水平間距
                    ),
                    child: Column(children: [BindingPCCard(pcList: pcList, onQRScan: _navigateToQRScanTab, onShowPicker: _showPicker)]),
                  ),
                ),
                SliverToBoxAdapter(
                  child: VisibilityDetector(
                    key: _scannerVisibilityKey,
                    onVisibilityChanged: (visibilityInfo) {
                      if (!mounted || _isDisposed) return;
                      final visibleFraction = visibilityInfo.visibleFraction;
                      debugPrint('Scanner visibility: \\${visibleFraction * 100}%');
                      if (visibleFraction > 0) {
                        debugPrint('Scanner is visible, starting camera...');
                        _scannerController.start().catchError((error) {
                          debugPrint('Error starting camera: \\$error');
                        });
                      } else {
                        debugPrint('Scanner is not visible, stopping camera...');
                        _scannerController.stop().catchError((error) {
                          debugPrint('Error stopping camera: \\$error');
                        });
                      }
                    },
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.87,
                        height: MediaQuery.of(context).size.height * 0.28,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.18), blurRadius: 8, offset: Offset(0, 6))],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: MobileScanner(controller: _scannerController, fit: BoxFit.cover, onDetect: _handleScan),
                            ),
                            // 四角高亮装饰
                            Positioned.fill(child: CustomPaint(painter: _CornerDecorationPainter())),

                            // 美化的掃描模式切換按鈕
                            Positioned(
                              top: 12.0,
                              right: 16.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors:
                                        scan_mode == "QRCode"
                                            ? [CupertinoColors.systemBlue, CupertinoColors.systemBlue.darkColor]
                                            : [CupertinoColors.systemGreen, CupertinoColors.activeGreen],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (scan_mode == "QRCode" ? CupertinoColors.systemBlue : CupertinoColors.systemGreen).withOpacity(0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CupertinoButton(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                  color: const Color.fromRGBO(0, 0, 0, 0), // 透明色
                                  borderRadius: BorderRadius.circular(20.0),
                                  minSize: 0,
                                  onPressed: () {
                                    setState(() {
                                      scan_mode = scan_mode == "QRCode" ? "BarCode" : "QRCode";
                                    });
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(scan_mode == "QRCode" ? CupertinoIcons.qrcode : CupertinoIcons.barcode, color: CupertinoColors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        scan_mode == "QRCode" ? 'QR Code' : 'Bar Code',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context).size.width * 0.035,
                                          color: CupertinoColors.white,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: screenWidth * 0.06),
                    child: Container(
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: CupertinoColors.systemGrey5, width: 1.5),
                        boxShadow: [
                          BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4), spreadRadius: 1),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Professional Header Section
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemGrey6.withOpacity(0.5),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                              border: Border(bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: CupertinoColors.activeBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                      child: Icon(CupertinoIcons.barcode_viewfinder, color: CupertinoColors.activeBlue, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Scan Results',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: CupertinoColors.black,
                                            letterSpacing: 0.3,
                                            shadows: [Shadow(color: CupertinoColors.systemGrey3.withOpacity(0.3), offset: Offset(0, 1), blurRadius: 2)],
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Barcode List',
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.systemBlue, letterSpacing: 0.2),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (code1.isNotEmpty || code2.isNotEmpty || code3.isNotEmpty)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemRed.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3), width: 1),
                                    ),
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      minSize: 0,
                                      onPressed: () {
                                        setState(() {
                                          code1 = '';
                                          code2 = '';
                                          code3 = '';
                                          _clearBuffer(1);
                                          _clearBuffer(2);
                                          _clearBuffer(3);
                                        });
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(CupertinoIcons.clear_fill, color: CupertinoColors.systemRed, size: 16),
                                          const SizedBox(width: 6),
                                          Text('Clear All', style: TextStyle(color: CupertinoColors.systemRed, fontSize: 13, fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Content Section with original code rows
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                _buildCodeRow('Code 1', code1),
                                const SizedBox(height: 6),
                                _buildCodeRow('Code 2', code2),
                                const SizedBox(height: 6),
                                _buildCodeRow('Code 3', code3),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // MQTT推送按钮
                SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(vertical: 0.0, horizontal: screenWidth * 0.06), child: _buildMqttPushButton())),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0), child: _buildBottomInfo())),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 16.0, left: screenWidth * 0.1, right: screenWidth * 0.1),
                      child: const Text(
                        'Tap the card to select binding PC, tap the QR icon to open camera for binding, pull down to reconnect Server.',
                        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    // 移除MQTT連接狀態監聽
    MqttService().isConnected.removeListener(_onMqttConnectionChanged);

    try {
      _scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
    // 延遲釋放控制器，確保異步操作完成
    Future.delayed(const Duration(milliseconds: 100), () {
      try {
        _scannerController.dispose();
      } catch (e) {
        debugPrint('Error disposing scanner: $e');
      }
    });
    super.dispose();
  }

  // 优化底部信息显示，减少重复判断
  Widget _buildBottomInfo() {
    List<Widget> widgets = [];

    // 显示用户ID或机器ID信息
    String info = '';
    if (page_stage == "User" && p_user_id.isNotEmpty) {
      info = 'User Id : $p_user_id';
    } else if (page_stage == "Machine" && p_machine_id.isNotEmpty) {
      info = 'Machine Id : $p_machine_id';
    }

    if (info.isNotEmpty) {
      widgets.add(
        Text(
          info,
          style: const TextStyle(
            color: Color(0xFF204080), // 柔和蓝色
            fontSize: 20.0, // 更大
            fontWeight: FontWeight.w600, // 半粗体
            letterSpacing: 0.5,
            shadows: [Shadow(color: Color(0x22000000), offset: Offset(0, 1), blurRadius: 2)],
          ),
          textAlign: TextAlign.center,
        ),
      );
      widgets.add(const SizedBox(height: 16));
    }

    // 显示三个条码信息

    if (widgets.isEmpty) return const SizedBox.shrink();

    return Column(children: widgets);
  }

  // 构建条码行的辅助方法
  Widget _buildCodeRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('$label：', style: const TextStyle(color: CupertinoColors.black, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 16, fontWeight: FontWeight.w600))),
        // 加上 CupertinoIcons ， 如果是 value 是空则显示警告图标 ， 如果是正常的value 则显示 check 图标
        if (value.isEmpty)
          Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 20)
        else
          Icon(CupertinoIcons.check_mark, color: CupertinoColors.systemGreen, size: 20),
        // 清除資料圖示
        CupertinoButton(
          padding: const EdgeInsets.all(2),
          minSize: 0,
          onPressed: () {
            setState(() {
              if (label == 'Code 1') {
                code1 = '';
                _clearBuffer(1);
              } else if (label == 'Code 2') {
                code2 = '';
                _clearBuffer(2);
              } else if (label == 'Code 3') {
                code3 = '';
                _clearBuffer(3);
              }
            });
          },
          child: Icon(CupertinoIcons.clear_circled, color: CupertinoColors.systemGrey, size: 18),
        ),
      ],
    );
  }

  // 构建MQTT推送按钮
  Widget _buildMqttPushButton() {
    final bool isDisabled = _isPushing || code1.isEmpty || code2.isEmpty || code3.isEmpty;

    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient:
            isDisabled
                ? LinearGradient(
                  colors: [CupertinoColors.systemGrey5.withOpacity(0.8), CupertinoColors.systemGrey4.withOpacity(0.6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2), Color(0xFF667EEA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0.0, 0.5, 1.0],
                ),
        boxShadow:
            isDisabled
                ? [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))]
                : [
                  BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: 2),
                  BoxShadow(color: CupertinoColors.white.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, -2), spreadRadius: 0),
                ],
        border:
            isDisabled
                ? Border.all(color: CupertinoColors.systemGrey4.withOpacity(0.3), width: 1)
                : Border.all(color: CupertinoColors.white.withOpacity(0.2), width: 1.5),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(18),
        onPressed: isDisabled ? null : _pushDataToMqtt,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child:
              _isPushing
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CupertinoActivityIndicator(color: CupertinoColors.white.withOpacity(0.9), radius: 12),
                      const SizedBox(width: 16),
                      Text(
                        'Pushing...',
                        style: TextStyle(color: CupertinoColors.white.withOpacity(0.9), fontSize: 17, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(0),

                        child: Icon(CupertinoIcons.cloud_upload_fill, color: isDisabled ? CupertinoColors.systemGrey2 : CupertinoColors.white, size: 46),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send To PC',
                              style: TextStyle(
                                color: isDisabled ? CupertinoColors.systemGrey2 : CupertinoColors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                                height: 1.0,
                              ),
                            ),

                            //const SizedBox(height: 2),
                          ],
                        ),
                      ),
                      if (!isDisabled && !_isPushing)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: CupertinoColors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                          child: Icon(CupertinoIcons.arrow_right, color: CupertinoColors.white.withOpacity(0.9), size: 24),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }

  // 推送数据到MQTT
  Future<void> _pushDataToMqtt() async {
    if (_isPushing) return;

    setState(() {
      _isPushing = true;
    });

    try {
      // 检查MQTT连接状态
      if (!MqttService().isConnected.value) {
        await MqttService().connect();
      }

      // 发送数据到MQTT，使用user_id作为topic
      final topic = context.read<SelectedPCProvider>().selectedPC;

      while (code1.contains("  ")) {
        code1 = code1.replaceAll("  ", " ");
      }
      while (code2.contains("  ")) {
        code2 = code2.replaceAll("  ", " ");
      }
      while (code3.contains("  ")) {
        code3 = code3.replaceAll("  ", " ");
      }

      final message = "$code1\$$code2\$$code3";
      final success = await MqttService().publishAndWaitAck(topic, message);
      if (success) {
        _showResultDialog('Success', 'Data sent to PC', CupertinoColors.systemGreen);
        setState(() {
          code1 = '';
          code2 = '';
          code3 = '';
          _clearBuffer(1);
          _clearBuffer(2);
          _clearBuffer(3);
        });
      } else {
        _showResultDialog('Failed', 'Failed to send data to PC. Please try again.', CupertinoColors.systemRed);
      }
    } catch (e) {
      debugPrint('Error pushing data to MQTT: $e');
      _showResultDialog('Error', 'An error occurred: $e', CupertinoColors.systemRed);
    } finally {
      if (mounted) {
        setState(() {
          _isPushing = false;
        });
      }
    }
  }

  // 显示结果对话框
  void _showResultDialog(String title, String message, Color iconColor) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(title == 'Success' ? CupertinoIcons.check_mark_circled : CupertinoIcons.exclamationmark_triangle, color: iconColor, size: 24),
              const SizedBox(width: 8),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 添加掃描結果到緩衝區，當緩衝區滿且所有值相同時才確認結果
  void _addToBuffer(List<String> buffer, String scanResult, int codeNumber) {
    // 添加新的掃描結果到緩衝區
    buffer.add(scanResult);

    // 如果緩衝區超過設定大小，移除最舊的元素
    if (buffer.length > _scanBufferSize) {
      buffer.removeAt(0);
    }

    // 檢查緩衝區是否已滿且所有值都相同
    if (buffer.length == _scanBufferSize && _isBufferConsistent(buffer)) {
      // 確認掃描結果並更新對應的code變數
      switch (codeNumber) {
        case 1:
          if (code1 != scanResult) {
            code1 = scanResult;
            setState(() {});
            debugPrint('Code 1 確認: $scanResult');
          }
          break;
        case 2:
          if (code2 != scanResult) {
            code2 = scanResult;
            setState(() {});
            debugPrint('Code 2 確認: $scanResult');
          }
          break;
        case 3:
          if (code3 != scanResult) {
            code3 = scanResult;
            setState(() {});
            debugPrint('Code 3 確認: $scanResult');
          }
          break;
      }
    }
  }

  /// 檢查緩衝區中的所有值是否一致
  bool _isBufferConsistent(List<String> buffer) {
    if (buffer.isEmpty) return false;
    String firstValue = buffer.first;
    return buffer.every((value) => value == firstValue);
  }

  /// 清除指定的緩衝區
  void _clearBuffer(int codeNumber) {
    switch (codeNumber) {
      case 1:
        _code1Buffer.clear();
        break;
      case 2:
        _code2Buffer.clear();
        break;
      case 3:
        _code3Buffer.clear();
        break;
    }
  }
}

// 四角高亮装饰Painter
class _CornerDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1E90FF)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;
    const double cornerLen = 28;
    const double radius = 10;
    // 左上
    canvas.drawArc(Rect.fromLTWH(0, 0, radius * 2, radius * 2), 3.14, 1.57, false, paint);
    canvas.drawLine(Offset(0, radius), Offset(0, cornerLen), paint);
    canvas.drawLine(Offset(radius, 0), Offset(cornerLen, 0), paint);
    // 右上
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, 0, radius * 2, radius * 2), 4.71, 1.57, false, paint);
    canvas.drawLine(Offset(size.width, radius), Offset(size.width, cornerLen), paint);
    canvas.drawLine(Offset(size.width - radius, 0), Offset(size.width - cornerLen, 0), paint);
    // 左下
    canvas.drawArc(Rect.fromLTWH(0, size.height - radius * 2, radius * 2, radius * 2), 1.57, 1.57, false, paint);
    canvas.drawLine(Offset(0, size.height - radius), Offset(0, size.height - cornerLen), paint);
    canvas.drawLine(Offset(radius, size.height), Offset(cornerLen, size.height), paint);
    // 右下
    canvas.drawArc(Rect.fromLTWH(size.width - radius * 2, size.height - radius * 2, radius * 2, radius * 2), 0, 1.57, false, paint);
    canvas.drawLine(Offset(size.width, size.height - radius), Offset(size.width, size.height - cornerLen), paint);
    canvas.drawLine(Offset(size.width - radius, size.height), Offset(size.width - cornerLen, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
