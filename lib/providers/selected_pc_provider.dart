import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SelectedPCProvider extends ChangeNotifier {
  String _selectedPC = 'Please Bind PC'; // 預設值
  final List<String> _pcList = []; // 預設值

  static const String _pcListKey = 'pc_list';
  static const String _selectedPCKey = 'selected_pc';

  SelectedPCProvider() {
    _loadPCList();
  }

  String get selectedPC => _selectedPC;
  List<String> get pcList => List.unmodifiable(_pcList);

  Future<void> _loadPCList() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_pcListKey) ?? [];
    _pcList.clear();
    _pcList.addAll(list);
    _selectedPC = prefs.getString(_selectedPCKey) ?? (_pcList.isNotEmpty ? _pcList.last : 'Please Bind PC');
    notifyListeners();
  }

  Future<void> _savePCList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pcListKey, _pcList);
    await prefs.setString(_selectedPCKey, _selectedPC);
  }

  void setSelectedPC(String pc) {
    _selectedPC = pc;
    _savePCList();
    notifyListeners();
  }

  void addPC(String pc) {
    if (_pcList.contains(pc)) {
      _pcList.remove(pc);
    }
    _pcList.add(pc);
    while (_pcList.length > 10) {
      _pcList.removeAt(0);
    }
    _selectedPC = pc;
    _savePCList();
    notifyListeners();
  }

  // 清空所有 PC 記錄與選擇
  void clearAll() {
    _pcList.clear();
    _selectedPC = 'Please Bind PC';
    _savePCList();
    notifyListeners();
  }
}
