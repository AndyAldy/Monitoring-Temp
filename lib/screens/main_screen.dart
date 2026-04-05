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

  // Variabel state untuk menyimpan data dari Wokwi/HiveMQ
  bool _isOnline = false;
  double _suhu = 0.0;
  double _kelembapan = 0.0;
  bool _isKipasNyala = false;

  MqttServerClient? client;

  @override
  void initState() {
    super.initState();
    // Panggil fungsi koneksi MQTT saat layar pertama kali dimuat
    _connectToHiveMQ();
  }

  // Fungsi untuk terhubung ke broker HiveMQ Cloud sesuai dengan setup di Wokwi
Future<void> _connectToHiveMQ() async {
    String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud'; 
    String clientId = 'FlutterApp_${DateTime.now().millisecondsSinceEpoch}';
    
    client = MqttServerClient(server, clientId);
    
    // ======== SOLUSI ANTI BLOKIR PROVIDER SELULER ========
    // Gunakan WebSocket (Port 8884) alih-alih TCP murni (Port 8883)
    client!.useWebSocket = true; 
    client!.port = 8884; 
    // =====================================================

    client!.secure = true; 
    // Gunakan SecurityContext() kosong atau defaultContext
    client!.securityContext = SecurityContext.defaultContext;
    client!.onBadCertificate = (Object cert) => true;
    client!.setProtocolV311(); 
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean(); 
        // ❌ BARIS INI DIHAPUS: .withWillQos(MqttQos.atLeastOnce);
    
    client!.connectionMessage = connMessage;

    try {
      print('Mencoba terhubung ke HiveMQ Cloud...');
      // Gunakan username dan password dari HiveMQ Cloud kamu
      await client!.connect('smart_temp', 'Andyaldy13');
    } catch (e) {
      print('Gagal connect: $e');
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('🟢 BERHASIL TERHUBUNG KE HIVEMQ CLOUD!');
      setState(() {
        _isOnline = true; 
      });
      
      client!.subscribe('monitor/iot/suhu', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kelembapan', MqttQos.atLeastOnce);
      client!.subscribe('monitor/iot/kipas_status', MqttQos.atLeastOnce);

      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        
        print('Terima data dari topik <${c[0].topic}>: $payload');
        
        if (c[0].topic == 'monitor/iot/suhu') {
          setState(() {
            _suhu = double.tryParse(payload) ?? _suhu; 
          });
        } else if (c[0].topic == 'monitor/iot/kelembapan') {
          setState(() {
            _kelembapan = double.tryParse(payload) ?? _kelembapan; 
          });
        } else if (c[0].topic == 'monitor/iot/kipas_status') {
          setState(() {
            _isKipasNyala = (payload == 'ON'); 
          });
        }
      });
    } else {
      print('🔴 Koneksi gagal dengan status: ${client!.connectionStatus!.state}');
      client!.disconnect();
      setState(() {
        _isOnline = false;
      });
    }
}

  // Tombol untuk merefresh / mencoba konek ulang secara manual (Tombol Sync di atas kanan)
  void _sinkronisasiUlang() {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      _connectToHiveMQ();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sudah terhubung ke server.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mencoba menyambungkan ulang ke server...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // List halaman yang akan ditukar-tukar berdasarkan tab yang diklik
    final List<Widget> daftarHalaman = [
      HomePage(
        isOnline: _isOnline,
        suhu: _suhu,
        kelembapan: _kelembapan,
        isKipasNyala: _isKipasNyala,
      ),
      const HistoryPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            const Text(
              'Dashboard IoT',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const Spacer(),
            // Status Chip modern
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _isOnline ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.wifi : Icons.wifi_off,
                    size: 16,
                    color: _isOnline ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _isOnline ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi Ulang',
            onPressed: _sinkronisasiUlang,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: daftarHalaman[_indeksNavigasi],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeksNavigasi,
        onDestinationSelected: (int index) {
          setState(() {
            _indeksNavigasi = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Colors.teal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: Colors.teal),
            label: 'History',
          ),
        ],
      ),
    );
  }
}