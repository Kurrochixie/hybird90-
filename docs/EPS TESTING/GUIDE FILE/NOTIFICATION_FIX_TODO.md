# TODO: Perbaikan Sistem Notifikasi

## 🔥 Issue Prioritas
- [ ] Fix System Reset - Alarm masih berbunyi saat reset
- [ ] Fix Wake Lock - Hanya untuk drill, bukan untuk button lain
- [ ] Fix Recent Status - Data tidak muncul di home
- [ ] Update notification logic untuk button lain (push notification biasa)

## Perbaikan yang Diperlukan
### 1. Background App Service
- [ ] Pastikan systemReset() menghentikan semua audio
- [ ] Hapus wake lock untuk non-drill events
- [ ] Fix logic untuk SYSTEM_RESET event handling

### 2. Local Audio Manager  
- [ ] Sinkronisasi dengan system reset
- [ ] Pastikan stopAllSounds() dipanggil saat reset

### 3. Enhanced Notification Service
- [ ] Update channel logic untuk non-critical events
- [ ] Remove wake lock untuk status update notifications

### 4. Home Page Recent Status
- [ ] Investigasi mengapa activity logs kosong
- [ ] Periksa FireAlarmData activityLogs population
- [ ] Fix date filtering logic

### 5. Control Page Integration
- [ ] Pastikan reset menghentikan audio di semua services
- [ ] Update notification behavior untuk berbagai button types
