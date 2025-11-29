# PANDUAN INSTALASI APLIKASI ANDROID LENGKAP

## 📱 INFORMASI APK

**File APK berhasil dibuat:**
- 📁 Lokasi: `build/app/outputs/flutter-apk/app-release.apk`
- 📏 Ukuran: 51.8 MB
- 🏷️ Tipe: Release (Produksi)

## 🚀 CARA INSTALASI DI ANDROID

### Metode 1: Instalasi Langsung via USB

1. **Hubungkan HP Android ke PC**
   - Gunakan kabel USB
   - Pilih mode "File Transfer" atau "MTP" di HP

2. **Salin file APK ke HP**
   ```
   Salin file: build/app/outputs/flutter-apk/app-release.apk
   Ke folder: Download di HP Android
   ```

3. **Instal dari HP**
   - Buka File Manager di HP
   - Cari folder Download
   - Klik file `app-release.apk`
   - Ikuti proses instalasi

### Metode 2: Instalasi via ADB (Untuk Developer)

1. **Aktifkan USB Debugging di HP**
   - Buka Settings → About Phone
   - Tap 7x pada "Build Number" untuk aktifkan Developer Options
   - Buka Developer Options → Aktifkan "USB Debugging"

2. **Install via command line**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

### Metode 3: Instalasi via Email/Cloud

1. **Upload APK ke cloud**
   - Upload file `app-release.apk` ke Google Drive, Dropbox, atau Email

2. **Download dan install di HP**
   - Buka link di HP Android
   - Download file APK
   - Install seperti biasa

## ⚙️ SETTING YANG DIBUTUHKAN

### 1. Izin Install Aplikasi Sumber Tidak Dikenal
- Buka Settings → Security & Privacy
- Aktifkan "Install from Unknown Sources" atau "Allow from this source"
- Pilih File Manager atau Browser yang digunakan untuk download

### 2. Izin Aplikasi (Setelah Install)
Aplikasi ini membutuhkan izin:
- ✅ **Notifikasi** - Untuk alarm dan notifikasi sistem
- ✅ **Audio** - Untuk播放 suara alarm
- ✅ **Storage** - Untuk menyimpan data dan konfigurasi
- ✅ **Network** - Untuk koneksi Firebase dan ESP32
- ✅ **Background** - Untuk notifikasi background

## 🔧 KONFIGURASI AWAL APLIKASI

### 1. Firebase Configuration
- Pastikan device terhubung internet
- Aplikasi akan otomatis connect ke Firebase
- Cek koneksi di menu Settings

### 2. ESP32 Connection
- Pastikan ESP32 dalam mode AP/STA
- Scan WiFi ESP32 dari aplikasi
- Input password jika diperlukan

### 3. Notifikasi & Audio
- Test notifikasi di menu Settings
- Pastikan volume media aktif
- Test suara alarm

## 🐞 TROUBLESHOOTING

### Masalah Umum:

**1. "Install Blocked"**
- Settings → Security → Allow Unknown Sources
- Atau Settings → Apps & Notifications → Special Access → Install Unknown Apps

**2. "App Not Installed"**
- Hapus versi lama jika ada
- Pastikan cukup storage
- Restart HP dan coba lagi

**3. "App Crashes"**
- Berikan semua izin yang diminta
- Pastikan Android versi 5.0+ (API 21)
- Clear cache aplikasi

**4. "No Notifications"**
- Settings → Apps → [Aplikasi] → Notifications → Allow
- Settings → Battery → [Aplikasi] → No optimization
- Pastikan Do Not Disturb mati

**5. "No Sound"**
- Pastikan volume media aktif
- Settings → Apps → [Aplikasi] → Permissions → Microphone/Storage
- Test dengan headphone

## 📋 SPESIFIKASI MINIMAL

### Android Requirements:
- ✅ Android 5.0 (API Level 21) atau lebih tinggi
- ✅ RAM minimal 2GB direkomendasikan
- ✅ Storage minimal 100MB tersedia
- ✅ Koneksi Internet (WiFi/Mobile Data)

### Hardware Requirements:
- ✅ Speaker untuk audio alarm
- ✅ WiFi untuk koneksi ESP32
- ✅ Notifikasi support

## 🎯 FITUR YANG TERSEDIAL

### ✅ Fitur Utama:
- 🔥 **Fire Alarm Monitoring** - Real-time monitoring sistem alarm kebakaran
- 📱 **Push Notifications** - Notifikasi instant untuk semua status
- 🔊 **Audio Alerts** - Suara alarm untuk berbagai kondisi
- 📊 **Data History** - Riwayat status dan peristiwa
- ⚙️ **Settings Management** - Konfigurasi zona dan pengaturan

### ✅ Fitur Background:
- 🔄 **Background Service** - Monitoring berjalan di background
- 🔔 **Lock Screen Notifications** - Notifikasi muncul di lock screen
- 🎵 **Local Audio** - Audio system tanpa perlu internet
- 📡 **Auto Reconnect** - Otomatis reconnect ke ESP32

## 📞 SUPPORT

Jika mengalami masalah:
1. Cek troubleshooting di atas
2. Pastikan semua izin diberikan
3. Restart aplikasi dan device
4. Hubungi developer untuk bantuan teknis

---

**🎉 Selamat Menggunakan!**

Aplikasi Fire Alarm Monitoring System Anda siap digunakan. Pastikan untuk melakukan test semua fitur untuk memastikan semuanya berfungsi dengan baik.
