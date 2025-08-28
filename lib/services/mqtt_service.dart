// import 'package:mqtt_client/mqtt_server_client.dart';
// import 'package:flutter/foundation.dart';

// class MqttService {
//   static final MqttService _instance = MqttService._internal();
//   factory MqttService() => _instance;
//   late MqttServerClient client;

//   // 新增：連線狀態通知器
//   final ValueNotifier<bool> isConnected = ValueNotifier(false);

//   MqttService._internal();

//   Future<void> connect() async {
//     // 假資料，請稍後自行修改
//     const String server = '10.125.1.104';
//     const int port = 1883;
//     const String clientId = 'prms_client';

//     client = MqttServerClient(server, clientId);
//     client.port = port;
//     client.logging(on: false);
//     client.keepAlivePeriod = 20;
//     client.onConnected = onConnected;
//     client.onDisconnected = onDisconnected;
//     client.onSubscribed = onSubscribed;
//     client.onSubscribeFail = onSubscribeFail;
//     client.pongCallback = pong;

//     // 連線前先設為 false，避免 UI loading 狀態殘留
//     isConnected.value = false;
//     try {
//       // await client.connect().timeout(const Duration(seconds: 10));
//       // // 連線後檢查狀態
//       // if (client.connectionStatus?.state == MqttConnectionState.connected) {
//       //   isConnected.value = true;
//       // } else {
//       //   print('MQTT 連線失敗: 狀態 ${client.connectionStatus?.state}');
//       //   isConnected.value = false;
//       //   client.disconnect();
//       // }
//     } catch (e) {
//       // print('MQTT 連線失敗: $e');
//       // isConnected.value = false;
//       // client.disconnect();
//     }
//   }

//   void onConnected() {
//     // print('MQTT Connected');
//     isConnected.value = true;
//   }

//   void onDisconnected() {
//     // print('MQTT Disconnected');
//     isConnected.value = false;
//   }

//   void onSubscribed(String topic) {
//     // print('Subscribed to: $topic');
//   }

//   void onSubscribeFail(String topic) {
//     // print('Failed to subscribe: $topic');
//   }

//   void pong() {
//     // print('Ping response received');
//   }
// }

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:prmsapp/services/config_service.dart';
import 'package:uuid/uuid.dart';

/// MQTT 服務單例，跨 Page 取得與監聽連線狀態：
///
/// final mqtt = MqttService.instance;
/// ValueListenableBuilder<bool>(
///   valueListenable: mqtt.isConnected,
///   builder: (context, connected, child) {
///     return Text(connected ? 'MQTT 已連線' : 'MQTT 未連線');
///   },
/// )
class MqttService {
  static final MqttService _instance = MqttService._internal();
  factory MqttService() => _instance;
  static MqttService get instance => _instance;
  late MqttServerClient client;

  // clientId 改回 String?，並只初始化一次
  String? _clientId;
  Future<void>? _clientIdInitFuture;

  // 新增：連線狀態通知器
  final ValueNotifier<bool> isConnected = ValueNotifier(false);
  // 新增：連線中狀態通知器
  final ValueNotifier<bool> isConnecting = ValueNotifier(false);
  // 新增：ack訊號通知
  final ValueNotifier<String?> ackNotifier = ValueNotifier(null);

  StreamSubscription? _updateSubscription;
  final Map<String, Completer<String>> _ackCompleters = {};

  MqttService._internal();

