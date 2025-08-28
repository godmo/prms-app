// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prmsapp/providers/selected_pc_provider.dart';
import 'package:prmsapp/services/mqtt_service.dart';
import 'package:prmsapp/utility/prms_data_check.dart';
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

  // 三个条码变量
  String code1 = "";
  String code2 = "";
  String code3 = "";

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
    if (widget.onQRScanTab != null) {
      debugPrint('[HomePage] Calling onQRScanTab callback');
      widget.onQRScanTab!(fromBindingCard: fromBindingCard);
    } else {
      debugPrint('[HomePage] ERROR: onQRScanTab callback is null!');
    }
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
        final scanContent = barcode.rawValue!;
        debugPrint('掃描結果: $scanContent');
        if (page_stage == "User") {
          // 当符合 员工ID 的格式时，才会更新 p_user_id
          // scanContent 必須是6位數字，
          if (PrmsDataCheck.isValidUserId(scanContent)) {
            setState(() {
              p_user_id = scanContent;
              page_stage = "Machine";
            });
          }
        } else if (page_stage == "Machine") {
          // 当符合 Machine ID 的格式时，才会更新 p_machine_id
          // 以M開頭+5位數字，可依實際需求調整
          if (PrmsDataCheck.isValidMachineId(scanContent)) {
            setState(() {
              p_machine_id = scanContent;
              page_stage = "Complete";
            });
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
                        color: CupertinoColors.systemGrey6.withOpacity(0.5),
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
                // 这边加上 一个 Button 来推送资料到MQTT
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('$label:', style: const TextStyle(color: CupertinoColors.systemGrey, fontSize: 16, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(color: Color(0xFF204080), fontSize: 16, fontWeight: FontWeight.w600)),
        // 加上 CupertinoIcons ， 如果是 value 是空则显示警告图标 ， 如果是正常的value 则显示 check 图标
        if (value.isEmpty)
          Icon(CupertinoIcons.exclamationmark_triangle, color: CupertinoColors.systemRed, size: 20)
        else
          Icon(CupertinoIcons.check_mark, color: CupertinoColors.systemGreen, size: 20),
      ],
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
