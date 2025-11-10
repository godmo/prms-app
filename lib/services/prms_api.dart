import 'dart:convert';
import 'dart:io';

import 'package:prmsapp/config/api_config.dart';

class PrmsApi {
  static Future<Map<String, dynamic>?> getAppVersion() async {
    final url = Uri.parse(ApiConfig.appVersionUrl);

    try {
      // 模拟网络慢的现象，延迟3秒
      //await Future.delayed(Duration(seconds: 3));

      final headers = {'Content-Type': 'application/json'};
      final body = json.encode({"app_name": "prmsapp"});

      // 创建自定义的HttpClient来处理SSL证书问题
      final httpClient = HttpClient();
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        // 对于内网IP地址，允许自签名证书
        return host == Uri.parse(ApiConfig.baseProxyUrl).host;
      };

      final request = await httpClient.postUrl(url);
      headers.forEach((key, value) {
        request.headers.set(key, value);
      });
      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      httpClient.close();

      if (response.statusCode == 200) {
        print('App version check successful: $responseBody');
        try {
          final Map<String, dynamic> jsonResponse = json.decode(responseBody);
          return {'success': true, 'version': jsonResponse['version'] ?? 'Unknown', 'data': jsonResponse};
        } catch (parseError) {
          print('Failed to parse response: $parseError');
          return {
            'success': true,
            'version': 'Unknown',
            'data': {'raw_response': responseBody},
          };
        }
      } else {
        print('App version check failed with status: ${response.statusCode}');
        return {'success': false, 'version': null, 'error': 'HTTP ${response.statusCode}'};
      }
    } on SocketException catch (e) {
      print('Network error getting app version: $e');
      return {'success': false, 'version': null, 'error': 'Network error: $e'};
    } on HandshakeException catch (e) {
      print('SSL handshake error getting app version: $e');
      return {'success': false, 'version': null, 'error': 'SSL handshake error: $e'};
    } catch (e) {
      print('Error getting app version: $e');
      return {'success': false, 'version': null, 'error': 'Unknown error: $e'};
    }
  }
}