  Future<void> _initClientId() async {
    if (_clientId != null) return; // 已初始化過
    final deviceInfo = DeviceInfoPlugin();
    String id = '';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      id = androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      id = iosInfo.identifierForVendor ?? '';
    }
    id = id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    id = id.trim().isEmpty ? Uuid().v4() : id;
    _clientId = '${id}_viscanner';
  }

  Future<void> connect() async {
    try {
      // 確保 clientId 已初始化
      _clientIdInitFuture ??= _initClientId();
      await _clientIdInitFuture;
      final String clientId = _clientId!;
      final mqtt = ConfigService.mqttConfig;
      final String server = mqtt['host'] ?? 'localhost';
      final int port = mqtt['port'] ?? 1883;
      isConnecting.value = true;
      // client 尚未初始化時，先初始化
      if (!_isClientInitialized()) {
        client = MqttServerClient(server, clientId);
      }
      // 嘗試安全判斷 client 狀態，避免重複連線
      try {
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          print('MQTT 已連線，略過重複 connect');
          return;
        }
        if (client.connectionStatus?.state != MqttConnectionState.disconnected) {
          try {
            client.disconnect();
          } catch (e) {
            print('MQTT disconnect error: $e');
          }
        }
      } catch (_) {
        // client 尚未初始化，略過
      }
      // 只在必要時 new client（如已初始化則覆蓋）
      client = MqttServerClient(server, clientId);
      client.port = port;
      client.logging(on: false);
      client.keepAlivePeriod = 20;
      client.onConnected = onConnected;
      client.onDisconnected = onDisconnected;
      client.onSubscribed = onSubscribed;
      client.onSubscribeFail = onSubscribeFail;
      client.pongCallback = pong;

      try {
        await client.connect().timeout(const Duration(seconds: 10));
        if (client.connectionStatus?.state == MqttConnectionState.connected) {
          isConnected.value = true;
          // 只加一次 updates listener
          _updateSubscription?.cancel();
          _updateSubscription = client.updates?.listen(_onMessage);
        } else {
          print('MQTT 連線失敗: 狀態 \\${client.connectionStatus?.state}');
          isConnected.value = false;
          isConnecting.value = false;
          if (client.connectionStatus?.state != MqttConnectionState.disconnected) {
            client.disconnect();
          }
        }
      } catch (e) {
        print('MQTT 連線失敗: $e');
        isConnected.value = false;
        isConnecting.value = false;
        try {
          if (client.connectionStatus?.state != MqttConnectionState.disconnected) {
            client.disconnect();
          }
        } catch (_) {}
      }
    } finally {
      isConnecting.value = false; // 只在連線流程結束時設為 false
    }
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> c) {
    final recMess = c[0].payload as MqttPublishMessage;
    final payload = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
    print('收到訊息: topic= [200m\\${c[0].topic} [0m, payload=$payload');
    // 處理 ack
    if (c[0].topic.startsWith('barcode/ack/')) {
      final topicKey = c[0].topic.replaceFirst('barcode/ack/', '');
      if (_ackCompleters.containsKey(topicKey)) {
        _ackCompleters[topicKey]!.complete(payload);
        _ackCompleters.remove(topicKey);
      }
      ackNotifier.value = payload;
    }
  }

  void onConnected() {
    print('MQTT Connected');
    isConnected.value = true;
    // 連線成功後自動重新訂閱所有 topic
    for (final topic in _subscribedTopics) {
      client.subscribe(topic, MqttQos.atLeastOnce);
      print('重新訂閱: $topic');
    }
  }

  void onDisconnected() {
    print('MQTT Disconnected');
    isConnected.value = false;
  }

  void onSubscribed(String topic) {
    print('Subscribed to: $topic');
  }

  void onSubscribeFail(String topic) {
    print('Failed to subscribe: $topic');
  }

  void pong() {
    print('Ping response received');
  }

  // 新增：發佈訊息方法（僅供內部使用）
  void _publish(String topic, String message) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      var payloadMqtt = "{\"sendkey\": \"$message\", \"ack\": \"enter\"}";
      builder.addString(payloadMqtt);
      client.publishMessage('barcode/$topic', MqttQos.atLeastOnce, builder.payload!);
      print('MQTT 已發佈: topic=$topic, message=$message');
    } else {
      print('MQTT 尚未連線，無法發佈訊息');
    }
  }

  // 新增：已訂閱的 topic 集合，避免重複訂閱
  final Set<String> _subscribedTopics = {};

  void subscribe(String topic) {
    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      if (_subscribedTopics.contains(topic)) {
        print('已重複訂閱: $topic，略過');
        return;
      }
      client.subscribe(topic, MqttQos.atLeastOnce);
      _subscribedTopics.add(topic);
      print('已訂閱: $topic');
      // listener 已在 connect 時加過，不重複加
    } else {
      print('MQTT 尚未連線，無法訂閱 $topic');
    }
  }

  /// 發佈訊息並等待 ack 訊號，成功回傳 true，失敗回傳 false
  Future<bool> publishAndWaitAck(String topic, String message, {Duration timeout = const Duration(seconds: 5)}) async {
    subscribe('barcode/ack/$topic');
    final completer = Completer<String>();
    _ackCompleters[topic] = completer;
    _publish(topic, message);
    try {
      await completer.future.timeout(timeout);
      return true;
    } catch (_) {
      _ackCompleters.remove(topic);
      return false;
    }
  }

  bool _isClientInitialized() {
    try {
      // 嘗試存取 client 的屬性，若未初始化會丟出例外
      client.connectionStatus;
      return true;
    } catch (_) {
      return false;
    }
  }
}
