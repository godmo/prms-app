import 'package:flutter/cupertino.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:prmsapp/services/wifi_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WiFi 信息的全域狀態管理
/// 提供 WiFi SSID、BSSID、IP 地址等信息的全域存儲和訪問
/// 包含 WiFi SSID 白名單檢查功能
class WiFiProvider extends ChangeNotifier {
  String _wifiSSID = '';
  String _wifiBSSID = '';
  String _wifiIP = '';
  DateTime? _lastUpdated;

  // WiFi SSID 白名單
  List<String> _wifiWhitelist = [];

  // SharedPreferences 鍵值
  static const String _wifiSSIDKey = 'wifi_ssid';
  static const String _wifiBSSIDKey = 'wifi_bssid';
  static const String _wifiIPKey = 'wifi_ip';
  static const String _lastUpdatedKey = 'wifi_last_updated';
  static const String _wifiWhitelistKey = 'wifi_whitelist';

  WiFiProvider() {
    _loadWiFiInfo();
    _loadWifiWhitelist();
  }

  // Getters
  String get wifiSSID => _wifiSSID;
  String get wifiBSSID => _wifiBSSID;
  String get wifiIP => _wifiIP;
  DateTime? get lastUpdated => _lastUpdated;
  List<String> get wifiWhitelist => List.unmodifiable(_wifiWhitelist);

  /// 檢查 WiFi 信息是否可用
  bool get hasWiFiInfo => _wifiSSID.isNotEmpty;

  /// 檢查當前 WiFi SSID 是否在白名單中
  bool get isCurrentWiFiInWhitelist {
    if (_wifiSSID.isEmpty || _wifiWhitelist.isEmpty) return false;
    return _wifiWhitelist.contains(_wifiSSID);
  }

  /// 獲取完整的 WiFi 信息字符串
  String get wifiInfoString {
    if (!hasWiFiInfo) return 'No WiFi information available';

    String info = 'WiFi SSID: $_wifiSSID';
    if (_wifiBSSID.isNotEmpty) {
      info += '\nBSSID: $_wifiBSSID';
    }
    if (_wifiIP.isNotEmpty) {
      info += '\nIP Address: $_wifiIP';
    }
    if (_lastUpdated != null) {
      info += '\nLast Updated: ${_formatDateTime(_lastUpdated!)}';
    }
    return info;
  }

  /// 從 SharedPreferences 載入 WiFi 信息
  Future<void> _loadWiFiInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _wifiSSID = prefs.getString(_wifiSSIDKey) ?? '';
      _wifiBSSID = prefs.getString(_wifiBSSIDKey) ?? '';
      _wifiIP = prefs.getString(_wifiIPKey) ?? '';

