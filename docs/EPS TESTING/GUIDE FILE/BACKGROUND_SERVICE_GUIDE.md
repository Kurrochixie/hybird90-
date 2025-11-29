# Background Service Implementation Guide

## 📋 Overview
Panduan ini menjelaskan implementasi background service yang memungkinkan aplikasi Fire Alarm untuk terus berjalan di background dan memantau Firebase secara kontinyu, bahkan saat aplikasi tidak sedang dibuka.

## 🔧 Komponen Implementasi

### 1. **Background Notification Service** (`background_notification_service.dart`)
- Menangani FCM messages di background
- Menampilkan notifikasi dengan suara
- Mengaktifkan wake lock untuk critical alarms
- Memutar suara alarm dengan loop untuk event kritis

### 2. **Background App Service** (`background_app_service.dart`)
- Service yang benar-benar berjalan di background
- Monitor Firebase Realtime Database setiap 30 detik
- Menangani perubahan status alarm
- Integrasi dengan notification service

### 3. **Dependencies**
- `flutter_background_service: ^5.0.6` - Background service framework
- `flutter_background_service_android: ^6.2.2` - Android-specific background service
- `flutter_local_notifications: ^17.2.2` - Local notifications dengan suara
- `wakelock_plus: ^1.2.5` - Menjaga device tetap aktif
- `audioplayers: ^5.2.1` - Pemutaran suara alarm

## 🚀 Cara Kerja Background Service

### **1. Initialisasi Service**
```dart
// Di main.dart
await BackgroundAppService().initializeService();
```

### **2. Background Service Loop**
- Service berjalan sebagai foreground service
- Setiap 30 detik memonitor Firebase:
  - `fire_alarm_status` node
  - `recent_alarms` node (latest alarm)
- Deteksi perubahan status dan trigger notifikasi

### **3. Monitoring Flow**
```
Background Service Start
├── Initialize Firebase
├── Start Timer (30 seconds)
├── Monitor fire_alarm_status
│   ├── Check status changes
│   └── Trigger notification if ALARM/DRILL
├── Monitor recent_alarms
│   ├── Get latest alarm
│   └── Show notification for non-NORMAL events
└── Repeat every 30 seconds
```

## 📱 Background Service States

### **Foreground Service Mode**
- Menampilkan notifikasi ongoing di status bar
- Judul: "Fire Alarm Service"
- Konten: "Monitoring fire alarm status..."
- Notification ID: 888
- Channel: `fire_alarm_service_channel`

### **Background Service Mode**
- Service berjalan tanpa notifikasi visible
- Monitoring tetap aktif
- Notifikasi alarm tetap muncul untuk critical events

### **Service Persistence**
- Auto-start saat aplikasi dibuka
- Survive app termination (dengan batasan OS)
- Restart capability jika di-stop

## 🔧 Konfigurasi Android

### **Permissions**
```xml
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

### **Service Declaration**
```xml
<service
    android:name="id.flutter.flutter_background_service.BackgroundService"
    android:foregroundServiceType="dataSync"
    android:exported="false" />
```

## 📊 Monitoring Behavior

### **Firebase Nodes Dimonitor**
1. **fire_alarm_status**
   - Status global alarm system
   - Values: `NORMAL`, `ALARM_ACTIVE`, `DRILL_ACTIVE`
   - Check every 30 seconds

2. **recent_alarms**
   - Log alarm events
   - Get latest entry
   - Process eventType, status, user

### **Trigger Conditions**
- Status berubah dari normal → alarm/drill
- New alarm entry dengan eventType ≠ NORMAL
- Critical events: ALARM, DRILL, TROUBLE, etc.

## 🔊 Notification & Sound Behavior

### **Critical Alarms (ALARM, TROUBLE)**
- Full-screen notification
- Looping alarm sound (`alarm_clock.ogg`)
- Wake lock activated
- Vibration pattern: [0, 1000, 500, 1000]
- Stop alarm action available

### **Drill Notifications**
- Standard notification
- Single sound play (`beep_short.ogg`)
- Short vibration pattern: [0, 500, 200, 500]
- No wake lock
- Auto-dismiss

## 🧪 Testing Background Service

### **1. Install & Setup**
```bash
flutter clean
flutter pub get
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **2. Grant Permissions**
- Notifications
- Background activity (battery optimization)
- Storage (jika diperlukan)

### **3. Test Scenarios**

