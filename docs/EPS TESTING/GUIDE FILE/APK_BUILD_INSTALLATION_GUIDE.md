# APK Build and Installation Guide - Flutter Fire Alarm Monitoring

## Overview
This guide provides step-by-step instructions for building and installing the APK for the Flutter Fire Alarm Monitoring application with unified status bar and enhanced NO DATA detection.

## Prerequisites

### Required Software:
1. **Flutter SDK** (version 3.0 or higher)
2. **Android Studio** (version 4.0 or higher) OR Android SDK Command Line Tools
3. **Java Development Kit (JDK)** (version 11 or higher)
4. **Android SDK** (version 33 or higher)
5. **Physical Android device** OR **Android Emulator** for testing

### Environment Setup:
```bash
# Check Flutter version
flutter --version

# Check Android dependencies
flutter doctor

# Check connected devices
flutter devices
```

## APK Build Process

### 1. Clean Build Environment
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get
```

### 2. Build APK for Release

#### Option A: Build APK for All Architectures
```bash
# Build release APK for all architectures
flutter build apk --release
```

#### Option B: Build APK for Specific Architecture
```bash
# Build for ARM64 (most common)
flutter build apk --release --target-platform android-arm64

# Build for ARM32
flutter build apk --release --target-platform android-arm

# Build for x86_64 (emulators)
flutter build apk --release --target-platform android-x64
```

#### Option C: Build App Bundle (Recommended for Play Store)
```bash
# Build App Bundle for Play Store upload
flutter build appbundle --release
```

### 3. Locate Built APK
After successful build, APK files will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

App Bundle files (if built) will be at:
```
build/app/outputs/bundle/release/app-release.aab
```

## APK Installation

### Method 1: Install via ADB (Recommended for Development)

#### Step 1: Enable Developer Options on Android Device
1. Go to **Settings** → **About phone**
2. Tap **Build number** 7 times to enable Developer options
3. Go back to **Settings** → **System** → **Developer options**
4. Enable **USB debugging** and **Install via USB**

#### Step 2: Install APK
```bash
# Install APK on connected device
adb install build/app/outputs/flutter-apk/app-release.apk

# Install with debugging enabled (for development)
adb install -d build/app/outputs/flutter-apk/app-release.apk

# Uninstall previous version first (if needed)
adb uninstall com.example.flutter_application_1
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Method 2: Install via File Transfer

#### Step 1: Transfer APK to Device
- **USB Cable**: Copy APK to device storage
- **Email**: Send APK as attachment
- **Cloud Storage**: Upload to Google Drive/Dropbox
- **Wireless Transfer**: Use apps like ShareIt or Xender

#### Step 2: Install on Android Device
1. Open **File Manager** on Android device
2. Navigate to where APK is saved
3. Tap the APK file
4. If prompted, enable **Install from unknown sources**
5. Tap **Install** and follow prompts

## Application Configuration

### 1. Firebase Configuration
The application requires Firebase configuration. Ensure the following Firebase settings are properly configured:

#### Required Firebase Services:
- **Realtime Database** - For ESP32 data synchronization
- **Authentication** - For user login/logout
- **Cloud Messaging (FCM)** - For push notifications

#### Firebase Configuration Files:
- `google-services.json` - Android configuration
- `firebase.json` - Web configuration (if needed)

### 2. Android Permissions
The application requires the following permissions (automatically included in build):

```xml
<!-- AndroidManifest.xml permissions -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### 3. Network Configuration
Ensure the device has network connectivity for Firebase synchronization:
- **WiFi** - Recommended for stable connection
- **Mobile Data** - Alternative for remote access

## Testing the Installation

### 1. Basic Functionality Tests
- ✅ Application launches successfully
- ✅ Login/logout functionality works
- ✅ Navigation between tabs works
- ✅ Status bar displays correctly

### 2. Status Bar Tests
- ✅ Shows "NO DATA" when no ESP32 data is available
- ✅ Shows "SYSTEM NORMAL" when valid data is received
- ✅ Updates status in real-time with ESP32 data changes
- ✅ Responsive design works on different screen sizes

### 3. ESP32 Integration Tests
- ✅ Firebase connection status displays
- ✅ Zone monitoring works correctly
- ✅ Alarm/trouble detection functions
- ✅ Real-time updates from ESP32 devices

### 4. Notification Tests
- ✅ Push notifications work (if configured)
- ✅ Local notifications display
- ✅ Sound notifications play correctly

## Troubleshooting

### Common Issues and Solutions

#### 1. Installation Failed
**Problem**: "App not installed" or "Parse error"
**Solution**:
- Check if APK is corrupted (download again)
- Ensure sufficient storage space on device
- Try uninstalling previous version first
- Check Android version compatibility

#### 2. Firebase Connection Failed
**Problem**: "DISCONNECTED" status or no data synchronization
**Solution**:
- Verify internet connection
- Check Firebase configuration in `google-services.json`
- Ensure Firebase project is active
- Check Firebase security rules

#### 3. NO DATA Status Persistent
**Problem**: Always shows "NO DATA" even when ESP32 is connected
**Solution**:
- Verify ESP32 device is sending data to Firebase
- Check Firebase database structure
- Ensure `esp32_bridge/data/parsed_packet` path exists
- Validate ESP32 data format

#### 4. Application Crashes
**Problem**: App crashes on startup or during use
**Solution**:
- Check device logs using `adb logcat`
- Verify all required permissions are granted
- Check Firebase configuration
- Try clearing app data and cache

### 2. Advanced Troubleshooting

#### Generate Bug Report
```bash
# Collect logs from device
adb logcat -d > bug_report.log

