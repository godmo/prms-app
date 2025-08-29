// 忽略已弃用成员使用警告
// ignore_for_file: deprecated_member_use

// Flutter 基础组件
/// PRMS 主功能卡片组件
/// 展示所有光阻液相关操作按钮
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// 获取应用版本信息的插件
import 'package:package_info_plus/package_info_plus.dart';
// 各功能页面
import 'package:prmsapp/pages/page_clean_flow.dart'; // 清洁流程页面
import 'package:prmsapp/pages/page_cumsume.dart'; // 消耗页面
import 'package:prmsapp/pages/page_incoming_scan.dart'; // 进货扫描页面
import 'package:prmsapp/pages/page_move_in_rack.dart'; // 移入机架页面
import 'package:prmsapp/pages/page_move_out_rack.dart'; // 移出机架页面
import 'package:prmsapp/pages/page_put_on_flow.dart'; // 上机流程页面
import 'package:prmsapp/pages/page_take_off_flow.dart'; // 下机流程页面
// 全域狀態管理
import 'package:prmsapp/providers/wifi_provider.dart'; // WiFi Provider
// 服务类
import 'package:prmsapp/services/prms_api.dart'; // PRMS API服务
// 引入 Provider
import 'package:provider/provider.dart';

/// PRMS 主功能卡片组件
/// 展示所有光阻液相关操作按钮
class BindingPrmsCard extends StatefulWidget {
  const BindingPrmsCard({super.key});

  @override
  State<BindingPrmsCard> createState() => _BindingPCCardState();
}

/// 绑定卡片的状态类，负责渲染所有按钮和功能
class _BindingPCCardState extends State<BindingPrmsCard> with WidgetsBindingObserver {
  // 是否被点击（预留扩展）
  bool isTapped = false;

  // 当前 WiFi SSID
  String currentSSID = 'Loading...';

  @override
  void initState() {
    super.initState();
    // 添加应用生命周期监听器
    WidgetsBinding.instance.addObserver(this);
    // 初始化时执行 WiFi 检查
    _performWiFiCheck();
  }

