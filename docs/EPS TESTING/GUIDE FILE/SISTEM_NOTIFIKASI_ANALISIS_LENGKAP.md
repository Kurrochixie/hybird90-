# ANALISIS SISTEM NOTIFIKASI LENGKAP - DDS FIRE ALARM MOBILE

## 📋 OVERVIEW SISTEM

Sistem notifikasi dalam aplikasi DDS Fire Alarm Mobile adalah arsitektur hybrid yang menggabungkan:
- **Firebase Cloud Messaging (FCM)** untuk notifikasi real-time dari backend
- **Local Notifications** untuk notifikasi foreground dan background
- **Audio Management System** untuk alarm dan sound effects
- **Background Services** untuk operasi persisten

---

## 🏗️ ARSITEKTUR KOMPONEN

### 1. **Dependencies & Configuration**
- **Firebase Core**: `firebase_core: ^2.24.2`
- **FCM**: `firebase_messaging: ^14.7.10`
- **Local Notifications**: `flutter_local_notifications: ^17.2.2`
- **Audio Player**: `audioplayers: ^5.2.1`
- **Wake Lock**: `wakelock_plus: ^1.2.5`

### 2. **Android Permissions (AndroidManifest.xml)**
```xml
<!-- Critical Permissions -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
```

---

## 🔄 ALUR KERJA SISTEM NOTIFIKASI

### **ALUR 1: INISIALISASI APLIKASI**

#### 1.1 Main.dart Initialization
```dart
void main() async {
  // 1. Firebase Initialization
  await Firebase.initializeApp();
  
  // 2. FCM Permission Request
  NotificationSettings settings = await messaging.requestPermission();
  
  // 3. Get FCM Token
  String? token = await messaging.getToken();
  
  // 4. Subscribe to Topics
  await messaging.subscribeToTopic('status_updates');
  await FCMService.subscribeToFireAlarmEvents(token);
  
  // 5. Background Message Handler Setup
  FirebaseMessaging.onBackgroundMessage(bg_notification.BackgroundNotificationService.firebaseMessagingBackgroundHandler);
  
  // 6. Foreground Message Handler
  FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  
  // 7. Initialize Services
  await bg_notification.BackgroundNotificationService().initialize();
  await LocalAudioManager().initialize();
}
```

#### 1.2 Service Initialization Chain
```
Firebase App → FCM Service → Background Notification Service → Local Audio Manager → Enhanced Notification Service
```

---

### **ALUR 2: TRIGGER NOTIFIKASI DARI USER ACTION**

#### 2.1 User Action Flow (Control.dart)
```dart
// User menekan button DRILL
_handleDrill() async {
  // 1. Check Firebase Connection
  if (!fireAlarmData.isFirebaseConnected) return;
  
  // 2. Show Confirmation Dialog
  final confirmed = await _showConfirmationDialog();
  
  // 3. Update Local State
  fireAlarmData.updateSystemStatus('Drill', newStatus);
  fireAlarmData.updateRecentActivity('DRILL : ON', user: currentUser);
  
  // 4. Trigger Notification
  fireAlarmData.sendNotification();
  
  // 5. Update Audio Manager
  _audioManager.updateAudioStatusFromButtons(...);
}
```

#### 2.2 FireAlarmData.sendNotification()
```dart
void sendNotification() async {
  // 1. Get current user
  final String? currentUser = await authService.getCurrentUsername();
  
  // 2. Send via FCM Service
  await FCMService.sendDrillNotification(
    status: 'ON',
    user: currentUser ?? 'Unknown',
    projectName: projectName,
    panelType: panelType,
  );
}
```

---

### **ALUR 3: BACKEND PROCESSING (Firebase Cloud Functions)**

#### 3.1 FCM Service Send Flow
```dart
// lib/services/fcm_service.dart
static Future<bool> sendFireAlarmNotification({...}) async {
  // 1. Prepare HTTP Request to Firebase Functions
  final response = await http.post(
    Uri.parse('$_functionsUrl/sendFireAlarmNotification'),
    body: jsonEncode({
      'data': {
        'eventType': eventType,
        'status': status,
        'user': user,
        'projectName': projectName,
        'panelType': panelType,
      }
    }),
  );
  
  // 2. Handle Response with Retry Logic
  if (response.statusCode == 200) {
    return true; // Success
  } else {
    // Retry mechanism for errors
  }
}
```

