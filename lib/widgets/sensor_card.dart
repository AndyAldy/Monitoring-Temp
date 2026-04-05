import 'package:flutter/material.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color? textColor;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    this.bgColor = Colors.white,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    // Logika warna teks default jika tidak ditentukan
    final Color finalTitleColor = textColor ?? Colors.grey.shade600;
    final Color finalValueColor = textColor ?? Colors.black;
    final Color finalUnitColor = textColor ?? Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 36),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(color: finalTitleColor, fontSize: 14)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: finalValueColor,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(fontSize: 16, color: finalUnitColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}