import 'package:flutter/material.dart';
import 'package:monitoring_tempe/widgets/sensor_card.dart';

class HomePage extends StatelessWidget {
  final bool isOnline;
  final double suhu;
  final double kelembapan;
  final bool isKipasNyala;

  const HomePage({
    super.key,
    required this.isOnline,
    required this.suhu,
    required this.kelembapan,
    required this.isKipasNyala,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Logika tampilan jika offline
    if (!isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Menunggu Koneksi ESP32...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    // 2. Definisi variabel warna untuk Kelembapan (Logic Backend di Frontend)
    Color warnaBgKelembapan;
    Color warnaTeksKelembapan;
    Color warnaIkonKelembapan;

    if (kelembapan > 60.0) {
      // Merah jika > 60%
      warnaBgKelembapan = Colors.red.shade100;
      warnaTeksKelembapan = Colors.red.shade900;
      warnaIkonKelembapan = Colors.red.shade700;
    } else if (kelembapan >= 40.0 && kelembapan <= 60.0) {
      // Kuning/Amber jika 40% - 60% (Dibuat soft agar tidak menyilaukan)
      warnaBgKelembapan = Colors.amber.shade100;
      warnaTeksKelembapan = Colors.orange.shade900;
      warnaIkonKelembapan = Colors.orange.shade700;
    } else {
      // Hijau jika < 40%
      warnaBgKelembapan = Colors.green.shade100;
      warnaTeksKelembapan = Colors.green.shade900;
      warnaIkonKelembapan = Colors.green.shade700;
    }

    // 3. Tampilan Utama
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Monitor DHT22',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Card Suhu (Default Putih)
              Expanded(
                child: SensorCard(
                  title: 'Suhu',
                  value: suhu.toStringAsFixed(1),
                  unit: '°C',
                  icon: Icons.thermostat,
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              
              // Card Kelembapan (Warna Dinamis)
              Expanded(
                child: SensorCard(
                  title: 'Kelembapan',
                  value: kelembapan.toStringAsFixed(1),
                  unit: '%',
                  icon: Icons.water_drop,
                  iconColor: warnaIkonKelembapan,
                  bgColor: warnaBgKelembapan,
                  textColor: warnaTeksKelembapan,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Kontrol Perangkat',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Card Status Kipas
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isKipasNyala 
                    ? [Colors.teal.shade400, Colors.teal.shade200] 
                    : [Colors.red.shade400, Colors.red.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isKipasNyala ? Colors.teal : Colors.red).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mode_fan_off_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Kipas Pendingin',
                      style: TextStyle(
                        fontSize: 18, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  isKipasNyala ? 'ON' : 'OFF',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}