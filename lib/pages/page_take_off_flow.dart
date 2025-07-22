// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:prmsapp/config/api_config.dart';
import 'package:prmsapp/utility/prms_data_check.dart';
import 'package:prmsapp/widgets/global_nav_bar.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'main_page.dart';

class PageTakeOffFlow extends StatefulWidget {
  final GlobalKey<GlobalNavBarState>? navBarKey;
  const PageTakeOffFlow({super.key, this.navBarKey});

  @override
  State<PageTakeOffFlow> createState() => _PageTakeOffFlowState();
}

class _PageTakeOffFlowState extends State<PageTakeOffFlow> {
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
  String page_stage = "User"; // User , Machine , New_PR , New_Tube , Nozzle , Complete
  //String p_user_id = "220653 / HHCHENX"; // 220653
  String p_user_id = ""; // 220653
  String p_machine_id = "";
  String p_new_pr_id = "";
  String p_new_tube_id = "";
  String p_nozzle_id = "";

  bool _isButtonPressed = false;
  bool _isSubmitting = false; // 新增提交状态变量

  final Key _scannerVisibilityKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    // 為 VisibilityDetector 新增一個唯一的 Key

    // Flutter 没有 afterLoad 生命周期，但可以用 addPostFrameCallback 实现类似效果
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _afterLoad();
    });
  }

  void _afterLoad() {
    // 通过 globalNavBarKey.currentState 调用 setTitle
    globalNavBarKey.currentState?.setTitle('PRMS APP pageFun1');
  }

  checkStage() {
    if (p_user_id.isNotEmpty && p_machine_id.isNotEmpty && p_new_pr_id.isNotEmpty && p_new_tube_id.isNotEmpty) {
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
              page_stage = "New_PR";
            });
          }
        } else if (page_stage == "New_PR") {
          // 当符合 New PR ID 的格式时，才会更新 p_old_pr_id
          // PR開頭+6位數字，可依實際需求調整
          if (PrmsDataCheck.isValidPrId(scanContent)) {
            setState(() {
              p_new_pr_id = scanContent;
              page_stage = "New_Tube";
            });
          }
        } else if (page_stage == "New_Tube") {
          // 当符合 New Tube ID 的格式时，才会更新 p_old_pr_id
          // TUBE開頭+6位數字，可依實際需求調整
          if (PrmsDataCheck.isValidTubeId(scanContent)) {
            setState(() {
              p_new_tube_id = scanContent;
              page_stage = "Nozzle";
            });
          }
        } else if (page_stage == "Nozzle") {
          // 当符合 New Tube ID 的格式时，才会更新 p_old_pr_id
          // TUBE開頭+6位數字，可依實際需求調整
          if (PrmsDataCheck.isValidNozzleId(scanContent)) {
            setState(() {
              p_nozzle_id = scanContent;
              page_stage = "Complete";
            });
          }
        }

        // 在這裡可以根據需要處理掃描結果，例如顯示對話框或更新畫面
        // showDialog(
        //   context: context,
        //   builder: (context) => CupertinoAlertDialog(
        //     title: const Text('掃描結果'),
        //     content: Text(scanContent),
        //     actions: [
        //       CupertinoDialogAction(
        //         child: const Text('確定'),
        //         onPressed: () => Navigator.of(context).pop(),
        //       ),
        //     ],
        //   ),
        // );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    final screenWidth = MediaQuery.of(context).size.width;
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: screenWidth * 0.006),
                      child: Column(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                                child: Container(
                                  decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(6)),
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 3,
                                        height: 22,
                                        decoration: BoxDecoration(color: CupertinoColors.systemGrey3, borderRadius: BorderRadius.circular(2)),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Flow Stage ( Take Off Flow )',
                                        style: TextStyle(fontSize: 15, color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStageButton(
                                    context,
                                    icon: CupertinoIcons.person,
                                    label: 'User',
                                    selected: page_stage == "User",
                                    onTap: () {
                                      setState(() {
                                        page_stage = "User";
                                      });
                                    },
                                    height: 56,
                                  ),
                                  _buildStageButton(
                                    context,
                                    iconWidget: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset(
                                          'assets/machine.png',
                                          width: 22,
                                          height: 22,
                                          color: page_stage == "Machine" ? CupertinoColors.white : CupertinoColors.activeBlue,
                                        ),
                                      ],
                                    ),
                                    label: 'Mach.',
                                    selected: page_stage == "Machine",
                                    onTap: () {
                                      setState(() {
                                        page_stage = "Machine";
                                      });
                                    },
                                    height: 56,
                                  ),
                                  _buildStageButton(
                                    context,
                                    iconWidget: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.science,
                                          size: 16,
                                          color:
                                              page_stage == "New_PR"
                                                  ? Color(0xFF1E90FF) // Dodger Blue，代表“新”
                                                  : Color(0xFF1E90FF).withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                    label: 'PR',
                                    selected: page_stage == "New_PR",
                                    onTap: () {
                                      setState(() {
                                        page_stage = "New_PR";
                                      });
                                    },
                                    height: 56,
                                  ),
                                  _buildStageButton(
                                    context,
                                    iconWidget: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min, // 修正按钮内容宽度
                                      children: [
                                        Icon(
                                          CupertinoIcons.tag,
                                          size: 16,
                                          color:
                                              page_stage == "New_Tube"
                                                  ? Color(0xFF1E90FF) // Dodger Blue，代表“新”
                                                  : Color(0xFF1E90FF).withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                    label: 'Tube',
                                    selected: page_stage == "New_Tube",
                                    onTap: () {
                                      setState(() {
                                        page_stage = "New_Tube";
                                      });
                                    },
                                    height: 56,
                                  ),
                                  _buildStageButton(
                                    context,
                                    iconWidget: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min, // 修正按钮内容宽度
                                      children: [
                                        Icon(
                                          CupertinoIcons.arrow_uturn_down,
                                          size: 16,
                                          color:
                                              page_stage == "Nozzle"
                                                  ? Color(0xFF1E90FF) // Dodger Blue，代表“新”
                                                  : Color(0xFF1E90FF).withOpacity(0.7),
                                        ),
                                      ],
                                    ),
                                    label: 'Nozzle',
                                    selected: page_stage == "Nozzle",
                                    onTap: () {
                                      setState(() {
                                        page_stage = "Nozzle";
                                      });
                                    },
                                    height: 56,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 加入灰色dash样式的水平线
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final dashWidth = 1.5; // 更细腻
                                final dashSpace = 2.0; // 间距更小
                                final dashCount = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(dashCount, (_) {
                                    return Container(
                                      width: dashWidth,
                                      height: 1,
                                      color: const Color(0xFF888888), // 深一点的灰色
                                    );
                                  }),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          // 当前阶段提示区域优化
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // 阶段图标
                                      page_stage == "User"
                                          ? const Icon(CupertinoIcons.person, size: 32, color: CupertinoColors.activeBlue)
                                          : page_stage == "Machine"
                                          ? Image.asset('assets/machine.png', width: 44, height: 44, color: CupertinoColors.activeBlue)
                                          : page_stage == "New_PR"
                                          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.science, size: 28, color: Color(0xFF1E90FF))])
                                          : page_stage == "New_Tube"
                                          ? Row(mainAxisSize: MainAxisSize.min, children: [Icon(CupertinoIcons.tag, size: 28, color: Color(0xFF1E90FF))])
                                          : page_stage == "Nozzle"
                                          ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [Icon(CupertinoIcons.arrow_uturn_down, size: 28, color: Color(0xFF1E90FF))],
                                          )
                                          : const Icon(CupertinoIcons.add_circled, size: 0, color: CupertinoColors.activeBlue),
                                      SizedBox(width: 10),
                                      // 阶段提示语
                                      Flexible(
                                        child: Text(
                                          page_stage == "User"
                                              ? 'Scan your employee ID.'
                                              : page_stage == "Machine"
                                              ? 'Scan the barcode on the machine.'
                                              : page_stage == "New_PR"
                                              ? 'Scan barcode on PR bottle.'
                                              : page_stage == "New_Tube"
                                              ? 'Scan tube\'s barcode.'
                                              : page_stage == "Nozzle"
                                              ? 'Scan nozzle\'s barcode.'
                                              : '',
                                          style: TextStyle(fontSize: 17, color: CupertinoColors.activeBlue, fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.left,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // MobileScanner 区域
                  if (page_stage != "Complete")
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
                            height: MediaQuery.of(context).size.height * 0.36,
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
                                Positioned(
                                  top: 16.0,
                                  left: 16.0,
                                  child: CupertinoButton(
                                    padding: const EdgeInsets.all(8.0),
                                    color: CupertinoColors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(20.0),
                                    onPressed: () => _scannerController.switchCamera(),
                                    child: Icon(CupertinoIcons.camera_rotate, size: deviceSize.width * 0.06, color: CupertinoColors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  // page_stage == Complete 时的内容
                  if (page_stage == "Complete")
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.2), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Take Off  Flow Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: CupertinoColors.activeBlue,
                                letterSpacing: 1.2,
                                shadows: [Shadow(color: CupertinoColors.systemGrey.withOpacity(0.18), offset: Offset(0, 2), blurRadius: 4)],
                              ),
                            ),
                            SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                color: CupertinoColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.12), blurRadius: 8, offset: Offset(0, 2))],
                                border: Border.all(color: CupertinoColors.systemGrey4, width: 0.7),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRowStyled('User Id', p_user_id, CupertinoIcons.person),
                                  _buildDivider(),
                                  _buildInfoRowStyled(
                                    'Machine Id',
                                    p_machine_id,
                                    Icons.circle, // 传任意合法IconData避免类型错误
                                    iconWidget: Image.asset('assets/machine.png', width: 24, height: 24, color: CupertinoColors.activeBlue),
                                  ),
                                  _buildDivider(),

                                  _buildInfoRowStyled('PR Id', p_new_pr_id, Icons.science, color: Color(0xFF1E90FF)),
                                  _buildDivider(),
                                  _buildInfoRowStyled('Tube Id', p_new_tube_id, CupertinoIcons.tag, color: Color(0xFF1E90FF)),
                                  _buildDivider(),
                                  _buildInfoRowStyled('Nozzle Id', p_nozzle_id, CupertinoIcons.arrow_uturn_down, color: Color(0xFF1E90FF)),
                                ],
                              ),
                            ),
                            SizedBox(height: 28),
                            Center(
                              child: SizedBox(
                                width: 200,
                                child: GestureDetector(
                                  onTapDown: (_) => setState(() => _isButtonPressed = true),
                                  onTapUp: (_) => setState(() => _isButtonPressed = false),
                                  onTapCancel: () => setState(() => _isButtonPressed = false),
                                  onTap:
                                      _isSubmitting
                                          ? null
                                          : () async {
                                            setState(() {
                                              _isButtonPressed = false;
                                              _isSubmitting = true; // 开始提交
                                            });

                                            // 创建 Dio 实例并配置（仅用于开发环境）
                                            final dio = Dio();

                                            // 配置忽略SSL证书验证（仅用于开发环境）
                                            (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (client) {
                                              client.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
                                              return client;
                                            };

                                            final url = ApiConfig.proxyPostUrl;
                                            final postBody = {
                                              "url": ApiConfig.moveInSubmitUrl,
                                              "body": {
                                                "user_id": p_user_id,
                                                //"rack_id": p_rack_id,
                                                //"arr_pr": p_pr.map((pr) => {"pr_id": pr}).toList(), // 将 p_pr 转换为正确的数组格式
                                              },
                                            };

                                            try {
                                              final response = await dio.post(url, data: postBody, options: ApiConfig.defaultHttpOptions);

                                              if (response.statusCode == 200) {
                                                try {
                                                  final responseData = response.data;
                                                  if (responseData['status'] == 'success') {
                                                    await showCupertinoDialog(
                                                      context: context,
                                                      builder:
                                                          (context) => CupertinoAlertDialog(
                                                            title: Row(
                                                              children: [
                                                                Icon(CupertinoIcons.check_mark_circled_solid, color: CupertinoColors.activeGreen, size: 28),
                                                                SizedBox(width: 8),
                                                                Text('Move In Rack Success'),
                                                              ],
                                                            ),
                                                            content: Text('Your info has been submitted successfully.'),
                                                            actions: [
                                                              CupertinoDialogAction(
                                                                child: Text('Close'),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop(); // 先关闭弹窗
                                                                  Navigator.of(context).pushAndRemoveUntil(
                                                                    CupertinoPageRoute(builder: (context) => MainPage(title: 'PRMS APP', initialTabIndex: 0)),
                                                                    (route) => false,
                                                                  );
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  } else if (responseData['status'] == 'fail') {
                                                    await showCupertinoDialog(
                                                      context: context,
                                                      builder:
                                                          (context) => CupertinoAlertDialog(
                                                            title: Row(
                                                              children: [
                                                                Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed, size: 28),
                                                                SizedBox(width: 8),
                                                                Text('Move In Rack Fail'),
                                                              ],
                                                            ),
                                                            content: Text(responseData['message']),
                                                            actions: [
                                                              CupertinoDialogAction(
                                                                child: Text('Close'),
                                                                onPressed: () {
                                                                  Navigator.of(context).pop(); // 先关闭弹窗
                                                                },
                                                              ),
                                                            ],
                                                          ),
                                                    );
                                                  } else {
                                                    // 如果status不是success，显示错误信息
                                                    debugPrint('提交失败: ${responseData['message'] ?? 'Unknown error'}');
                                                  }
                                                } catch (parseError) {
                                                  debugPrint('响应解析失败: ${parseError.toString()}');
                                                }
                                                debugPrint('提交成功: ${response.data}');
                                              } else {
                                                // 失败处理
                                                debugPrint('提交失败: 状态码 ${response.statusCode}');
                                              }
                                            } catch (e) {
                                              if (e is DioException) {
                                                await showCupertinoDialog(
                                                  context: context,
                                                  builder:
                                                      (context) => CupertinoAlertDialog(
                                                        title: Row(
                                                          children: [
                                                            Icon(CupertinoIcons.exclamationmark_triangle_fill, color: CupertinoColors.systemRed, size: 28),
                                                            SizedBox(width: 8),
                                                            Text('Data submission failed'),
                                                          ],
                                                        ),
                                                        content: Text('Please check your network connection or try again later.'),
                                                        actions: [
                                                          CupertinoDialogAction(
                                                            child: Text('Close'),
                                                            onPressed: () {
                                                              Navigator.of(context).pop(); // 先关闭弹窗
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                );
                                              } else {
                                                debugPrint('请求异常: ${e.toString()}');
                                              }
                                            } finally {
                                              // 无论成功还是失败，都重置提交状态
                                              if (mounted) {
                                                setState(() {
                                                  _isSubmitting = false;
                                                });
                                              }
                                            }
                                          },
                                  child: AnimatedScale(
                                    scale: _isButtonPressed == true ? 0.96 : 1.0,
                                    duration: Duration(milliseconds: 80),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: _isSubmitting ? CupertinoColors.systemGrey3 : CupertinoColors.activeBlue,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [BoxShadow(color: CupertinoColors.systemGrey4.withOpacity(0.18), blurRadius: 8, offset: Offset(0, 2))],
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (_isSubmitting)
                                            CupertinoActivityIndicator(color: CupertinoColors.white)
                                          else
                                            Icon(CupertinoIcons.paperplane_fill, color: CupertinoColors.white, size: 32),
                                          SizedBox(width: 4),
                                          Text(
                                            _isSubmitting ? 'Submitting...' : 'Submit',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CupertinoColors.white, letterSpacing: 0.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(padding: EdgeInsets.only(bottom: 16.0, left: screenWidth * 0.1, right: screenWidth * 0.1), child: _buildBottomInfo()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

  // 新增iOS风格按钮构建方法
  Widget _buildStageButton(
    BuildContext context, {
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    double height = 48, // 新增height参数，默认48
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: SizedBox(
          height: height, // 统一高度
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
            color: selected ? const Color(0xFF204080) : CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(8),
            onPressed: onTap,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget ?? Icon(icon, size: 22, color: selected ? CupertinoColors.white : CupertinoColors.activeBlue),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: selected ? CupertinoColors.white : CupertinoColors.systemGrey,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 專業iOS表單行（帶圖標與顏色）
  Widget _buildInfoRowStyled(
    String label,
    String value,
    IconData? icon, {
    Color? color,
    Widget? iconWidget,
    Image? img, // 新增参数
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          iconWidget ??
              (icon != null
                  ? Icon(icon, size: 22, color: color ?? CupertinoColors.systemGrey)
                  : (img != null ? SizedBox(width: 22, height: 22, child: img) : SizedBox(width: 22, height: 22))),
          SizedBox(width: 10),
          SizedBox(width: 110, child: Text(label, style: TextStyle(color: CupertinoColors.systemGrey, fontWeight: FontWeight.w500, fontSize: 15))),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: CupertinoColors.label, fontWeight: FontWeight.bold, fontSize: 16),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 專業iOS分隔線
  Widget _buildDivider() {
    return Container(margin: EdgeInsets.symmetric(horizontal: 12), height: 1, color: CupertinoColors.systemGrey5);
  }

  // 优化底部信息显示，减少重复判断
  Widget _buildBottomInfo() {
    String info = '';
    if (page_stage == "User" && p_user_id.isNotEmpty) {
      info = 'User Id : $p_user_id';
    } else if (page_stage == "Machine" && p_machine_id.isNotEmpty) {
      info = 'Machine Id : $p_machine_id';
    } else if (page_stage == "New_PR" && p_new_pr_id.isNotEmpty) {
      info = 'New PR Id : $p_new_pr_id';
    } else if (page_stage == "New_Tube" && p_new_tube_id.isNotEmpty) {
      info = 'New Tube Id : $p_new_tube_id';
    }
    if (info.isEmpty) return const SizedBox.shrink();
    return Text(
      info,
      style: const TextStyle(
        color: Color(0xFF204080), // 柔和蓝色
        fontSize: 20.0, // 更大
        fontWeight: FontWeight.w600, // 半粗体
        letterSpacing: 0.5,
        shadows: [Shadow(color: Color(0x22000000), offset: Offset(0, 1), blurRadius: 2)],
      ),
      textAlign: TextAlign.center,
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
