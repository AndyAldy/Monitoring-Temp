import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import time
from sklearn.ensemble import IsolationForest

# 1. Inisialisasi Firebase
# Pastikan nama file JSON kredensial sudah benar
cred = credentials.Certificate("smart-fan-ba8a6-firebase-adminsdk-fbsvc-c4e7a0f15c.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def jalankan_analisis_ml():
    print("Membaca data terbaru dari Firestore...")
    
    # Ambil 100 data terbaru (Descending) agar ML menganalisis tren terkini
    try:
        docs = db.collection('history_sensor').order_by('Waktu', direction=firestore.Query.DESCENDING).limit(100).stream()
    except Exception as e:
        # Menyesuaikan jika nama field waktunya menggunakan huruf kecil di database
        docs = db.collection('history_sensor').order_by('waktu', direction=firestore.Query.DESCENDING).limit(100).stream()

    data_list = []
    for doc in docs:
        data = doc.to_dict()
        try:
            # Ekstraksi dan konversi ke float (jaga-jaga jika tipe datanya string)
            suhu = float(data.get('Suhu', data.get('suhu', 0)))
            kelembapan = float(data.get('Kelembapan', data.get('kelembapan', 0)))
            
            # Abaikan jika data 0 (mungkin sensor belum terbaca)
            if suhu > 0 and kelembapan > 0:
                data_list.append({
                    'suhu': suhu,
                    'kelembapan': kelembapan,
                })
        except ValueError:
            pass # Lewati baris data yang cacat / tidak bisa diubah ke angka

    # 2. Buat DataFrame Pandas
    df = pd.DataFrame(data_list)

    if df.empty or len(df) < 15:
        print("Data sensor belum cukup untuk dilatih oleh AI (Minimal 15 baris data).")
        # PERBAIKAN: Gunakan .document() bukan .doc()
        db.collection('ml_results').document('status_terkini').set({
            'is_anomaly': False,
            'status_prediksi': "Mengumpulkan data sensor...",
        })
        return

    # --- 3. PROSES MACHINE LEARNING (ISOLATION FOREST) ---
    X = df[['suhu', 'kelembapan']]

    # contamination=0.05 artinya kita asumsikan 5% dari data ekstrem adalah anomali
    model = IsolationForest(contamination=0.05, random_state=42)
    model.fit(X)

    # Ambil data indeks 0 (Data paling baru masuk / terkini)
    data_terkini = X.iloc[[0]]
    
    # Lakukan prediksi: 1 (Normal), -1 (Anomali)
    hasil_prediksi = model.predict(data_terkini)[0]

    suhu_sekarang = data_terkini['suhu'].values[0]
    humid_sekarang = data_terkini['kelembapan'].values[0]

    is_anomaly = False
    status_prediksi = f"Kondisi Normal (AI mendeteksi pola wajar)"

    if hasil_prediksi == -1:
        is_anomaly = True
        status_prediksi = f"⚠️ ANOMALI TERDETEKSI! Suhu {suhu_sekarang}°C dan Kelembapan {humid_sekarang}% di luar kebiasaan."

    print(f">> Analisis Selesai: {status_prediksi}")

    # --- 4. KIRIM HASIL KE APLIKASI FLUTTER ---
    # PERBAIKAN: Gunakan .document() bukan .doc()
    db.collection('ml_results').document('status_terkini').set({
        'is_anomaly': is_anomaly,
        'status_prediksi': status_prediksi,
        'suhu_tercatat': suhu_sekarang,
        'kelembapan_tercatat': humid_sekarang,
        'timestamp': firestore.SERVER_TIMESTAMP
    })
    print("Data berhasil di-push ke UI Flutter!\n")


# --- 5. LOOPING BACKEND WORKER ---
if __name__ == "__main__":
    print("=== Sistem Backend ML Monitoring Suhu Berjalan ===")
    while True:
        jalankan_analisis_ml()
        print("Menunggu 30 detik untuk analisis berikutnya...")
        time.sleep(30)