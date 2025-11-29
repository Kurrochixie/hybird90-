# 🔄 DIAGRAM ALUR SISTEM NOTIFIKASI - DDS FIRE ALARM MOBILE

## 📊 VISUAL FLOW DIAGRAM

### **1. USER ACTION INITIATION FLOW**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   User Press    │    │  Confirmation    │    │   Local State   │
│   Button (DRILL)│───▶│     Dialog       │───▶│    Update       │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Audio Manager   │    │  FireAlarmData   │    │   FCM Service   │
│     Sync        │◀───│  sendNotification│───▶│   HTTP POST     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### **2. BACKEND PROCESSING FLOW**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│ Firebase Cloud  │    │   Event Type     │    │   FCM Message   │
│   Functions     │───▶│   Processing     │───▶│   Creation      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Firestore     │    │   Topic Send     │    │   Priority      │
│     Logging     │◀───│ (fire_alarm_events)│───▶│   Configuration │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

### **3. CLIENT NOTIFICATION RECEIVAL FLOW**
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   FCM Message   │    │   Background     │    │   Service       │
│    Received     │───▶│   Handler        │───▶│ Initialization  │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Event Type    │    │   Notification   │    │   Audio         │
│   Detection     │───▶│   Creation       │───▶│   Playback      │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Wake Lock     │    │   UI State       │    │   User          │
│   Activation    │◀───│   Update         │◀───│   Interaction   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

---

## 🔗 DETAILED ARCHITECTURE FLOW

### **A. INITIALIZATION SEQUENCE**
```
App Start
    │
    ▼
Firebase.initializeApp()
    │
    ▼
FCM Permission Request
    │
    ▼
Get FCM Token
    │
    ▼
Subscribe to Topics
    │
    ├─▶ status_updates
    └─▶ fire_alarm_events
    │
    ▼
Background Handler Setup
    │
    ▼
Service Initialization Chain:
    ├─▶ BackgroundNotificationService
    ├─▶ LocalAudioManager
    ├─▶ EnhancedNotificationService
    └─▶ WakelockPlus
```

### **B. USER ACTION TO NOTIFICATION FLOW**
```
User Action (Control Page)
    │
    ▼
Connection Check
    │
    ▼
Confirmation Dialog
    │
    ▼
Local State Update (FireAlarmData)
    │
    ▼
Activity Log Update
    │
    ▼
FCM Service Call
    │
    ▼
HTTP POST to Cloud Functions
    │
    ▼
Cloud Function Processing
    │
    ├─▶ Event Type Detection
    ├─▶ Payload Creation
    ├─▶ Topic Broadcasting
    └─▶ Firestore Logging
    │
    ▼
All Clients Receive FCM
    │
    ▼
Background Handler Execution
    │
    ▼
Local Notification + Audio
    │
    ▼
UI State Synchronization
```

### **C. AUDIO SYSTEM FLOW**
```
Button State Change
    │
    ▼
LocalAudioManager.updateAudioStatusFromButtons()
    │
    ▼
Event Type Processing:
    │
    ├─▶ DRILL: beep_short.ogg (once)
    ├─▶ ALARM: alarm_clock.ogg (loop)
    ├─▶ TROUBLE: beep_short.ogg (every 2s)
    ├─▶ SYSTEM RESET: beep_short.ogg (once) + stop all
    ├─▶ ACKNOWLEDGE: beep_short.ogg (once) + stop alarm
    └─▶ SILENCE: stop alarm audio
    │
    ▼
Mute Status Check
    │
    ├─▶ Notification Muted?
    ├─▶ Sound Muted?
    └─▶ Bell Muted? (future)
    │
    ▼
AudioPlayer Configuration
    │
    ├─▶ ReleaseMode.loop (for alarms)
    ├─▶ ReleaseMode.stop (for beeps)
    └─▶ Volume/Device Settings
    │
    ▼
Audio Playback
    │
    ▼
Status Broadcast via Stream
```

### **D. NOTIFICATION CHANNEL ROUTING**
```
Event Type Detection
    │
    ▼
Channel Selection:
    │
    ├─▶ ALARM/TROUBLE → critical_alarm_channel
    │   ├─▶ Importance.max
    │   ├─▶ Priority.high
    │   ├─▶ Full-screen Intent
    │   ├─▶ FLAG_INSISTENT + FLAG_NO_CLEAR
    │   └─▶ alarm_clock.ogg (loop)
    │
    ├─▶ DRILL → drill_channel
    │   ├─▶ Importance.high
    │   ├─▶ Priority.high
    │   ├─▶ Standard Notification
    │   └─▶ beep_short.ogg (once)
    │
    └─▶ SYSTEM RESET/ACKNOWLEDGE/SILENCE → status_update_channel
        ├─▶ Importance.low
        ├─▶ Priority.default
        ├─▶ Silent Notification
        └─▶ No Sound
    │
    ▼
Notification Display
    │
    ▼
User Interaction Handling
```

