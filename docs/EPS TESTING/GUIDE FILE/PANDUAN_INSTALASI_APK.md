# PANDUAN INSTALASI APLIKASI DDS MOBILE

## 📱 File APK yang Tersedia

Aplikasi DDS Mobile telah berhasil dibuild dengan file-file berikut:

### 🎯 APK Release (Disarankan untuk Instalasi)
- **File**: `app-release.apk`
- **Ukuran**: 51.6 MB
- **Lokasi**: `build/app/outputs/flutter-apk/app-release.apk`
- **Status**: ✅ Siap diinstal

### 🛠️ APK Debug (Untuk Development)
- **File**: `app-debug.apk`
- **Lokasi**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Status**: ✅ Siap diinstal

---

## 📋 Cara Instalasi APK di Android

### Metode 1: Instalasi Langsung dari Komputer

1. **Hubungkan HP Android ke Komputer**
   - Gunakan kabel USB
   - Pastikan mode "File Transfer" atau "MTP" aktif

2. **Salin File APK**
   - Buka File Explorer di komputer
   - Navigasi ke folder: `D:\01_DATA CODING DDS MOBILE\RAR\test\flutter_application_1\build\app\outputs\flutter-apk\`
   - Salin file `app-release.apk`

3. **Paste di HP Android**
   - Buka folder "Download" atau "Documents" di HP
   - Paste file APK tersebut

4. **Instal Aplikasi**
   - Buka File Manager di HP
   - Cari file `app-release.apk`
   - Tap untuk mulai instalasi
   - Ikuti petunjuk di layar

### Metode 2: Instalasi via ADB (Untuk Developer)

1. **Pastikan ADB terinstall**
   ```bash
   adb devices
   ```

2. **Instal via ADB**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## ⚠️ Penting! Izin Instalasi

### Untuk Android 8.0+ (Oreo ke atas):
1. **Allow Unknown Sources**
   - Buka `Settings` → `Apps & notifications` → `Special app access`
   - Pilih `Install unknown apps`
   - Cari aplikasi File Manager yang digunakan
   - Aktifkan `Allow from this source`

### Untuk Android 11+:
1. **Install from this source**
   - Saat proses instalasi, Android akan meminta izin
   - Pilih `Allow from this source` untuk File Manager

---

## 🔐 Fitur Keamanan yang Diperlukan

Aplikasi ini memerlukan izin berikut:

### ✅ Izin Standar:
- **Internet**: Untuk koneksi Firebase
- **Network State**: Memeriksa status koneksi
- **Notifications**: Menampilkan notifikasi fire alarm

### ✅ Izin Khusus:
- **POST_NOTIFICATIONS**: Notifikasi Android 13+
- **FOREGROUND_SERVICE**: Layanan background
- **WAKE_LOCK**: Menjaga layar tetap aktif saat alarm
- **VIBRATE**: Getaran saat alarm
- **SYSTEM_ALERT_WINDOW**: Tampilan di atas aplikasi lain
- **RECEIVE_BOOT_COMPLETED**: Auto-start saat HP dinyalakan
- **MODIFY_AUDIO_SETTINGS**: Kontrol volume suara alarm

---

## 🚀 Setelah Instalasi

### Langkah 1: Buka Aplikasi
- Cari icon "DDS MOBILE" di homescreen
- Tap untuk membuka aplikasi

### Langkah 2: Login Pertama
- Gunakan email dan password yang terdaftar
- Atau daftar akun baru jika belum ada

### Langkah 3: Berikan Izin
- Saat diminta, berikan semua izin yang diperlukan
- Penting: Izinkan notifikasi agar alarm berfungsi

### Langkah 4: Test Notifikasi
- Buka menu Settings
- Test notifikasi untuk memastikan berfungsi

---

## 🐞 Troubleshooting

### Masalah: "Instalasi Gagal"
**Solusi:**
- Pastikan ruang penyimpanan cukup
- Hapus versi lama jika ada
- Restart HP dan coba lagi

### Masalah: "Aplikasi tidak terpasang"
**Solusi:**
- Cek versi Android minimal 5.0 (Lollipop)
- Aktifkan "Install unknown apps"
- Gunakan APK release (bukan debug)

### Masalah: "Notifikasi tidak muncul"
**Solusi:**
- Buka Settings → Apps → DDS MOBILE
- Aktifkan semua izin notifikasi
- Cek pengaturan Do Not Disturb

---

## 📞 Support

Jika mengalami masalah:
1. **Cek dokumentasi** di folder project
2. **Restart HP** dan coba instalasi ulang
3. **Hubungi developer** untuk bantuan teknis

---

## ✅ Checklist Instalasi

- [ ] Download/copy file APK
- [ ] Aktifkan izin instalasi dari sumber tidak dikenal
- [ ] Instal aplikasi
- [ ] Buka aplikasi
- [ ] Login/daftar akun
- [ ] Berikan semua izin yang diminta
- [ ] Test notifikasi
- [ ] Selesai! Aplikasi siap digunakan

---

**🎉 Selamat menggunakan DDS Mobile!**
*Aplikasi monitoring dan notifikasi Fire Alarm yang andal*
