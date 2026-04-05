import 'package:flutter/material.dart';

class KipasCard extends StatelessWidget {
  final bool isKipasNyala;
  final Function(bool) onToggle;

  const KipasCard({super.key, required this.isKipasNyala, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isKipasNyala 
              ? [Colors.teal.shade400, Colors.teal.shade200] 
              : [Colors.grey.shade400, Colors.grey.shade200], // Gunakan abu-abu jika mati agar beda dengan merah error
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isKipasNyala ? Colors.teal : Colors.grey).withOpacity(0.3),
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: Icon(
                  isKipasNyala ? Icons.mode_fan_off : Icons.mode_fan_off_outlined, 
                  color: Colors.white, 
                  size: 32
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Kipas Pendingin',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
Switch(
  value: isKipasNyala,
  activeColor: Colors.white,
  activeTrackColor: Colors.teal.shade700,
  // 👉 Saat ditekan, ia menjalankan fungsi yang dikirim dari MainScreen
  onChanged: (value) {
    onToggle(value); 
  },
),
        ],
      ),
    );
  }
}