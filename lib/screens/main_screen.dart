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
  
  // 👉 TAMBAHKAN INI: Variabel untuk menyimpan riwayat (maksimal 50 log terbaru)
  List<Map<String, dynamic>> _riwayatData = [];

  MqttServerClient? client;

@override
  void initState() {
    super.initState();
    // Beri jeda 1.5 detik agar network native HP benar-benar siap
    // sebelum Flutter menembak server MQTT
    Future.delayed(const Duration(milliseconds: 1500), () {
      _connectToHiveMQ();
    });
  }

  // Fungsi untuk terhubung ke broker HiveMQ Cloud sesuai dengan setup di Wokwi
// Fungsi untuk terhubung ke broker HiveMQ Cloud sesuai dengan setup di Wokwi
  Future<void> _connectToHiveMQ() async {
    String server = 'a845939b5e3b46399f4ede06dfc0ee83.s1.eu.hivemq.cloud'; 
    // Ambil 8 digit angka terakhir saja biar tidak kepanjangan
    String waktu = DateTime.now().millisecondsSinceEpoch.toString();
    String waktuPendek = waktu.substring(waktu.length - 8);
    
    // Hasilnya akan murni huruf & angka, contoh: "App4707870"
    String clientId = 'App$waktuPendek'; 
    
    // Cukup panggil SATU KALI saja
    client = MqttServerClient.withPort(server, clientId, 8883);
    
    // PASTIKAN WEBSOCKET DIMATIKAN
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

    // 👉 SISTEM AUTO-RETRY (COBA 3 KALI)
    int maksimalPercobaan = 3;
    bool berhasilKonek = false;

    for (int i = 1; i <= maksimalPercobaan; i++) {
      try {
        print('Mencoba terhubung ke HiveMQ (Percobaan $i dari $maksimalPercobaan)...');
        await client!.connect('smart_temp', 'Andyaldy13');
        berhasilKonek = true;
        break; // Keluar dari loop jika berhasil!
      } catch (e) {
        print('Gagal connect pada percobaan $i: $e');
        client!.disconnect();
        
        // Jika belum percobaan terakhir, tunggu 2 detik lalu coba lagi
        if (i < maksimalPercobaan) {
          print('Menunggu jaringan HP stabil, mencoba lagi dalam 2 detik...');
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    // Pengecekan akhir setelah proses percobaan selesai
    if (berhasilKonek && client!.connectionStatus!.state == MqttConnectionState.connected) {
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
            
            // Logika riwayat
            final waktuSekarang = DateTime.now();
            final formatWaktu = "${waktuSekarang.hour.toString().padLeft(2, '0')}:${waktuSekarang.minute.toString().padLeft(2, '0')}:${waktuSekarang.second.toString().padLeft(2, '0')}";
            
            _riwayatData.insert(0, {
              'suhu': _suhu,
              'kelembapan': _kelembapan,
              'waktu': formatWaktu,
            });

            if (_riwayatData.length > 50) {
              _riwayatData.removeLast();
            }
          });
        } else if (c[0].topic == 'monitor/iot/kipas_status') {
          setState(() {
            _isKipasNyala = (payload == 'ON'); 
          });
        }
      });
    } else {
      print('🔴 Koneksi gagal total setelah $maksimalPercobaan percobaan.');
      client!.disconnect();
      setState(() {
        _isOnline = false;
      });
    }
  }

  // Tombol untuk merefresh / mencoba konek ulang secara manual (Tombol Sync di atas kanan)
// Ubah fungsi ini menjadi async
  void _sinkronisasiUlang() async { 
    if (client?.connectionStatus?.state != MqttConnectionState.connected) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mencoba menyambungkan ulang ke server...'),
          duration: Duration(seconds: 2),
        ),
      );

      // 👉 PENTING: Putuskan dan bersihkan socket yang menggantung terlebih dahulu!
      if (client != null) {
        client!.disconnect();
        // Beri jeda sebentar agar HiveMQ menyadari bahwa kita sudah "Log Out" 
        // secara baik-baik sebelum "Log In" kembali.
        await Future.delayed(const Duration(milliseconds: 500)); 
      }

      _connectToHiveMQ();
      
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sudah terhubung ke server.'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.green,
        ),
      );
    }
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
      HistoryPage(riwayatData: _riwayatData),
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