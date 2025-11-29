# APK INSTALLATION GUIDE

## 📱 File APK yang Tersedia

### ✅ APK Release (Production)
- **File**: `build/app/outputs/flutter-apk/app-release.apk`
- **Size**: 52.8 MB
- **Type**: Release APK (Optimized for production)
- **Status**: ✅ READY FOR INSTALLATION

### 📋 APK Debug (Development)
- **File**: `build/app/outputs/flutter-apk/app-debug.apk`
- **Size**: ~50 MB
- **Type**: Debug APK (For testing purposes)
- **Status**: ✅ AVAILABLE

---

## 🔧 Cara Instalasi APK

### Metode 1: Instalasi Langsung via USB (Recommended)

#### Persyaratan:
- Android device dengan USB Debugging enabled
- Kabel USB
- Komputer/laptop

#### Langkah-langkah:
1. **Enable USB Debugging di Android:**
   - Buka **Settings** → **About Phone**
   - Tap **Build Number** 7 kali sampai muncul "You are now a developer!"
   - Kembali ke **Settings** → **Developer Options**
   - Enable **USB Debugging**

2. **Install APK menggunakan ADB:**
   ```bash
   # Buka command prompt/terminal di project folder
   cd "d:\01_DATA CODING DDS MOBILE\RAR\test\flutter_application_1"
   
   # Install APK Release
   adb install build/app/outputs/flutter-apk/app-release.apk
   
   # Atau install APK Debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

3. **Verifikasi Instalasi:**
   - Cek aplikasi di drawer/homescreen Android
   - Aplikasi bernama "flutter_application_1" akan muncul

### Metode 2: Transfer File & Install Manual

#### Langkah-langkah:
1. **Transfer APK ke Android:**
   - Copy file `app-release.apk` ke Android via:
     - USB cable
     - Bluetooth
     - WhatsApp/Telegram
     - Google Drive
     - Email

2. **Install APK:**
   - Buka **File Manager** di Android
   - Cari file APK yang ditransfer
   - Tap file APK
   - Allow installation from unknown sources jika diminta
   - Tap **Install**

3. **Permission Settings:**
   - Jika diminta, enable **Install from unknown sources**
   - Buka **Settings** → **Apps & Notifications** → **Special app access**
   - Enable **Install unknown apps** untuk aplikasi file manager

---

## 📋 Informasi Aplikasi

### 🎯 Fitur Utama:
- ✅ **System Reset Audio** - Play audio saat reset
- ✅ **Smart Status Detection** - Cek status sistem otomatis
- ✅ **Firebase Integration** - Real-time data sync
- ✅ **Audio Notifications** - Multiple sound alerts
- ✅ **Background Service** - Continuous monitoring
- ✅ **Local Audio Management** - Independent audio control

### 🔊 Audio Files Included:
- `system reset.mp3` - Audio saat system reset
- `system normal.mp3` - Audio saat system normal
- `alarm_clock.ogg` - Audio alarm/drill
- `beep_short.ogg` - Audio trouble beep
- Dan lainnya...

### 📱 System Requirements:
- **Android Version**: 5.0 (API Level 21) keatas
- **Storage**: Minimal 100 MB free space
- **RAM**: Minimal 2 GB recommended
- **Internet**: Required for Firebase sync

---

## 🚀 Quick Start Setelah Instalasi

### 1. First Time Setup:
1. Buka aplikasi "flutter_application_1"
2. Allow permissions yang diminta:
   - Storage/Media access
   - Notification access
   - Microphone (jika diperlukan)
3. Tunggu loading data dari Firebase
4. Login dengan kredensial yang tersedia

### 2. Test Audio System Reset:
1. Navigasi ke halaman **Control**
2. Tekan button **SYSTEM RESET**
3. Dengarkan audio `system reset.mp3`
4. Tunggu proses reset selesai
5. Jika system normal, akan terdengar audio `system normal.mp3`

---

## 🔍 Troubleshooting

### ❌ Common Issues & Solutions:

#### 1. "Install Blocked" Error:
**Solution:**
- Buka **Settings** → **Security**
- Enable **Unknown Sources**
- Atau enable **Install from unknown apps** untuk file manager

#### 2. "App Not Installed" Error:
**Solution:**
- Uninstall versi lama jika ada
- Clear cache: **Settings** → **Apps** → **Show system apps** → **Package Installer** → **Storage** → **Clear cache**
- Restart device
- Coba install ulang

#### 3. "Parse Error" / "There was a problem parsing the package":
**Solution:**
- Pastikan file APK tidak corrupt (download ulang)
- Cek free space di device
- Pastikan Android version compatible

#### 4. Audio Not Working:
**Solution:**
- Cek volume device
- Pastikan permission storage/access media diijinkan
- Test di halaman Control dengan tekan button reset

#### 5. Firebase Connection Failed:
**Solution:**
- Pastikan internet connection aktif
- Cek Firebase configuration di project
- Restart aplikasi

---

## 📞 Support & Contact

### 🐛 Bug Reports:
- Screenshot error
- Logcat output (jika tersedia)
- Device information (Android version, model)
- Steps to reproduce

### 📧 Technical Support:
- Document issues dengan detail
- Sertakan screenshot/screen recording
- Berikan device spec yang digunakan

---

## 📝 Additional Notes

### 🔐 Security:
- APK release sudah signed dan optimized
- Tidak ada debug code di production build
- Firebase configuration secured

### 📦 File Size:
- APK Release: 52.8 MB (compressed)
- Setelah install: ~80-100 MB
- Audio assets: ~10 MB

### 🔄 Updates:
- Untuk update versi baru:
  1. Download APK baru
  2. Install (otomatis replace versi lama)
  3. Data user akan preserved

---

## ✅ Installation Checklist

### Sebelum Install:
- [ ] Android device dengan minimal 100 MB free space
- [ ] Internet connection aktif
- [ ] USB Debugging enabled (untuk install via ADB)
- [ ] Backup data penting (optional)

### Setelah Install:
- [ ] Aplikasi muncul di app drawer
- [ ] Buka aplikasi berhasil
- [ ] Login berhasil
- [ ] Firebase connection aktif
- [ ] Audio system reset berfungsi
- [ ] Notifikasi berfungsi

---

**Status APK: ✅ READY FOR DISTRIBUTION**
**Build Date:** 15 Oktober 2025
**Version:** 1.0.0+1
**Features:** System Reset Audio Implementation Complete
