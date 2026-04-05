import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Membuat list dummy untuk mempercantik UI
    final List<Map<String, dynamic>> riwayatDummy = List.generate(10, (index) {
      return {
        'suhu': 29.0 + (index * 0.2),
        'kelembapan': 60.0 + (index * 1.5),
        'waktu': 'Hari ini, 10:${59 - index}',
      };
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: riwayatDummy.length,
      itemBuilder: (context, index) {
        final data = riwayatDummy[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: CircleAvatar(
              backgroundColor: Colors.teal.shade50,
              child: const Icon(Icons.history, color: Colors.teal),
            ),
            title: Text(
              data['waktu'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text('Log Tersimpan'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${data['suhu'].toStringAsFixed(1)} °C',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('${data['kelembapan'].toStringAsFixed(1)} %',
                    style: const TextStyle(fontSize: 12, color: Colors.blue)),
              ],
            ),
          ),
        );
      },
    );
  }
}