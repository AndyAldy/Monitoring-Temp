import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final bool isOnline;
  final double suhu;
  final double kelembapan;
  final bool isKipasNyala;

  // Menerima data dari main_screen
  const HomePage({
    super.key,
    required this.isOnline,
    required this.suhu,
    required this.kelembapan,
    required this.isKipasNyala,
  });

  @override
  Widget build(BuildContext context) {
    // Jika ESP32 Offline, tampilkan teks saja
    if (!isOnline) {
      return const Center(
        child: Text(
          'esp32 belum konek nih',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
      );
    }

    // Jika ESP32 Online, tampilkan Dashboard
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Sensor DHT22
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text('Monitor DHT22', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Icon(Icons.thermostat, color: Colors.orange, size: 40),
                          const Text('Suhu', style: TextStyle(color: Colors.grey)),
                          Text('$suhu °C', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          const Icon(Icons.water_drop, color: Colors.blue, size: 40),
                          const Text('Kelembapan', style: TextStyle(color: Colors.grey)),
                          Text('$kelembapan %', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Card Status Kipas
          Card(
            elevation: 4,
            color: isKipasNyala ? Colors.green.shade50 : Colors.red.shade50,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.mode_fan_off_outlined,
                        color: isKipasNyala ? Colors.green : Colors.red,
                        size: 40,
                      ),
                      const SizedBox(width: 16),
                      const Text('Status Kipas:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(
                    isKipasNyala ? 'MENYALA' : 'MATI',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isKipasNyala ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}