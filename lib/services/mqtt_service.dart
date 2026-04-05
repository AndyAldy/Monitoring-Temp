import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  
  // Callback untuk mengirim data ke UI (Frontend)
  Function(bool)? onConnectionStateChanged;
  Function(String, String)? onDataReceived;

  Future<void> connect() async {
    String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud';
    String waktu = DateTime.now().millisecondsSinceEpoch.toString();
    String clientId = 'App${waktu.substring(waktu.length - 8)}';

    client = MqttServerClient.withPort(server, clientId, 8883);
    client!.useWebSocket = false;
    client!.secure = true;
    client!.securityContext = SecurityContext.defaultContext;
    client!.onBadCertificate = (dynamic cert) => true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 60;

    final connMessage = MqttConnectMessage().withClientIdentifier(clientId).startClean();
    client!.connectionMessage = connMessage;

    try {
      await client!.connect('smart_temp', 'Andyaldy13');
    } catch (e) {
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      onConnectionStateChanged?.call(true);
      
      // Subscribe ke semua topik yang diperlukan
      client!.subscribe('monitor/iot/suhu', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kelembapan', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kipas_status', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kipas_kontrol', MqttQos.atLeastOnce);

      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        onDataReceived?.call(c[0].topic, payload);
      });
    } else {
      onConnectionStateChanged?.call(false);
      client!.disconnect();
    }
  }

  void publish(String topic, String message) {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      final builder = MqttClientPayloadBuilder();
      builder.addString(message);
      client!.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
    }
  }

  void disconnect() {
    client?.disconnect();
    onConnectionStateChanged?.call(false);
  }
}