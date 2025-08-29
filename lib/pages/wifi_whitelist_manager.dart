import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:prmsapp/providers/wifi_provider.dart';
import 'package:provider/provider.dart';

/// WiFi 白名單管理頁面
/// 允許用戶查看、添加和移除白名單中的 WiFi SSID
class WiFiWhitelistManagerPage extends StatefulWidget {
  const WiFiWhitelistManagerPage({super.key});

  @override
  State<WiFiWhitelistManagerPage> createState() => _WiFiWhitelistManagerPageState();
}

class _WiFiWhitelistManagerPageState extends State<WiFiWhitelistManagerPage> {
  final TextEditingController _addSSIDController = TextEditingController();

  @override
  void dispose() {
    _addSSIDController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('WiFi 白名單管理')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 標題區域
              const Text('🔒 WiFi 白名單設定', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue)),
              const SizedBox(height: 8),
              const Text('只有在白名單中的 WiFi 網路才允許使用 PRMS 應用程式。', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
              const SizedBox(height: 24),

              // 當前 WiFi 狀態
              Consumer<WiFiProvider>(
                builder: (context, wifiProvider, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: wifiProvider.isCurrentWiFiInWhitelist ? CupertinoColors.systemGreen.withOpacity(0.1) : CupertinoColors.systemRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: wifiProvider.isCurrentWiFiInWhitelist ? CupertinoColors.systemGreen : CupertinoColors.systemRed, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              wifiProvider.isCurrentWiFiInWhitelist ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.xmark_circle_fill,
                              color: wifiProvider.isCurrentWiFiInWhitelist ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              wifiProvider.isCurrentWiFiInWhitelist ? '允許使用' : '禁止使用',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: wifiProvider.isCurrentWiFiInWhitelist ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('當前 WiFi: ${wifiProvider.wifiSSID.isNotEmpty ? wifiProvider.wifiSSID : '未連接'}', style: const TextStyle(fontSize: 14)),
                        if (wifiProvider.wifiSSID.isNotEmpty && !wifiProvider.isCurrentWiFiInWhitelist) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: CupertinoColors.activeBlue,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: const Text('添加當前 WiFi 到白名單'),
                              onPressed: () async {
                                await wifiProvider.addToWhitelist(wifiProvider.wifiSSID);
                                if (mounted) {
                                  _showSuccessDialog('已將 "${wifiProvider.wifiSSID}" 添加到白名單');
                                }
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // 添加新的 SSID
              const Text('添加新的 WiFi SSID', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CupertinoTextField(
                      controller: _addSSIDController,
                      placeholder: '輸入 WiFi SSID 名稱',
                      decoration: BoxDecoration(border: Border.all(color: CupertinoColors.systemGrey4), borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoButton(
                    color: CupertinoColors.activeBlue,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: const Text('添加'),
                    onPressed: () async {
                      final ssid = _addSSIDController.text.trim();
                      if (ssid.isNotEmpty) {
                        final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);
                        await wifiProvider.addToWhitelist(ssid);
                        _addSSIDController.clear();
                        if (mounted) {
                          _showSuccessDialog('已將 "$ssid" 添加到白名單');
                        }
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // 白名單列表
              const Text('白名單 WiFi 網路', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),

              // 白名單項目
              Expanded(
                child: Consumer<WiFiProvider>(
                  builder: (context, wifiProvider, child) {
                    if (wifiProvider.wifiWhitelist.isEmpty) {
                      return const Center(
                        child: Text('白名單為空\n請添加允許的 WiFi 網路', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                      );
                    }

                    return ListView.builder(
                      itemCount: wifiProvider.wifiWhitelist.length,
                      itemBuilder: (context, index) {
                        final ssid = wifiProvider.wifiWhitelist[index];
                        final isCurrentWiFi = ssid == wifiProvider.wifiSSID;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isCurrentWiFi ? CupertinoColors.activeBlue.withOpacity(0.1) : CupertinoColors.systemGrey6,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isCurrentWiFi ? CupertinoColors.activeBlue : CupertinoColors.systemGrey5, width: 1),
                          ),
                          child: ListTile(
                            leading: Icon(
                              isCurrentWiFi ? CupertinoIcons.wifi : CupertinoIcons.antenna_radiowaves_left_right,
                              color: isCurrentWiFi ? CupertinoColors.activeBlue : CupertinoColors.systemGrey,
                            ),
                            title: Text(
                              ssid,
                              style: TextStyle(
                                fontWeight: isCurrentWiFi ? FontWeight.w600 : FontWeight.normal,
                                color: isCurrentWiFi ? CupertinoColors.activeBlue : CupertinoColors.black,
                              ),
                            ),
                            subtitle: isCurrentWiFi ? const Text('當前連接', style: TextStyle(color: CupertinoColors.activeBlue, fontSize: 12)) : null,
                            trailing: CupertinoButton(
                              padding: EdgeInsets.zero,
                              child: const Icon(CupertinoIcons.delete, color: CupertinoColors.systemRed, size: 20),
                              onPressed: () {
                                _showDeleteConfirmation(context, ssid, wifiProvider);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // 操作按鈕
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemOrange,
                      child: const Text('測試當前 WiFi'),
                      onPressed: () async {
                        final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);
                        await wifiProvider.checkWiFiWithWhitelist(context);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CupertinoButton(
                      color: CupertinoColors.systemRed,
                      child: const Text('清空白名單'),
                      onPressed: () {
                        _showClearWhitelistConfirmation(context);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 顯示成功訊息
  void _showSuccessDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('✅ 成功'),
          content: Text(message),
          actions: [CupertinoDialogAction(child: const Text('確定'), onPressed: () => Navigator.of(context).pop())],
        );
      },
    );
  }

  /// 顯示刪除確認對話框
  void _showDeleteConfirmation(BuildContext context, String ssid, WiFiProvider wifiProvider) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('確認刪除'),
          content: Text('確定要從白名單中移除 "$ssid" 嗎？'),
          actions: [
            CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('刪除'),
              onPressed: () async {
                Navigator.of(context).pop();
                await wifiProvider.removeFromWhitelist(ssid);
                if (mounted) {
                  _showSuccessDialog('已從白名單中移除 "$ssid"');
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 顯示清空白名單確認對話框
  void _showClearWhitelistConfirmation(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('⚠️ 警告'),
          content: const Text('確定要清空整個白名單嗎？這將移除所有允許的 WiFi 網路。'),
          actions: [
            CupertinoDialogAction(child: const Text('取消'), onPressed: () => Navigator.of(context).pop()),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('清空'),
              onPressed: () async {
                Navigator.of(context).pop();
                final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);
                await wifiProvider.updateWhitelist([]);
                if (mounted) {
                  _showSuccessDialog('白名單已清空');
                }
              },
            ),
          ],
        );
      },
    );
  }
}
