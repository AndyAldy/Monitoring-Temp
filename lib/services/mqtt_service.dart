import 'dart:io';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService {
  MqttServerClient? client;
  
  // Callback untuk mengirim data ke UI (Frontend)
  Function(bool)? onConnectionStateChanged;
  Function(String, String)? onDataReceived;

Future<void> connect() async {
    // 1. CEK STATE: Jangan lakukan apa-apa jika sedang mencoba connect
    if (client != null && client!.connectionStatus!.state == MqttConnectionState.connecting) {
      print('MQTT: Sedang mencoba terhubung, harap tunggu...');
      return; 
    }

    // 2. BERSIHKAN STATE: Disconnect dulu jika statusnya menggantung
    if (client != null && client!.connectionStatus!.state != MqttConnectionState.disconnected) {
      print('MQTT: Memutus koneksi lama sebelum refresh...');
      client!.disconnect();
    }

String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud';
    String waktu = DateTime.now().millisecondsSinceEpoch.toString();
    String clientId = 'App${waktu.substring(waktu.length - 8)}';

    // 1. GANTI PORT MENJADI 8884 (Port khusus WebSocket HiveMQ)
    client = MqttServerClient.withPort(server, clientId, 8883);
    
    // 2. AKTIFKAN WEBSOCKET
    client!.useWebSocket = true;
    
    // 3. PENGATURAN KEAMANAN (Wajib untuk HiveMQ)
    client!.secure = true;
    client!.securityContext = SecurityContext.defaultContext;
    client!.onBadCertificate = (dynamic cert) => true;
    client!.setProtocolV311();
    client!.keepAlivePeriod = 60;

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        // Pastikan username dan password HiveMQ Anda benar di sini
        .authenticateAs('smart_temp', 'Andyaldy13') 
        .startClean();
        
    client!.connectionMessage = connMessage;

    try {
      print('MQTT: Mulai menghubungi server HiveMQ via WebSocket...');
      // Hapus parameter username & password dari sini karena sudah dimasukkan di connMessage atas
      await client!.connect().timeout(const Duration(seconds: 10)); 
    } catch (e) {
      print('MQTT Error saat connect: $e');
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT: Berhasil Terhubung!');
      onConnectionStateChanged?.call(true);
      
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
      print('MQTT: Gagal terhubung. Status: ${client!.connectionStatus!.state}');
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