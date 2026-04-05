import 'package:flutter/material.dart';
import '../services/mqtt_service.dart';
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
  bool _isManualMode = false;

  // Panggil Backend Service
  final MqttService _mqttService = MqttService();

  @override
  void initState() {
    super.initState();
    _setupMqtt();
  }

  void _setupMqtt() {
    // 1. Sinkronisasi status Online/Offline
    _mqttService.onConnectionStateChanged = (status) {
      if (mounted) setState(() => _isOnline = status);
    };

    // 2. Sinkronisasi Data Masuk
_mqttService.onDataReceived = (topic, payload) {
  if (mounted) {
    setState(() {
      if (topic == 'monitor/iot/suhu') {
        _suhu = double.tryParse(payload) ?? _suhu;
      } else if (topic == 'monitor/iot/kelembapan') {
        _kelembapan = double.tryParse(payload) ?? _kelembapan;
        _simpanKeRiwayat();
      } else if (topic == 'monitor/iot/kipas_status') {
        _isKipasNyala = (payload == 'ON');
      } 
      // 👉 TAMBAHKAN LOGIKA INI:
      else if (topic == 'monitor/iot/kipas_kontrol') {
        if (payload == "AUTO") {
          _isManualMode = false;
        } else {
          // Jika ON atau OFF, berarti sedang mode manual
          _isManualMode = true;
        }
      }
    });
  }
};

    // Mulai koneksi (Delay 1.5 detik agar jaringan HP siap)
    Future.delayed(const Duration(milliseconds: 1500), () => _mqttService.connect());
  }

  void _simpanKeRiwayat() {
    final sekarang = DateTime.now();
    _riwayatData.insert(0, {
      'suhu': _suhu.toStringAsFixed(1),
      'kelembapan': _kelembapan.toStringAsFixed(1),
      'waktu': "${sekarang.hour.toString().padLeft(2, '0')}:${sekarang.minute.toString().padLeft(2, '0')}:${sekarang.second.toString().padLeft(2, '0')}",
    });
    if (_riwayatData.length > 50) _riwayatData.removeLast();
  }

  // --- LOGIKA SINKRONISASI MANUAL ---
  void _toggleKipasManual(bool status) {
    setState(() => _isKipasNyala = status); // Update UI instan
    _mqttService.publish('monitor/iot/kipas_kontrol', status ? "ON" : "OFF");
  }

  void _clearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text('Semua log akan dihapus permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              setState(() => _riwayatData.clear());
              Navigator.pop(context);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

void _setKipasOtomatis() {
  _mqttService.publish('monitor/iot/kipas_kontrol', 'AUTO');
  setState(() {
    _isManualMode = false;
  });
}

  @override
  Widget build(BuildContext context) {
final List<Widget> daftarHalaman = [
  HomePage(
    isOnline: _isOnline,
    suhu: _suhu,
    kelembapan: _kelembapan,
    isKipasNyala: _isKipasNyala,
    isManualMode: _isManualMode, // Kirim status mode
    onToggleKipas: _toggleKipasManual,
    onSetAuto: _setKipasOtomatis, // Kirim fungsi set auto
  ),
  HistoryPage(riwayatData: _riwayatData, onDeleteAll: _clearHistory),
];

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Dashboard IoT', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            // Chip Status Sinkron
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
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () => _mqttService.connect(),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: daftarHalaman[_indeksNavigasi],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indeksNavigasi,
        onDestinationSelected: (int i) => setState(() => _indeksNavigasi = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history_outlined), label: 'History'),
        ],
      ),
    );
  }
}