import 'package:tflite_flutter/tflite_flutter.dart';

class MLService {
  Interpreter? _interpreter;

  // 1. Load Model
  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/model_suhu.tflite');
      print("Model ML berhasil dimuat");
    } catch (e) {
      print("Gagal memuat model: $e");
    }
  }

  // 2. Fungsi Prediksi
  double predict(List<double> inputData) {
    if (_interpreter == null) return 0.0;

    // Pastikan bentuk input sesuai dengan model (misal: [1, 10, 1] untuk LSTM)
    var input = inputData.reshape([1, 10, 1]); 
    var output = List.filled(1, 0.0).reshape([1, 1]);

    _interpreter!.run(input, output);

    return output[0][0]; // Hasil prediksi
  }
}