---

## 🎯 CRITICAL PATH ANALYSIS

### **Path 1: DRILL ACTITATION**
```
Time: 0ms     ┌─────────────────┐
             │ User Press DRILL│
             └─────────────────┘
Time: 100ms   ▼
             ┌─────────────────┐
             │ Confirmation    │
             │ Dialog          │
             └─────────────────┘
Time: 2000ms  ▼
             ┌─────────────────┐
             │ Local State     │
             │ Update          │
             └─────────────────┘
Time: 2100ms  ▼
             ┌─────────────────┐
             │ FCM Service     │
             │ HTTP POST       │
             └─────────────────┘
Time: 3000ms  ▼
             ┌─────────────────┐
             │ Cloud Function  │
             │ Processing      │
             └─────────────────┘
Time: 3500ms  ▼
             ┌─────────────────┐
             │ FCM Broadcast   │
             │ to All Devices  │
             └─────────────────┘
Time: 4000ms  ▼
             ┌─────────────────┐
             │ Background      │
             │ Handler         │
             └─────────────────┘
Time: 4100ms  ▼
             ┌─────────────────┐
             │ Notification +  │
             │ Audio           │
             └─────────────────┘
Time: 4200ms  ▼
             ┌─────────────────┐
             │ UI Update       │
             └─────────────────┘
```

### **Path 2: ALARM EVENT**
```
System Event → Firebase → FCM → Background Handler → Critical Notification → Wake Lock → Loop Audio
```

### **Path 3: USER ACKNOWLEDGE**
```
User Action → Local Audio Stop → FCM Broadcast → Other Devices Update → UI Sync
```

---

## 🔄 STATE MANAGEMENT FLOW

### **Global State Flow**
```
FireAlarmData (Provider)
    │
    ├─▶ System Status (Drill/Alarm/Trouble/Silenced/Disabled)
    ├─▶ Activity Logs
    ├─▶ Connection Status
    ├─▶ Project Info
    └─▶ User Info
         │
         ▼
Consumer Widgets (Home/Control/Monitoring)
    │
    ├─▶ Real-time UI Updates
    ├─▶ Status Indicators
    ├─▶ Activity Display
    └─▶ Control Buttons
         │
         ▼
LocalAudioManager
    │
    ├─▶ Audio State Sync
    ├─▶ Mute Status Management
    └─▶ Stream Broadcasting
         │
         ▼
EnhancedNotificationService
    │
    ├─▶ Notification Queue
    ├─▶ Debounce Logic
    └─▶ Channel Routing
```

---

## 🚨 ERROR RECOVERY FLOWS

### **Network Error Recovery**
```
FCM Send Failed
    │
    ▼
Retry Count Check (max 3)
    │
    ├─▶ Retry #1: 2s delay
    ├─▶ Retry #2: 4s delay
    └─▶ Retry #3: 6s delay
         │
         ▼
Local Fallback
    │
    ├─▶ Local Notification Only
    ├─▶ Audio Playback
    └─▶ State Update
```

### **Service Initialization Recovery**
```
Service Failed
    │
    ▼
Graceful Degradation
    │
    ├─▶ Continue without Firebase
    ├─▶ Local-only Mode
    ├─▶ User Notification
    └─▶ Retry on Next App Start
```

---

## 📱 PLATFORM-SPECIFIC FLOWS

### **Android Flow**
```
Notification Received
    │
    ▼
Channel Selection
    │
    ▼
Permission Check
    │
    ├─▶ POST_NOTIFICATIONS
    ├─▶ SYSTEM_ALERT_WINDOW
    └─▶ USE_FULL_SCREEN_INTENT
         │
         ▼
Notification Display
    │
    ├─▶ Full-screen Intent (Critical)
    ├─▶ Heads-up Notification (High)
    └─▶ Status Bar Notification (Low)
         │
         ▼
Audio Playback
    │
    ├─▶ Wake Lock Acquisition
    ├─▶ Audio Focus Management
    └─▶ Vibration Pattern
```

### **iOS Flow**
```
APNS Notification Received
    │
    ▼
Payload Processing
    │
    ├─▶ Sound File (.caf)
    ├─▶ Badge Number
    └─▶ Category
         │
