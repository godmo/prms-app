import 'dart:typed_data';
import 'package:msal_auth/msal_auth.dart';
import 'package:dio/dio.dart';

class AuthService {
  SingleAccountPca? _msalAuth;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    _msalAuth = await SingleAccountPca.create(
      clientId: '588bddd4-a2de-4350-9a17-45867f3c90e3',
      androidConfig: AndroidConfig(
        configFilePath: 'assets/msal_config.json',
        redirectUri: 'msauth.vis.com.tw.prmsapp://auth',
      ),
      appleConfig: AppleConfig(
        authority:
            'https://login.microsoftonline.com/49f64f9b-544c-4ceb-97a3-d40679183765',
        authorityType: AuthorityType.aad,
        broker: Broker.msAuthenticator,
      ),
    );
    _isInitialized = true;
  }

  Future<AuthenticationResult?> signIn() async {
    await init();
    if (_msalAuth == null) return null;
    return await _msalAuth!.acquireToken(scopes: ['User.Read']);
  }

  Future<void> signOut() async {
    if (_msalAuth != null) {
      try {
        await _msalAuth!.signOut();
      } catch (e) {
        // 忽略 no_account 錯誤（broker 模式下常見）
        if (e.toString().contains('no_account')) {
          return;
        }
        rethrow;
      }
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String accessToken) async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://graph.microsoft.com/v1.0/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      Uint8List? avatar;
      try {
        final photoResponse = await dio.get(
          'https://graph.microsoft.com/v1.0/me/photo/\$value',
          options: Options(
            headers: {'Authorization': 'Bearer $accessToken'},
            responseType: ResponseType.bytes,
          ),
        );
        if (photoResponse.statusCode == 200) {
          avatar = Uint8List.fromList(photoResponse.data);
        }
      } catch (_) {
        avatar = null;
      }
      return {
        'displayName': data['displayName'] ?? '',
        'email': data['mail'] ?? data['userPrincipalName'] ?? '',
        'avatar': avatar,
        'mobilePhone': data['mobilePhone'] ?? '',
        'jobTitle': data['jobTitle'] ?? '',
        'department': data['department'] ?? '',
        'officeLocation': data['officeLocation'] ?? '',
        'preferredLanguage': data['preferredLanguage'] ?? '',
      };
    } catch (_) {
      return null;
    }
  }

  Future<AuthenticationResult?> acquireTokenSilent() async {
    await init();
    if (_msalAuth == null) return null;
    try {
      return await _msalAuth!.acquireTokenSilent(scopes: ['User.Read']);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    await init();
    if (_msalAuth == null) return null;
    final result = await _msalAuth!.acquireToken(scopes: ['Mail.Send']);
    return result.accessToken;
  }
}
