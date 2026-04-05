import 'package:flutter/material.dart';

class KipasCard extends StatelessWidget {
  final bool isKipasNyala;
  final Function(bool) onToggle;

  const KipasCard({super.key, required this.isKipasNyala, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
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
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.mode_fan_off_outlined, color: Colors.white, size: 32),
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
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }
}