import 'package:flutter/material.dart';
// WAJIB TAMBAHKAN IMPORT FIRESTORE INI:
import 'package:cloud_firestore/cloud_firestore.dart'; 

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
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.isOnline,
    required this.suhu,
    required this.kelembapan,
    required this.isKipasNyala,
    required this.isManualMode,
    required this.onToggleKipas,
    required this.onSetAuto,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOnline) {
      return _buildOfflineView();
    }
    final Color textColor = isDarkMode ? Colors.white : Colors.black87;

    // Logika warna kelembapan
    Color bgColorhumid = kelembapan > 60.0 ? Colors.red.shade100 : (kelembapan >= 40.0 ? Colors.amber.shade100 : Colors.green.shade100);
    Color txtColorhumid = kelembapan > 60.0 ? Colors.red.shade900 : (kelembapan >= 40.0 ? Colors.orange.shade900 : Colors.green.shade900);
    Color iconColorhumid = kelembapan > 60.0 ? Colors.red.shade700 : (kelembapan >= 40.0 ? Colors.orange.shade700 : Colors.green.shade700);

    // Logika warna suhu
    Color bgColortemp = suhu > 28 ? Colors.red : ( suhu >= 25 ? Colors.blue.shade300 : Colors.lightBlueAccent);
    Color txtColortemp = suhu > 28 ? Colors.cyan.shade200 : ( suhu >= 25 ? Colors.greenAccent.shade400 : Colors.pink);
    Color iconColortemp = suhu > 28 ? Colors.cyan.shade200 : ( suhu >= 25 ? Colors.greenAccent.shade400 : Colors.pink);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Monitor DHT22', style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: SensorCard(title: 'Suhu', value: suhu.toStringAsFixed(1), unit: '°C', icon: Icons.thermostat, iconColor: iconColortemp, backgroundColor: bgColortemp, textColor: txtColortemp)),
              const SizedBox(width: 16),
              Expanded(child: SensorCard(title: 'Kelembapan', value: kelembapan.toStringAsFixed(1), unit: '%', icon: Icons.water_drop, iconColor: iconColorhumid, backgroundColor: bgColorhumid, textColor: txtColorhumid)),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // ---- PENAMBAHAN KODE WIDGET MACHINE LEARNING DI SINI ----
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('ml_results').doc('status_terkini').snapshots(),
            builder: (context, snapshot) {
              // 1. Tangkap error Firestore (agar tidak layar merah)
              if (snapshot.hasError) {
                return Card(
                  color: Colors.red.shade100,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Error Firebase:\n${snapshot.error}', 
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              // 2. Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              // 3. Database masih kosong
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text("Data dari Python ML belum tersedia di database.", textAlign: TextAlign.center,),
                  ),
                );
              }

              // 4. Data berhasil diambil, tampilkan UI aslinya
              var dataML = snapshot.data!.data() as Map<String, dynamic>;
              bool isAnomaly = dataML['is_anomaly'] ?? false;
              String statusText = dataML['status_prediksi'] ?? 'Menunggu AI...';

              return Card(
                color: isAnomaly ? Colors.red.shade100 : Colors.green.shade100,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isAnomaly ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                            color: isAnomaly ? Colors.red : Colors.green,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Analisis AI (Machine Learning)",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: isAnomaly ? Colors.red.shade900 : Colors.green.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // --------------------------------------------------------

          const SizedBox(height: 24),
          Text('Kontrol Perangkat', style: TextStyle(fontSize: 20, color: textColor, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ModeCard(isManualMode: isManualMode, onSetAuto: onSetAuto),
          const SizedBox(height: 16),
          KipasCard(
            isKipasNyala: isKipasNyala, 
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