import 'package:flutter/material.dart';

class ModeCard extends StatelessWidget {
  final bool isManualMode;
  final VoidCallback onSetAuto;

  const ModeCard({super.key, required this.isManualMode, required this.onSetAuto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isManualMode ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isManualMode ? Colors.orange.shade200 : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isManualMode ? Icons.touch_app : Icons.settings_suggest,
            color: isManualMode ? Colors.orange.shade700 : Colors.blue.shade700,
          ),
          const SizedBox(width: 12),
          Text(
            isManualMode ? "Mode : Manual" : "Mode : Auto (Sensor)",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isManualMode ? Colors.orange.shade900 : Colors.blue.shade900,
            ),
          ),
          const Spacer(),
          if (isManualMode)
            ElevatedButton.icon(
              onPressed: onSetAuto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text("Set Auto"),
            ),
        ],
      ),
    );
  }
}