#### **Scenario A: Background Monitoring**
1. Buka aplikasi
2. Minimize aplikasi
3. Trigger alarm di Firebase
4. Harus muncul notifikasi dengan suara

#### **Scenario B: Service Persistence**
1. Buka aplikasi (service start)
2. Close aplikasi dari recent apps
3. Trigger alarm di Firebase
4. Background service harus detect dan notifikasi

#### **Scenario C: Status Change Detection**
1. Set Firebase `fire_alarm_status` = "NORMAL"
2. Start background service
3. Change status to "ALARM_ACTIVE"
4. Service harus detect dan trigger notification

### **4. Firebase Test Data**
```json
// Test fire_alarm_status
{
  "fire_alarm_status": "ALARM_ACTIVE"
}

// Test recent_alarms
{
  "recent_alarms": {
    "alarm_001": {
      "eventType": "ALARM",
      "status": "ACTIVE",
      "user": "Test User",
      "timestamp": "1697234567890"
    }
  }
}
```

## 🔍 Troubleshooting

### **Service Not Starting**
1. Check permissions di Settings > Apps > Your App > Permissions
2. Pastikan battery optimization disabled
3. Restart device
4. Check logcat untuk error messages

### **Notifications Not Showing**
1. Check notification settings untuk app
2. Pastikan notification channels enabled
3. Test dengan app di foreground dulu

### **Sound Not Playing**
1. Check device volume
2. Check Do Not Disturb mode
3. Pastikan file audio ada di `android/app/src/main/res/raw/`

### **Service Stops Unexpectedly**
1. Check battery optimization settings
2. Pastikan app di "allow background activity"
3. Monitor logcat untuk service lifecycle events

## 📱 Device-Specific Notes

### **Android 8.0+ (Oreo)**
- Background services dibatasi
- Notification channels required
- Battery optimization perlu di-disable

### **Android 10+**
- Stricter background execution limits
- Background location permission mungkin diperlukan

### **Android 12+**
- `POST_NOTIFICATIONS` permission required
- Notification trampolines untuk better handling

### **OEM-Specific (Samsung, Xiaomi, etc.)**
- Aggressive battery optimization
- Manual whitelist app diperlukan
- Custom permission settings

## 🔄 Service Management

### **Manual Control**
```dart
// Stop service
await BackgroundAppService().stopService();

// Restart service
await BackgroundAppService().restartService();

// Check service status
bool isRunning = await FlutterBackgroundService().isRunning();
```

### **Service Lifecycle**
1. **Start**: Saat aplikasi dibuka
2. **Run**: Continuous monitoring setiap 30 detik
3. **Pause**: Saat device di Doze mode
4. **Restart**: Setelah device wake up
5. **Stop**: Saat service explicitly di-stop atau app di-uninstall

## ⚡ Performance Considerations

### **Battery Usage**
- Service menggunakan foreground service mode
- Wake lock hanya untuk critical alarms
- Minimal network requests (setiap 30 detik)

### **Memory Usage**
- Lightweight background service
- Firebase connection reused
- Audio player hanya saat alarm aktif

### **Network Usage**
- Small Firebase database reads
- ~1KB data per 30 detik
- ~2.4MB per hour continuous monitoring

## 🛡️ Security & Privacy

### **Data Protection**
- Firebase security rules untuk access control
- Tidak ada data sensitive disimpan di device
- Encrypted Firebase connection

### **Service Security**
- Service tidak exported ke apps lain
- Permission-based access
- Secure inter-process communication

## 📈 Monitoring & Analytics

### **Service Health**
- Log semua service events
- Monitor Firebase connection status
- Track notification delivery rates

### **Debug Information**
```dart
// Enable debug logging
debugPrint('Service status: $isRunning');
debugPrint('Last alarm check: $lastCheckTime');
debugPrint('Firebase connection: $isConnected');
```

---

## 🎯 Best Practices

1. **Test secara menyeluruh** di berbagai device dan Android versions
2. **Monitor battery usage** dan optimalkan jika perlu
3. **Provide clear user instructions** untuk permissions
4. **Implement proper error handling** dan recovery
5. **Regular testing** dari background service functionality

## 📞 Support

Jika mengalami masalah dengan background service:
1. Check logcat untuk error messages
2. Verify Firebase configuration
3. Test pada device yang berbeda
4. Contact development team dengan detail logs

---
*Last Updated: 13 October 2025*
*Version: 2.0.0*
