# 🔥 FCM Notification System Guide - Fire Alarm Events

## 📋 Overview

Sistem FCM (Firebase Cloud Messaging) yang ditingkatkan untuk mengirim notifikasi spesifik saat events fire alarm terjadi:
- **Drill** (DRILL)
- **System Reset** (SYSTEM RESET)
- **Silence** (SILENCE)
- **Acknowledge** (ACKNOWLEDGE)
- **Alarm** (ALARM)
- **Trouble** (TROUBLE)

## 🏗️ System Architecture

### Firebase Functions (Backend)
```
functions/index.js
├── sendFireAlarmNotification()     # Main notification handler
├── subscribeToFireAlarmEvents()    # Subscribe to topic
└── unsubscribeFromFireAlarmEvents() # Unsubscribe from topic
```

### Flutter App (Frontend)
```
lib/
├── services/fcm_service.dart         # FCM service layer
├── fire_alarm_data.dart             # Integration with system events
└── main.dart                         # FCM initialization
```

## 🚀 Features

### 1. Event-Specific Notifications
Setiap event memiliki notifikasi yang berbeda:

#### 🚨 DRILL Events
- **Title**: "🚨 FIRE DRILL ALERT"
- **Body**: "Drill mode ON/OFF by [User]"
- **Sound**: `drill_alarm.mp3` (when ON)
- **Priority**: High

#### 🔄 SYSTEM RESET Events
- **Title**: "🔄 SYSTEM RESET"
- **Body**: "Fire alarm system reset by [User]"
- **Sound**: `system_reset.mp3`
- **Priority**: High

#### 🔇 SILENCE Events
- **Title**: "🔇 ALARM SILENCED"
- **Body**: "Fire alarm ON/OFF by [User]"
- **Sound**: `silence_alarm.mp3`
- **Priority**: Medium

#### ✅ ACKNOWLEDGE Events
- **Title**: "✅ ALARM ACKNOWLEDGED"
- **Body**: "Fire alarm ON/OFF by [User]"
- **Sound**: `acknowledge.mp3`
- **Priority**: Medium

#### 🚨 ALARM Events
- **Title**: "🚨 FIRE ALARM"
- **Body**: "Fire alarm ON/OFF by [User/System]"
- **Sound**: `fire_alarm.mp3`
- **Priority**: High

#### ⚠️ TROUBLE Events
- **Title**: "⚠️ SYSTEM TROUBLE"
- **Body**: "System trouble ON/OFF by [User/System]"
- **Sound**: `trouble_alarm.mp3`
- **Priority**: Medium

### 2. Enhanced Notification Features
- **Custom sounds** for each event type
- **Priority levels** (High/Medium/Normal)
- **User attribution** (siapa yang melakukan action)
- **Project information** (nama project & panel type)
- **Timestamp** untuk setiap notifikasi
- **Topic-based broadcasting** ke semua users

### 3. Local Notification Handling
- **Foreground messages** → Local notifications
- **Background messages** → System notifications
- **Custom vibration patterns** berdasarkan priority
- **Channel management** untuk Android

## 🔧 Technical Implementation

### Firebase Functions Configuration

```javascript
// Function URL: https://us-central1-testing1do.cloudfunctions.net
exports.sendFireAlarmNotification = onCall(async (req) => {
  const {eventType, status, user, projectName, panelType} = req.data;
  // ... implementation
});
```

### Flutter Integration

#### 1. FCM Service Methods
```dart
// Send specific event notifications
await FCMService.sendDrillNotification(status: 'ON', user: 'Admin');
await FCMService.sendSystemResetNotification(user: 'Admin');
await FCMService.sendSilenceNotification(status: 'ON', user: 'Admin');
await FCMService.sendAcknowledgeNotification(status: 'ON', user: 'Admin');
await FCMService.sendAlarmNotification(status: 'ON', user: 'Admin');
await FCMService.sendTroubleNotification(status: 'ON', user: 'Admin');
```

#### 2. Auto-Subscription
```dart
// In main.dart - automatically subscribe on app start
await FCMService.subscribeToFireAlarmEvents(fcmToken);
```

#### 3. Event Detection
```dart
// In fire_alarm_data.dart - automatically detect events and send notifications
if (recentActivity.contains('DRILL')) {
  await FCMService.sendDrillNotification(/*...*/);
}
```

## 📱 Notification Flow

