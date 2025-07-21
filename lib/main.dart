import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // 引入services套件以設定系統UI樣式
import 'package:prmsapp/services/messaging_service.dart';
import 'package:prmsapp/pages/main_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:prmsapp/providers/auth_provider.dart';

/// ViScanner應用程序主入口點
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // 確保Flutter綁定已初始化

  // 初始化Firebase
  try {
    await Firebase.initializeApp();
  } catch (e) {
    print("Firebase initialization failed: $e");
    return;
  }
  // 設定狀態列樣式，使其背景色跟隨APP主題
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color.fromRGBO(0, 0, 0, 0), // 透明色，讓背景色可以顯示
      statusBarBrightness: Brightness.light, // iOS狀態列亮度，淺色背景用深色文字
      statusBarIconBrightness: Brightness.dark, // Android狀態列圖標亮度
    ),
  );

  // 初始化推播通知服務
  // await PushNotificationService().init();

  runApp(const PrmsApp());
}

/// 設定應用整體主題與風格，採用iOS風格的CupertinoApp
class PrmsApp extends StatelessWidget {
  const PrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: CupertinoApp(
        // 改用 CupertinoApp
        debugShowCheckedModeBanner: false,
        theme: const CupertinoThemeData(
          // 設定亮色主題
          brightness: Brightness.light,
          //primaryColor: CupertinoColors.systemBlue,
        ),
        home: MainPage(title: 'PRMS APP main'), // 直接使用 MainPage 作為首頁
      ),
    );
  }
}
