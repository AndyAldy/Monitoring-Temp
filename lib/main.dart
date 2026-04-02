import 'package:flutter/material.dart';
import 'screens/splash_screen.dart'; // Mengambil file splash_screen.dart

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
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const SplashScreen()
    );
  }
}