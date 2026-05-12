import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Fungsi untuk menyimpan data sensor
  Future<void> simpanDataSensor(double suhu, double kelembapan) async {
    try {
      await _db.collection('history_sensor').add({
        'suhu': suhu,
        'kelembapan': kelembapan,
        'timestamp': FieldValue.serverTimestamp(), // Waktu otomatis dari server Firebase
      });
      print("Data berhasil disimpan ke Firestore");
    } catch (e) {
      print("Gagal menyimpan data: $e");
    }
  }

  // Fungsi untuk membaca data (opsional, jika ingin ditampilkan di UI)
  Stream<QuerySnapshot> streamDataSensor() {
    return _db.collection('history_sensor')
              .orderBy('timestamp', descending: true)
              .snapshots();
  }
}