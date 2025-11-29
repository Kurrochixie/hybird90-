# ESP32 Test Page - Panduan Penggunaan

## Overview
ESP32 Test Page adalah halaman dummy yang dibuat untuk testing komunikasi data serial dari ESP32 ke Firebase. Halaman ini menampilkan semua data yang dikirimkan oleh ESP32 dalam sebuah box yang terorganisir.

## Fitur Utama

### 1. Real-time Data Monitoring
- **Sensor Data**: Menampilkan data dari berbagai sensor (temperature, humidity, etc.)
- **Alarm Data**: Menampilkan status alarm dan zona yang terdeteksi
- **System Data**: Menampilkan status sistem ESP32 (battery, WiFi signal, firmware version)
- **Log Data**: Menampilkan log aktivitas dari ESP32

### 2. Control Panel
- **Device Selection**: Memilih ESP32 device yang ingin dimonitor (ESP32_Bridge_001, 002, 003)
- **Send Test Data**: Mengirim data test ke Firebase untuk simulasi
- **Clear All Data**: Menghapus semua data test dari Firebase
- **Refresh**: Memuat ulang data secara manual

### 3. Auto Refresh
- **Toggle Auto Refresh**: Mengaktifkan/menonaktifkan refresh otomatis
- **Interval Selection**: Mengatur interval refresh (1s, 3s, 5s, 10s)

### 4. Statistics
- Menampilkan jumlah data untuk setiap kategori (Sensors, Alarms, System, Total)

## Cara Mengakses

1. Buka aplikasi Flutter
2. Login dengan akun yang sudah terdaftar
3. Buka drawer menu (klik icon hamburger di kiri atas)
4. Pilih "ESP32 Data Test" dari menu

## Struktur Data di Firebase

### 1. Sensor Data
```
/devices/{deviceId}/sensors/{sensorKey}/
{
  "deviceId": "ESP32_Bridge_001",
  "sensorType": "temperature",
  "value": 25.5,
  "unit": "Celsius",
  "location": "room1",
  "timestamp": "2025-10-14T15:30:00"
}
```

### 2. Alarm Data
```
/devices/{deviceId}/alarms/{alarmKey}/
{
  "deviceId": "ESP32_Bridge_001",
  "alarmType": "fire",
  "zone": "zone1",
  "isActive": true,
  "severity": "high",
  "timestamp": "2025-10-14T15:30:00"
}
```

### 3. System Status
```
/status/{deviceId}/
{
  "deviceId": "ESP32_Bridge_001",
  "status": "online",
  "message": "System operating normally",
  "batteryLevel": 85,
  "timestamp": "2025-10-14T15:30:00",
  "firmwareVersion": "1.0.0",
  "wifiSignal": -45
}
```

### 4. Log Data
```
/logs/{deviceId}/{timestamp}/
{
  "deviceId": "ESP32_Bridge_001",
  "level": "info",
  "message": "Received sensor data: temperature=25.5°C",
  "timestamp": "2025-10-14T15:30:00"
}
```

## Cara Penggunaan

### 1. Monitoring Data Aktual
1. Pastikan ESP32 sudah terhubung dan mengirim data ke Firebase
2. Pilih device ID yang sesuai di dropdown
3. Aktifkan auto refresh untuk mendapatkan data terbaru
4. Data akan ditampilkan secara real-time dalam box yang berbeda berdasarkan tipe

### 2. Testing dengan Data Dummy
1. Klik tombol "Send Test Data" (icon send)
2. Akan mengirim data test berikut:
   - Temperature sensor (25-35°C)
   - Humidity sensor (60-80%)
   - Test alarm (active, low severity)
   - System status (testing mode)
3. Data akan muncul langsung di layar

### 3. Membersihkan Data Test
1. Klik tombol "Clear All Data" (icon clear_all)
2. Konfirmasi untuk menghapus semua data test
3. Data akan dihapus dari Firebase dan layar akan kosong

## Visualisasi Data

### Color Coding
- **Blue**: Data Sensor
- **Red**: Data Alarm
- **Green**: Data System
- **Grey**: Data Log

### Icon Types
- **Sensors Icon**: Data sensor
- **Warning Icon**: Data alarm
- **Settings Icon**: Data system
- **List Icon**: Data log

### Card Layout
Setiap data ditampilkan dalam card dengan:
- Icon dan tipe data (color-coded)
- Timestamp pembuatan data
- Key-value pairs dari data tersebut
- Background yang berbeda untuk setiap tipe

## Troubleshooting

### 1. Data Tidak Muncul
- Pastikan ESP32 terhubung ke internet
- Cek device ID yang dipilih sudah benar
- Pastikan Firebase configuration valid
- Cek koneksi internet aplikasi

### 2. Data Tidak Update
- Aktifkan auto refresh
- Klik tombol refresh manual
- Cek interval refresh yang sesuai
- Pastikan ESP32 mengirim data secara berkala

### 3. Error Saat Send Test Data
- Cek koneksi internet
- Pastikan Firebase rules mengizinkan write access
- Cek console logs untuk error detail

## Integrasi dengan ESP32

### 1. Format Data yang Didukung
ESP32 harus mengirim data dalam format JSON:

```json
{
  "type": "sensor",
  "sensorType": "temperature",
  "value": 25.5,
  "unit": "Celsius",
  "location": "room1",
  "timestamp": "2025-10-14T15:30:00"
}
```

### 2. Firebase Structure
Data akan disimpan di:
- `devices/{deviceId}/sensors/` untuk data sensor
- `devices/{deviceId}/alarms/` untuk data alarm
- `status/{deviceId}/` untuk status sistem
- `logs/{deviceId}/` untuk log aktivitas

### 3. Timestamp
Selalu sertakan timestamp dalam format ISO 8601:
```
2025-10-14T15:30:00
```

## Best Practices

### 1. Performance
- Gunakan interval refresh yang sesuai (3-5 detik)
- Hindari refresh terlalu sering untuk menghemat bandwidth
- Clear data test secara berkala

### 2. Testing
- Gunakan fitur "Send Test Data" untuk simulasi
- Test dengan berbagai tipe data
- Verifikasi format data yang dikirim ESP32

### 3. Monitoring
- Perhatikan statistik data untuk memastikan ESP32 aktif
- Monitor timestamp untuk memastikan data real-time
- Gunakan color coding untuk identifikasi cepat

## Future Enhancements

### 1. Advanced Filtering
- Filter data berdasarkan tipe
- Filter data berdasarkan rentang waktu
- Search functionality untuk data spesifik

### 2. Data Visualization
- Graph untuk sensor data
- Chart untuk trend analysis
- Map visualization untuk lokasi sensor

### 3. Export Functionality
- Export data ke CSV
- Export data ke PDF report
- Share data via email/WhatsApp

### 4. Alert System
- Notifikasi untuk alarm aktif
- Alert untuk nilai sensor di luar batas
- System health monitoring

## Technical Details

### Dependencies
- `firebase_database`: Untuk koneksi Firebase Realtime Database
- `intl`: Untuk formatting timestamp
- `provider`: Untuk state management

### Firebase Rules
Pastikan Firebase rules mengizinkan read/write access:
```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "status": {
      "$deviceId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "logs": {
      "$deviceId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    }
  }
}
```

### Error Handling
- Network timeout handling
- Firebase connection error
- Data parsing error
- UI error states

---

**Catatan**: Halaman ini dirancang khusus untuk testing dan development. Untuk production, pertimbangkan untuk menambahkan fitur security dan monitoring yang lebih comprehensive.
