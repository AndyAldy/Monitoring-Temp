import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const AplikasiMonitoringSuhu());
}

class AplikasiMonitoringSuhu extends StatelessWidget {
  const AplikasiMonitoringSuhu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Monitoring Suhu',
      theme: ThemeData(
        // Menggunakan skema warna Teal (Hijau Kebiruan) yang cocok untuk IoT
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // Konfigurasi font bawaan agar sedikit lebih elegan
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}