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
  
  // Variabel tidak lagi "final" agar bisa diubah saat data MQTT masuk
  bool _isOnline = false;
  double _suhu = 0.0;
  double _kelembapan = 0.0;
  bool _isKipasNyala = false;

  MqttServerClient? client;

  @override
  void initState() {
    super.initState();
    // Otomatis mencoba connect ke HiveMQ saat halaman dibuka
    _connectToHiveMQ(); 
  }

  // ==== FUNGSI KONEKSI KE HIVEMQ CLOUD ====
  Future<void> _connectToHiveMQ() async {
    // 1. GANTI INI DENGAN URL CLUSTER KAMU (tanpa mqtt:// atau https://)
    String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud'; 
    
    client = MqttServerClient.withPort(server, 'FlutterClient_Angel', 8883);
    
    // Wajib dinyalakan untuk HiveMQ Cloud
    client!.secure = true; 
    client!.securityContext = SecurityContext.defaultContext;
    client!.setProtocolV311(); 
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    
    final connMessage = MqttConnectMessage()
        .withClientIdentifier('FlutterClient_Andy')
        .withWillQos(MqttQos.atLeastOnce);
    
    client!.connectionMessage = connMessage;

    try {
      print('Menghubungkan ke HiveMQ Cloud...');
      // 2. GANTI INI DENGAN USERNAME & PASSWORD HIVEMQ CLOUD KAMU
      await client!.connect('smart_temp', 'Andyaldy13');
    } catch (e) {
      print('Gagal connect: $e');
      client!.disconnect();
    }

    if (client!.connectionStatus!.state == MqttConnectionState.connected) {
      print('Status: Terhubung ke HiveMQ Cloud!');
      setState(() {
        _isOnline = true; // Ubah status UI jadi Online
      });
      
      // Subscribe ke topik sensor (Sesuaikan dengan topik di Wokwi)
      client!.subscribe('angel/iot/suhu', MqttQos.atLeastOnce);

      // Dengarkan pesan yang masuk
      client!.updates!.listen((List<MqttReceivedMessage<MqttMessage>> c) {
        final MqttPublishMessage message = c[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(message.payload.message);
        
        print('Terima data dari topik <${c[0].topic}>: $payload');
        
        // Memperbarui UI Flutter secara real-time
        if (c[0].topic == 'angel/iot/suhu') {
          setState(() {
            _suhu = double.tryParse(payload) ?? _suhu; 
          });
        }
      });
    } else {
      print('Koneksi gagal!');
      client!.disconnect();
      setState(() {
        _isOnline = false;
      });
    }
  }

  // Tombol sinkronisasi manual jika tiba-tiba terputus
  void _sinkronisasiUlang() {
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      _connectToHiveMQ();
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
            // Status Chip
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
            onPressed: _sinkronisasiUlang, // Panggil ulang koneksi
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