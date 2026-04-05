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
          // Memecah Suhu & Kelembapan menjadi 2 Card terpisah di dalam Row
// Di dalam build method HomePage...
          Row(
            children: [
              Expanded(
                child: SensorCard(
                  title: 'Suhu',
                  value: '$suhu',
                  unit: '°C',
                  icon: Icons.thermostat,
                  iconColor: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SensorCard(
                  title: 'Kelembapan',
                  value: '$kelembapan',
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
                      child: Icon(
                        Icons.mode_fan_off_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Kipas Pendingin',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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