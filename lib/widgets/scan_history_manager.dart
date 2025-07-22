import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 掃描歷史項目類
///
/// 存儲單個掃描結果的所有相關數據，包括：
/// - 掃描內容
/// - 掃描類型（QR碼、條碼或文字）
/// - 掃描時間
class ScanHistoryItem {
  final String content; // 掃描內容
  final String type; // 掃描類型（QR碼、條碼、文字）
  final DateTime dateTime; // 掃描時間

  ScanHistoryItem({
    required this.content,
    required this.type,
    required this.dateTime,
  });

  /// 將物件轉換為JSON格式進行存儲
  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  /// 從JSON格式還原物件
  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      content: json['content'] as String,
      type: json['type'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
    );
  }

  /// 獲取格式化的日期時間字符串
  String get formattedDateTime {
    return DateFormat('yyyy/MM/dd HH:mm').format(dateTime);
  }
}

/// 掃描歷史管理器
///
/// 負責處理所有與掃描歷史相關的操作，包括：
/// - 添加新的掃描記錄
/// - 刪除指定的掃描記錄
/// - 清空所有掃描記錄
/// - 從本地持久化存儲加載記錄
/// - 將記錄保存到本地持久化存儲
class ScanHistoryManager extends ChangeNotifier {
  static final ScanHistoryManager _instance = ScanHistoryManager._internal();
  static const String _storageKey = 'scan_history';
  List<ScanHistoryItem> _scanHistory = [];

  factory ScanHistoryManager() {
    return _instance;
  }

  ScanHistoryManager._internal() {
    _loadHistory();
  }

  /// 獲取掃描歷史記錄列表
  List<ScanHistoryItem> get scanHistory => _scanHistory;

  /// 從SharedPreferences加載歷史記錄
  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_storageKey);
      if (historyJson != null) {
        final List<dynamic> decoded = jsonDecode(historyJson);
        _scanHistory =
            decoded
                .map((item) => ScanHistoryItem.fromJson(item))
                .toList(); // 移除了 .reversed.toList()，因為 addScanRecord 已經將新項目放在最前面
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading scan history: $e');
    }
  }

  /// 強制從SharedPreferences重新加載歷史記錄
  ///
  /// 用於在切換頁面或應用程序恢復前台時刷新數據
  /// 返回一個Future，完成時表示加載完成
  Future<void> reloadHistory() async {
    return await _loadHistory();
  }

  /// 保存歷史記錄到SharedPreferences
  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<dynamic> jsonList =
          _scanHistory.map((item) => item.toJson()).toList();
      final String encodedJson = jsonEncode(jsonList);
      await prefs.setString(_storageKey, encodedJson);
    } catch (e) {
      debugPrint('Error saving scan history: $e');
    }
  }

  /// 添加新的掃描記錄
  ///
  /// [content] - 掃描的內容
  /// [type] - 掃描類型（如QR碼、條碼等）
  /// 如果已存在相同內容的記錄，只會更新時間戳記
  Future<void> addScanRecord(String content, String type) async {
    // 檢查是否已存在相同內容的記錄
    final existingIndex = _scanHistory.indexWhere(
      (item) => item.content == content,
    );

    if (existingIndex >= 0) {
      // 如果存在相同內容的記錄，刪除舊記錄
      _scanHistory.removeAt(existingIndex);
    }

    // 添加新記錄（或更新後的記錄）到列表開頭
    final newItem = ScanHistoryItem(
      content: content,
      type: type,
      dateTime: DateTime.now(),
    );

    _scanHistory.insert(0, newItem); // 確保新項目總是在列表的開頭
    await _saveHistory();
    notifyListeners();
  }

  /// 刪除指定索引的掃描記錄
  ///
  /// [index] - 要刪除的記錄索引
  Future<void> deleteScanRecord(int index) async {
    if (index >= 0 && index < _scanHistory.length) {
      _scanHistory.removeAt(index);
      await _saveHistory();
      notifyListeners();
    }
  }

  /// 清空所有掃描記錄
  Future<void> clearAllRecords() async {
    _scanHistory.clear();
    await _saveHistory();
    notifyListeners();
  }
}