### 1. User Action Flow
```
User presses button → Control.dart → FireAlarmData.updateRecentActivity() 
→ FireAlarmData._sendFCMMessage() → FCMService.sendXXXNotification() 
→ Firebase Functions → FCM → All Devices
```

### 2. System Event Flow
```
System status change → Firebase listener → FireAlarmData._sendFCMMessage()
→ FCMService.sendXXXNotification() → Firebase Functions → FCM → All Devices
```

## 🔊 Sound Files (Optional)

Untuk notifikasi yang lebih baik, tambahkan sound files ke `assets/sounds/`:
- `drill_alarm.mp3`
- `system_reset.mp3`
- `silence_alarm.mp3`
- `acknowledge.mp3`
- `fire_alarm.mp3`
- `trouble_alarm.mp3`

## 📊 Logging & Monitoring

### Firebase Functions Logging
```javascript
// Automatic logging to Firestore
await admin.firestore().collection('notification_logs').add({
  eventType: 'DRILL',
  status: 'ON',
  user: 'Admin',
  timestamp: admin.firestore.FieldValue.serverTimestamp(),
  messageId: response
});
```

### Flutter Debug Logs
```dart
debugPrint('Sending fire alarm notification: $eventType - $status by $user');
debugPrint('Fire alarm notification sent successfully');
```

## 🛠️ Configuration

### Environment Variables
```bash
# Firebase Functions
GEMINI_API_KEY=your_gemini_api_key

# Flutter (google-services.json)
FCM Server Key: AIzaSyC69zY0U35iz0lhEf3FPauqHemlTZ--41A
```

### Topics
- `fire_alarm_events` - Main topic for all fire alarm events
- `status_updates` - Legacy topic (kept for compatibility)

## 🚀 Deployment Status

### ✅ Completed
- [x] Firebase Functions deployed and working
- [x] Flutter FCM service updated
- [x] Event detection in FireAlarmData
- [x] Auto-subscription on app start
- [x] Enhanced notification payloads
- [x] Sound and vibration settings
- [x] User attribution
- [x] Project information inclusion

### 🔄 Function URLs
- **Main Function**: https://us-central1-testing1do.cloudfunctions.net/sendFireAlarmNotification
- **Subscribe**: https://us-central1-testing1do.cloudfunctions.net/subscribeToFireAlarmEvents
- **Unsubscribe**: https://us-central1-testing1do.cloudfunctions.net/unsubscribeFromFireAlarmEvents

## 📱 Testing

### Test Scenarios
1. **Drill Test**: Tekan tombol DRILL → Notifikasi 🚨 terima
2. **Reset Test**: Tekan tombol SYSTEM RESET → Notifikasi 🔄 terima
3. **Silence Test**: Tekan tombol SILENCE → Notifikasi 🔇 terima
4. **Acknowledge Test**: Tekan tombol ACKNOWLEDGE → Notifikasi ✅ terima

### Debug Steps
1. Cek FCM token di debug console
2. Verifikasi subscription ke topic
3. Monitor Firebase Functions logs
4. Test dengan multiple devices

## 🔍 Troubleshooting

### Common Issues
1. **Notifications not received**
   - Check internet connection
   - Verify FCM token is valid
   - Check subscription to `fire_alarm_events` topic

2. **Sound not playing**
   - Ensure sound files exist in assets
   - Check notification channel settings
   - Verify device sound is enabled

3. **User not showing**
   - Check user extraction regex
   - Verify activity format
   - Debug recentActivity string

### Debug Commands
```bash
# Check Firebase Functions logs
firebase functions:log

# Test FCM service manually
flutter run --debug
```

## 📈 Future Enhancements

### Planned Features
- [ ] Custom notification channels per event type
- [ ] Notification history in app
- [ ] Do Not Disturb mode
- [ ] Scheduled notifications
- [ ] Notification analytics
- [ ] Push notification images

### Performance Optimizations
- [ ] Batch notification sending
- [ ] Local caching of user preferences
- [ ] Reduced notification payload size

---

## 📞 Support

Jika mengalami masalah dengan sistem notifikasi:
1. Cek Firebase Console untuk function logs
2. Verifikasi konfigurasi di Flutter
3. Test dengan manual trigger
4. Contact development team

**System Status**: ✅ Active and Working
**Last Updated**: 2025-10-13
**Version**: 2.0.0
