import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:io';

import 'home_page.dart';
import 'history_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indeksNavigasi = 0;

  bool _isOnline = false;
  double _suhu = 0.0;
  double _kelembapan = 0.0;
  bool _isKipasNyala = false;
  
  List<Map<String, dynamic>> _riwayatData = [];
  MqttServerClient? client;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      _connectToHiveMQ();
    });
  }

  // === FUNGSI KONTROL MANUAL (LOGIKA BARU) ===
  void _toggleKipasManual(bool status) {
    // 1. Update UI secara instan agar tombol langsung bergerak
    setState(() {
      _isKipasNyala = status;
    });

    // 2. Kirim perintah ke ESP32 melalui MQTT
    final builder = MqttClientPayloadBuilder();
    builder.addString(status ? "ON" : "OFF");

    if (client != null && client!.connectionStatus!.state == MqttConnectionState.connected) {
      client!.publishMessage(
        'monitor/iot/kipas_kontrol', 
        MqttQos.atLeastOnce, 
        builder.payload!,
      );
      print('Mengirim perintah manual: ${status ? "ON" : "OFF"}');
    }
  }

  Future<void> _connectToHiveMQ() async {
    String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud'; 
    String waktu = DateTime.now().millisecondsSinceEpoch.toString();
    String clientId = 'App${waktu.substring(waktu.length - 8)}';
    
    client = MqttServerClient.withPort(server, clientId, 8883);
    client!.useWebSocket = false; 
    client!.secure = true; 
    client!.securityContext = SecurityContext.defaultContext;
    client!.onBadCertificate = (dynamic cert) => true; 
    client!.setProtocolV311(); 
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean(); 
    
    client!.connectionMessage = connMessage;

    int maksimalPercobaan = 3;
    bool berhasilKonek = false;

    for (int i = 1; i <= maksimalPercobaan; i++) {
      try {
        await client!.connect('smart_temp', 'Andyaldy13');
        berhasilKonek = true;
        break; 
      } catch (e) {
        client!.disconnect();
        if (i < maksimalPercobaan) {
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    if (berhasilKonek && client!.connectionStatus!.state == MqttConnectionState.connected) {
      setState(() {
        _isOnline = true; 
      });
      
      client!.subscribe('monitor/iot/suhu', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kelembapan', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kipas_status', MqttQos.atLeastOnce);
      // Subscribe juga ke topik kontrol agar sinkron jika ada perangkat lain yang mengontrol
      client!.subscribe('monitor/iot/kipas_kontrol', MqttQos.atLeastOnce);

      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        
        if (mounted) {
          setState(() {
            if (c[0].topic == 'monitor/iot/suhu') {
              _suhu = double.tryParse(payload) ?? _suhu; 
            } else if (c[0].topic == 'monitor/iot/kelembapan') {
              _kelembapan = double.tryParse(payload) ?? _kelembapan; 
              _simpanKeRiwayat();
            } else if (c[0].topic == 'monitor/iot/kipas_status' || c[0].topic == 'monitor/iot/kipas_kontrol') {
              // Update status tombol berdasarkan laporan balik dari ESP32
              _isKipasNyala = (payload == 'ON'); 
            }
          });
        }
      });
    } else {
      setState(() {
        _isOnline = false;
      });
    }
  }

  void _simpanKeRiwayat() {
    final waktuSekarang = DateTime.now();
    final formatWaktu = "${waktuSekarang.hour.toString().padLeft(2, '0')}:${waktuSekarang.minute.toString().padLeft(2, '0')}:${waktuSekarang.second.toString().padLeft(2, '0')}";
    
    _riwayatData.insert(0, {
      'suhu': _suhu.toStringAsFixed(1),
      'kelembapan': _kelembapan.toStringAsFixed(1),
      'waktu': formatWaktu,
    });

    if (_riwayatData.length > 50) _riwayatData.removeLast();
  }

  void _sinkronisasiUlang() async { 
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      if (client != null) {
        client!.disconnect();
        await Future.delayed(const Duration(milliseconds: 500)); 
      }
      _connectToHiveMQ();
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> daftarHalaman = [
      HomePage(
        isOnline: _isOnline,
        suhu: _suhu,
        kelembapan: _kelembapan,
        isKipasNyala: _isKipasNyala,
        onToggleKipas: _toggleKipasManual, // Kirim fungsi kontrol ke HomePage
      ),
      HistoryPage(riwayatData: _riwayatData, onDeleteAll: () {  },),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Dashboard IoT', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(_isOnline ? Icons.wifi : Icons.wifi_off, size: 16, color: _isOnline ? Colors.green.shade700 : Colors.red.shade700),
                  const SizedBox(width: 6),
                  Text(_isOnline ? 'Online' : 'Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _isOnline ? Colors.green.shade700 : Colors.red.shade700)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.sync), onPressed: _sinkronisasiUlang),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: daftarHalaman[_indeksNavigasi],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeksNavigasi,
        onDestinationSelected: (int index) => setState(() => _indeksNavigasi = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), label: 'History'),
        ],
      ),
    );
  }
}