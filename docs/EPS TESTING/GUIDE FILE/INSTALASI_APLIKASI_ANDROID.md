# 📱 PANDUAN INSTALASI APLIKASI DDS FIRE ALARM MONITORING

## 📦 File yang Dibutuhkan

APK sudah berhasil dibuild! Lokasi file:
```
build\app\outputs\flutter-apk\app-release.apk
```

Ukuran file: **57.3 MB**

## 📲 Cara Instalasi di Android

### Metode 1: Instalasi Langsung via USB

1. **Transfer APK ke HP Android**
   - Hubungkan HP Android ke PC dengan kabel USB
   - Copy file `app-release.apk` ke folder Downloads di HP

2. **Izinkan Install dari Sumber Tidak Dikenal**
   - Buka **Settings** → **Security & privacy**
   - Aktifkan **Install from unknown sources**
   - Pilih browser/file manager yang digunakan

3. **Instal Aplikasi**
   - Buka file manager di HP
   - Cari file `app-release.apk` di folder Downloads
   - Tap file untuk memulai instalasi
   - Ikuti petunjuk di layar

### Metode 2: Via ADB (Untuk Developer)

```bash
# Install via ADB
adb install build\app\outputs\flutter-apk\app-release.apk

# Atau jika sudah ada versi terinstall
adb install -r build\app\outputs\flutter-apk\app-release.apk
```

## ⚙️ Informasi Aplikasi

- **Nama Aplikasi**: DDS Fire Alarm Monitoring
- **Package ID**: com.example.flutter_application_1
- **Version**: 1.0.0
- **Minimum Android**: Android 5.0 (API 21) atau lebih tinggi
- **Target Android**: Android 14 (API 34)

## 🔐 Izin yang Dibutuhkan

Aplikasi memerlukan izin berikut:
- **Internet** - Untuk koneksi Firebase
- **Network Access** - Untuk komunikasi dengan ESP32
- **Storage** - Untuk menyimpan log dan data
- **Notification** - Untuk notifikasi alarm

## 🚀 Fitur Utama

1. **Real-time Monitoring**
   - Pantau status alarm DDS secara real-time
   - Notifikasi instan saat ada alarm aktif

2. **WiFi Management**
   - Scan dan konfigurasi WiFi ESP32
   - Monitor koneksi jaringan

3. **Database Integration**
   - Sync data ke Firebase
   - Historical data tracking

4. **Multi-device Support**
   - Bisa digunakan di multiple Android devices
   - Real-time sync antar devices

## 🐞 Troubleshooting

### Problem: Install Blocked
**Solusi**:
- Buka Settings → Apps → Special Access → Install from unknown sources
- Aktifkan untuk browser/file manager yang digunakan

### Problem: App Won't Open
**Solusi**:
- Pastikan Android version 5.0 atau lebih tinggi
- Clear cache: Settings → Apps → DDS Fire Alarm → Storage → Clear cache

### Problem: No Connection to ESP32
**Solusi**:
- Pastikan HP dan ESP32 terhubung ke WiFi yang sama
- Cek Firebase configuration di aplikasi
- Restart aplikasi dan ESP32

## 📱 Kompatibilitas

### Android Version Support
- ✅ Android 5.0 (Lollipop) - API 21
- ✅ Android 6.0 (Marshmallow) - API 23
- ✅ Android 7.0 (Nougat) - API 24
- ✅ Android 8.0 (Oreo) - API 26
- ✅ Android 9.0 (Pie) - API 28
- ✅ Android 10 (Q) - API 29
- ✅ Android 11 (R) - API 30
- ✅ Android 12 (S) - API 31
- ✅ Android 13 (Tiramisu) - API 33
- ✅ Android 14 (Upside Down Cake) - API 34

### Device Requirements
- **RAM**: Minimum 2GB (Recommended 4GB+)
- **Storage**: 100MB free space
- **Network**: WiFi atau Mobile Data

## 🔄 Update Aplikasi

Untuk update ke versi baru:
1. Download APK versi terbaru
2. Install seperti langkah di atas
3. Aplikasi akan otomatis ter-update (data tidak akan hilang)

## 📞 Support

Jika mengalami masalah:
1. Pastikan ESP32 terhubung dengan benar
2. Cek koneksi internet
3. Restart aplikasi dan device ESP32
4. Hubungi support team

---

**Catatan**: Aplikasi ini menggunakan debug signing untuk development. Untuk production, gunakan release signing dengan keystore yang proper.