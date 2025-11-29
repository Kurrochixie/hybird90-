# Analisis Alur Aplikasi Fire Alarm Monitoring

Dokumen ini menjelaskan alur kerja dan struktur utama dari aplikasi Flutter `flutter_application_1`.

## 1. Titik Masuk Aplikasi (Entry Point)

- **File Utama**: Berdasarkan konfigurasi proyek (`.idea/runConfigurations/main_dart.xml`), file utama yang dijalankan adalah `lib/main.dart`.
- **Inisialisasi**: Fungsi `main()` di dalam `lib/main.dart` melakukan beberapa proses penting sebelum aplikasi ditampilkan:
  - `WidgetsFlutterBinding.ensureInitialized()`: Memastikan semua binding Flutter siap.
  - `Firebase.initializeApp()`: Menginisialisasi koneksi ke Firebase.
  - **FCM (Firebase Cloud Messaging)**: Melakukan inisialisasi, meminta izin notifikasi, dan mengambil token FCM untuk notifikasi push.
  - **Background Services**: Mengatur handler untuk notifikasi yang diterima saat aplikasi berjalan di background (`onBackgroundMessage`) dan foreground (`onMessage`).

## 2. Alur Otentikasi Pengguna

- **Widget Awal**: `MyApp` menjalankan `AuthNavigation` sebagai halaman pertama.
- **`AuthNavigation` (`lib/auth_navigation.dart`)**: Widget ini bertugas sebagai "gerbang" aplikasi.
  - Ia memeriksa apakah ada sesi login yang valid (kemungkinan besar dengan `AuthService.checkExistingSession`).
  - **Jika sudah login**: Pengguna akan langsung diarahkan ke `MainNavigation` (halaman utama aplikasi).
  - **Jika belum login**: Pengguna akan diarahkan ke `LoginPage` (`lib/login.dart`).
- **Login & Registrasi**:
  - `lib/login.dart`: Halaman untuk memasukkan email dan password.
  - `lib/register.dart`: Halaman untuk pendaftaran pengguna baru.
  - **`AuthService` (`lib/services/auth_service.dart`)**: Kelas ini menangani semua logika terkait otentikasi, seperti:
    - Login dengan Firebase Auth.
    - Menyimpan data pengguna (username, phone, dll.) ke Firebase Realtime Database.
    - Menyimpan sesi login secara lokal menggunakan `shared_preferences` untuk login otomatis di masa mendatang.

## 3. Struktur Halaman Utama (`MainNavigation`)

Setelah berhasil login, pengguna masuk ke `MainNavigation` (`lib/main.dart`), yang merupakan inti dari antarmuka pengguna.

- **Scaffold & Drawer**: `MainNavigation` berisi `Scaffold` yang memiliki `Drawer` (menu samping).
  - **Drawer Header**: Menampilkan informasi pengguna seperti nama, nomor telepon, dan foto profil (yang seharusnya sudah diperbarui dari ikon statis).
  - **Menu Drawer**:
    - `My Profile`: Mengarah ke `ProfilePage` untuk mengubah data profil.
    - `Zone Name Settings`: Mengarah ke `ZoneNameSettingsPage`.
    - `Full Monitoring`: Mengarah ke `FullMonitoringPage`.
    - `Logout`: Untuk keluar dari aplikasi.
- **Bottom Navigation Bar**: Navigasi utama aplikasi menggunakan `BottomNavigationBar` dengan 4 tab:
  1.  **Home** (`lib/home.dart`): Halaman utama/dashboard.
  2.  **Monitoring** (`lib/monitoring.dart`): Halaman untuk memantau status.
  3.  **Control** (`lib/control.dart`): Halaman untuk mengontrol perangkat.
  4.  **History** (`lib/history.dart`): Halaman untuk melihat riwayat kejadian.

## 4. Manajemen State

- **Provider & ChangeNotifier**: Aplikasi menggunakan package `provider` untuk manajemen state.
- **`FireAlarmData` (`lib/fire_alarm_data.dart`)**: Ini adalah `ChangeNotifier` utama yang kemungkinan besar menyimpan state global aplikasi (seperti status koneksi Firebase) dan memberitahu widget lain jika ada perubahan.

## 5. Halaman Profil Pengguna (`ProfilePage`)

- **File**: `lib/profile_page.dart`
- **Fungsionalitas**:
  - Menampilkan nama, nomor telepon, dan foto profil saat ini.
  - Mengizinkan pengguna memilih gambar baru dari galeri menggunakan `image_picker`.
  - Mengunggah gambar baru ke `Firebase Storage`.
  - Menyimpan perubahan (nama, telepon, URL foto baru) ke Firebase Auth, Firebase Realtime Database, dan `shared_preferences` melalui `AuthService`.
