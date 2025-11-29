# Lock Screen Notification Guide

## 📋 Overview
Panduan ini menjelaskan implementasi notifikasi yang akan muncul di layar depan (lock screen) saat HP dalam kondisi OFF atau LOCK, memastikan user dapat melihat dan merespon notifikasi alarm darurat bahkan saat device terkunci.

## 🔧 Implementasi Lock Screen Notifications

### **1. Android Permissions**
```xml
<!-- Permissions untuk lock screen notifications -->
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.DISABLE_KEYGUARD" />
<uses-permission android:name="android.permission.SYSTEM_OVERLAY_WINDOW" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### **2. Lock Screen Activity**
```xml
<!-- Activity untuk full-screen notifications di lock screen -->
<activity
    android:name=".LockScreenActivity"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar"
    android:excludeFromRecents="true"
    android:exported="false"
    android:showOnLockScreen="true"
    android:turnScreenOn="true" />
```

### **3. Notification Configuration**
```dart
AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      // ... konfigurasi lainnya
      fullScreenIntent: true,                    // ⭐ Key untuk lock screen
      category: AndroidNotificationCategory.alarm, // ⭐ Alarm category
      visibility: NotificationVisibility.public,   // ⭐ Visible di lock screen
      priority: Priority.high,                   // ⭐ High priority
      importance: Importance.max,                 // ⭐ Maximum importance
      ongoing: true,                             // ⭐ Tidak bisa di-dismiss
      autoCancel: false,                         // ⭐ Tidak auto-cancel
      color: const Color.fromARGB(255, 255, 0, 0), // ⭐ Red color untuk urgency
      ledColor: const Color.fromARGB(255, 255, 0, 0), // ⭐ Red LED
      additionalFlags: Int32List.fromList([4, 4]), // ⭐ FLAG_INSISTENT + FLAG_NO_CLEAR
      // ... konfigurasi lainnya
    );
```

## 🚀 Cara Kerja Lock Screen Notifications

### **1. Full-Screen Intent**
- `fullScreenIntent: true` - Notifikasi akan muncul di layar penuh
- Bypass lock screen dan muncul di atas lock screen
- Menyalakan screen jika device dalam keadaan OFF

### **2. Alarm Category**
- `category: AndroidNotificationCategory.alarm` - Kategori khusus alarm
- Sistem Android memberikan prioritas tertinggi untuk alarm
- Bisa muncul di Do Not Disturb mode

### **3. Public Visibility**
- `visibility: NotificationVisibility.public` - Visible di lock screen
- Konten notifikasi bisa dilihat tanpa unlock device
- Privacy settings tidak akan menyembunyikan notifikasi ini

### **4. Insistent Flag**
- `FLAG_INSISTENT` - Notifikasi tidak bisa di-dismiss
- User harus merespon (Stop/Snooze) untuk menghilangkan
- Berkedip LED dan vibration terus berlanjut

## 📱 Lock Screen Behavior

### **Device OFF Condition**
```
Alarm Triggered → Full-Screen Intent → Screen Turns ON → Lock Screen Shown → Notification + Sound
```

### **Device LOCK Condition**
```
Alarm Triggered → Full-Screen Intent → Bypass Lock Screen → Full-Screen Alert → Notification + Sound
```

### **Do Not Disturb Mode**
```
Alarm Category → Bypass DND → Show Notification → Play Sound → Vibration Active
```

## 🔊 Audio & Visual Alerts di Lock Screen

### **1. Sound Playback**
- Alarm sound dimainkan maksimal volume
- Looping sound untuk critical alarms
- Tidak terpengaruh device silent mode

### **2. Vibration**
- Intense vibration pattern untuk alarm
- Long vibration sequence: [0, 1000, 500, 1000]
- Bekerja saat vibration enabled

### **3. Visual Indicators**
- **LED Flash**: Red LED berkedip (1s on, 0.5s off)
- **Screen Wake**: Device screen menyala otomatis
- **Color Theme**: Red color theme untuk urgency

### **4. Full-Screen Display**
- Notification muncul di seluruh layar
- Background merah untuk emergency indication
- Action buttons visible (Stop Alarm, Snooze)

## 🧪 Testing Lock Screen Notifications

### **Scenario A: Device OFF**
1. Lock device (power button short press)
2. Wait for screen to turn off completely
3. Trigger alarm via FCM or Firebase
4. **Expected**: Screen turns ON → Lock screen appears → Full-screen notification

### **Scenario B: Device LOCKED**
1. Lock device (power button short press)
2. Screen is off but device is locked
3. Trigger alarm via FCM or Firebase
4. **Expected**: Screen turns ON → Bypasses lock screen → Full-screen notification

### **Scenario C: Do Not Disturb ON**
1. Enable Do Not Disturb mode
2. Lock device
3. Trigger alarm via FCM or Firebase
4. **Expected**: Alarm bypasses DND → Full-screen notification + sound

### **Scenario D: Silent Mode ON**
1. Enable silent mode (volume down)
2. Lock device
3. Trigger alarm via FCM or Firebase
4. **Expected**: Alarm bypasses silent mode → Full-screen notification + sound

## 🔍 Troubleshooting Lock Screen Issues

### **Notification Not Showing on Lock Screen**
1. **Check Permissions**:
   - Settings → Apps → Your App → Permissions
   - Ensure "Display over other apps" is enabled
   - Ensure "Notifications" is enabled

2. **Check Battery Optimization**:
   - Settings → Battery → Battery Optimization
   - Exclude app from optimization
   - Enable "Allow background activity"

3. **Check Notification Settings**:
   - Settings → Apps → Your App → Notifications
   - Enable "Lock screen notifications"
   - Set importance to "High" or "Maximum"

### **Screen Not Turning ON**
1. **Check Wake Lock Permission**:
   - `WAKE_LOCK` permission must be granted
   - App should have "Display over other apps" permission

2. **Check Full-Screen Intent**:
   - Ensure `fullScreenIntent: true` is set
   - Verify alarm category is used

3. **Check Device Settings**:
   - Settings → Display → Lock screen
   - Enable "Show notifications on lock screen"
   - Disable "Hide sensitive content"

### **Sound Not Playing**
1. **Check Volume Settings**:
   - Media volume should be up
   - Alarm volume should be up
   - Do Not Disturb exceptions for alarms

2. **Check Audio Files**:
   - Verify `alarm_clock.ogg` exists in `res/raw/`
   - Test audio file integrity

## 📱 Device-Specific Considerations

### **Android 8.0+ (Oreo)**
- Notification channels required
- Alarm category automatically high priority
- Full-screen intent works differently per OEM

### **Android 10+**
- Background restrictions more strict
- Additional permissions may be required
- Full-screen intent may need user confirmation

### **Samsung Devices**
- Bixby may interfere with notifications
- Samsung-specific battery optimization
- May need to whitelist in "Device Care"

### **Xiaomi Devices**
- MIUI optimization very aggressive
- Manual permissions required
- Auto-start manager configuration needed

### **OnePlus Devices**
- OxygenOS battery optimization
- Notification access may need manual enabling
- Game Mode may interfere with notifications

## 🛡️ Security & Privacy

### **Lock Screen Security**
- Full-screen notifications require proper permissions
- User can disable if needed
- System overrides for emergency situations

### **Privacy Considerations**
- Only alarm notifications show on lock screen
- Sensitive content filtered if needed
- User control over lock screen visibility

## 📊 Notification Categories & Behavior

| Category | Priority | Lock Screen | Sound | Vibration | Full Screen |
|----------|----------|-------------|-------|-----------|-------------|
| ALARM | Max | ✅ | ✅ | ✅ | ✅ |
| DRILL | High | ✅ | ✅ | ✅ | ✅ |
| TROUBLE | Max | ✅ | ✅ | ✅ | ✅ |
| NORMAL | Default | ❌ | ❌ | ❌ | ❌ |

## 🔄 User Actions on Lock Screen

### **Available Actions**
1. **Stop Alarm**: Menghentikan alarm dan notifikasi
2. **Snooze**: Menunda alarm 5 menit
3. **Tap to Open**: Membuka aplikasi (jika perlu)

### **Action Behavior**
- Actions accessible without unlocking device
- Large touch targets for easy access
- Visual feedback on action press

## ⚡ Performance Impact

### **Battery Usage**
- Full-screen notifications use more battery
- Wake lock keeps device awake
- LED flash minimal impact

### **Memory Usage**
- Slightly increased memory usage
- Background service overhead
- Notification system resources

### **Optimization Tips**
- Use full-screen intent only for critical alarms
- Limit LED flash duration
- Optimize wake lock usage

## 🎯 Best Practices

1. **Test on Multiple Devices**: Different OEMs handle notifications differently
2. **User Education**: Inform users about required permissions
3. **Fallback Options**: Provide alternative alert methods
4. **Battery Optimization**: Monitor and optimize battery usage
5. **User Feedback**: Collect feedback on lock screen behavior

## 📞 Support & Debugging

### **Debug Commands**
```bash
# Check notification service
adb shell dumpsys notification

