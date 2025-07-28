import 'package:dio/dio.dart';

class ApiConfig {
  // 基础配置
  static const String _baseProxyUrl = 'https://10.125.1.104:3002';
  static const String _baseApiUrl = 'http://10.29.11.237:5098';

  // API 端点
  static String get proxyPostUrl => '$_baseProxyUrl/api/proxy/post';
  static String get cleanFlowSubmitUrl => '$_baseApiUrl/CleanFlowRouter/submit';
  static String get moveInSubmitUrl => '$_baseApiUrl/MoveInRack/submit';
  static String get moveOutSubmitUrl => '$_baseApiUrl/MoveOutRack/submit';
  static String get cumsumeSubmitUrl => '$_baseApiUrl/consume/submit';
  static String get cumsumeCheckUrl => '$_baseApiUrl/consume/check';
  static String get putOnFlowUrl => '$_baseApiUrl/PutOnFlowRouter/submit';
  static String get takeOffFlowUrl => '$_baseApiUrl/TakeOffFlowRouter/submit';

  // 其他可能的端点
  static String get userValidationUrl => '$_baseApiUrl/UserRouter/validate';
  static String get machineStatusUrl => '$_baseApiUrl/MachineRouter/status';

  // 环境配置
  static const bool isDevelopment = true;
  static const int requestTimeoutMs = 30000; // 30秒

  // 可以根据环境切换配置
  static String getProxyUrl({bool useLocalhost = false}) {
    if (useLocalhost) {
      return 'https://localhost:3002/api/proxy/post';
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
