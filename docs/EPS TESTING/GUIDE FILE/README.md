# Flutter Fire Alarm Monitoring System

## 📋 Deskripsi
Aplikasi monitoring sistem alarm kebakaran (fire alarm) berbasis Flutter yang terintegrasi dengan perangkat ESP32 untuk monitoring real-time status zona, alarm, dan trouble. Aplikasi ini menampilkan status sistem secara visual dengan deteksi NO DATA yang ditingkatkankan.

## 🚀 Fitur Utama

### Status Bar Terpusat
- **Unified Status Bar**: Status bar konsisten di semua halaman
- **NO DATA Detection**: Menampilkan "NO DATA" ketika tidak ada data valid dari ESP32
- **Real-time Updates**: Status diperbarui secara real-time berdasarkan data Firebase
- **Responsive Design**: Menyesuaikan dengan ukuran layar berbagai perangkat

### Monitoring Zona
- **ESP32 Integration**: Terintegrasi dengan perangkat ESP32 untuk monitoring zona
- **Zone Status**: Menampilkan status setiap zona (Normal, Alarm, Trouble)
- **Bell Trouble Detection**: Deteksi masalah bell/kontak
- **Module Management**: Mendukung hingga 63 modul dengan 5 zona per modul

### Sistem Status
- **System Status**: Menampilkan status sistem (Normal, Alarm, Trouble, Drill, dll)
- **Firebase Integration**: Sinkronisasi data dengan Firebase Realtime Database
- **LED Status Decoder**: Mendekode status LED dari perangkat panel
- **Notification System**: Sistem notifikasi push dan lokal

### User Interface
- **Tab Navigation**: Navigasi tab yang responsif
- **Recent Status**: Menampilkan status aktivitas terkini
- **Date Filtering**: Filter status berdasarkan tanggal
- **Control Panel**: Panel kontrol untuk sistem reset dan operasi lainnya

## 📱 Persyaratan Sistem

### Minimum Requirements
- **Android**: Android 5.0 (API Level 21) atau lebih tinggi
- **RAM**: Minimum 2 GB RAM
- **Storage**: Minimum 100 MB ruang penyimpanan
- **Internet**: Koneksi internet untuk Firebase synchronization

### Recommended Requirements
- **Android**: Android 7.0 (API Level 24) atau lebih tinggi
- **RAM**: 4 GB RAM atau lebih
- **Storage**: 500 MB ruang penyimpanan atau lebih
- **Processor**: ARM64 atau x86_64 processor
- **Display**: Resolusi minimum 720p

## 🛠️ Instalasi APK

### Metode 1: Instalasi Langsung (Windows)
1. **Download APK**: Unduh file APK dari link yang disediakan
2. **Enable Unknown Sources**: Buka Settings → Security → Enable "Unknown sources"
3. **Install APK**: Tap file APK yang telah diunduh dan ikuti instruksi
4. **Grant Permissions**: Berikan izin yang diperlukan saat instalasi

### Metode 2: Instalasi via ADB (Development)
1. **Download Script**: Gunakan script build yang disediakan
2. **Build APK**: Jalankan `build_apk.bat build-all` (Windows) atau `./build_apk.sh build-all` (Linux/Mac)
3. **Install via ADB**: `adb install build/app/outputs/flutter-apk/app-release.apk`

### Metode 3: Instalasi via Google Play Store (Coming Soon)
1. **Open Play Store**: Buka Google Play Store
2. **Search App**: Cari "Flutter Fire Alarm Monitoring"
3. **Install**: Tap "Install" dan tunggu hingga selesai

## 📖 Panduan Penggunaan

### Setup Awal
1. **Login**: Masuk dengan kredensial yang telah terdaftar
2. **Firebase Connection**: Pastikan aplikasi terhubung ke Firebase
3. **ESP32 Setup**: Konfigurasikan perangkat ESP32 untuk mengirim data ke Firebase

### Monitoring Status
1. **View Status Bar**: Lihat status sistem di bagian atas setiap halaman
2. **Check Zone Status**: Navigasi ke halaman Monitoring untuk detail status zona
3. **Real-time Updates**: Status akan diperbarui otomatis saat ESP32 mengirim data

### Kontrol Sistem
1. **System Reset**: Gunakan tombol reset untuk mereset sistem
2. **Alarm Control**: Kontrol alarm dan notifikasi
3. **Troubleshoot**: Gunakan halaman ESP32 Data untuk troubleshooting

## 🔧 Konfigurasi

### Firebase Configuration
1. **Create Firebase Project**: Buat project baru di Firebase Console
2. **Enable Services**: Aktifkan Realtime Database, Authentication, Cloud Messaging
3. **Download Config**: Unduh `google-services.json` dan letakkan di `android/app/`
4. **Security Rules**: Konfigurasikan aturan keamanan database

### ESP32 Configuration
1. **Hardware Setup**: Hubungkan ESP32 dengan panel alarm
2. **WiFi Configuration**: Konfigurasikan WiFi ESP32
3. **Firebase Integration**: Integrasikan ESP32 dengan Firebase Realtime Database
4. **Data Format**: Pastikan format data sesuai dengan spesifikasi

## 📊 Data Flow

### ESP32 → Firebase → App
```
ESP32 Device → WiFi → Firebase Realtime Database → Flutter App
```

### Status Detection Flow
```
1. ESP32 mengirim data zona ke Firebase
2. ESP32ZoneParser memvalidasi data
3. FireAlarmData memproses status
4. UnifiedStatusBar menampilkan status
```

