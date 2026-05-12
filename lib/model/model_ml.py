import firebase_admin
from firebase_admin import credentials, firestore
import pandas as pd

# 1. Inisialisasi Firebase menggunakan file JSON yang di-download
# Ganti nama file json di bawah ini sesuai dengan yang kamu download
cred = credentials.Certificate("monitoring-suhu-firebase-adminsdk.json")
firebase_admin.initialize_app(cred)

# 2. Akses Firestore
db = firestore.client()

# 3. Mengambil data dari collection 'history_sensor'
docs = db.collection('history_sensor').order_by('timestamp').stream()

# 4. Memasukkan data ke dalam list lalu diubah ke Pandas DataFrame agar siap untuk ML
data_list = []
for doc in docs:
    data = doc.to_dict()
    # Mengabaikan data jika timestamp-nya belum ter-generate
    if data.get('timestamp') is not None: 
        data_list.append({
            'id': doc.id,
            'suhu': data.get('Suhu'),
            'kelembapan': data.get('Kelembapan'),
            'waktu': data.get('timestamp')
        })

# Membuat DataFrame
df = pd.DataFrame(data_list)

print("Data berhasil diambil dari Firestore!")
print(df.head()) # Menampilkan 5 baris pertama

# --- DI SINI KAMU BISA MEMULAI MACHINE LEARNING ---
# Contoh: 
# X = df[['kelembapan']]  # Fitur (Features)
# y = df['suhu']          # Target prediksi (Labels)
# 
# from sklearn.model_selection import train_test_split
# from sklearn.linear_model import LinearRegression
# 
# X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2)
# model = LinearRegression()
# model.fit(X_train, y_train)
# print("Akurasi Model:", model.score(X_test, y_test))