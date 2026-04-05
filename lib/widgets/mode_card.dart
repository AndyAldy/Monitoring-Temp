import 'package:flutter/material.dart';

class ModeCard extends StatelessWidget {
  final bool isManualMode;
  final VoidCallback onSetAuto;

  const ModeCard({super.key, required this.isManualMode, required this.onSetAuto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isManualMode ? Colors.orange.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isManualMode ? Colors.orange.shade200 : Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(
            isManualMode ? Icons.pan_tool_outlined : Icons.auto_mode,
            color: isManualMode ? Colors.orange : Colors.blue,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Mode Perangkat", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(
                isManualMode ? "MANUAL" : "OTOMATIS (SENSOR)",
                style: TextStyle(fontWeight: FontWeight.bold, color: isManualMode ? Colors.orange.shade900 : Colors.blue.shade900),
              ),
            ],
          ),
          const Spacer(),
          if (isManualMode)
            ElevatedButton(
              onPressed: onSetAuto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Set Auto"),
            ),
        ],
      ),
    );
  }
}