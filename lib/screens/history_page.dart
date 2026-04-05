import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  // Parameter ini wajib ada untuk menerima data
  final List<Map<String, dynamic>> riwayatData;

  const HistoryPage({
    super.key,
    required this.riwayatData,
  });

  @override
  Widget build(BuildContext context) {
    if (riwayatData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Belum ada data riwayat.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final data = riwayatData[index];
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
              data['waktu'].toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            subtitle: const Text('Log Tersimpan'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${data['suhu']} °C',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text(
                  '${data['kelembapan']} %',
                  style: const TextStyle(fontSize: 12, color: Colors.blue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}