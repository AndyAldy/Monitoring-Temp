import 'package:flutter/material.dart';
import 'dart:async'; // Dibutuhkan untuk fitur Timer
import 'main_screen.dart'; // Import halaman utama

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    
    // Menjalankan Timer selama 3 detik
    Timer(const Duration(seconds: 3), () {
      // Setelah 3 detik, pindah ke MainScreen dan hapus SplashScreen dari riwayat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700, // Warna latar belakang splash screen
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon atau Logo Aplikasi
            Icon(
              Icons.thermostat_auto,
              size: 100,
              color: Colors.white,
            ),
            SizedBox(height: 20),
            
            // Nama Aplikasi
            Text(
              'Smart IoT Monitor',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 40),
            
            // Animasi Loading berputar
            CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}