      final lastUpdatedMillis = prefs.getInt(_lastUpdatedKey);
      if (lastUpdatedMillis != null) {
        _lastUpdated = DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis);
      }

      notifyListeners();
    } catch (e) {
      print('載入 WiFi 信息失敗: $e');
    }
  }

  /// 保存 WiFi 信息到 SharedPreferences
  Future<void> _saveWiFiInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_wifiSSIDKey, _wifiSSID);
      await prefs.setString(_wifiBSSIDKey, _wifiBSSID);
      await prefs.setString(_wifiIPKey, _wifiIP);

      if (_lastUpdated != null) {
        await prefs.setInt(_lastUpdatedKey, _lastUpdated!.millisecondsSinceEpoch);
      }
    } catch (e) {
      print('保存 WiFi 信息失敗: $e');
    }
  }

  /// 從 SharedPreferences 載入 WiFi 白名單
  Future<void> _loadWifiWhitelist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final whitelistJson = prefs.getStringList(_wifiWhitelistKey) ?? [];
      _wifiWhitelist = whitelistJson;

      // 如果白名單為空，設置預設白名單
      if (_wifiWhitelist.isEmpty) {
        _wifiWhitelist = [
          'VSMC_WiFi',
          'VSMC_Guest',
          'VIS_Lab',
          'TestWiFi',
          // 添加更多預設的 WiFi SSID
        ];
        await _saveWifiWhitelist();
      }

      notifyListeners();
    } catch (e) {
      print('載入 WiFi 白名單失敗: $e');
    }
  }

  /// 保存 WiFi 白名單到 SharedPreferences
  Future<void> _saveWifiWhitelist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_wifiWhitelistKey, _wifiWhitelist);
    } catch (e) {
      print('保存 WiFi 白名單失敗: $e');
    }
  }

  /// 添加 WiFi SSID 到白名單
  Future<void> addToWhitelist(String ssid) async {
    final cleanSSID = ssid.replaceAll('"', '');
    if (!_wifiWhitelist.contains(cleanSSID)) {
      _wifiWhitelist.add(cleanSSID);
      await _saveWifiWhitelist();
      notifyListeners();
    }
  }

  /// 從白名單移除 WiFi SSID
  Future<void> removeFromWhitelist(String ssid) async {
    final cleanSSID = ssid.replaceAll('"', '');
    if (_wifiWhitelist.remove(cleanSSID)) {
      await _saveWifiWhitelist();
      notifyListeners();
    }
  }

  /// 檢查指定的 SSID 是否在白名單中
  bool isSSIDInWhitelist(String ssid) {
    final cleanSSID = ssid.replaceAll('"', '');
    return _wifiWhitelist.contains(cleanSSID);
  }

  /// 更新白名單
  Future<void> updateWhitelist(List<String> newWhitelist) async {
    _wifiWhitelist = newWhitelist.map((ssid) => ssid.replaceAll('"', '')).toList();
    await _saveWifiWhitelist();
    notifyListeners();
  }

  /// 更新 WiFi SSID（會自動清理引號）
  Future<void> updateWiFiSSID(String ssid) async {
    // 移除 SSID 中的引號（如果有的話）
    final cleanSSID = ssid.replaceAll('"', '');

    if (_wifiSSID != cleanSSID) {
      _wifiSSID = cleanSSID;
      _lastUpdated = DateTime.now();
      notifyListeners();
      await _saveWiFiInfo();
    }
  }

  /// 更新 WiFi BSSID
  Future<void> updateWiFiBSSID(String bssid) async {
    if (_wifiBSSID != bssid) {
      _wifiBSSID = bssid;
      _lastUpdated = DateTime.now();
      notifyListeners();
      await _saveWiFiInfo();
    }
  }

  /// 更新 WiFi IP 地址
  Future<void> updateWiFiIP(String ip) async {
    if (_wifiIP != ip) {
      _wifiIP = ip;
      _lastUpdated = DateTime.now();
      notifyListeners();
      await _saveWiFiInfo();
    }
  }

  /// 批量更新 WiFi 信息
  Future<void> updateWiFiInfo({String? ssid, String? bssid, String? ip}) async {
    bool hasChanges = false;

    if (ssid != null) {
      final cleanSSID = ssid.replaceAll('"', '');
      if (_wifiSSID != cleanSSID) {
        _wifiSSID = cleanSSID;
        hasChanges = true;
      }
    }

    if (bssid != null && _wifiBSSID != bssid) {
      _wifiBSSID = bssid;
      hasChanges = true;
    }

    if (ip != null && _wifiIP != ip) {
      _wifiIP = ip;
      hasChanges = true;
    }

    if (hasChanges) {
      _lastUpdated = DateTime.now();
      notifyListeners();
      await _saveWiFiInfo();
    }
  }

  /// 清除所有 WiFi 信息
  Future<void> clearWiFiInfo() async {
    _wifiSSID = '';
    _wifiBSSID = '';
    _wifiIP = '';
    _lastUpdated = null;
    notifyListeners();
    await _saveWiFiInfo();
  }

  /// 格式化日期時間
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// 檢查 WiFi 信息是否過期（超過指定分鐘數）
  bool isWiFiInfoExpired([int minutesThreshold = 30]) {
    if (_lastUpdated == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);
    return difference.inMinutes > minutesThreshold;
  }

  /// 獲取 WiFi 信息的摘要（用於調試或顯示）
  Map<String, dynamic> getWiFiInfoSummary() {
    return {
      'ssid': _wifiSSID,
      'bssid': _wifiBSSID,
      'ip': _wifiIP,
      'lastUpdated': _lastUpdated?.toIso8601String(),
      'hasInfo': hasWiFiInfo,
      'isExpired': isWiFiInfoExpired(),
    };
  }

  /// 從原生系統獲取並更新 WiFi 信息
  ///
  /// 這是一個全域方法，可以被任何頁面或組件調用來獲取最新的 WiFi 信息
  ///
  /// 返回值：
  /// - Map<String, dynamic> 包含操作結果和顯示信息
  ///   - 'success': bool - 操作是否成功
  ///   - 'displayText': String - 可用於 UI 顯示的文本
  ///   - 'cleanWifiName': String? - 清理後的 WiFi 名稱（僅在成功時）
  Future<Map<String, dynamic>> fetchAndUpdateWiFiInfo() async {
    try {
      // 使用原生iOS方法獲取WiFi信息
      final wifiResult = await WifiService.getWifiSSIDNative();

      String displayText = '';
      String? cleanWifiName;

      // 处理成功获取WiFi信息的情况
      if (wifiResult['success'] == true) {
        final ssid = wifiResult['ssid'] as String? ?? '';
        final bssid = wifiResult['bssid'] as String? ?? '';

        if (ssid.isNotEmpty) {
          // 移除SSID中的引号（如果有的话）并存储到全域状态
          cleanWifiName = ssid.replaceAll('"', '');

          // 尝试获取IP地址作为补充信息
          String wifiIP = '';
          try {
            final info = NetworkInfo();
            final ip = await info.getWifiIP();
            if (ip != null && ip.isNotEmpty) {
              wifiIP = ip;
            }
          } catch (e) {
            print('Failed to get IP: $e');
          }

          // 批量更新WiFi信息到全域状态
          await updateWiFiInfo(ssid: cleanWifiName, bssid: bssid.isNotEmpty ? bssid : null, ip: wifiIP.isNotEmpty ? wifiIP : null);

          // 構建顯示文本
          displayText = 'WiFi SSID: $cleanWifiName';
          if (bssid.isNotEmpty) {
            displayText += '\nBSSID: $bssid';
          }
          if (wifiIP.isNotEmpty) {
            displayText += '\nIP Address: $wifiIP';
          }
          displayText += '\n\n✓ WiFi information saved to global state';

          return {'success': true, 'displayText': displayText, 'cleanWifiName': cleanWifiName};
        } else {
          // 无WiFi连接或信息不可用的提示
          displayText = 'No WiFi connection detected or WiFi information not available.\n\nNote: On iOS simulators, WiFi information is always unavailable.';

          return {'success': false, 'displayText': displayText};
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

        return {'success': false, 'displayText': displayText, 'errorCode': errorCode, 'errorMessage': errorMessage};
      }
    } catch (e) {
      // 异常处理
      final errorDisplayText =
          'Failed to get WiFi information: ${e.toString()}\n\nPlease ensure:\n• Location services are enabled\n• App has location permission\n• Device is connected to WiFi';

      return {'success': false, 'displayText': errorDisplayText, 'error': e.toString()};
    }
  }

  /// 全域 WiFi 信息獲取和顯示方法
  ///
  /// 這個方法結合了獲取 WiFi 信息和顯示對話框的功能
  /// 可以被任何頁面直接調用來顯示 WiFi 信息
  ///
  /// 參數：
  /// - [context]: BuildContext 用於顯示對話框
  /// - [showDialog]: bool 是否顯示對話框（預設為 true）
  ///
  /// 返回值：同 fetchAndUpdateWiFiInfo()
  Future<Map<String, dynamic>> showWiFiInfo(BuildContext context, {bool showDialog = true}) async {
    final result = await fetchAndUpdateWiFiInfo();

    if (showDialog && context.mounted) {
      final title = result['success'] == true ? 'WiFi Information' : 'Error';
      final content = result['displayText'] as String;

      _showWiFiDialog(context, title, content);
    }

    return result;
  }

  /// 🔒 專為 binding_prms_card 設計的 WiFi 檢查方法
  ///
  /// 這個方法會：
  /// 1. 獲取當前 WiFi 信息
  /// 2. 檢查 SSID 是否在白名單中
  /// 3. 如果不在白名單中，顯示禁止使用的通知
  /// 4. 如果在白名單中，顯示正常的 WiFi 信息
  ///
  /// 參數：
  /// - [context]: BuildContext 用於顯示對話框
  ///
  /// 返回值：
  /// - Map<String, dynamic> 包含檢查結果
  ///   - 'success': bool - WiFi 獲取是否成功
  ///   - 'whitelisted': bool - SSID 是否在白名單中
  ///   - 'cleanWifiName': String? - 清理後的 WiFi 名稱
  ///   - 'displayText': String - 顯示文本
  Future<Map<String, dynamic>> checkWiFiWithWhitelist(BuildContext context) async {
    final result = await fetchAndUpdateWiFiInfo();

    if (result['success'] == true && context.mounted) {
      final cleanWifiName = result['cleanWifiName'] as String?;

      if (cleanWifiName != null && cleanWifiName.isNotEmpty) {
        final isWhitelisted = isSSIDInWhitelist(cleanWifiName);

        if (!isWhitelisted) {
          // WiFi 不在白名單中，顯示禁止使用的通知
          _showWiFiBlockedDialog(context, cleanWifiName);

          return {
            'success': true,
            'whitelisted': false,
            'cleanWifiName': cleanWifiName,
            'displayText': 'WiFi "$cleanWifiName" is not in the whitelist and access is denied.',
          };
        } else {
          // WiFi 在白名單中，顯示正常信息
          final title = 'WiFi Information';
          final content = result['displayText'] as String;
          _showWiFiDialog(context, title, content);

          return {'success': true, 'whitelisted': true, 'cleanWifiName': cleanWifiName, 'displayText': result['displayText']};
        }
      }
    }

    // 處理獲取失敗的情況
    if (context.mounted) {
      final title = 'Error';
      final content = result['displayText'] as String;
      _showWiFiDialog(context, title, content);
    }

    return {'success': result['success'] ?? false, 'whitelisted': false, 'displayText': result['displayText'] ?? 'Failed to get WiFi information'};
  }

  /// 顯示 WiFi 被阻擋的警告對話框
  ///
  /// 當 WiFi SSID 不在白名單中時顯示此對話框
  void _showWiFiBlockedDialog(BuildContext context, String ssid) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('🚫 禁止使用', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.systemRed)),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('您當前連接的 WiFi 網路不在允許使用的白名單中：', style: const TextStyle(fontSize: 14, color: CupertinoColors.black), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CupertinoColors.systemRed.withOpacity(0.3)),
                  ),
                  child: Text('"$ssid"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: CupertinoColors.systemRed)),
                ),
                const SizedBox(height: 12),
                const Text(
                  '請聯繫系統管理員將此網路添加到白名單，或切換到允許的 WiFi 網路。',
                  style: TextStyle(fontSize: 14, color: CupertinoColors.systemGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text('允許的網路：', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: CupertinoColors.systemGrey2)),
                Text(
                  _wifiWhitelist.isNotEmpty ? _wifiWhitelist.join(', ') : '無',
                  style: const TextStyle(fontSize: 12, color: CupertinoColors.systemGrey2),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('了解', style: TextStyle(color: CupertinoColors.systemRed, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              child: const Text('添加到白名單', style: TextStyle(color: CupertinoColors.activeBlue, fontWeight: FontWeight.w600)),
              onPressed: () async {
                Navigator.of(context).pop();
                await addToWhitelist(ssid);
                if (context.mounted) {
                  _showWiFiDialog(context, '✅ 已添加', 'WiFi "$ssid" 已成功添加到白名單中！');
                }
              },
            ),
          ],
        );
      },
    );
  }

  /// 顯示 WiFi 信息對話框
  ///
  /// 這是一個私有方法，用於顯示 Cupertino 風格的對話框
  void _showWiFiDialog(BuildContext context, String title, String content) {
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
}