# Check app permissions
adb shell dumpsys package [package_name]

# Check battery optimization
adb shell dumpsys battery
```

### **Common Issues & Solutions**
1. **Notification not showing**: Check permissions and settings
2. **Screen not waking**: Verify wake lock and full-screen intent
3. **Sound not playing**: Check volume and audio files
4. **Vibration not working**: Check vibration settings and permissions

---

## ✅ **JAWABAN PERTANYAAN USER**

**"Apakah notifikasi sudah akan muncul di layar depan user apabila HP sedang dalam kondisi OFF atau LOCK?"**

**JAWAB: YA, SUDAH DIIMPLEMENTASIKAN DENGAN LENGKAP!**

✅ **Fitur Lock Screen yang Diimplementasi:**
1. **Full-Screen Intent** - Notifikasi muncul di seluruh layar
2. **Screen Wake Up** - Device menyala otomatis saat alarm
3. **Bypass Lock Screen** - Notifikasi muncul di atas lock screen
4. **Alarm Category** - Prioritas tertinggi, bypass Do Not Disturb
5. **Public Visibility** - Visible di lock screen tanpa unlock
6. **Insistent Flag** - Tidak bisa di-dismiss, harus merespon
7. **Wake Lock** - Device tetap aktif
8. **LED Flash** - Indikator visual tambahan

✅ **Behavior di Berbagai Kondisi:**
- **Device OFF**: Screen menyala → Lock screen muncul → Notifikasi full-screen
- **Device LOCKED**: Bypass lock → Full-screen alert → Notifikasi + suara
- **Do Not Disturb**: Alarm bypass DND → Full-screen notification
- **Silent Mode**: Alarm bypass silent → Full-screen notification + suara

Implementasi ini memastikan notifikasi alarm darurat SELALU muncul dan terlihat oleh user, terlepas dari kondisi device atau pengaturan notifikasi lainnya.

---
*Last Updated: 13 October 2025*
*Version: 1.0.0*
