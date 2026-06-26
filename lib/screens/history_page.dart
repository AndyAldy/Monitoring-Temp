import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryPage extends StatefulWidget {
  final bool isDarkMode;

  const HistoryPage({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Map<String, dynamic>> _riwayatData = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _listenToFirestore(); 
  }

  void _listenToFirestore() {
    _subscription = FirebaseFirestore.instance
        .collection('history_sensor')
        .orderBy('Waktu', descending: true) 
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _riwayatData = snapshot.docs.map((doc) {
          var data = doc.data();
          data['docId'] = doc.id; 
          return data;
        }).toList();
      });
    });
  }

  Future<void> _deleteAllData() async {
    final collection = FirebaseFirestore.instance.collection('history_sensor');
    var snapshots = await collection.get();
    
    var batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    _subscription?.cancel(); 
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_riwayatData.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildPredictionCard(),
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _riwayatData.length,
            itemBuilder: (context, index) => _buildHistoryItem(_riwayatData[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
    if (_riwayatData.length < 10) {
      return Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          "Butuh minimal 10 data untuk memunculkan prediksi AI.",
          style: TextStyle(color: Colors.orange),
        ),
      );
    }

    // Menggunakan StreamBuilder agar Card Prediksi otomatis update 
    // dengan data dari script Python di Firestore
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('ml_results').doc('status_terkini').snapshots(),
      builder: (context, snapshot) {
        double prediksiSuhu = 0.0;

        if (snapshot.hasData && snapshot.data!.exists) {
          var data = snapshot.data!.data() as Map<String, dynamic>;
          prediksiSuhu = (data['prediksi_suhu_lstm'] ?? 0.0).toDouble();
        }

        return Card(
          margin: const EdgeInsets.all(16),
          elevation: 4,
          color: Colors.teal.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.psychology, color: Colors.white, size: 40),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Prediksi Suhu Selanjutnya (LSTM)",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "${prediksiSuhu.toStringAsFixed(1)} °C",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${_riwayatData.length} Log',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          TextButton.icon(
            onPressed: _deleteAllData, 
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            label: const Text('Hapus Semua', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> data) {
    var rawWaktu = data['Waktu'] ?? data['waktu'];
    String waktuTampil = '-';

    if (rawWaktu is Timestamp) {
      DateTime dt = rawWaktu.toDate(); 
      waktuTampil = "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (rawWaktu != null) {
      waktuTampil = rawWaktu.toString();
    }

    String suhu = (data['Suhu'] ?? data['suhu'] ?? '-').toString();
    String humid = (data['Kelembapan'] ?? data['kelembapan'] ?? '-').toString();

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
            backgroundColor: Colors.teal.shade50, child: const Icon(Icons.history, color: Colors.teal)),
        title: Text(waktuTampil, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: const Text('Log Tersimpan'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$suhu °C', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            Text('$humid %', style: const TextStyle(fontSize: 12, color: Colors.blue)),
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