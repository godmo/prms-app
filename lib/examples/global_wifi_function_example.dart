import 'package:flutter/cupertino.dart';
import 'package:prmsapp/providers/wifi_provider.dart';
import 'package:provider/provider.dart';

/// 全域 WiFi 功能使用示例
/// 展示如何在任何頁面中使用 WiFiProvider 的全域方法
class GlobalWiFiFunctionExample extends StatelessWidget {
  const GlobalWiFiFunctionExample({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(middle: Text('Global WiFi Function Example')),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🌐 全域 WiFi 功能示例', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CupertinoColors.activeBlue)),
              const SizedBox(height: 16),

              const Text('以下示例展示如何在任何頁面中使用 WiFiProvider 的全域方法來獲取和管理 WiFi 信息：', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 24),

              // 方法 1: 獲取 WiFi 信息但不顯示對話框
              _buildMethodCard(
                context,
                title: '方法 1: 獲取 WiFi 信息（無對話框）',
                description: '使用 fetchAndUpdateWiFiInfo() 獲取最新 WiFi 信息並更新全域狀態',
                buttonText: '獲取 WiFi 信息',
                onPressed: () => _demonstrateMethod1(context),
              ),

              const SizedBox(height: 16),

              // 方法 2: 獲取並顯示 WiFi 信息對話框
              _buildMethodCard(
                context,
                title: '方法 2: 獲取並顯示 WiFi 信息',
                description: '使用 showWiFiInfo() 獲取 WiFi 信息並自動顯示對話框',
                buttonText: '顯示 WiFi 對話框',
                onPressed: () => _demonstrateMethod2(context),
              ),

              const SizedBox(height: 16),

              // 方法 3: 讀取已存儲的 WiFi 信息
              _buildMethodCard(
                context,
                title: '方法 3: 讀取已存儲的信息',
                description: '直接從 WiFiProvider 讀取已存儲的 WiFi 信息',
                buttonText: '讀取存儲信息',
                onPressed: () => _demonstrateMethod3(context),
              ),

              const SizedBox(height: 32),

              // 當前 WiFi 信息顯示
              Consumer<WiFiProvider>(
                builder: (context, wifiProvider, child) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📱 當前 WiFi 狀態', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.activeBlue)),
                        const SizedBox(height: 12),
                        Text('SSID: ${wifiProvider.wifiSSID.isNotEmpty ? wifiProvider.wifiSSID : '未連接'}', style: const TextStyle(fontSize: 14)),
                        Text('BSSID: ${wifiProvider.wifiBSSID.isNotEmpty ? wifiProvider.wifiBSSID : '無'}', style: const TextStyle(fontSize: 14)),
                        Text('IP: ${wifiProvider.wifiIP.isNotEmpty ? wifiProvider.wifiIP : '無'}', style: const TextStyle(fontSize: 14)),
                        Text(
                          '最後更新: ${wifiProvider.lastUpdated != null ? _formatDateTime(wifiProvider.lastUpdated!) : '從未'}',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 構建方法示例卡片
  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: CupertinoColors.systemGrey.withOpacity(0.1), spreadRadius: 1, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.black)),
          const SizedBox(height: 8),
          Text(description, style: const TextStyle(fontSize: 14, color: CupertinoColors.systemGrey)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: CupertinoColors.activeBlue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              onPressed: onPressed,
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }

  /// 方法 1 示例：獲取 WiFi 信息但不顯示對話框
  Future<void> _demonstrateMethod1(BuildContext context) async {
    try {
      final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);

      // 使用全域方法獲取 WiFi 信息
      final result = await wifiProvider.fetchAndUpdateWiFiInfo();

      // 處理結果
      if (result['success'] == true) {
        final cleanWifiName = result['cleanWifiName'] as String?;
        _showResultDialog(context, '✅ 成功', '已獲取 WiFi 信息：\n${cleanWifiName ?? '未知'}\n\n信息已更新到全域狀態！');
      } else {
        final displayText = result['displayText'] as String;
        _showResultDialog(context, '❌ 失敗', displayText);
      }
    } catch (e) {
      _showResultDialog(context, '❌ 錯誤', '發生錯誤：$e');
    }
  }

  /// 方法 2 示例：獲取並顯示 WiFi 信息對話框
  Future<void> _demonstrateMethod2(BuildContext context) async {
    try {
      final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);

      // 使用全域方法顯示 WiFi 信息（會自動顯示對話框）
      await wifiProvider.showWiFiInfo(context);
    } catch (e) {
      _showResultDialog(context, '❌ 錯誤', '發生錯誤：$e');
    }
  }

  /// 方法 3 示例：讀取已存儲的 WiFi 信息
  void _demonstrateMethod3(BuildContext context) {
    final wifiProvider = Provider.of<WiFiProvider>(context, listen: false);

    if (wifiProvider.hasWiFiInfo) {
      final summary = wifiProvider.getWiFiInfoSummary();
      final infoText = '''
📊 WiFi 信息摘要：

SSID: ${summary['ssid']}
BSSID: ${summary['bssid']}
IP: ${summary['ip']}
最後更新: ${summary['lastUpdated'] ?? '未知'}
是否過期: ${summary['isExpired'] ? '是' : '否'}

完整信息字符串：
${wifiProvider.wifiInfoString}
      ''';

      _showResultDialog(context, '📱 已存儲的 WiFi 信息', infoText);
    } else {
      _showResultDialog(context, '📭 無信息', '目前沒有存儲的 WiFi 信息。\n\n請先使用方法 1 或 2 獲取 WiFi 信息。');
    }
  }

  /// 顯示結果對話框
  void _showResultDialog(BuildContext context, String title, String content) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(title),
          content: Padding(padding: const EdgeInsets.only(top: 16), child: Text(content, style: const TextStyle(fontSize: 14), textAlign: TextAlign.left)),
          actions: [CupertinoDialogAction(child: const Text('確定'), onPressed: () => Navigator.of(context).pop())],
        );
      },
    );
  }

  /// 格式化日期時間
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
