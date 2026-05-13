import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:monitoring_tempe/model/ml_service.dart';

class HistoryPage extends StatefulWidget {
  final bool isDarkMode;

  // Hapus parameter riwayatData dan onDeleteAll, karena sekarang 
  // halaman ini mandiri mengatur datanya sendiri dari Firestore.
  const HistoryPage({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MLService _mlService = MLService();
  double _hasilPrediksi = 0.0;
  bool _isModelReady = false;

  // Variabel lokal untuk menyimpan aliran data dari Firestore
  List<Map<String, dynamic>> _riwayatData = [];
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _initML();
    _listenToFirestore(); // Panggil fungsi Stream Firestore
  }

  Future<void> _initML() async {
    await _mlService.initModel();
    setState(() {
      _isModelReady = true;
    });
    _jalankanPrediksi();
  }

  // Fungsi utama untuk menarik data permanen secara Real-Time
  void _listenToFirestore() {
    _subscription = FirebaseFirestore.instance
        .collection('history_sensor')
        // Sesuaikan dengan nama field kamu (Waktu kapital atau waktu kecil)
        .orderBy('Waktu', descending: true) 
        .snapshots()
        .listen((snapshot) {
      
      setState(() {
        _riwayatData = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          data['docId'] = doc.id; // Simpan ID untuk keperluan hapus data
          return data;
        }).toList();
      });

      // Setiap ada data baru masuk, otomatis update prediksi AI
      if (_isModelReady) {
        _jalankanPrediksi();
      }
    });
  }

  void _jalankanPrediksi() {
    if (_riwayatData.length >= 10) {
      try {
        // Ambil 10 data terakhir, toleransi huruf besar/kecil dari Firestore
        List<double> inputSuhu = _riwayatData
            .take(10)
            .map((data) => ((data['Suhu'] ?? data['suhu'] ?? 0.0) as num).toDouble())
            .toList()
            .reversed
            .toList();

        List<double> normalizedInput = inputSuhu.map((s) => s / 100).toList();
        double pred = _mlService.predict(normalizedInput);

        setState(() {
          _hasilPrediksi = pred * 100;
        });
      } catch (e) {
        print("Error ML Prediksi: $e");
      }
    }
  }

  // Fungsi khusus untuk menghapus data langsung dari Database
  Future<void> _deleteAllData() async {
    final collection = FirebaseFirestore.instance.collection('history_sensor');
    var snapshots = await collection.get();
    
    // Gunakan WriteBatch agar bisa menghapus ratusan data sekaligus
    var batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  @override
  void dispose() {
    // Wajib dihentikan agar tidak bocor memori saat pindah halaman
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
          "Butuh minimal 10 data untuk menjalankan prediksi AI.",
          style: TextStyle(color: Colors.orange),
        ),
      );
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
                  "${_hasilPrediksi.toStringAsFixed(1)} °C",
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${_riwayatData.length} Log',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          TextButton.icon(
            // Panggil fungsi hapus massal Firestore di sini
            onPressed: _deleteAllData, 
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            label: const Text('Hapus Semua', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

Widget _buildHistoryItem(Map<String, dynamic> data) {
    // 1. Ambil data waktu mentah
    var rawWaktu = data['Waktu'] ?? data['waktu'];
    String waktuTampil = '-';

    // 2. Cek apakah formatnya Timestamp dari Firestore
    if (rawWaktu is Timestamp) {
      DateTime dt = rawWaktu.toDate(); // Ubah ke DateTime
      // Format manual menjadi "DD/MM/YYYY HH:MM" (contoh: 12/5/2026 14:05)
      waktuTampil = "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    } else if (rawWaktu != null) {
      // Jika ternyata sudah berwujud String
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
        // 3. Gunakan waktu yang sudah diformat di sini
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