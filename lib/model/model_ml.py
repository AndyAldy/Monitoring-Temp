import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import time
import numpy as np
import tensorflow as tf
from sklearn.ensemble import IsolationForest

# 1. Inisialisasi Firebase
cred = credentials.Certificate(r"D:/kuliah/Semester6/Sistem_Kendali/monitoring_tempe/smart-fan-ba8a6-firebase-adminsdk-fbsvc-b738c7078b.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

print("Memuat model LSTM TFLite...")
try:
    # Cukup sebutkan namanya saja
    interpreter = tf.lite.Interpreter(model_path="model_suhu.tflite")
    interpreter.allocate_tensors()
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    lstm_ready = True
    print("Model LSTM berhasil dimuat!")
except Exception as e:
    print(f"Gagal memuat model TFLite: {e}")
    lstm_ready = False


def jalankan_analisis_ml():
    print("Membaca data terbaru dari Firestore...")
    
    docs_generator = db.collection('history_sensor').order_by('Waktu', direction=firestore.Query.DESCENDING).limit(25).stream()
    
    data_list = []
    try:
        for doc in docs_generator:
            data = doc.to_dict()
            try:
                suhu = float(data.get('Suhu', data.get('suhu', 0)))
                kelembapan = float(data.get('Kelembapan', data.get('kelembapan', 0)))
                
                if suhu > 0 and kelembapan > 0:
                    data_list.append({
                        'suhu': suhu,
                        'kelembapan': kelembapan,
                    })
            except ValueError:
                pass
                
        if len(data_list) == 0:
            docs_generator = db.collection('history_sensor').order_by('waktu', direction=firestore.Query.DESCENDING).limit(25).stream()
            for doc in docs_generator:
                data = doc.to_dict()
                try:
                    suhu = float(data.get('Suhu', data.get('suhu', 0)))
                    kelembapan = float(data.get('Kelembapan', data.get('kelembapan', 0)))
                    if suhu > 0 and kelembapan > 0:
                        data_list.append({'suhu': suhu, 'kelembapan': kelembapan})
                except ValueError:
                    pass

    except Exception as e:
        print(f"Error saat menarik data dari Firestore: {e}")
        return 

    df = pd.DataFrame(data_list)

    if df.empty or len(df) < 15:
        print(f"Data sensor belum cukup untuk dilatih oleh AI (Terkumpul: {len(df)}).")
        db.collection('ml_results').document('status_terkini').set({
            'is_anomaly': False,
            'status_prediksi': "Mengumpulkan data sensor (Minimal 15)...",
        })
        return

    # --- 1. PROSES MACHINE LEARNING (ISOLATION FOREST - ANOMALI) ---
    X = df[['suhu', 'kelembapan']]

    model = IsolationForest(contamination='auto', random_state=42)
    model.fit(X)

    data_terkini = X.iloc[[0]]
    hasil_prediksi = model.predict(data_terkini)[0]

    suhu_sekarang = data_terkini['suhu'].values[0]
    humid_sekarang = data_terkini['kelembapan'].values[0]

    is_anomaly = False
    status_prediksi = f"Kondisi Normal (Suhu dan Kelembapan stabil)"

    if hasil_prediksi == -1:
        is_anomaly = True
        status_prediksi = f"⚠️ ANOMALI TERDETEKSI! Suhu {suhu_sekarang}°C dan Kelembapan {humid_sekarang}% melonjak drastis."


    # --- 2. PROSES PREDIKSI MASA DEPAN (LSTM) ---
    suhu_masa_depan = 0.0
    if lstm_ready and len(df) >= 10:
        try:
            # Ambil 10 data terakhir, balik menjadi urutan kronologis
            suhu_10_terakhir = df['suhu'].head(10).values[::-1]
            
            # --- NORMALISASI ---
            # WAJIB SAMA DENGAN SAAT PELATIHAN MODEL (Ganti jika beda)
            min_temp = 20.0
            max_temp = 40.0
            
            suhu_norm = [(s - min_temp) / (max_temp - min_temp) for s in suhu_10_terakhir]
            
            # Reshape menjadi 3D [1, 10, 1] tipe Float32
            input_data = np.array(suhu_norm, dtype=np.float32).reshape(1, 10, 1)
            
            # Eksekusi TFLite
            interpreter.set_tensor(input_details[0]['index'], input_data)
            interpreter.invoke()
            output_data = interpreter.get_tensor(output_details[0]['index'])
            
            # --- DENORMALISASI ---
            hasil_norm = output_data[0][0]
            suhu_masa_depan = (hasil_norm * (max_temp - min_temp)) + min_temp
        except Exception as e:
            print(f"Error prediksi LSTM: {e}")

    print(f">> Analisis Selesai: {status_prediksi} | Prediksi LSTM: {suhu_masa_depan:.2f} °C")

    # --- 3. KIRIM SEMUA HASIL KE APLIKASI FLUTTER ---
    db.collection('ml_results').document('status_terkini').set({
        'is_anomaly': is_anomaly,
        'status_prediksi': status_prediksi,
        'suhu_tercatat': suhu_sekarang,
        'kelembapan_tercatat': humid_sekarang,
        'prediksi_suhu_lstm': float(suhu_masa_depan), # Menyisipkan hasil LSTM
        'timestamp': firestore.SERVER_TIMESTAMP
    })
    print("Data berhasil di-push ke UI Flutter!\n")


if __name__ == "__main__":
    print("=== Sistem Backend ML Monitoring Suhu Berjalan ===")
    while True:
        try:
            jalankan_analisis_ml()
        except Exception as e:
            print(f"!!! Terjadi kesalahan sistem: {e}")
            print("Sistem akan mencoba lagi pada putaran berikutnya...")
            
        print("Menunggu 60 detik untuk analisis berikutnya...")
        time.sleep(60)