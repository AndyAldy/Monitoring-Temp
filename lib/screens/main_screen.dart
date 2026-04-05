import 'package:flutter/material.dart';
import '../services/mqtt_service.dart'; // Import Service
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

  // Panggil Backend Service
  final MqttService _mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  void _setupMqtt() {
    // Setup listener untuk status koneksi
    _mqttService.onConnectionStateChanged = (status) {
      setState(() => _isOnline = status);
    };

    // Setup listener untuk data masuk
    _mqttService.onDataReceived = (topic, payload) {
      setState(() {
        if (topic == 'monitor/iot/suhu') {
          _suhu = double.tryParse(payload) ?? _suhu;
        } else if (topic == 'monitor/iot/kelembapan') {
          _kelembapan = double.tryParse(payload) ?? _kelembapan;
          _tambahKeRiwayat();
        } else if (topic == 'monitor/iot/kipas_status') {
          _isKipasNyala = (payload == 'ON');
        }
      });
    };

    _mqttService.connect();
  }

  void _tambahKeRiwayat() {
    final waktu = DateTime.now();
    _riwayatData.insert(0, {
      'suhu': _suhu,
      'kelembapan': _kelembapan,
      'waktu': "${waktu.hour}:${waktu.minute}:${waktu.second}",
    });
    if (_riwayatData.length > 50) _riwayatData.removeLast();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> daftarHalaman = [
      HomePage(isOnline: _isOnline, suhu: _suhu, kelembapan: _kelembapan, isKipasNyala: _isKipasNyala),
      HistoryPage(riwayatData: _riwayatData),
    ];

    return Scaffold(
      // ... (Sisa kode UI AppBar dan BottomNav tetap sama)
      body: daftarHalaman[_indeksNavigasi],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeksNavigasi,
        onDestinationSelected: (i) => setState(() => _indeksNavigasi = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
        ],
      ),
    );
  }
}