  @override
  void dispose() {
    // 移除应用生命周期监听器
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台返回到前台时执行 WiFi 检查
    if (state == AppLifecycleState.resumed) {
      _performWiFiCheck();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 当从其他页面返回时执行 WiFi 检查
    _performWiFiCheck();
  }

  /// 执行 WiFi 检查的方法
  void _performWiFiCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        try {
          final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);

          // 执行白名单检查，这会更新 WiFi 信息
          await wifiProvider.checkWiFiWithWhitelist(context);

          // 更新状态显示 SSID
          if (mounted) {
            setState(() {
              currentSSID = wifiProvider.wifiSSID.isNotEmpty ? wifiProvider.wifiSSID : 'Not Connected';
            });
          }
        } catch (e) {
          // 如果获取 SSID 失败，显示错误信息
          if (mounted) {
            setState(() {
              currentSSID = 'Error: ${e.toString()}';
            });
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕宽度用于自适应布局，确保在不同设备上都能正确显示
    final screenWidth = MediaQuery.of(context).size.width;

    // 返回主容器，包含所有PRMS功能按钮
    return Container(
      // 设置外边距：垂直方向无边距
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      // 设置内边距：水平方向根据屏幕宽度自适应(6%)，垂直方向固定15像素
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 15.0),
      // 设置容器装饰样式
      decoration: BoxDecoration(
        // 设置渐变背景：从浅蓝色到白色的线性渐变
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // 浅蓝色 - 渐变起始色
            Color(0xFFFFFFFF), // 白色 - 渐变结束色
          ],
          begin: Alignment.topCenter, // 渐变从顶部中心开始
          end: Alignment.bottomCenter, // 渐变到底部中心结束
        ),
        // 设置圆角：8像素圆角矩形
        borderRadius: BorderRadius.circular(8.0),
        // 设置阴影效果：灰色半透明阴影，增加立体感
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      // 主体为可滚动区域，包含所有操作按钮
      child: CustomScrollView(
        // 收缩包装：仅使用必要的空间
        shrinkWrap: true,
        // 使用ClampingScrollPhysics：防止过度滚动效果
        physics: const ClampingScrollPhysics(),
        slivers: [
          // 使用SliverFillRemaining确保内容填充剩余空间
          SliverFillRemaining(
            hasScrollBody: false, // 不需要滚动体，因为内容是固定的
            child: Column(
              // 子组件在横向上拉伸填充
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 更换光阻液 - 消耗功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.arrow_2_squarepath, // 交换/置换的合适图标
                  label: ' Consume',
                  onPressed: () {
                    // 跳转到消耗页面，处理光阻液的消耗记录
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageCunsume()));
                  },
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液上防爆柜 - 移入机架功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.tray_arrow_down, // 更贴合"放进柜子"功能的图标
                  label: ' Move In Rack',
                  onPressed: () {
                    // 跳转到移入机架页面，处理将光阻液放入防爆柜的流程
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageMoveInRack()));
                  },
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液下防爆柜 - 移出机架功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.tray_arrow_up, // 更贴合"从柜子取出"功能的图标
                  label: ' Move Out Rack',
                  onPressed: () {
                    // 跳转到移出机架页面，处理从防爆柜取出光阻液的流程
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageMoveOutRack()));
                  },
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液上机 - 上机流程功能按钮（使用自定义图片图标）
                _buildCupertinoButtonWithIcons(
                  context,
                  icons: [], // 不使用系统图标，使用自定义图片
                  label: 'Put On Flow',
                  onPressed: () {
                    // 跳转到上机流程页面，处理光阻液上机的完整流程
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PagePutOnFlow()));
                  },
                  // 使用自定义图片作为按钮图标
                  imageWidget: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.asset(
                      'assets/put_on_flow.png', // 上机流程专用图标
                      width: 28,
                      height: 28,
                      color: CupertinoColors.activeBlue, // 使用活泼的蓝色作为图标颜色
                    ),
                  ),
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液下机 - 下机流程功能按钮（使用自定义图片图标）
                _buildCupertinoButtonWithIcons(
                  context,
                  icons: [], // 不使用系统图标，使用自定义图片
                  label: 'Take Off Flow',
                  onPressed: () {
                    // 跳转到下机流程页面，处理光阻液下机的完整流程
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageTakeOffFlow()));
                  },
                  // 使用自定义图片作为按钮图标
                  imageWidget: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.asset('assets/take_off_flow.png', width: 28, height: 28, color: CupertinoColors.activeBlue),
                  ),
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液解除 Alert - 清洁流程功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // 更贴合"清除/重置"用途的图标
                  label: '  Clean Flow',
                  onPressed: () {
                    // 跳转到清洁流程页面，处理设备清洁和状态重置
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageCleanFlow()));
                  },
                ),
                SizedBox(height: 6), // 按钮间距
                // 光阻液解除 Alert - 清洁流程功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.camera_viewfinder, // 更贴合"清除/重置"用途的图标
                  label: '  Incoming Scan',
                  onPressed: () {
                    // 跳转到清洁流程页面，处理设备清洁和状态重置
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageIncomingScan()));
                  },
                ),
                // SizedBox(height: 6), // 按钮间距
                // // 取得目前的网路基地台 SSID - WiFi信息查询功能按钮
                // _buildCupertinoButton(
                //   context,
                //   icon: CupertinoIcons.refresh_circled, // WiFi信息查询图标
                //   label: '  Get WiFi SSID',
                //   onPressed: () {
                //     // 获取并显示当前连接的WiFi网络信息
                //     _showWifiSSID(context);
                //   },
                // ),
                SizedBox(height: 6), // 按钮间距
                // 检查App版本 - 版本信息查询功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // 版本检查图标
                  label: '  Check App Version',
                  onPressed: () {
                    // 弹窗显示应用版本信息和服务器连接状态
                    _showVersionDialog(context);
                  },
                ),
                // SizedBox(height: 6), // 按钮间距
                // // WiFi 白名單管理 - 管理允許的 WiFi 網路
                // _buildCupertinoButton(
                //   context,
                //   icon: CupertinoIcons.lock_shield, // WiFi 安全管理圖標
                //   label: '  WiFi Whitelist',
                //   onPressed: () {
                //     // 跳轉到 WiFi 白名單管理頁面
                //     Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const WiFiWhitelistManagerPage()));
                //   },
                // ),
                SizedBox(height: 6), // 按钮间距
                // 使用Expanded占据剩余空间，将版权信息推到底部
                Expanded(child: SizedBox()),
                // WiFi SSID 显示区域
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey6.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: CupertinoColors.systemGrey4.withOpacity(0.6), width: 1.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.wifi,
                        color: currentSSID.contains('Error') || currentSSID == 'Not Connected' ? CupertinoColors.systemRed : CupertinoColors.systemGreen,
                        size: 16.0,
                      ),
                      const SizedBox(width: 8.0),
                      Flexible(
                        child: Text(
                          'WiFi: $currentSSID',
                          style: TextStyle(
                            color: currentSSID.contains('Error') || currentSSID == 'Not Connected' ? CupertinoColors.systemRed : CupertinoColors.systemBlue,
                            fontSize: 12.0,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                // 版权信息区域
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, bottom: 4.0),
                  child: Text(
                    'Copyright © 2025 VIS,VSMC. All rights reserved.',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue, // 使用活泼的蓝色
                      fontSize: 10.0, // 小字体
                      fontWeight: FontWeight.bold, // 粗体
                      letterSpacing: 0.3, // 字母间距
                      // 添加文字阴影效果，增强视觉层次
                      shadows: [Shadow(color: CupertinoColors.systemGrey.withOpacity(0.2), offset: Offset(0, 1), blurRadius: 2)],
                    ),
                    textAlign: TextAlign.center, // 居中对齐
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标准的Cupertino风格按钮
  ///
  /// 参数说明：
  /// - [context]: 构建上下文
  /// - [icon]: 按钮左侧显示的图标
  /// - [label]: 按钮显示的文本标签
  /// - [onPressed]: 按钮点击时的回调函数
  ///
  /// 返回一个带有边框、白色背景、圆角的按钮组件
  Widget _buildCupertinoButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Container(
      // 设置按钮边框：浅灰色细边框，圆角4像素
      decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey3, width: 0.8), borderRadius: BorderRadius.circular(4)),
      child: CupertinoButton(
        color: CupertinoColors.white, // 按钮背景色为白色
        borderRadius: BorderRadius.circular(4), // 按钮圆角4像素
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // 按钮内边距
        onPressed: onPressed, // 点击回调
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 子组件从左开始排列
          children: [
            // 左侧图标
            Icon(icon, color: CupertinoColors.activeBlue, size: 24),
            const SizedBox(width: 12), // 图标与文字间距
            // 中间文本标签，使用Expanded占据剩余空间
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black, letterSpacing: 0.2))),
            // 右侧箭头图标，表示可点击跳转
            Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 22),
          ],
        ),
      ),
    );
  }

  /// 构建支持多图标和自定义图片的Cupertino风格按钮
  ///
  /// 参数说明：
  /// - [context]: 构建上下文
  /// - [icons]: 系统图标列表（当前主要用于兼容，实际多使用imageWidget）
  /// - [label]: 按钮显示的文本标签
  /// - [onPressed]: 按钮点击时的回调函数
  /// - [imageWidget]: 可选的自定义图片组件，用于替代系统图标
  ///
  /// 返回一个可以同时支持系统图标和自定义图片的按钮组件
  Widget _buildCupertinoButtonWithIcons(
    BuildContext context, {
    required List<IconData> icons,
    required String label,
    required VoidCallback onPressed,
    Widget? imageWidget, // 新增可选的imageWidget参数
  }) {
    return Container(
      // 设置按钮边框：浅灰色细边框，圆角4像素
      decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey3, width: 0.8), borderRadius: BorderRadius.circular(4)),
      child: CupertinoButton(
        color: CupertinoColors.white, // 按钮背景色为白色
        borderRadius: BorderRadius.circular(4), // 按钮圆角4像素
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), // 按钮内边距
        onPressed: onPressed, // 点击回调
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start, // 子组件从左开始排列
          children: [
            // 如果提供了自定义图片组件则优先显示
            if (imageWidget != null) imageWidget,
            // 显示系统图标列表（如果有的话）
            Row(
              children:
                  icons
                      .map((icon) => Padding(padding: const EdgeInsets.only(right: 6), child: Icon(icon, color: CupertinoColors.activeBlue, size: 22)))
                      .toList(),
            ),
            const SizedBox(width: 8), // 图标与文字间距
            // 中间文本标签，使用Expanded占据剩余空间
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black, letterSpacing: 0.2))),
            // 右侧箭头图标，表示可点击跳转
            Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 22),
          ],
        ),
      ),
    );
  }

  /// 显示应用版本信息对话框
  ///
  /// 功能说明：
  /// 1. 创建一个包含版本检查功能的对话框
  /// 2. 使用FutureBuilder异步获取服务器版本信息和本地版本信息
  /// 3. 显示本地版本、服务器版本和连接状态
  /// 4. 根据连接状态显示不同的UI反馈
  ///
  /// 参数：
  /// - [context]: 用于显示对话框的构建上下文
  void _showVersionDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          // 对话框标题
          title: const Text('App Version', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
          // 对话框内容：使用FutureBuilder异步加载版本信息
          content: FutureBuilder<Map<String, dynamic>>(
            future: _getVersionInfo(), // 获取版本信息（包括本地和服务器版本）
            builder: (context, snapshot) {
              // 显示加载状态
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 16),
                    CupertinoActivityIndicator(), // iOS风格的加载指示器
                    SizedBox(height: 16),
                    Text('Checking version...'), // 加载提示文本
                  ],
                );
              } else {
                // 处理加载完成后的数据
                final versionInfo = snapshot.data ?? {};
                final localVersion = versionInfo['localVersion'] ?? 'Unknown'; // 本地版本
                final serverVersionData = versionInfo['serverVersion'] as Map<String, dynamic>?;
                final isConnected = serverVersionData?['success'] == true; // 服务器连接状态
                final serverVersion = serverVersionData?['version'] ?? 'Unknown'; // 服务器版本
                final errorMessage = serverVersionData?['error']; // 错误信息

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // 应用名称
                    const Text('PRMS App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    // 本地版本信息（动态获取）
                    Text('Local Version: $localVersion', style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 8),
                    // 服务器版本信息（动态获取）
                    Text(
                      'Server Version: $serverVersion',
                      style: TextStyle(
                        fontSize: 14,
                        // 根据连接状态设置颜色
                        color: isConnected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                        fontWeight: isConnected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 构建信息
                    const Text('Build: PRMA APP', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 8),
                    // 服务器连接状态指示
                    Text(
                      isConnected ? 'Server connection: ✓' : 'Server connection: ✗',
                      style: TextStyle(fontSize: 14, color: isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed),
                    ),
                    // 如果连接失败且有错误信息，则显示错误详情
                    if (!isConnected && errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(errorMessage, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed), textAlign: TextAlign.center),
                    ],
                  ],
                );
              }
            },
          ),
          // 对话框操作按钮
          actions: [
            CupertinoDialogAction(
              child: const Text('OK', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
            ),
          ],
        );
      },
    );
  }

  /// 获取版本信息（本地版本和服务器版本）
  ///
  /// 返回包含本地版本和服务器版本信息的Map
  Future<Map<String, dynamic>> _getVersionInfo() async {
    String localVersion = 'Unknown';
    Map<String, dynamic>? serverVersionData;

    try {
      // 尝试获取本地版本信息
      final packageInfo = await PackageInfo.fromPlatform();

      // 检查版本和构建号是否为空
      final version = packageInfo.version;
      final buildNumber = packageInfo.buildNumber;

      if (version.isNotEmpty && buildNumber.isNotEmpty) {
        localVersion = '$version+$buildNumber';
      } else if (version.isNotEmpty) {
        localVersion = version;
      } else {
        localVersion = 'Unknown (Empty version)';
      }
    } catch (e) {
      print('获取PackageInfo失败: $e');
      // 如果是 MissingPluginException，说明插件没有正确注册
      if (e.toString().contains('MissingPluginException')) {
        localVersion = '1.0.2+1 (Plugin error)';
      } else {
        localVersion = '1.0.2+1 (Error: ${e.runtimeType})';
      }
    }

    try {
      // 获取服务器版本信息
      serverVersionData = await PrmsApi.getAppVersion();
    } catch (e) {
      print('获取服务器版本失败: $e');
      serverVersionData = {'success': false, 'error': 'Failed to fetch server version: $e'};
    }

    return {
      'localVersion': localVersion,
      'serverVersion': serverVersionData ?? {'success': false, 'error': 'Server version data is null'},
    };
  }
}
