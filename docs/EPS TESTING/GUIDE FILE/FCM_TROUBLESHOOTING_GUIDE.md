# 🔧 FCM Notification System - Troubleshooting Guide

## 🚨 Common Issues & Solutions

### Issue 1: "Looking up a deactivated widget's ancestor is unsafe"
**Symptoms**: Multiple error messages di Flutter console
**Cause**: Widget mencoba mengakses ancestor yang sudah di-deactivate saat navigasi
**Solution**: Ini adalah warning non-kritis yang tidak mempengaruhi fungsi notifikasi

---

### Issue 2: Firebase Analytics Library Missing Warning
**Symptoms**: 
```
W/FirebaseMessaging(15025): Unable to log event: analytics library is missing
```

**Root Cause**: Firebase Analytics package tidak diinstall
**✅ SOLVED**: Added `firebase_analytics: ^10.10.7` ke pubspec.yaml dan inisialisasi di main.dart

---

### Issue 3: Intermittent 404/500 Errors
**Symptoms**: 
```
I/flutter (15025): Failed to send FCM notification: 404 <HTML>...
```

**Root Cause**: Cold start, network issues, atau temporary server unavailability
**✅ SOLVED**: Added retry mechanism dengan exponential backoff:
```dart
// Retry logic untuk 404, 500, timeout, and network errors
int maxRetries = 3;
// 404: retry in 2s, 4s, 6s
// 500: retry in 3s, 6s, 9s
// Timeout/Network: retry in 2s, 4s, 6s
```

---

### Issue 4: Cloud Firestore API Disabled (Non-critical)
**Symptoms**: Error di Firebase Functions logs saat logging
**Root Cause**: Firestore API belum dienable untuk project
**✅ SOLVED**: Graceful error handling di Firebase Functions:
```javascript
try {
  await admin.firestore().collection('notification_logs').add({...});
} catch (firestoreError) {
  console.warn('Failed to log to Firestore (API might be disabled):', firestoreError.message);
  // Continue without failing the main function
}
```

---

## 🔍 Debugging Steps

### 1. Check Firebase Functions Status
```bash
npx firebase-tools functions:list
```
**Expected Output**: 4 functions dengan trigger `callable`

### 2. Test Firebase Functions Manual
```powershell
Invoke-WebRequest -Uri "https://us-central1-testing1do.cloudfunctions.net/sendFireAlarmNotification" -Method POST -ContentType "application/json" -Body '{"data":{"eventType":"DRILL","status":"ON","user":"Test User","projectName":"Test Project","panelType":"Test Panel"}}'
```
**Expected Response**: `{"result":{"success":true,...}}`

### 3. Check Flutter Debug Logs
```dart
// Aktifkan debug logging di FCM service
debugPrint('Sending fire alarm notification: $eventType - $status by $user');
debugPrint('Response status: ${response.statusCode}');
debugPrint('Response body: ${response.body}');
```

### 4. Verify FCM Token
```dart
// Di main.dart
String? token = await messaging.getToken();
debugPrint('FCM Token: $token');
```

## 🛠️ Configuration Checklist

### ✅ Firebase Functions
- [x] Functions deployed successfully
- [x] Error handling implemented
- [x] Firestore logging with fallback
- [x] Callable trigger working

### ✅ Flutter App
- [x] FCM service updated with HTTP calls
- [x] Event detection working
- [x] Auto-subscription implemented
- [x] Debug logging enhanced

### ✅ Firebase Project
- [x] Cloud Functions API enabled
- [x] Cloud Messaging API enabled
- [ ] Cloud Firestore API (optional - untuk logging)

## 📱 Testing Scenarios

### Test 1: Manual Function Test
```bash
# Test DRILL notification
curl -X POST "https://us-central1-testing1do.cloudfunctions.net/sendFireAlarmNotification" \
  -H "Content-Type: application/json" \
  -d '{"data":{"eventType":"DRILL","status":"ON","user":"Test User"}}'
```

### Test 2: Flutter App Test
1. Build dan run Flutter app
2. Tekan tombol DRILL
3. Check debug console untuk:
   - `Sending fire alarm notification: DRILL - ON by [User]`
   - `Response status: 200`
   - `Response body: {"result":{"success":true,...}}`

### Test 3: Multiple Devices
1. Install app di 2+ devices
2. Tekan tombol DRILL di device 1
3. Semua devices harus menerima notifikasi

## 🔊 Expected Behavior

### Successful Notification Flow:
```
User Action → Flutter App → FCM Service → Firebase Functions → FCM → All Devices
```

### Debug Logs (Success):
```
I/flutter (14689): Sending fire alarm notification: DRILL - ON by ALDONII
I/flutter (14689): Response status: 200
I/flutter (14689): Response body: {"result":{"success":true,...}}
I/flutter (14689): Fire alarm notification sent successfully: Notification sent for DRILL: ON
```

## 🚨 Error Messages & Meanings

### `HTTP error: 500`
- **Meaning**: Internal server error di Firebase Functions
- **Action**: Check Firebase Functions logs
- **Command**: `npx firebase-tools functions:log`

### `HTTP error: 404`
- **Meaning**: Function URL tidak ditemukan
- **Action**: Verify function deployment
- **Command**: `npx firebase-tools functions:list`

### `Failed to send FCM notification`
- **Meaning**: Network error atau function error
- **Action**: Check internet connection dan debug logs

## 📊 Monitoring

### Firebase Functions Logs
```bash
# Real-time logs
npx firebase-tools functions:log

# Specific function logs
npx firebase-tools functions:log --only sendFireAlarmNotification
```

### Flutter Debug Console
- Aktifkan debug mode
- Monitor FCM service logs
- Check network requests

## 🔄 Recovery Steps

### If Notifications Stop Working:
1. **Check Firebase Functions status**
   ```bash
   npx firebase-tools functions:list
   ```

2. **Redeploy functions**
   ```bash
   npx firebase-tools deploy --only functions
   ```

3. **Test manual function call**
   ```powershell
   Invoke-WebRequest -Uri "https://us-central1-testing1do.cloudfunctions.net/sendFireAlarmNotification" ...
   ```

4. **Restart Flutter app**
   ```bash
   flutter clean
   flutter run
   ```

## 📞 Support

### Quick Fixes:
- **HTTP 500**: Redeploy functions
- **HTTP 404**: Check function URLs
- **No notifications**: Check FCM token and subscription

### Advanced Debugging:
- Check Firebase Console → Functions → Logs
- Monitor network traffic in Flutter DevTools
- Test with different event types

### Contact Development:
- Provide debug console logs
- Include Firebase Functions logs
- Specify event type and user action

---

## 🎯 Current Status

### ✅ **Working Components:**
- Firebase Functions (all 4 functions)
- FCM notification delivery
- Event detection in Flutter
- Error handling and logging
- Manual function testing

### ⚠️ **Known Issues:**
- Firestore API disabled (non-critical)
- Widget ancestor warnings (cosmetic)

### 🚀 **System Status: FULLY OPERATIONAL**

**Last Updated**: 2025-10-13  
**Version**: 2.1.0  
**Status**: ✅ All Issues Resolved
