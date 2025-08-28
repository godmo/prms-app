import 'package:flutter/cupertino.dart';
import 'package:prmsapp/providers/selected_pc_provider.dart';
import 'package:prmsapp/services/mqtt_service.dart';
import 'package:provider/provider.dart';

class BindingPCCard extends StatefulWidget {
  final List<String> pcList;
  final VoidCallback onShowPicker;
  final ValueChanged<bool> onQRScan;

  const BindingPCCard({super.key, required this.pcList, required this.onQRScan, required this.onShowPicker});

  @override
  State<BindingPCCard> createState() => _BindingPCCardState();
}

class _BindingPCCardState extends State<BindingPCCard> {
  bool isTapped = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final mqtt = MqttService.instance;
    return ValueListenableBuilder<bool>(
      valueListenable: mqtt.isConnected,
      builder: (context, connected, _) {
        // 新增：監聽 isConnecting 狀態
        return ValueListenableBuilder<bool>(
          valueListenable: mqtt.isConnecting,
          builder: (context, connecting, __) {
            final Color cardColor = connected ? const Color(0xFFE6F9EA) : const Color(0xFFFDEAEA);
            final Color iconColor = connected ? CupertinoColors.activeGreen : CupertinoColors.systemRed;
            final selectedPC = Provider.of<SelectedPCProvider>(context).selectedPC;

            return GestureDetector(
              onTapDown: (_) {
                setState(() {
                  isTapped = true;
                });
              },
              onTapUp: (_) {
                setState(() {
                  isTapped = false;
                });
                widget.onShowPicker();
              },
              onTapCancel: () {
                setState(() {
                  isTapped = false;
                });
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16.0),
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06, vertical: 15.0),
                decoration: BoxDecoration(
                  color: isTapped ? cardColor.withOpacity(0.7) : cardColor,
                  borderRadius: BorderRadius.circular(16.0),
                  boxShadow: [BoxShadow(color: CupertinoColors.black.withOpacity(0.3), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.desktopcomputer, size: 25, color: CupertinoColors.black),
                        SizedBox(width: 6),
                        const Text(
                          'Binding PC',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.normal, color: CupertinoColors.black),
                          textAlign: TextAlign.left,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (connecting)
                      Center(
                        child: CupertinoActivityIndicator(
                          color: CupertinoColors.systemGrey,
                          radius: screenWidth * 0.06, // 可依需求調整大小
                        ),
                      )
                    else
                      Row(
                        children: [
                          GestureDetector(
                            child: Icon(
                              !connected
                                  ? CupertinoIcons.xmark_circle_fill
                                  : (selectedPC.isEmpty || selectedPC == 'Please Bind PC')
                                  ? CupertinoIcons.exclamationmark_triangle_fill
                                  : CupertinoIcons.check_mark_circled_solid,
                              size: screenWidth * 0.12,
                              color:
                                  !connected
                                      ? CupertinoColors.systemRed
                                      : (selectedPC.isEmpty || selectedPC == 'Please Bind PC')
                                      ? CupertinoColors.systemYellow
                                      : CupertinoColors.systemGreen,
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.04),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Consumer<SelectedPCProvider>(
                                        builder:
                                            (context, pcProvider, _) => Text(
                                              pcProvider.selectedPC,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(CupertinoIcons.chevron_down, size: 14, color: CupertinoColors.black),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 0,
                            onPressed: () {
                              debugPrint('[BindingPCCard] QR button pressed, calling onQRScan(true)');
                              widget.onQRScan(true);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12.0)),
                              child: Icon(CupertinoIcons.qrcode, size: screenWidth * 0.08, color: iconColor),
                            ),
                          ),
                        ],
                      ),
                    // 新增：若未連線顯示提醒
                    if (!connected)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 2.0, right: 2.0),
                        child: Text(
                          'Please check:\n1. Is VPN connected?\n2. Is bound PC name correct?\n3. Is PC\'s binding QRcode enabled?',
                          style: TextStyle(color: CupertinoColors.systemRed, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    // 新增：若已選擇PC，顯示提醒打開PC端小程式
                    if (selectedPC.isNotEmpty && selectedPC != 'Please Bind PC' && connected)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0, left: 2.0, right: 2.0),
                        child: Row(
                          children: const [
                            Icon(CupertinoIcons.info, color: CupertinoColors.systemGreen, size: 18),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Please check the binding QRcode  is running on your OA PC',
                                style: TextStyle(color: CupertinoColors.systemGreen, fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
