// 忽略已弃用成员使用警告
// ignore_for_file: deprecated_member_use

// Flutter 基础组件
/// PRMS 主功能卡片组件
/// 展示所有光阻液相关操作按钮
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// 获取网络信息的插件
import 'package:network_info_plus/network_info_plus.dart';
// 各功能页面
import 'package:prmsapp/pages/page_clean_flow.dart'; // 清洁流程页面
import 'package:prmsapp/pages/page_cumsume.dart'; // 消耗页面
import 'package:prmsapp/pages/page_incoming_scan.dart'; // 进货扫描页面
import 'package:prmsapp/pages/page_move_in_rack.dart'; // 移入机架页面
import 'package:prmsapp/pages/page_move_out_rack.dart'; // 移出机架页面
import 'package:prmsapp/pages/page_put_on_flow.dart'; // 上机流程页面
import 'package:prmsapp/pages/page_take_off_flow.dart'; // 下机流程页面
// 服务类
import 'package:prmsapp/services/prms_api.dart'; // PRMS API服务
import 'package:prmsapp/services/wifi_service.dart'; // WiFi服务

/// PRMS 主功能卡片组件
/// 展示所有光阻液相关操作按钮
class BindingPrmsCard extends StatefulWidget {
  const BindingPrmsCard({super.key});

  @override
  State<BindingPrmsCard> createState() => _BindingPCCardState();
}

/// 绑定卡片的状态类，负责渲染所有按钮和功能
class _BindingPCCardState extends State<BindingPrmsCard> {
  // 是否被点击（预留扩展）
  bool isTapped = false;

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
                SizedBox(height: 6), // 按钮间距
                // 取得目前的网路基地台 SSID - WiFi信息查询功能按钮
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // WiFi信息查询图标
                  label: '  Get WiFi SSID',
                  onPressed: () {
                    // 获取并显示当前连接的WiFi网络信息
                    _showWifiSSID(context);
                  },
                ),
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
                SizedBox(height: 6), // 按钮间距
                // 使用Expanded占据剩余空间，将版权信息推到底部
                Expanded(child: SizedBox()),
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

  /// 显示WiFi SSID信息的异步方法
  ///
  /// 功能说明：
  /// 1. 使用原生iOS方法获取WiFi网络信息
  /// 2. 处理各种错误情况（权限拒绝、无网络接口等）
  /// 3. 尝试获取补充信息如IP地址
  /// 4. 以对话框形式显示结果
  ///
  /// 参数：
  /// - [context]: 用于显示对话框的构建上下文
  void _showWifiSSID(BuildContext context) async {
    try {
      // 注释的代码：显示加载指示器
      // if (context.mounted) {
      //   _showLoadingDialog(context);
      // }

      // 使用原生iOS方法获取WiFi信息
      final wifiResult = await WifiService.getWifiSSIDNative();

      // 注释的代码：关闭加载对话框
      // if (context.mounted) {
      //   Navigator.of(context).pop();
      // }

      String displayText = '';

      // 处理成功获取WiFi信息的情况
      if (wifiResult['success'] == true) {
        final ssid = wifiResult['ssid'] as String? ?? '';
        final bssid = wifiResult['bssid'] as String? ?? '';

        if (ssid.isNotEmpty) {
          // 移除SSID中的引号（如果有的话）
          String cleanWifiName = ssid.replaceAll('"', '');
          displayText = 'WiFi SSID: $cleanWifiName';
          // 如果有BSSID信息则添加显示
          if (bssid.isNotEmpty) {
            displayText += '\nBSSID: $bssid';
          }

          // 尝试获取IP地址作为补充信息（使用原来的方法）
          try {
            final info = NetworkInfo();
            final wifiIP = await info.getWifiIP();
            if (wifiIP != null && wifiIP.isNotEmpty) {
              displayText += '\nIP Address: $wifiIP';
            }
          } catch (e) {
            // IP获取失败不影响主要功能，只打印调试信息
            print('Failed to get IP: $e');
          }
        } else {
          // 无WiFi连接或信息不可用的提示
          displayText = 'No WiFi connection detected or WiFi information not available.\n\nNote: On iOS simulators, WiFi information is always unavailable.';
        }
      } else {
        // 处理各种错误情况
        final errorCode = wifiResult['code'] as String?;
        final errorMessage = wifiResult['error'] as String? ?? 'Unknown error';

        // 根据错误代码提供具体的解决方案
        if (errorCode == 'PERMISSION_DENIED') {
          displayText =
              'Location permission is required to get WiFi information.\n\nPlease grant location permission in Settings:\nSettings > Privacy & Security > Location Services > PRMS App';
        } else if (errorCode == 'NO_INTERFACES') {
          displayText = 'No network interfaces found.\n\nPlease ensure your device is connected to WiFi and try again.';
        } else {
          displayText =
              'Failed to get WiFi information: $errorMessage\n\nPlease ensure:\n• Location services are enabled\n• App has location permission\n• Device is connected to WiFi\n• Local network access is granted (iOS 14+)';
        }
      }

      // 确保context仍然有效后显示结果对话框
      if (context.mounted) {
        _showSSIDDialog(context, 'WiFi Information', displayText);
      }
    } catch (e) {
      // 异常处理：确保关闭可能存在的加载对话框
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      // 显示异常错误信息
      if (context.mounted) {
        _showSSIDDialog(
          context,
          'Error',
          'Failed to get WiFi information: ${e.toString()}\n\nPlease ensure:\n• Location services are enabled\n• App has location permission\n• Device is connected to WiFi',
        );
      }
    }
  }

  /// 显示WiFi信息对话框
  ///
  /// 参数说明：
  /// - [context]: 构建上下文
  /// - [title]: 对话框标题
  /// - [content]: 对话框内容文本
  ///
  /// 创建并显示一个Cupertino风格的信息对话框
  void _showSSIDDialog(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          // 对话框标题样式
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
          // 对话框内容区域
          content: Padding(
            padding: const EdgeInsets.only(top: 16), // 标题与内容间距
            child: Text(content, style: const TextStyle(fontSize: 14, color: CupertinoColors.black), textAlign: TextAlign.left),
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

  /// 显示应用版本信息对话框
  ///
  /// 功能说明：
  /// 1. 创建一个包含版本检查功能的对话框
  /// 2. 使用FutureBuilder异步获取服务器版本信息
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
          content: FutureBuilder<Map<String, dynamic>?>(
            future: PrmsApi.getAppVersion(), // 调用API获取版本信息
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
                final versionData = snapshot.data;
                final isConnected = versionData?['success'] == true; // 服务器连接状态
                final serverVersion = versionData?['version'] ?? 'Unknown'; // 服务器版本
                final errorMessage = versionData?['error']; // 错误信息

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    // 应用名称
                    const Text('PRMS App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    // 本地版本信息（硬编码）
                    const Text('Local Version: 1.0.0+1', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
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
}
