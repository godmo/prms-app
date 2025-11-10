import 'package:flutter/cupertino.dart';
import 'package:prmsapp/providers/auth_provider.dart';
import 'package:prmsapp/widgets/user_profile_card.dart';
import 'package:provider/provider.dart';

//void main() => runApp(const SettingsScreen());

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsForm(); // 直接返回 SettingsForm
  }
}

class SettingsForm extends StatefulWidget {
  const SettingsForm({super.key});

  @override
  State<SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends State<SettingsForm> {
  bool darkMode = false; // 原airplaneMode更名为darkMode
  final TextEditingController _textController = TextEditingController(text: 'Enter'); // 避免重建controller

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // AuthProvider 會自動在建構時執行 _silentLogin
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Settings'), // 顯示在中間的標題
        previousPageTitle: 'Back', // 顯示上一頁的標題
        backgroundColor: CupertinoColors.systemBlue,
      ),
      // Add safe area widget to place the CupertinoFormSection below the navigation bar.
      child: Stack(
        children: [
          SafeArea(
            child: CupertinoListSection(
              backgroundColor: const Color.fromARGB(255, 255, 255, 255),
              header: const Text('Connectivity'),
              children: <Widget>[
                CupertinoFormRow(
                  prefix: const PrefixWidget(icon: CupertinoIcons.bitcoin_circle, title: 'Dark mode', color: CupertinoColors.systemOrange),
                  child: CupertinoSwitch(
                    value: darkMode,
                    onChanged: (bool value) {
                      setState(() {
                        darkMode = value;
                      });
                    },
                  ),
                ),
                CupertinoFormRow(
                  prefix: const PrefixWidget(icon: CupertinoIcons.desktopcomputer, title: 'Device Binding', color: Color.fromARGB(255, 255, 0, 157)),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // TODO: 添加设备绑定逻辑
                    },
                    child: const Icon(CupertinoIcons.qrcode, color: CupertinoColors.systemBlue),
                  ),
                ),
                const CupertinoFormRow(
                  prefix: PrefixWidget(icon: CupertinoIcons.wifi, title: 'MQTT Connection', color: CupertinoColors.systemBlue),
                  error: Text('MQTT unavailable'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[Text('Not connected'), SizedBox(width: 5), Icon(CupertinoIcons.forward)],
                  ),
                ),
                CupertinoFormRow(
                  prefix: const PrefixWidget(icon: CupertinoIcons.keyboard, title: 'Keyboard Input', color: CupertinoColors.secondaryLabel),
                  helper: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: CupertinoTextField(
                      placeholder: 'Enter text',
                      controller: _textController, // 使用持久controller
                    ),
                  ),
                  child: const Row(mainAxisAlignment: MainAxisAlignment.end),
                ),
                const CupertinoFormRow(
                  prefix: PrefixWidget(icon: CupertinoIcons.goforward_15, title: 'Mobile Data', color: CupertinoColors.systemGreen),
                  child: Icon(CupertinoIcons.forward),
                ),

                // 使用者個人檔案卡片
                Container(
                  margin: const EdgeInsets.only(top: 20),
                  child: Consumer<AuthProvider>(
                    builder: (context, auth, child) {
                      return UserProfileCard(
                        userName: auth.userName,
                        userEmail: auth.userEmail,
                        avatarBytes: auth.userAvatar,
                        mobilePhone: auth.mobilePhone ?? '',
                        officeLocation: auth.officeLocation,
                        isLoggedIn: auth.isLoggedIn,
                        onLogin: () async {
                          await auth.signIn();
                        },
                        onLogout: () async {
                          await auth.signOut();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 遮罩層 - 禁用整個頁面
          Positioned.fill(
            child: Container(
              color: CupertinoColors.systemBackground.withOpacity(0.95),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.lock_shield_fill, size: 80, color: CupertinoColors.systemGrey),
                    const SizedBox(height: 24),
                    Text('Under Construction', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CupertinoColors.label, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Text(
                        'This feature is currently under development\nand will be available soon.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: CupertinoColors.secondaryLabel, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),
                    CupertinoButton(
                      color: CupertinoColors.systemGrey4,
                      borderRadius: BorderRadius.circular(12),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(CupertinoIcons.back, size: 20, color: CupertinoColors.label),
                          const SizedBox(width: 8),
                          Text('Go Back', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: CupertinoColors.label)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PrefixWidget extends StatelessWidget {
  const PrefixWidget({super.key, required this.icon, required this.title, required this.color});

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4.0)),
          child: Icon(icon, color: CupertinoColors.white),
        ),
        const SizedBox(width: 15),
        Text(title),
      ],
    );
  }
}
