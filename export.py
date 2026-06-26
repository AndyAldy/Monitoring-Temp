import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

# 1. Inisialisasi Firebase
cred = credentials.Certificate('smart-fan-ba8a6-firebase-adminsdk-fbsvc-b738c7078b.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

def export_to_csv(history_sensor):
    # 2. Ambil data dari koleksi
    docs = db.collection(history_sensor).stream()
    
    data_list = []
    for doc in docs:
        data = doc.to_dict()
        data['history_sensor'] = doc.id  # Tambahkan ID dokumen jika perlu
        data_list.append(data)
    
    # 3. Konversi ke DataFrame Pandas
    df = pd.DataFrame(data_list)
    
    # 4. Simpan ke CSV
    filename = f"{history_sensor}.csv"
    df.to_csv(filename, index=False)
    print(f"Berhasil! File disimpan sebagai {filename}")

# Jalankan fungsi
export_to_csv('history_sensor')