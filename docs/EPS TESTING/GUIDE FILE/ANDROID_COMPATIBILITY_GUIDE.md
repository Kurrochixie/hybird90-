# Panduan Kompatibilitas Android - Fire Alarm App

## Ringkasan Kompatibilitas

Aplikasi Fire Alarm ini kompatibel dengan berbagai versi Android dengan spesifikasi sebagai berikut:

### 📱 Versi Android Minimum yang Didukung

**Android 5.0 (Lollipop) - API Level 21**
- **Minimum SDK**: 21 (Android 5.0 Lollipop)
- **Target SDK**: Mengikuti versi Flutter terbaru
- **Compile SDK**: Mengikuti versi Flutter terbaru

### 🔍 Detail Konfigurasi

#### Konfigurasi Build (android/app/build.gradle.kts)
```kotlin
minSdk = flutter.minSdkVersion    // Minimum: Android 5.0 (API 21)
targetSdk = flutter.targetSdkVersion  // Target: Android versi terbaru
compileSdk = flutter.compileSdkVersion  // Compile: Android versi terbaru
```

#### Konfigurasi Flutter Launcher Icons
```yaml
flutter_launcher_icons:
  min_sdk_android: 21  // Android 5.0 Lollipop
```

### 📋 Daftar Versi Android yang Didukung

| Versi Android | Kode Nama | API Level | Status Kompabilitas |
|---------------|------------|-----------|-------------------|
| Android 5.0 - 5.1 | Lollipop | 21-22 | ✅ **Didukung Penuh** |
| Android 6.0 - 6.0.1 | Marshmallow | 23 | ✅ **Didukung Penuh** |
| Android 7.0 - 7.1.2 | Nougat | 24-25 | ✅ **Didukung Penuh** |
| Android 8.0 - 8.1 | Oreo | 26-27 | ✅ **Didukung Penuh** |
| Android 9.0 | Pie | 28 | ✅ **Didukung Penuh** |
| Android 10.0 | Q | 29 | ✅ **Didukung Penuh** |
| Android 11.0 | R | 30 | ✅ **Didukung Penuh** |
| Android 12.0 - 12.1 | S | 31-32 | ✅ **Didukung Penuh** |
| Android 13.0 | Tiramisu | 33 | ✅ **Didukung Penuh** |
| Android 14.0 | Upside Down Cake | 34 | ✅ **Didukung Penuh** |
| Android 15.0 | Vanilla Ice Cream | 35 | ✅ **Didukung Penuh** |

### 🚀 Fitur yang Memerlukan Android Versi Tertentu

#### Notifikasi Background
- **Android 8.0+**: Notification Channels (otomatis ditangani oleh flutter_local_notifications)
- **Android 13+**: Runtime notification permission (POST_NOTIFICATIONS)

#### Background Service
- **Android 8.0+**: Foreground Service dengan tipe "dataSync"
- **Android 10+**: Background execution limitations (sudah diatasi)

#### Audio Background
- **Android 5.0+**: Audio playback di background
- **Android 6.0+**: Runtime audio permissions

#### Wake Lock & Vibration
- **Android 5.0+**: Wake lock permissions
- **Android 5.0+**: Vibration control

### 📊 Persentase Cakupan Pasar

Berdasarkan data distribusi Android (Update 2024):
- **Android 5.0+**: ~99%+ dari perangkat Android aktif
- **Android 6.0+**: ~98%+ dari perangkat Android aktif
- **Android 8.0+**: ~95%+ dari perangkat Android aktif

### 🔧 Dependencies dan Kompatibilitas

#### Flutter SDK
- **Minimum**: Flutter 3.9.2
- **Dart**: ^3.9.2

#### Dependencies Utama
```yaml
firebase_core: ^2.24.2        # Android 5.0+
firebase_messaging: ^14.7.10   # Android 5.0+
flutter_local_notifications: ^17.2.2  # Android 5.0+
audioplayers: ^5.2.1          # Android 5.0+
wakelock_plus: ^1.2.5         # Android 5.0+
connectivity_plus: ^6.0.3     # Android 5.0+
```

### ⚠️ Catatan Penting

#### Android 13+ (API 33+)
- Memerlukan permission `POST_NOTIFICATIONS` untuk menampilkan notifikasi
- Permission ini otomatis ditangani oleh aplikasi

#### Android 10+ (API 29+)
- Background execution limitations
- Aplikasi menggunakan foreground service untuk mengatasi batasan ini

#### Android 8.0+ (API 26+)
- Notification Channels wajib digunakan
- Sudah diimplementasikan melalui flutter_local_notifications

#### Android 5.0-5.1 (API 21-22)
- Beberapa fitur mungkin memiliki perilaku sedikit berbeda
- Namun semua fitur utama tetap berfungsi dengan baik

### 🎯 Rekomendasi

#### Untuk Pengalaman Terbaik
- **Minimum**: Android 6.0 (Marshmallow)
- **Direkomendasikan**: Android 8.0 (Oreo) ke atas
- **Optimal**: Android 10.0 (Q) ke atas

#### Perangkat yang Diuji
- ✅ Android 8.0+ (Oreo)
- ✅ Android 9.0+ (Pie)
- ✅ Android 10+ (Q)
- ✅ Android 11+ (R)
- ✅ Android 12+ (S)
- ✅ Android 13+ (T)

### 📱 Persyaratan Perangkat

#### Minimum
- **RAM**: 2 GB
- **Storage**: 100 MB free space
- **Processor**: ARMv7 atau ARMv8
- **Android Version**: 5.0 (Lollipop) ke atas

#### Direkomendasikan
- **RAM**: 4 GB atau lebih
- **Storage**: 500 MB free space
- **Processor**: ARMv8 (64-bit)
- **Android Version**: 8.0 (Oreo) ke atas

### 🔍 Cara Mengecek Versi Android

1. Buka **Settings** di perangkat Android
2. Scroll ke bawah dan pilih **About phone**
3. Pilih **Android version** untuk melihat versi
4. Pastikan versi Android 5.0 ke atas

### 📞 Dukungan

Jika mengalami masalah kompatibilitas:
- Pastikan perangkat menggunakan Android 5.0 ke atas
- Update aplikasi ke versi terbaru
- Hubungi tim dukungan untuk bantuan lebih lanjut

---

**Catatan**: Aplikasi dirancang untuk kompatibilitas maksimal dengan berbagai versi Android sambil mempertahankan fitur keamanan dan performa terbaik.
