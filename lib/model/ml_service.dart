import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;

  // 1. Load Model dengan pelacak error
  Future<void> initModel() async {
    try {
      print("⏳ Sedang mencoba memuat model TFLite...");
      _interpreter = await Interpreter.fromAsset('assets/model_suhu.tflite');
      print("✅ SUKSES: Model ML berhasil dimuat!");
    } catch (e) {
      print("❌ FATAL ERROR (Gagal memuat model): $e");
    }
  }

  // 2. Fungsi Prediksi Anti-Crash
  double predict(List<double> inputData) {
    if (_interpreter == null) {
      print("⚠️ PREDIKSI DIBATALKAN: Interpreter masih NULL (Model belum termuat).");
      return 0.0;
    }

    try {
      print(">> Memulai prediksi dengan ${inputData.length} data...");

      // Membuat array 3D secara manual: [Batch=1, Timesteps=10, Feature=1]
      // Menggunakan cara bawaan Dart agar terhindar dari NoSuchMethodError: reshape
      var input3D = [
        inputData.map((suhu) => [suhu]).toList()
      ];

      // Wadah output 2D: [Batch=1, Feature=1]
      var output2D = List.generate(1, (i) => List.filled(1, 0.0));

      // Jalankan model
      _interpreter!.run(input3D, output2D);

      double hasil = output2D[0][0];
      print("✅ SUKSES: Prediksi mentah TFLite = $hasil");
      
      return hasil;

    } catch (e) {
      print('❌ ERROR SAAT PREDIKSI: $e');
      return 0.0;
    }
  }
}