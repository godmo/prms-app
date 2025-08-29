import 'package:flutter/cupertino.dart';
import 'package:prmsapp/providers/wifi_provider.dart';
import 'package:provider/provider.dart';

/// 示例頁面：展示如何在其他頁面中使用全域 WiFi 信息
/// 這個文件展示了如何在任何頁面或組件中訪問和使用 WiFi 信息
class ExampleWiFiUsagePage extends StatelessWidget {
  const ExampleWiFiUsagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('WiFi Information Example')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 使用 Consumer 來監聽 WiFi 狀態變化
              Consumer<WiFiProvider>(
                builder: (context, wifiProvider, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current WiFi Information:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),

                      // 顯示是否有 WiFi 信息
                      _buildInfoRow(
                        'Has WiFi Info',
                        wifiProvider.hasWiFiInfo ? 'Yes' : 'No',
                        wifiProvider.hasWiFiInfo ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
                      ),

                      // 顯示 WiFi SSID
                      _buildInfoRow(
                        'WiFi SSID',
                        wifiProvider.wifiSSID.isNotEmpty ? wifiProvider.wifiSSID : 'Not available',
                        wifiProvider.wifiSSID.isNotEmpty ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                      ),

                      // 顯示 BSSID
                      _buildInfoRow(
                        'BSSID',
                        wifiProvider.wifiBSSID.isNotEmpty ? wifiProvider.wifiBSSID : 'Not available',
                        wifiProvider.wifiBSSID.isNotEmpty ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                      ),

                      // 顯示 IP 地址
                      _buildInfoRow(
                        'IP Address',
                        wifiProvider.wifiIP.isNotEmpty ? wifiProvider.wifiIP : 'Not available',
                        wifiProvider.wifiIP.isNotEmpty ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                      ),

                      // 顯示最後更新時間
                      _buildInfoRow(
                        'Last Updated',
                        wifiProvider.lastUpdated != null
                            ? '${wifiProvider.lastUpdated!.day}/${wifiProvider.lastUpdated!.month}/${wifiProvider.lastUpdated!.year} ${wifiProvider.lastUpdated!.hour}:${wifiProvider.lastUpdated!.minute.toString().padLeft(2, '0')}'
                            : 'Never',
                        wifiProvider.lastUpdated != null ? CupertinoColors.systemBlue : CupertinoColors.systemGrey,
                      ),

                      // 顯示信息是否過期
                      _buildInfoRow(
                        'Is Expired (30min)',
                        wifiProvider.isWiFiInfoExpired() ? 'Yes' : 'No',
                        wifiProvider.isWiFiInfoExpired() ? CupertinoColors.systemOrange : CupertinoColors.systemGreen,
                      ),

                      const SizedBox(height: 24),

                      // 完整信息字符串
                      const Text('Complete WiFi Info String:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(8)),
                        child: Text(wifiProvider.wifiInfoString, style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                      ),

                      const SizedBox(height: 24),

                      // 操作按鈕
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemBlue,
                              child: const Text('Clear WiFi Info'),
                              onPressed: () {
                                wifiProvider.clearWiFiInfo();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemOrange,
                              child: const Text('Refresh WiFi'),
                              onPressed: () async {
                                // 使用全域方法獲取最新 WiFi 信息
                                await wifiProvider.fetchAndUpdateWiFiInfo();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemGreen,
                              child: const Text('Show WiFi Dialog'),
                              onPressed: () async {
                                // 使用全域方法顯示 WiFi 信息對話框
                                await wifiProvider.showWiFiInfo(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoButton(
                              color: CupertinoColors.systemPurple,
                              child: const Text('Update Test Data'),
                              onPressed: () {
                                // 示例：手動更新 WiFi 信息
                                wifiProvider.updateWiFiInfo(
                                  ssid: 'TestWiFi-${DateTime.now().millisecond}',
                                  bssid: '00:11:22:33:44:55',
                                  ip: '192.168.1.${DateTime.now().millisecond % 255}',
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 32),

              // 使用說明
              const Text('How to use WiFiProvider in your code:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: CupertinoColors.systemGrey6, borderRadius: BorderRadius.circular(8)),
                child: const Text('''// 1. 獲取 WiFi Provider (不監聽變化)
final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);

// 2. 讀取 WiFi SSID
String ssid = wifiProvider.wifiSSID;

// 3. 更新 WiFi 信息
await wifiProvider.updateWiFiSSID('NewWiFiName');

// 4. 監聽變化 (使用 Consumer)
Consumer<WiFiProvider>(
  builder: (context, wifiProvider, child) {
    return Text('SSID: \${wifiProvider.wifiSSID}');
  },
)

// 🆕 5. 使用全域方法獲取最新 WiFi 信息
final result = await wifiProvider.fetchAndUpdateWiFiInfo();
if (result['success']) {
  print('WiFi 名稱: \${result['cleanWifiName']}');
}

// 🆕 6. 直接顯示 WiFi 信息對話框
await wifiProvider.showWiFiInfo(context);''', style: TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建信息行
  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text('$label:', style: const TextStyle(fontWeight: FontWeight.w500, color: CupertinoColors.label))),
          Expanded(child: Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w400))),
        ],
      ),
    );
  }
}
