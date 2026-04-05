import 'package:flutter/material.dart';
import '../widgets/sensor_card.dart';
import '../widgets/mode_card.dart';
import '../widgets/kipas_card.dart';

class HomePage extends StatelessWidget {
  final Function(bool) onToggleKipas;
  final VoidCallback onSetAuto;
  final bool isOnline;
  final double suhu;
  final double kelembapan;
  final bool isKipasNyala;
  final bool isManualMode;

  const HomePage({
    super.key,
    required this.isOnline,
    required this.suhu,
    required this.kelembapan,
    required this.isKipasNyala,
    required this.isManualMode,
    required this.onToggleKipas,
    required this.onSetAuto,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return _buildOfflineView();
    }

    // Logika warna kelembapan
    Color bgColor = kelembapan > 60.0 ? Colors.red.shade100 : (kelembapan >= 40.0 ? Colors.amber.shade100 : Colors.green.shade100);
    Color txtColor = kelembapan > 60.0 ? Colors.red.shade900 : (kelembapan >= 40.0 ? Colors.orange.shade900 : Colors.green.shade900);
    Color icoColor = kelembapan > 60.0 ? Colors.red.shade700 : (kelembapan >= 40.0 ? Colors.orange.shade700 : Colors.green.shade700);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Monitor DHT22', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SensorCard(title: 'Suhu', value: suhu.toStringAsFixed(1), unit: '°C', icon: Icons.thermostat, iconColor: Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: SensorCard(title: 'Kelembapan', value: kelembapan.toStringAsFixed(1), unit: '%', icon: Icons.water_drop, iconColor: icoColor, bgColor: bgColor, textColor: txtColor)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Kontrol Perangkat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ModeCard(isManualMode: isManualMode, onSetAuto: onSetAuto),
          const SizedBox(height: 16),
          KipasCard(
  isKipasNyala: isKipasNyala, 
  // 👉 Fungsi diteruskan ke widget KipasCard
  onToggle: onToggleKipas, 
),
        ],
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text('Menunggu Koneksi ESP32...', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}