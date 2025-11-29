# Background Notification Setup Guide

## 📋 Overview
Panduan ini menjelaskan setup yang telah dilakukan untuk memastikan aplikasi Fire Alarm dapat menerima notifikasi dan memutar suara bahkan saat aplikasi tidak dibuka (background/terminated state).

## 🔧 What Has Been Implemented

### 1. Dependencies Added
- `flutter_local_notifications: ^17.2.2` - Untuk notifikasi lokal dengan suara
- `wakelock_plus: ^1.2.5` - Untuk menjaga device tetap aktif saat alarm
- `workmanager: ^0.5.2` - Untuk background task management
- `timezone: ^0.9.2` - Untuk scheduled notifications

### 2. Android Permissions
AndroidManifest.xml sekarang memiliki permission:
- `WAKE_LOCK` - Menjaga device tetap aktif
- `VIBRATE` - Getar saat notifikasi
- `RECEIVE_BOOT_COMPLETED` - Auto-start setelah boot
- `FOREGROUND_SERVICE` - Background service
- `SYSTEM_ALERT_WINDOW` - Full-screen notifications
- `MODIFY_AUDIO_SETTINGS` - Kontrol audio

### 3. Background Service
- `BackgroundNotificationService` - Service khusus untuk notifikasi background
- WorkManager untuk periodic tasks setiap 15 menit
- Firebase Messaging background handler
- Wake lock untuk menjaga device tetap aktif

### 4. Notification Channels
Dua channel notifikasi dibuat:
- **fire_alarm_channel** - Untuk alarm kritis (importance: max)
- **drill_channel** - Untuk drill (importance: high)

### 5. Audio Files
- File suara disalin ke `android/app/src/main/res/raw/`
- `alarm_clock.ogg` - Untuk alarm kritis (loop)
- `beep_short.ogg` - Untuk drill (single play)

## 🚀 How It Works

### Foreground State (Aplikasi Dibuka)
1. FCM message diterima
2. BackgroundNotificationService menampilkan notifikasi
3. Suara dimainkan dengan vibration
4. User dapat stop/snooze alarm

### Background State (Aplikasi Diminimize)
1. FCM message diterika
2. Background handler otomatis aktif
3. Notifikasi fullscreen muncul
4. Suara alarm dimainkan dengan loop
5. Device tetap aktif (wake lock)

### Terminated State (Aplikasi Ditutup)
1. FCM message diterika oleh sistem Android
2. Background handler dijalankan
3. Service diinisialisasi
4. Notifikasi dan suara dimainkan
5. Wake lock diaktifkan

## 🧪 Testing Steps

### 1. Build Aplikasi
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### 2. Install di Device
```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

### 3. Grant Permissions
Pastikan semua permissions di-grant:
- Notifications
- Storage (jika diperlukan)
- Background activity
- Battery optimization (exclude app)

### 4. Test Scenarios

#### Scenario A: Foreground Test
1. Buka aplikasi
2. Kirim FCM message dengan data:
   ```json
   {
     "eventType": "DRILL",
     "status": "ACTIVE",
     "user": "Test User"
   }
   ```
3. Harus muncul notifikasi dengan suara

#### Scenario B: Background Test
1. Buka aplikasi
2. Minimize aplikasi (home button)
3. Kirim FCM message
4. Harus muncul notifikasi fullscreen dengan suara

#### Scenario C: Terminated Test
1. Buka aplikasi
2. Close aplikasi dari recent apps
3. Kirim FCM message
4. Harus muncul notifikasi dengan suara

### 5. Test Firebase Functions
```bash
# Test drill notification
curl -X POST https://us-central1-testing1do.cloudfunctions.net/sendFireAlarmNotification \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "eventType": "DRILL",
      "status": "ACTIVE",
      "user": "Test User",
      "projectName": "Test Project",
      "panelType": "Test Panel"
    }
  }'
```

## 🔍 Troubleshooting

### Notification Not Showing
1. Check permissions di Settings > Apps > Your App > Notifications
2. Pastikan notification channels enabled
3. Restart device jika perlu

### Sound Not Playing
1. Check device volume
2. Check Do Not Disturb mode
3. Pastikan file audio ada di `android/app/src/main/res/raw/`

### Background Not Working
1. Check battery optimization settings
2. Pastikan app tidak di-kill oleh OS
3. Check WorkManager logs

### Wake Lock Not Working
1. Check `WAKE_LOCK` permission
2. Pastikan app memiliki permission untuk modify system settings

## 📱 Device Specific Notes

### Android 8.0+ (Oreo)
- Background services dibatasi
- Notification channels required
- Battery optimization perlu di-disable

### Android 10+
- Background location permission mungkin diperlukan
- Stricter background execution limits

### Android 12+
- Need to request `POST_NOTIFICATIONS` permission
- Notification trampolines untuk better background handling

## 🎯 Key Features

### 1. Critical Alarm Handling
- Full-screen notification
- Looping alarm sound
- Wake lock activation
- Vibration pattern
- Stop/Snooze actions

### 2. Drill Notifications
- Standard notification
- Single sound play
- No wake lock
- Short vibration

### 3. Background Persistence
- WorkManager periodic tasks
- Boot receiver
- Service restart capability
- Firebase message handling

### 4. User Actions
- Stop alarm immediately
- Snooze for 5 minutes
- Tap to open app
- Dismiss notifications

## 📊 Expected Behavior

| State | Notification | Sound | Vibration | Wake Lock |
|-------|--------------|-------|-----------|-----------|
| Foreground | ✅ | ✅ | ✅ | ✅ |
| Background | ✅ | ✅ | ✅ | ✅ |
| Terminated | ✅ | ✅ | ✅ | ✅ |

## 🚨 Important Notes

1. **Device Compatibility**: Some devices may kill background services aggressively
2. **Battery Optimization**: Must exclude app from battery optimization
3. **Do Not Disturb**: May block sounds/vibrations
4. **Storage Space**: Ensure sufficient space for audio files
5. **Network**: Required for FCM message delivery

## 🔄 Maintenance

1. Monitor WorkManager task execution
2. Check Firebase delivery rates
3. Test on different Android versions
4. Update notification channels if needed
5. Monitor battery usage impact

## 📞 Support

Jika mengalami masalah:
1. Check logcat untuk error messages
2. Verify Firebase configuration
3. Test dengan device yang berbeda
4. Contact development team dengan logs

---
*Last Updated: 13 October 2025*
*Version: 1.0.0*