#### 3.2 Firebase Cloud Functions Processing
```javascript
// functions/index.js
exports.sendFireAlarmNotification = onCall(async (req) => {
  // 1. Extract Event Data
  const {eventType, status, user, projectName, panelType} = req.data;
  
  // 2. Create Notification Payload
  let title, body, data;
  switch (eventType) {
    case 'DRILL':
      title = '🚨 FIRE DRILL ALERT';
      body = `Drill mode ${status.toUpperCase()} by ${user}`;
      data = { eventType: 'DRILL', status: status, user: user, priority: 'high' };
      break;
    // ... other event types
  }
  
  // 3. Create FCM Message
  const message = {
    topic: 'fire_alarm_events',
    notification: { title, body },
    data: data,
    android: { priority: 'high', notification: { sound: 'drill_alarm.mp3' } },
    apns: { payload: { aps: { sound: data.sound, badge: 1 } } }
  };
  
  // 4. Send to FCM
  const response = await admin.messaging().send(message);
  
  // 5. Log to Firestore
  await admin.firestore().collection('notification_logs').add({...});
  
  return { success: true, messageId: response };
});
```

---

### **ALUR 4: NOTIFICATION DELIVERY TO CLIENT**

#### 4.1 FCM Message Reception
```dart
// Background Message Handler
@pragma('vm:entry-point')
static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Initialize Background Service
  final service = BackgroundNotificationService();
  await service.initialize();
  
  // 2. Extract Message Data
  final data = message.data;
  final eventType = data['eventType'] ?? 'UNKNOWN';
  final status = data['status'] ?? '';
  final user = data['user'] ?? 'System';
  
  // 3. Handle Specific Events
  if (eventType == 'SYSTEM_RESET') {
    await service.systemReset();
  } else if (eventType == 'ACKNOWLEDGE') {
    await service.acknowledge();
  } else {
    // 4. Show Notification with Sound
    await service.showFireAlarmNotification(
      title: 'Fire Alarm: $eventType',
      body: 'Status: $status - By: $user',
      eventType: eventType,
      data: data,
    );
  }
}
```

#### 4.2 Foreground Message Handling
```dart
// Foreground Message Handler
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final data = message.data;
  final eventType = data['eventType'] ?? 'UNKNOWN';
  
  // Show notification even when app is in foreground
  bg_notification.BackgroundNotificationService().showFireAlarmNotification(
    title: 'Fire Alarm: $eventType',
    body: 'Status: $status - By: $user',
    eventType: eventType,
    data: data,
  );
});
```

---

### **ALUR 5: LOCAL NOTIFICATION & AUDIO PROCESSING**

#### 5.1 Background Notification Service
```dart
// lib/services/background_app_service.dart
Future<void> showFireAlarmNotification({...}) async {
  // 1. Acquire Wake Lock
  await WakelockPlus.enable();
  
  // 2. Determine Sound Based on Event Type
  String soundFileName = '';
  ReleaseMode releaseMode = ReleaseMode.stop;
  
  if (eventType == 'DRILL') {
    soundFileName = 'beep_short.ogg';
    releaseMode = ReleaseMode.stop; // Play once
  } else if (eventType == 'ALARM') {
    if (_isDrillMode && !_isSilentMode) {
      soundFileName = 'alarm_clock.ogg';
      releaseMode = ReleaseMode.loop; // Loop for alarm
    }
  }
  
  // 3. Create Android Notification Channel
  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    'Fire Alarm Notifications',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    sound: RawResourceAndroidNotificationSound(soundFileName),
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    additionalFlags: Int32List.fromList([4, 4]), // FLAG_INSISTENT + FLAG_NO_CLEAR
  );
  
  // 4. Show Notification
  await flutterLocalNotificationsPlugin.show(...);
  
  // 5. Play Sound
  if (soundFileName.isNotEmpty) {
    await _playSound(soundFileName, releaseMode);
  }
}
```

#### 5.2 Local Audio Manager Integration
```dart
// lib/services/local_audio_manager.dart
void updateAudioStatusFromButtons({...}) {
  // Handle Drill
  if (isDrillActive != _isDrillActive) {
    _isDrillActive = isDrillActive;
    if (isDrillActive && !_isSoundMuted) {
      _playDrillSound(); // Loop alarm_clock.ogg
    } else {
      _stopDrillSound();
    }
  }
  
  // Handle Alarm
  if (isAlarmActive != _isAlarmActive) {
    _isAlarmActive = isAlarmActive;
    if (isAlarmActive && !_isSilencedActive && !_isSoundMuted) {
      _playAlarmSound(); // Loop alarm_clock.ogg
    } else {
      _stopAlarmSound();
    }
  }
  
  // Handle Trouble
  if (isTroubleActive != _isTroubleActive) {
    _isTroubleActive = isTroubleActive;
    if (isTroubleActive && !_isSoundMuted) {
      _startTroubleBeep(); // Beep every 2 seconds
    } else {
      _stopTroubleBeep();
    }
  }
}
```

