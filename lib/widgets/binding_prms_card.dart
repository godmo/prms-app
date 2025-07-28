// ignore_for_file: deprecated_member_use
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:prmsapp/pages/page_clean_flow.dart';
import 'package:prmsapp/pages/page_cumsume.dart';
import 'package:prmsapp/pages/page_move_in_rack.dart';
import 'package:prmsapp/pages/page_move_out_rack.dart';
import 'package:prmsapp/pages/page_put_on_flow.dart';
import 'package:prmsapp/pages/page_take_off_flow.dart';
import 'package:prmsapp/services/prms_api.dart';
import 'package:prmsapp/services/wifi_service.dart';

class BindingPrmsCard extends StatefulWidget {
  const BindingPrmsCard({super.key});

  @override
  State<BindingPrmsCard> createState() => _BindingPCCardState();
}

class _BindingPCCardState extends State<BindingPrmsCard> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 15.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE3F2FD), // 浅蓝色
            Color(0xFFFFFFFF), // 白色
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: CustomScrollView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 更换光阻液
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.arrow_2_squarepath, // 交换/置换的合适图标
                  label: ' Consume',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageCunsume()));
                  },
                ),
                SizedBox(height: 6),
                // 光阻液上防爆柜
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.tray_arrow_down, // 更贴合“放进柜子”功能的图标
                  label: ' Move In Rack',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageMoveInRack()));
                  },
                ),
                SizedBox(height: 6),
                // 光阻液下防爆柜
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.tray_arrow_up, // 更贴合“从柜子取出”功能的图标
                  label: ' Move Out Rack',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageMoveOutRack()));
                  },
                ),
                SizedBox(height: 6),
                // 光阻液上机
                _buildCupertinoButtonWithIcons(
                  context,
                  icons: [], // 不再用icon
                  label: 'Put On Flow',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PagePutOnFlow()));
                  },
                  // 新增 imageWidget 参数
                  imageWidget: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.asset(
                      'assets/put_on_flow.png',
                      width: 28,
                      height: 28,
                      color: CupertinoColors.activeBlue, // 使用活泼的蓝色
                    ),
                  ),
                ),
                SizedBox(height: 6),
                // 光阻液下机
                _buildCupertinoButtonWithIcons(
                  context,
                  icons: [], // 不再用icon
                  label: 'Take Off Flow',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageTakeOffFlow()));
                  },
                  imageWidget: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Image.asset('assets/take_off_flow.png', width: 28, height: 28, color: CupertinoColors.activeBlue),
                  ),
                ),
                SizedBox(height: 6),
                // 光阻液解除 Alert
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // 更贴合“清除/重置”用途的图标
                  label: '  Clean Flow',
                  onPressed: () {
                    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => const PageCleanFlow()));
                  },
                ),
                SizedBox(height: 6),
                // 取得目前的网路基地台 SID
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // 更贴合“清除/重置”用途的图标
                  label: '  Get WiFi SSID',
                  onPressed: () {
                    _showWifiSSID(context);
                  },
                ),
                SizedBox(height: 6),
                // 光阻液解除 Alert
                _buildCupertinoButton(
                  context,
                  icon: CupertinoIcons.refresh_circled, // 更贴合“清除/重置”用途的图标
                  label: '  Check App Version',
                  onPressed: () {
                    _showVersionDialog(context);
                  },
                ),
                SizedBox(height: 6),
                // 计算最后一个按钮和底部版权信息之间的剩余空间
                Expanded(child: SizedBox()),
                Padding(
                  padding: const EdgeInsets.only(top: 0.0, bottom: 4.0),
                  child: Text(
                    'Copyright © 2025 VIS,VSMC. All rights reserved.',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue, // 更活泼的蓝色
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      shadows: [Shadow(color: CupertinoColors.systemGrey.withOpacity(0.2), offset: Offset(0, 1), blurRadius: 2)],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCupertinoButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey3, width: 0.8), borderRadius: BorderRadius.circular(4)),
      child: CupertinoButton(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(icon, color: CupertinoColors.activeBlue, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black, letterSpacing: 0.2))),
            Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 22),
          ],
        ),
      ),
    );
  }

  // 新增多icon按钮构建方法
  Widget _buildCupertinoButtonWithIcons(
    BuildContext context, {
    required List<IconData> icons,
    required String label,
    required VoidCallback onPressed,
    Widget? imageWidget, // 新增可选的imageWidget参数
  }) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey3, width: 0.8), borderRadius: BorderRadius.circular(4)),
      child: CupertinoButton(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            if (imageWidget != null) imageWidget, // 如果提供了imageWidget则显示
            Row(
              children:
                  icons
                      .map((icon) => Padding(padding: const EdgeInsets.only(right: 6), child: Icon(icon, color: CupertinoColors.activeBlue, size: 22)))
                      .toList(),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black, letterSpacing: 0.2))),
            Icon(CupertinoIcons.right_chevron, color: CupertinoColors.systemGrey, size: 22),
          ],
        ),
      ),
    );
  }

  void _showWifiSSID(BuildContext context) async {
    try {
      // 显示加载指示器
      // if (context.mounted) {
      //   _showLoadingDialog(context);
      // }

      // 使用原生iOS方法获取WiFi信息
      final wifiResult = await WifiService.getWifiSSIDNative();

      // 关闭加载对话框
      // if (context.mounted) {
      //   Navigator.of(context).pop();
      // }

      String displayText = '';

      if (wifiResult['success'] == true) {
        final ssid = wifiResult['ssid'] as String? ?? '';
        final bssid = wifiResult['bssid'] as String? ?? '';

        if (ssid.isNotEmpty) {
          // 移除引号（如果有的话）
          String cleanWifiName = ssid.replaceAll('"', '');
          displayText = 'WiFi SSID: $cleanWifiName';
          if (bssid.isNotEmpty) {
            displayText += '\nBSSID: $bssid';
          }

          // 如果可能，尝试获取IP地址（使用原来的方法作为补充）
          try {
            final info = NetworkInfo();
            final wifiIP = await info.getWifiIP();
            if (wifiIP != null && wifiIP.isNotEmpty) {
              displayText += '\nIP Address: $wifiIP';
            }
          } catch (e) {
            // IP获取失败不影响主要功能
            print('Failed to get IP: $e');
          }
        } else {
          displayText = 'No WiFi connection detected or WiFi information not available.\n\nNote: On iOS simulators, WiFi information is always unavailable.';
        }
      } else {
        // 处理错误情况
        final errorCode = wifiResult['code'] as String?;
        final errorMessage = wifiResult['error'] as String? ?? 'Unknown error';

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

      if (context.mounted) {
        _showSSIDDialog(context, 'WiFi Information', displayText);
      }
    } catch (e) {
      // 确保关闭可能存在的加载对话框
      if (context.mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      if (context.mounted) {
        _showSSIDDialog(
          context,
          'Error',
          'Failed to get WiFi information: ${e.toString()}\n\nPlease ensure:\n• Location services are enabled\n• App has location permission\n• Device is connected to WiFi',
        );
      }
    }
  }

  void _showSSIDDialog(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(content, style: const TextStyle(fontSize: 14, color: CupertinoColors.black), textAlign: TextAlign.left),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showVersionDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('App Version', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
          content: FutureBuilder<Map<String, dynamic>?>(
            future: PrmsApi.getAppVersion(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [SizedBox(height: 16), CupertinoActivityIndicator(), SizedBox(height: 16), Text('Checking version...')],
                );
              } else {
                final versionData = snapshot.data;
                final isConnected = versionData?['success'] == true;
                final serverVersion = versionData?['version'] ?? 'Unknown';
                final errorMessage = versionData?['error'];

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text('PRMS App', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    const Text('Local Version: 1.0.0+1', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 8),
                    Text(
                      'Server Version: $serverVersion',
                      style: TextStyle(
                        fontSize: 14,
                        color: isConnected ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                        fontWeight: isConnected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Build: PRMA APP', style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
                    const SizedBox(height: 8),
                    Text(
                      isConnected ? 'Server connection: ✓' : 'Server connection: ✗',
                      style: TextStyle(fontSize: 14, color: isConnected ? CupertinoColors.systemGreen : CupertinoColors.systemRed),
                    ),
                    if (!isConnected && errorMessage != null) ...[
                      const SizedBox(height: 4),
                      Text(errorMessage, style: const TextStyle(fontSize: 12, color: CupertinoColors.systemRed), textAlign: TextAlign.center),
                    ],
                  ],
                );
              }
            },
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600)),
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
