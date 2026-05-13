import 'package:flutter/material.dart';
import 'package:monitoring_tempe/model/ml_service.dart'; // Pastikan file service ML sudah dibuat

class HistoryPage extends StatefulWidget {
  final List<Map<String, dynamic>> riwayatData;
  final VoidCallback onDeleteAll;
  final bool isDarkMode;

  const HistoryPage({
    super.key,
    required this.riwayatData,
    required this.onDeleteAll,
    required this.isDarkMode,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final MLService _mlService = MLService();
  double _hasilPrediksi = 0.0;
  bool _isModelReady = false;

  @override
  void initState() {
    super.initState();
    _initML();
  }

  Future<void> _initML() async {
    await _mlService.initModel();
    _jalankanPrediksi();
    setState(() {
      _isModelReady = true;
    });
  }

  void _jalankanPrediksi() {
    if (widget.riwayatData.length >= 10) {
      // 1. Ambil 10 data suhu terakhir
      List<double> inputSuhu = widget.riwayatData
          .take(10) // Karena biasanya Firestore orderBy Desc, 10 pertama adalah yang terbaru
          .map((data) => (data['suhu'] as num).toDouble())
          .toList()
          .reversed // Balikkan agar urutan: lama -> baru
          .toList();

      // 2. Normalisasi (Contoh: bagi 100, samakan dengan saat training Python)
      List<double> normalizedInput = inputSuhu.map((s) => s / 100).toList();

      // 3. Prediksi
      double pred = _mlService.predict(normalizedInput);

      // 4. Denormalisasi (Contoh: kali 100)
      setState(() {
        _hasilPrediksi = pred * 100;
      });
    }
  }

  @override
  void didUpdateWidget(covariant HistoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Jalankan ulang prediksi jika ada data baru masuk dari Firestore
    if (widget.riwayatData.length != oldWidget.riwayatData.length) {
      _jalankanPrediksi();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.riwayatData.isEmpty) {
      return _buildEmptyView();
    }

    return Column(
      children: [
        _buildPredictionCard(), // Card baru untuk hasil ML
        _buildHeader(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.riwayatData.length,
            itemBuilder: (context, index) => _buildHistoryItem(widget.riwayatData[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionCard() {
    if (widget.riwayatData.length < 10) {
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

  // ... (Tetap gunakan _buildHeader, _buildHistoryItem, dan _buildEmptyView dari kode lama Anda)
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 10, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: ${widget.riwayatData.length} Log',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          TextButton.icon(
            onPressed: widget.onDeleteAll,
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
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
            backgroundColor: Colors.teal.shade50, child: const Icon(Icons.history, color: Colors.teal)),
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