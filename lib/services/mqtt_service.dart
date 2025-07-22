import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:flutter/foundation.dart';

class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  late MqttServerClient client;

  // 新增：連線狀態通知器
  final ValueNotifier<bool> isConnected = ValueNotifier(false);

  MqttService._internal();

  Future<void> connect() async {
    // 假資料，請稍後自行修改
    const String server = '10.125.1.104';
    const int port = 1883;
    const String clientId = 'prms_client';

    client = MqttServerClient(server, clientId);
    client.port = port;
    client.logging(on: false);
    client.keepAlivePeriod = 20;
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;

    // 連線前先設為 false，避免 UI loading 狀態殘留
    isConnected.value = false;
    try {
      // await client.connect().timeout(const Duration(seconds: 10));
      // // 連線後檢查狀態
      // if (client.connectionStatus?.state == MqttConnectionState.connected) {
      //   isConnected.value = true;
      // } else {
      //   print('MQTT 連線失敗: 狀態 ${client.connectionStatus?.state}');
      //   isConnected.value = false;
      //   client.disconnect();
      // }
    } catch (e) {
      // print('MQTT 連線失敗: $e');
      // isConnected.value = false;
      // client.disconnect();
    }
  }

  void onConnected() {
    // print('MQTT Connected');
    isConnected.value = true;
  }

  void onDisconnected() {
    // print('MQTT Disconnected');
    isConnected.value = false;
  }

  void onSubscribed(String topic) {
    // print('Subscribed to: $topic');
  }

  void onSubscribeFail(String topic) {
    // print('Failed to subscribe: $topic');
  }

  void pong() {
    // print('Ping response received');
  }
}
