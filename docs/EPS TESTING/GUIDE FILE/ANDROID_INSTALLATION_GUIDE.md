# Fire Alarm Monitoring - Android Installation Guide

## 📱 File Informasi

### APK untuk Direct Install
- **Nama File**: `FireAlarm_Monitoring_v1.0_Release.apk`
- **Ukuran**: 58 MB
- **Tipe**: Android Package (APK)
- **Penggunaan**: Direct install/manual distribution

### AAB untuk Play Store
- **Nama File**: `FireAlarm_Monitoring_v1.0_PlayStore.aab`
- **Ukuran**: 49 MB
- **Tipe**: Android App Bundle (AAB)
- **Penggunaan**: Google Play Store upload

### System Requirements
- **Versi**: 1.0 (Release)
- **Build Date**: 26 Oktober 2025
- **Minimum Android**: Android 5.0 (API Level 21) atau lebih tinggi
- **Architecture**: ARM, ARM64, x86, x86_64 (universal)

## 🔧 Cara Instalasi

### Metode 1: Transfer Langsung ke Android

1. **Download/Transfer APK**
   - Salin file `FireAlarm_Monitoring_v1.0_Release.apk` ke perangkat Android
   - Bisa melalui USB, email, cloud storage, atau transfer file apps

2. **Enable Unknown Sources**
   - Buka **Settings** → **Security** → **Unknown Sources** (enable)
   - Untuk Android 8+: Buka **Settings** → **Apps & Notifications** → **Special Access** → **Install Unknown Apps**

3. **Install APK**
   - Buka file APK dari File Manager atau Downloads
   - Klik **Install**
   - Ikuti instruksi hingga selesai

4. **Launch App**
   - Cari icon **Fire Alarm Monitoring** di home screen
   - Buka aplikasi untuk memulai monitoring

### Metode 2: Google Play Store (Production)

**Untuk distribusi via Google Play Store:**

1. **Upload App Bundle**
   - Buka [Google Play Console](https://play.google.com/console)
   - Buat aplikasi baru atau edit existing
   - Upload file `FireAlarm_Monitoring_v1.0_PlayStore.aab`

2. **Play Store Requirements**
   - Complete app store listing
   - Add screenshots and app icon
   - Set content rating and privacy policy
   - Configure pricing and distribution

3. **Release Management**
   - Internal testing → Closed testing → Open testing → Production release
   - App Bundle akan otomatis generate APK untuk setiap device architecture

### Metode 3: ADB Install (untuk developer)

```bash
# Connect device via USB
adb devices

# Install APK
adb install FireAlarm_Monitoring_v1.0_Release.apk

# Launch app (optional)
adb shell am start -n com.example.flutter_application_1/com.example.flutter_application_1.MainActivity
```

## 🚀 Setup Awal Aplikasi

### Firebase Configuration
Aplikasi ini terhubung ke Firebase Realtime Database:
- **Database URL**: `https://testing1do-default-rtdb.asia-southeast1.firebasedatabase.app`
- **Real-time Data**: Monitor zona alarm dan trouble status secara real-time

### Permissions Required
- **Internet Access**: Untuk koneksi Firebase
- **Network Access**: Untuk update data real-time
- **Notifications**: Untuk alert system (opsional)

### Fitur Utama
- ✅ **Real-time Monitoring**: 63 devices dengan 5 zones per device
- ✅ **System Status**: Alarm, Trouble, Drill, Silenced status monitoring
- ✅ **Firebase Integration**: Otomatis sync dengan `all_slave_data`
- ✅ **Enhanced Parser**: Parsing data hex AABBCC yang akurat
- ✅ **SystemStatusData**: Single source of truth untuk status sistem
- ✅ **Priority Hierarchy**: Alarm > Trouble > Normal

## 📊 Technical Details

### Data Flow
1. **Firebase** (`all_slave_data/raw_data`) →
2. **Enhanced Zone Parser** →
3. **SystemStatusExtractor** →
4. **UI Update** (Real-time)

### Status Indicators
- 🔴 **ALARM**: Zona aktif alarm (prioritas tertinggi)
- 🟡 **TROUBLE**: Zona mengalami trouble
- 🔵 **NORMAL**: Semua zona normal
- ⚪ **DISABLED**: Device tidak terhubung

### Troubleshooting

#### Issue: Tidak Ada Data
- Pastikan koneksi internet stabil
- Cek Firebase configuration
- Verify `all_slave_data` path di database

#### Issue: Install Failed
- Pastikan **Unknown Sources** enabled
- Clear cache sebelum install ulang
- Restart device jika perlu

#### Issue: App Crash
- Pastikan Android version compatible (5.0+)
- Check available storage (minimal 100MB free)
- Report bugs dengan logcat output

## 🔒 Security Notes
- APK ini telah di-sign dengan debug key untuk development
- Untuk production, gunakan release signing key
- Firebase menggunakan aturan security yang telah dikonfigurasi

## 📞 Support
Jika mengalami masalah:
1. Cek troubleshooting section
2. Pastikan device compatible
3. Verify koneksi internet
4. Contact development team dengan device info dan error log

---
**Version**: 1.0
**Build Date**: 2025-10-26
**Platform**: Android (ARM/x86)
**Framework**: Flutter 3.35.6