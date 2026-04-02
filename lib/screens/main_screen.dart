import 'package:flutter/material.dart';
import 'home_page.dart';     // Mengambil file home_page.dart
import 'history_page.dart';  // Mengambil file history_page.dart

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _indeksNavigasi = 0;
  bool _isOnline = false;

  // Data Dummy Sensor
  final double _suhu = 29.5;
  final double _kelembapan = 65.0;
  final bool _isKipasNyala = true;

  void _pilihTab(int index) {
    setState(() {
      _indeksNavigasi = index;
    });
  }

  void _simulasiKoneksi() {
    setState(() {
      _isOnline = !_isOnline;
    });
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
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          _isOnline ? 'Status: Online 🟢' : 'Status: Offline 🔴',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _isOnline ? Colors.green.shade100 : Colors.red.shade100,
        actions: [
          IconButton(
            icon: const Icon(Icons.wifi),
            tooltip: 'Simulasi Koneksi ESP32',
            onPressed: _simulasiKoneksi,
          ),
        ],
      ),
      body: daftarHalaman[_indeksNavigasi], // Menampilkan halaman yang aktif
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indeksNavigasi,
        onTap: _pilihTab,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}