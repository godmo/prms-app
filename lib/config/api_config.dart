import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class ApiConfig {
  // 基础配置（從 JSON 載入，帶預設值）
  static String _baseProxyUrl = 'https://10.92.144.29:80';
  static String _baseApiUrl = 'http://10.92.144.25:5098';
  static bool _isInitialized = false;

  /// 從 assets/app_config.json 載入配置
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      final String jsonString = await rootBundle.loadString('assets/app_config.json');
      final Map<String, dynamic> config = json.decode(jsonString);
      _baseProxyUrl = config['baseProxyUrl'] ?? _baseProxyUrl;
      _baseApiUrl = config['baseApiUrl'] ?? _baseApiUrl;
      _isInitialized = true;
      print('API Config initialized: proxy=$_baseProxyUrl, api=$_baseApiUrl');
    } catch (e) {
      print('Failed to load app_config.json, using default values: $e');
      _isInitialized = true; // 標記為已初始化，避免重複嘗試
    }
  }

  // API 端點
  static String get proxyPostUrl => '$_baseProxyUrl/api/proxy/post';
  static String get cleanFlowSubmitUrl => '$_baseApiUrl/CleanFlowRouter/submit';
  static String get moveInSubmitUrl => '$_baseApiUrl/MoveInRack/submit';
  static String get moveOutSubmitUrl => '$_baseApiUrl/MoveOutRack/submit';
  static String get cumsumeSubmitUrl => '$_baseApiUrl/consume/submit';
  static String get cumsumeCheckUrl => '$_baseApiUrl/consume/check';
  static String get putOnFlowUrl => '$_baseApiUrl/PutOnFlowRouter/submit';
  static String get takeOffFlowUrl => '$_baseApiUrl/TakeOffFlowRouter/submit';

  // 其他可能的端點
  static String get userValidationUrl => '$_baseApiUrl/UserRouter/validate';
  static String get machineStatusUrl => '$_baseApiUrl/MachineRouter/status';
  static String get appVersionUrl => '$_baseProxyUrl/app_version/api/version/getVersion';

  // Getters for base URLs
  static String get baseProxyUrl => _baseProxyUrl;
  static String get baseApiUrl => _baseApiUrl;

  // 环境配置
  static const bool isDevelopment = true;
  static const int requestTimeoutMs = 30000; // 30秒

  // 可以根据环境切换配置
  static String getProxyUrl({bool useLocalhost = false}) {
    if (useLocalhost) {
      return '$_baseProxyUrl/api/proxy/post';
    }
    return proxyPostUrl;
  }

  // HTTP 配置选项
  static Options get defaultHttpOptions => Options(
    headers: {"Content-Type": "application/json"},
    sendTimeout: Duration(milliseconds: requestTimeoutMs),
    receiveTimeout: Duration(milliseconds: requestTimeoutMs),
  );
}
