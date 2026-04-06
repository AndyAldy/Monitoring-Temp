import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  final List<Map<String, dynamic>> riwayatData;
  final VoidCallback onDeleteAll;
  final bool isDarkMode;

  const HistoryPage({super.key,
  required this.riwayatData, 
  required this.onDeleteAll,
  required this.isDarkMode,
  }
  );

  @override
  Widget build(BuildContext context) {
    if (riwayatData.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: riwayatData.length,
            itemBuilder: (context, index) => _buildHistoryItem(riwayatData[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${riwayatData.length} Log', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          TextButton.icon(
            onPressed: onDeleteAll,
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            label: const Text('Hapus Semua', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> data) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(backgroundColor: Colors.teal.shade50, child: const Icon(Icons.history, color: Colors.teal)),
        title: Text(data['waktu'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Log Tersimpan'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('${data['suhu']} °C', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            Text('${data['kelembapan']} %', style: const TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text('Belum ada data riwayat.', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
        ],
      ),
    );
  }
}