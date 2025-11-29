# PANDUAN INSTALASI APLIKASI FIRE ALARM MONITORING UNTUK ANDROID

## Informasi APK
- **Nama File**: app-release.apk
- **Ukuran**: ~50 MB
- **Lokasi File**: `flutter_application_1/build/app/outputs/apk/release/app-release.apk`
- **Tanggal Build**: 10 Januari 2025

## Persyaratan Sistem
- Android 5.0 (API level 21) atau lebih tinggi
- Ruang penyimpanan minimal 100 MB
- Koneksi internet untuk fitur Firebase

## Cara Instalasi

### Metode 1: Transfer Langsung ke HP Android

1. **Salin File APK**
   - Hubungkan HP Android ke komputer menggunakan kabel USB
   - Salin file `app-release.apk` dari folder:
     ```
     D:\dds\DDS SOFTAWRE\02_PHONE\FILE CODE\test\flutter_application_1\build\app\outputs\apk\release\
     ```
   - Tempel ke folder Download di HP Android Anda

2. **Aktifkan Instalasi dari Sumber Tidak Dikenal**
   - Buka **Pengaturan** → **Keamanan**
   - Aktifkan **Sumber Tidak Dikenal** atau **Install unknown apps**
   - Pada Android 8.0+: Berikan izin untuk aplikasi File Manager

3. **Install APK**
   - Buka File Manager di HP Android
   - Navigasi ke folder Download
   - Tap file `app-release.apk`
   - Tap **Install**
   - Tunggu proses instalasi selesai
   - Tap **Open** untuk membuka aplikasi

### Metode 2: Transfer via WhatsApp/Email

1. **Kirim File APK**
   - Kirim file `app-release.apk` melalui WhatsApp atau Email
   - Buka pesan di HP Android target

2. **Download dan Install**
   - Download file APK dari pesan
   - Tap file yang sudah didownload
   - Ikuti langkah instalasi seperti Metode 1

### Metode 3: Upload ke Google Drive

1. **Upload ke Google Drive**
   - Upload file `app-release.apk` ke Google Drive
   - Share link dengan akun yang bisa diakses dari HP Android

2. **Download dari Google Drive**
   - Buka Google Drive di HP Android
   - Download file APK
   - Install seperti langkah di Metode 1

## Konfigurasi Setelah Instalasi

1. **Buka Aplikasi**
   - Cari ikon "Fire Alarm" di menu aplikasi
   - Tap untuk membuka

2. **Login/Register**
   - Gunakan email dan password untuk login
   - Atau buat akun baru dengan Register

3. **Izin Aplikasi**
   - Berikan izin yang diperlukan:
     - Internet: untuk koneksi Firebase
     - Notifikasi: untuk menerima alert

## Troubleshooting

### Masalah: "App not installed"
**Solusi:**
- Pastikan versi Android minimal 5.0
- Hapus versi lama aplikasi jika ada
- Pastikan ruang penyimpanan cukup
- Restart HP dan coba install ulang

### Masalah: "Parse error"
**Solusi:**
- File APK mungkin corrupt, build ulang dengan:
  ```
  flutter build apk --release
  ```

### Masalah: Tidak bisa login
**Solusi:**
- Pastikan koneksi internet aktif
- Cek konfigurasi Firebase
- Pastikan email dan password benar

## Build APK Baru (Untuk Developer)

Jika perlu build ulang APK:

```bash
# Masuk ke folder project
cd flutter_application_1

# Clean build sebelumnya
flutter clean

# Get dependencies
flutter pub get

# Build APK release
flutter build apk --release

# APK akan tersedia di:
# build/app/outputs/apk/release/app-release.apk
```

## Build App Bundle (Untuk Upload ke Play Store)

```bash
# Build App Bundle
flutter build appbundle --release

# File akan tersedia di:
# build/app/outputs/bundle/release/app-release.aab
```

## Informasi Tambahan

- **Package Name**: com.example.flutter_application_1
- **Version**: 1.0.0+1
- **Min SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)

## Kontak Support

Jika ada masalah saat instalasi, hubungi:
- Tim Developer DDS Fire Alarm System
- Email: support@dds-firealarm.com
- WhatsApp: 6281295865655

---
© 2025 DDS Fire Alarm Monitoring System