---

### **ALUR 6: ENHANCED NOTIFICATION SERVICE**

#### 6.1 Notification Queue & Debouncing
```dart
// lib/services/enhanced_notification_service.dart
Future<void> showNotification({...}) async {
  // 1. Check Mute Status
  if (_isNotificationMuted) return;
  
  // 2. Generate Consistent Notification ID
  final notificationId = _generateNotificationId(eventType, data);
  
  // 3. Debounce Rapid Notifications
  if (_shouldDebounceNotification(notificationId)) return;
  
  // 4. Add to Queue
  final request = _NotificationRequest(...);
  _notificationQueue.add(request);
  
  // 5. Process Queue
  if (!_isProcessingQueue) {
    _processNotificationQueue();
  }
}

Future<void> _processNotificationQueue() async {
  while (_notificationQueue.isNotEmpty) {
    final request = _notificationQueue.removeAt(0);
    await _showSingleNotification(request);
    await Future.delayed(const Duration(milliseconds: 100));
  }
}
```

#### 6.2 Channel-Based Notification Routing
```dart
AndroidNotificationDetails _buildCriticalNotificationDetails(...) {
  return AndroidNotificationDetails(
    'critical_alarm_channel',
    'Critical Fire Alarm',
    importance: Importance.max,
    priority: Priority.high,
    fullScreenIntent: true,
    category: AndroidNotificationCategory.alarm,
    sound: RawResourceAndroidNotificationSound('alarm_clock'),
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    additionalFlags: Int32List.fromList([4, 4]), // FLAG_INSISTENT + FLAG_NO_CLEAR
    actions: [
      AndroidNotificationAction('stop_alarm', 'Stop Alarm'),
      AndroidNotificationAction('snooze', 'Snooze 5min'),
    ],
  );
}
```

---

## 🎵 AUDIO SYSTEM ARCHITECTURE

### **Audio File Mapping**
```
- alarm_clock.ogg → Critical ALARM & DRILL events (looped)
- beep_short.ogg → System actions & status updates (single play)
```

### **Audio Logic Flow**
```dart
// Event Type → Audio Behavior
DRILL ON:  beep_short.ogg (once) → LocalAudioManager sync
ALARM ON:  alarm_clock.ogg (loop) → Wake lock enabled
TROUBLE ON: beep_short.ogg (every 2 seconds)
SYSTEM RESET: beep_short.ogg (once) → Stop all audio
ACKNOWLEDGE: beep_short.ogg (once) → Stop alarm audio
SILENCE: Stop alarm audio → Update audio state
```

### **Local Mute System**
```dart
// Three-tier mute system
bool _isNotificationMuted = false; // Mute all notifications
bool _isSoundMuted = false;        // Mute audio only
bool _isBellMuted = false;         // Mute bell system (future)

// Persistent storage via SharedPreferences
await prefs.setBool('notification_muted', _isNotificationMuted);
await prefs.setBool('sound_muted', _isSoundMuted);
await prefs.setBool('bell_muted', _isBellMuted);
```

---

## 🔄 BACKGROUND PROCESSING

### **Background Service Types**
1. **FCM Background Handler**: Processes incoming FCM messages when app is backgrounded
2. **Background Notification Service**: Manages persistent notifications and audio
3. **Local Audio Manager**: Handles audio playback in background
4. **Wake Lock Manager**: Keeps device awake during critical events

### **Background Message Flow**
```
FCM Message → Background Handler → Service Initialization → 
Notification Creation → Audio Playback → Wake Lock → State Update
```

---

## 📊 NOTIFICATION CHANNELS & PRIORITIES

### **Android Notification Channels**
```dart
// Critical Alarm Channel
'critical_alarm_channel' → Importance.max, Priority.high, Full-screen intent

// Drill Channel  
'drill_channel' → Importance.high, Priority.high, Standard notification

// Status Update Channel
'status_update_channel' → Importance.low, Priority.default, Silent
```

### **Event Type Priorities**
```
ALARM/TROUBLE → High Priority → Full-screen, insistent, looped audio
DRILL → High Priority → Standard notification, single audio
SYSTEM RESET/ACKNOWLEDGE → Medium Priority → Silent notification
SILENCE → Low Priority → Silent notification
```

---

## 🔧 LOCAL CONTROLS & SETTINGS

