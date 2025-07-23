import 'package:flutter/services.dart';

class WifiService {
  static const MethodChannel _channel = MethodChannel('com.prms.wifi');

  /// 使用原生iOS方法获取WiFi SSID信息
  static Future<Map<String, dynamic>> getWifiSSIDNative() async {
    try {
      final result = await _channel.invokeMethod('getWifiSSID');
      if (result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return {'success': false, 'error': 'Invalid response format', 'ssid': '', 'bssid': ''};
    } on PlatformException catch (e) {
      return {'success': false, 'error': e.message ?? 'Platform error occurred', 'ssid': '', 'bssid': '', 'code': e.code};
    } catch (e) {
      return {'success': false, 'error': 'Unexpected error: ${e.toString()}', 'ssid': '', 'bssid': ''};
    }
  }
}