# Get device information
adb devices

# Get app version information
adb shell dumpsys package com.example.flutter_application_1
```

#### Debug APK Build
```bash
# Build debug APK for testing
flutter build apk --debug

# Install debug APK
adb install build/app/outputs/flutter-apk/app-debug.apk
```

## Production Deployment

### 1. Play Store Deployment (Recommended)
1. **Build App Bundle**:
   ```bash
   flutter build appbundle --release
   ```

2. **Upload to Google Play Console**:
   - Create new application or update existing
   - Upload `app-release.aab` file
   - Fill in store listing information
   - Set pricing and distribution
   - Submit for review

### 2. Direct APK Distribution
1. **Host APK on website/server**
2. **Provide download link to users**
3. **Include installation instructions**
4. **Ensure version compatibility**

## Version Management

### 1. Version Number Configuration
Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

### 2. Build Number Configuration
Update build number in `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        versionCode: 2
        versionName: "1.0.1"
    }
}
```

### 3. Release Notes Template
```
## Version 1.0.0 - [Date]

### New Features:
- Unified status bar implementation
- Enhanced NO DATA detection
- Real-time ESP32 zone monitoring
- Responsive design improvements

### Bug Fixes:
- Fixed inconsistent status bar across pages
- Resolved default status behavior issues
- Improved data validation logic

### Improvements:
- Enhanced user interface consistency
- Optimized performance
- Improved error handling
```

## Security Considerations

### 1. APK Security
- **Sign APK**: Use release keystore for production builds
- **Obfuscate Code**: Enable code obfuscation for release builds
- **Remove Debug Information**: Ensure no debug symbols in release

### 2. Data Security
- **Firebase Security Rules**: Implement proper database security
- **API Keys**: Store sensitive keys securely
- **User Authentication**: Implement proper user authentication

### 3. Network Security
- **HTTPS**: Ensure all network communications use HTTPS
- **Certificate Pinning**: Implement certificate pinning if needed
- **Data Encryption**: Encrypt sensitive data in transit

## Performance Optimization

### 1. APK Size Optimization
```bash
# Analyze APK size
flutter build apk --analyze-size

# Reduce APK size if needed
# - Use --split-debug-info for debug builds
# - Optimize images and assets
# - Remove unused dependencies
```

### 2. Performance Monitoring
- **Firebase Performance Monitoring**: Integrate for production monitoring
- **Crashlytics**: Set up crash reporting
- **Analytics**: Track user behavior and app performance

## Maintenance and Updates

### 1. Regular Updates
- **Monthly**: Security patches and bug fixes
- **Quarterly**: New features and improvements
- **Annually**: Major version updates

### 2. Monitoring
- **Firebase Analytics**: Monitor user engagement
- **Crash Reports**: Track and fix crashes
- **Performance Metrics**: Monitor app performance

### 3. User Support
- **Documentation**: Maintain up-to-date user guides
- **Support Channel**: Provide user support contact
- **Feedback Collection**: Collect and respond to user feedback

## Conclusion

This comprehensive guide covers the complete process of building, installing, and maintaining the Flutter Fire Alarm Monitoring application. The unified status bar system with enhanced NO DATA detection ensures reliable operation and accurate status reporting across all deployment scenarios.

For technical support or questions, refer to the project documentation or contact the development team.

---

**Last Updated**: October 16, 2025  
**Version**: 1.0.0  
**Status**: ✅ Production Ready
