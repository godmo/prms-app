import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:prmsapp/services/auth_service.dart';
// import 'package:msal_auth/msal_auth.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool isLoggedIn = false; // 目前是否已登入
  bool isAuthLoading = true; // 是否正在進行登入流程
  String userName = 'Please login';
  String userEmail = '';
  Uint8List? userAvatar;
  String? _accessToken;
  String? mobilePhone = '';
  String jobTitle = '';
  String department = '';
  String officeLocation = '';
  String preferredLanguage = '';

  AuthProvider() {
    _silentLogin();
  }

  Future<void> _silentLogin() async {
    isAuthLoading = true;
    notifyListeners();
    try {
      final result = await _authService.acquireTokenSilent();
      if (result != null) {
        isLoggedIn = true;
        _accessToken = result.accessToken;
        await fetchUserProfile();
      }
    } catch (e) {
      // 如果靜默登入失敗，則重置狀態
      isLoggedIn = false;
      userName = 'Please login';
      userEmail = '';
      userAvatar = null;
      _accessToken = null;
      mobilePhone = '';
      jobTitle = '';
      department = '';
      officeLocation = '';
      preferredLanguage = '';
    }
    isAuthLoading = false;
    notifyListeners();
  }

  Future<void> signIn() async {
    isAuthLoading = true;
    notifyListeners();
    try {
      //await _authService.signOut(); // 先強制登出，確保每次都能選帳號
      final result = await _authService.signIn();
      if (result != null) {
        isLoggedIn = true;
        _accessToken = result.accessToken;
        await fetchUserProfile();
      }
    } finally {
      isAuthLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    isLoggedIn = false;
    userName = 'Please login';
    userEmail = '';
    userAvatar = null;
    _accessToken = null;
    mobilePhone = '';
    jobTitle = '';
    department = '';
    officeLocation = '';
    preferredLanguage = '';
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    if (_accessToken == null) return;
    final profile = await _authService.getUserProfile(_accessToken!);
    if (profile != null) {
      userName = profile['displayName'] ?? '';
      userEmail = profile['email'] ?? '';
      userAvatar = profile['avatar'];
      mobilePhone = profile['mobilePhone'];
      jobTitle = profile['jobTitle'] ?? '';
      department = profile['department'] ?? '';
      officeLocation = profile['officeLocation'] ?? '';
      preferredLanguage = profile['preferredLanguage'] ?? '';
      notifyListeners();
    }
  }
}
