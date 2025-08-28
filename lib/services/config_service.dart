import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class ConfigService {
  static Map<String, dynamic>? _config;
  static bool _isLoaded = false;

  static Future<void> loadConfig() async {
    try {
      final data = await rootBundle.loadString('assets/app_config.json');
      _config = jsonDecode(data);
      _isLoaded = true;
    } catch (e) {
      throw Exception('Failed to load config: $e');
    }
  }

  static bool get isLoaded => _isLoaded;

  static String get logServerUrl {
    if (!_isLoaded || _config == null) {
      throw Exception('Config not loaded. Call ConfigService.loadConfig() first.');
    }
    return _config!['logServerUrl'] ?? '';
  }

  static Map<String, dynamic> get mqttConfig {
    if (!_isLoaded || _config == null) {
      throw Exception('Config not loaded. Call ConfigService.loadConfig() first.');
    }
    return _config!['mqtt'] ?? {};
  }
}