### NO DATA Detection
```
1. Tidak ada data dari ESP32 → "NO DATA"
2. Data tidak valid/garbage → "NO DATA"
3. Data valid → Status normal (Normal/Alarm/Trouble)
```

## 🐛 Troubleshooting

### Masalah Umum

#### 1. Status "NO DATA" Terus-menerus
**Solusi**:
- Periksa koneksi ESP32 ke Firebase
- Validasi format data yang dikirim ESP32
- Pastikan path Firebase `esp32_bridge/data/parsed_packet` ada

#### 2. Aplikasi Crash
**Solusi**:
- Pastikan Android versi 5.0 atau lebih tinggi
- Periksa ruang penyimpanan yang tersedia
- Hapus cache aplikasi dan coba lagi

#### 3. Tidak Ada Notifikasi
**Solusi**:
- Periksa izin notifikasi di pengaturan perangkat
- Pastikan FCM dikonfigurasi dengan benar
- Verifikasi konektivitas internet

#### 4. Sinkronisasi Data Lambat
**Solusi**:
- Periksa koneksi internet stabil
- Validasi konfigurasi Firebase
- Restart aplikasi dan ESP32

### Debug Mode
Untuk debugging, gunakan build debug:
```bash
# Windows
build_apk.bat build-debug

# Linux/Mac
./build_apk.sh build-debug
```

## 📱 Screen Shots

### Status Bar
- **Normal Status**: Status hijau dengan teks "SYSTEM NORMAL"
- **No Data Status**: Status abu-abu dengan teks "NO DATA"
- **Alarm Status**: Status merah dengan teks "SYSTEM ALARM"

### Monitoring Page
- **Zone Grid**: Grid zona dengan status visual
- **Module Information**: Informasi modul dan zona
- **Real-time Updates**: Perbaruan status real-time

### Control Page
- **System Controls**: Tombol kontrol sistem
- **Status Indicators**: Indikator status visual
- **Operation Feedback**: Feedback untuk setiap operasi

## 🔒 Keamanan

### Data Security
- **HTTPS Communication**: Semua komunikasi menggunakan HTTPS
- **Firebase Security**: Aturan keamanan Firebase yang ketat
- **Local Data**: Data sensitif disimpan secara lokal dan terenkripsi

### Privacy
- **No Personal Data Collection**: Aplikasi tidak mengumpulkan data pribadi
- **Anonymous Usage**: Penggunaan aplikasi tidak dilacak
- **Data Minimization**: Minimalisasi data yang dikirim ke server

## 🔄 Pembaruan dan Pemeliharaan

### Update Aplikasi
- **Auto-update**: Aplikasi akan memberitahu jika ada update tersedia
- **Version Management**: Sistem manajemen versi yang jelas
- **Backward Compatibility**: Kompatibilitas dengan versi sebelumnya

### Firebase Sync
- **Real-time Sync**: Sinkronisasi data real-time
- **Offline Support**: Mendukung mode offline dengan cache lokal
- **Conflict Resolution**: Resolusi konflik data otomatis

## 📞 Dukungan Teknis

### Dokumentasi
- **User Guide**: Panduan pengguna lengkap
- **API Documentation**: Dokumentasi API untuk integrasi
- **Troubleshooting Guide**: Panduan troubleshooting umum

### Support Channels
- **Email**: dukungan@firealarm-monitoring.com
- **Documentation**: Wiki dan FAQ online
- **Community**: Forum diskusi pengguna

## 📄 Lisensi

### Open Source Components
- **Flutter Framework**: BSD 3-Clause License
- **Firebase**: Google Terms of Service
- **Various Libraries**: Sesuai dengan lisensi masing-masing

### Proprietary Code
- **Application Code**: Hak cipta milik DDS Fire Alarm Monitoring
- **Custom Implementations**: Implementasi kustom proprietary

## 🤝 Kontribusi

### Bug Reports
- **GitHub Issues**: Laporkan bug melalui GitHub Issues
- **Crash Reports**: Gunakan crash reporting dalam aplikasi
- **Feedback**: Berikan feedback melalui channel yang tersedia

### Feature Requests
- **Feature Request**: Ajukan fitur baru melalui GitHub Issues
- **Discussions**: Diskusikan ide fitur di forum komunitas
- **Pull Requests**: Kontribusi kode melalui GitHub Pull Request

## 📝 Changelog

### Version 1.0.0 (2025-10-16)
#### New Features
- ✅ Unified status bar implementation
- ✅ Enhanced NO DATA detection
- ✅ Real-time ESP32 zone monitoring
- ✅ Responsive design improvements
- ✅ Firebase integration
- ✅ Notification system
- ✅ Control panel functionality

#### Bug Fixes
- ✅ Fixed inconsistent status bar across pages
- ✅ Resolved default status behavior issues
- ✅ Improved data validation logic
- ✅ Enhanced error handling

#### Improvements
- ✅ Enhanced user interface consistency
- ✅ Optimized performance
- ✅ Improved error handling
- ✅ Better documentation

---

**Versi Saat Ini**: 1.0.0  
**Tanggal Rilis**: 16 Oktober 2025  
**Status**: ✅ Production Ready  
**Platform**: Android 5.0+  
**Framework**: Flutter 3.0+

---

## 📞 Tentang Pengembang

**Developer**: DDS Fire Alarm Monitoring Team  
**Contact**: dev@firealarm-monitoring.com  
**Website**: www.firealarm-monitoring.com  
**GitHub**: github.com/firealarm-monitoring/flutter-app

---

*Terima kasih telah menggunakan aplikasi Flutter Fire Alarm Monitoring System. Untuk dukungan teknis, silakan hubungi tim pengembang kami.*
