import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd
import time
from sklearn.ensemble import IsolationForest

# 1. Inisialisasi Firebase
cred = credentials.Certificate("D:\kuliah\Semester6\Sistem_Kendali\monitoring_tempe\smart-fan-ba8a6-firebase-adminsdk-fbsvc-b738c7078b.json")
firebase_admin.initialize_app(cred)
db = firestore.client()

def jalankan_analisis_ml():
    print("Membaca data terbaru dari Firestore...")
    
    # PERBAIKAN 1: Cek dokumen menggunakan 'waktu' atau 'Waktu' secara aman
    docs_generator = db.collection('history_sensor').order_by('Waktu', direction=firestore.Query.DESCENDING).limit(25).stream()
    
    data_list = []
    # Data ditarik di sini. Kita bungkus pakai try-except untuk cegah gagal jaringan
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
                
        # Jika pakai 'Waktu' (huruf besar) ternyata datanya kosong, coba pakai 'waktu' (huruf kecil)
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
        return # Keluar dari fungsi jika gagal baca database

    # 2. Buat DataFrame Pandas
    df = pd.DataFrame(data_list)

    if df.empty or len(df) < 15:
        print(f"Data sensor belum cukup untuk dilatih oleh AI (Terkumpul: {len(df)}).")
        db.collection('ml_results').document('status_terkini').set({
            'is_anomaly': False,
            'status_prediksi': "Mengumpulkan data sensor (Minimal 15)...",
        })
        return

    # --- 3. PROSES MACHINE LEARNING (ISOLATION FOREST) ---
    X = df[['suhu', 'kelembapan']]

    # PERBAIKAN 2: Ubah contamination ke 'auto' agar AI menyesuaikan diri. 
    # AI tidak akan "memaksa" mencari anomali jika memang datanya normal semua.
    model = IsolationForest(contamination='auto', random_state=42)
    model.fit(X)

    # Ambil data indeks 0 (Data paling baru masuk / terkini)
    data_terkini = X.iloc[[0]]
    
    # Lakukan prediksi: 1 (Normal), -1 (Anomali)
    hasil_prediksi = model.predict(data_terkini)[0]

    suhu_sekarang = data_terkini['suhu'].values[0]
    humid_sekarang = data_terkini['kelembapan'].values[0]

    is_anomaly = False
    status_prediksi = f"Kondisi Normal (Suhu dan Kelembapan stabil)"

    if hasil_prediksi == -1:
        is_anomaly = True
        status_prediksi = f"⚠️ ANOMALI TERDETEKSI! Suhu {suhu_sekarang}°C dan Kelembapan {humid_sekarang}% melonjak drastis."

    print(f">> Analisis Selesai: {status_prediksi}")

    # --- 4. KIRIM HASIL KE APLIKASI FLUTTER ---
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
        # PERBAIKAN 3: Cegah crash total akibat RTO (Request Time Out)
        try:
            jalankan_analisis_ml()
        except Exception as e:
            print(f"!!! Terjadi kesalahan sistem: {e}")
            print("Sistem akan mencoba lagi pada putaran berikutnya...")
            
        print("Menunggu 60 detik untuk analisis berikutnya...")
        time.sleep(60)