### **Control Page Local Features**
```dart
// METODE (LOCAL) Section
- MUTE NOTIF → Toggle _isNotificationMuted
- MUTE SOUND → Toggle _isSoundMuted  
- MUTE BELL → Toggle _isBellMuted (coming soon)
```

### **Settings Persistence**
```dart
// SharedPreferences Keys
'notification_muted' → bool
'sound_muted' → bool
'bell_muted' → bool
```

---

## 🚨 ERROR HANDLING & RETRY MECHANISM

### **FCM Retry Logic**
```dart
// Multi-level retry with exponential backoff
int retryCount = 0;
while (retryCount <= maxRetries) {
  try {
    final response = await http.post(...).timeout(Duration(seconds: 10));
    if (response.statusCode == 200) return true;
    
    if (response.statusCode == 404 || response.statusCode == 500) {
      retryCount++;
      await Future.delayed(Duration(seconds: 2 * retryCount));
      continue;
    }
  } catch (e) {
    if (e.toString().contains('TimeoutException') || 
        e.toString().contains('SocketException')) {
      retryCount++;
      await Future.delayed(Duration(seconds: 2 * retryCount));
      continue;
    }
  }
  break;
}
```

### **Service Initialization Error Handling**
```dart
// Graceful degradation
try {
  await Firebase.initializeApp();
} catch (e) {
  debugPrint('Firebase initialization failed: $e');
  // Continue without Firebase functionality
}
```

---

## 📱 PLATFORM-SPECIFIC BEHAVIORS

### **Android Specific**
- Full-screen intent notifications for critical alarms
- FLAG_INSISTENT + FLAG_NO_CLEAR for persistent alarms
- Custom vibration patterns per event type
- Wake lock for keeping screen awake
- System overlay window permissions

### **iOS Specific**
- APNS payload configuration
- Custom sound files (.caf format)
- Badge numbers
- Mutable content support
- Category-based actions

---

## 🔗 DATA FLOW DIAGRAM

```
USER ACTION (Control Page)
    ↓
FireAlarmData.updateSystemStatus()
    ↓
FCMService.sendDrillNotification()
    ↓
HTTP POST to Firebase Functions
    ↓
Cloud Functions Process Event
    ↓
FCM Topic Message (fire_alarm_events)
    ↓
All Subscribed Devices Receive
    ↓
Background Handler Processes
    ↓
Local Notification + Audio
    ↓
User Sees/Hears Notification
    ↓
Local Audio Manager Sync
    ↓
UI Updates via Provider
```

---

## 📈 PERFORMANCE OPTIMIZATIONS

### **Notification Debouncing**
- Prevents duplicate notifications within 2 seconds
- Consistent notification ID generation
- Queue-based processing system

### **Audio Management**
- Single AudioPlayer instance
- Proper resource cleanup
- State-based audio control

### **Memory Management**
- Service disposal on app exit
- Stream subscription cleanup
- Timer cancellation for trouble beeps

---

## 🛡️ SECURITY & PERMISSIONS

### **Required Permissions**
- `POST_NOTIFICATIONS`: Android 13+ notification permission
- `WAKE_LOCK`: Keep device awake during alarms
- `SYSTEM_ALERT_WINDOW`: Show notifications over other apps
- `FOREGROUND_SERVICE`: Background processing
- `USE_FULL_SCREEN_INTENT`: Critical alarm display

### **Security Measures**
- FCM server key protection
- User authentication for actions
- Confirmation dialogs for critical actions
- Firebase security rules for data access

---

## 🔮 FUTURE ENHANCEMENTS

### **Planned Features**
- Bell mute system implementation
- Rich notifications with images
- Custom notification sounds per zone
- Notification history and analytics
- Push notification grouping
- Geofence-based notifications

### **Potential Improvements**
- WebSocket integration for real-time updates
- Local notification scheduling
- Notification priority learning
- Adaptive notification patterns
- Multi-language support

---

## 📝 SUMMARY

Sistem notifikasi DDS Fire Alarm Mobile adalah arsitektur komprehensif yang menggabungkan:

1. **Real-time Cloud Messaging** via Firebase FCM
2. **Robust Local Notifications** dengan channel-based routing
3. **Intelligent Audio Management** dengan multi-tier mute system
4. **Persistent Background Processing** untuk operasi 24/7
5. **User-friendly Local Controls** untuk personalisasi
6. **Comprehensive Error Handling** dengan retry mechanisms
7. **Platform-specific Optimizations** untuk Android & iOS

Sistem ini dirancang untuk **keandalan maksimal** dalam situasi darurat fire alarm, dengan **redundansi built-in** dan **graceful degradation** saat terjadi masalah koneksi atau service.
