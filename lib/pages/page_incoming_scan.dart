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

import 'main_page.dart';

class PageIncomingScan extends StatefulWidget {
  final GlobalKey<GlobalNavBarState>? navBarKey;
  final void Function({bool fromBindingCard})? onQRScanTab;
  const PageIncomingScan({super.key, this.navBarKey, this.onQRScanTab});

  @override
  State<PageIncomingScan> createState() => _PageIncomingScanState();
}

class _PageIncomingScanState extends State<PageIncomingScan> {
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

  // QR码解析对象
  Map<String, dynamic>? qrcode_obj;

  // MQTT推送状态
  bool _isPushing = false;

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
                alignment: Alignment.center,
                child: const Text('PC List', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

    // 添加测试数据来展示条码UI效果
    // 你可以根据实际需要修改或删除这些测试数据
    setState(() {
      code1 = "";
      code2 = "";
      code3 = "";
    });
  }

  void _afterLoad() {
    // 通过 globalNavBarKey.currentState 调用 setTitle
    globalNavBarKey.currentState?.setTitle('PRMS APP pageFun1');
    if (MqttService().isConnected.value == true) {
      scan_mode = "Barcode";
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
    // 加入冷卻時間判斷，避免因為相機畫面殘影、手抖、或多條碼同時入鏡時，短時間內重複觸發掃描
    // final now = DateTime.now();
    // if (_lastScanTime != null &&
    //     now.difference(_lastScanTime!).inMilliseconds < 1000) {
    //   debugPrint('冷卻中，忽略本次掃描');
    //   return;
    // }
    // _lastScanTime = now;

    // // 在單次掃描模式下，如果已經掃描過，則忽略
    // if (!_isContinuousScanMode && _hasScanned) {
    //   debugPrint('單次掃描已完成，忽略新的掃描結果');
    //   return;
    // }

    for (final barcode in barcodes.barcodes) {
      if (barcode.rawValue != null) {
        final scanContent = barcode.rawValue!.trim();
        debugPrint('掃描結果: $scanContent');

        if (scan_mode == "BarCode") {
          if (scanContent.isEmpty) {
            // 空掃描結果不處理
            return;
          } else {
            if (scanContent.startsWith("1")) {
              code1 = scanContent;
              setState(() {});
            } else if (scanContent.startsWith("2")) {
              code2 = scanContent;
              setState(() {});
            } else if (scanContent.startsWith("3")) {
              code3 = scanContent;
              setState(() {});
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
                context.read<SelectedPCProvider>().addPC(newPC);
                debugPrint('[DEBUG] 已將 topic 加入 PC List: $newPC');
                context.read<SelectedPCProvider>().setSelectedPC(newPC);
                debugPrint('[DEBUG] 已將 topic 設為當前選擇: $newPC');

                // 綁定成功後再背景重連 MQTT，不阻塞 UI
                MqttService().connect();

                scan_mode = "BarCode";
              }
            }
          } catch (e) {
            debugPrint('QR码解析失败: $e');
            qrcode_obj = null;
          }
        }
      }
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
                      vertical: 24.0, // 增大垂直間距
                      horizontal: screenWidth * 0.06, // 增大水平間距
                    ),
                    child: Column(
                      children: [
                        BindingPCCard(pcList: pcList, onQRScan: _navigateToQRScanTab, onShowPicker: _showPicker),

                        //const SizedBox(height: 16),
                        // VPN 狀態卡片 不要移除 未來可能使用
                        // FutureBuilder<bool>(
                        //   future: _checkVPN(),
                        //   builder: (context, snapshot) {
                        //     final connected = snapshot.data ?? false;
                        //     return VpnStatusCard(connected: connected);
                        //   },
                        // ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: VisibilityDetector(
                    key: _scannerVisibilityKey,
                    onVisibilityChanged: (visibilityInfo) {
                      if (!mounted) return;
                      final visibleFraction = visibilityInfo.visibleFraction;
                      debugPrint('Scanner visibility: \\${visibleFraction * 100}%');
                      if (visibleFraction > 0) {
                        debugPrint('Scanner is visible, starting camera...');
                        _scannerController.start().catchError((error) {
                          debugPrint('Error starting camera: \\$error');
                        });
                      } else {
                        debugPrint('Scanner is not visible, stopping camera...');
                        _scannerController.stop();
                      }
                    },
                    child: Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.85,
                        height: MediaQuery.of(context).size.height * 0.28,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.18), blurRadius: 16, offset: Offset(0, 6))],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: MobileScanner(controller: _scannerController, fit: BoxFit.cover, onDetect: _handleScan),
                            ),
                            // 四角高亮装饰
                            Positioned.fill(child: CustomPaint(painter: _CornerDecorationPainter())),
                            // 摄像头切换按钮
                            Positioned(
                              top: 14.0,
                              left: 14.0,
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(8.0),
                                color: CupertinoColors.black.withOpacity(0.32),
                                borderRadius: BorderRadius.circular(20.0),
                                onPressed: () => _scannerController.switchCamera(),
                                child: Icon(CupertinoIcons.camera_rotate, size: MediaQuery.of(context).size.width * 0.06, color: CupertinoColors.white),
                              ),
                            ),
                            Positioned(
                              top: 14.0,
                              left: 250.0,
                              child: CupertinoButton(
                                padding: const EdgeInsets.all(8.0),
                                color: CupertinoColors.systemYellow.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(00.0),
                                onPressed: () => _scannerController.switchCamera(),
                                child:
                                    scan_mode == "QRCode"
                                        ? Text('QRCode', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, color: CupertinoColors.black))
                                        : Text('BarCode', style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.04, color: CupertinoColors.black)),
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
                    padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: screenWidth * 0.06),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CupertinoColors.activeGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildCodeRow('Code 1', code1),
                          const SizedBox(height: 8),
                          _buildCodeRow('Code 2', code2),
                          const SizedBox(height: 8),
                          _buildCodeRow('Code 3', code3),
                        ],
                      ),
                    ),
                  ),
                ),
                // MQTT推送按钮
                SliverToBoxAdapter(
                  child: Padding(padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: screenWidth * 0.06), child: _buildMqttPushButton()),
                ),
                SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0), child: _buildBottomInfo())),
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
    try {
      _scannerController.stop();
    } catch (e) {
      debugPrint('Error stopping camera: $e');
    }
    _scannerController.dispose();
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
        Text('$label:', style: const TextStyle(color: CupertinoColors.black, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(width: 12),
        Expanded(child: Text(value, style: const TextStyle(color: CupertinoColors.activeBlue, fontSize: 16, fontWeight: FontWeight.w600))),
        // 加上 CupertinoIcons ， 如果是 value 是空则显示警告图标 ， 如果是正常的value 则显示 check 图标
        if (value.isEmpty)
          Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 20)
        else
          Icon(CupertinoIcons.check_mark, color: CupertinoColors.systemGreen, size: 20),
      ],
    );
  }

  // 构建MQTT推送按钮
  Widget _buildMqttPushButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(colors: [Color(0xFF1E90FF), Color(0xFF4169E1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: const Color(0xFF1E90FF).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: CupertinoButton(
        //padding: const EdgeInsets.symmetric(vertical: 16.0),
        onPressed: _isPushing ? null : _pushDataToMqtt,
        child:
            _isPushing
                ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CupertinoActivityIndicator(color: CupertinoColors.white),
                    SizedBox(width: 12),
                    Text('Pushing...', style: TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
                : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.cloud_upload, color: CupertinoColors.white, size: 20),
                    SizedBox(width: 8),
                    Text('Send PC', style: TextStyle(color: CupertinoColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
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

      // 构建要发送的数据
      final selectedPC = context.read<SelectedPCProvider>().selectedPC;
      final data = {
        'user_id': p_user_id,
        'machine_id': p_machine_id,
        'page_stage': page_stage,
        'code1': code1,
        'code2': code2,
        'code3': code3,
        'selected_pc': selectedPC,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // 发送数据到MQTT，使用user_id作为topic
      final topic = p_user_id.isNotEmpty ? p_user_id : 'default';
      final message = data.toString();

      final success = await MqttService().publishAndWaitAck(topic, message);

      if (success) {
        _showResultDialog('Success', 'Data pushed to MQTT successfully!', CupertinoColors.systemGreen);
      } else {
        _showResultDialog('Failed', 'Failed to push data to MQTT. Please try again.', CupertinoColors.systemRed);
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
    const double radius = 20;
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
