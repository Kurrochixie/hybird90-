# 🔨 BUILD GUIDE ANDROID APK

## 📋 Prerequisites

### Software yang Dibutuhkan:
- **Flutter SDK** (versi 3.9.2 atau lebih tinggi)
- **Android Studio** dengan SDK terinstall
- **Java JDK 11** atau lebih tinggi
- **Git** (optional)

### Setup Environment:
```bash
# Check Flutter installation
flutter doctor -v

# Check Android SDK
echo $ANDROID_HOME
```

## 🚀 Quick Build

### Build APK Debug (Untuk Testing)
```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Build debug APK
flutter build apk --debug
```

### Build APK Release (Untuk Distribusi)
```bash
# Clean project
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release
```

**Output**: `build/app/outputs/flutter-apk/app-release.apk`

## 📦 Build Commands Lengkap

### 1. Build APK (Untuk Manual Install)
```bash
# Standard release APK
flutter build apk --release

# Dengan split APK per ABI (lebih kecil)
flutter build apk --split-per-abi --release

# Tanpa tree shake icons (jika ada masalah icons)
flutter build apk --release --no-tree-shake-icons
```

### 2. Build App Bundle (Untuk Play Store)
```bash
# Build AAB untuk Google Play
flutter build appbundle --release
```

**Output**: `build/app/outputs/bundle/release/app-release.aab`

### 3. Build dengan Custom Signing
```bash
# Generate keystore dulu (jika belum ada)
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Build dengan keystore
flutter build apk --release --dart-define=FLUTTER_WEB_CANVASKIT_URL=https://www.gstatic.com/flutter-canvaskit/
```

## ⚙️ Konfigurasi Build

### File Konfigurasi Penting:
1. **`android/key.properties`** - Konfigurasi signing key
2. **`android/app/build.gradle.kts`** - Build configuration
3. **`pubspec.yaml`** - Dependencies dan app info

### Custom Application ID:
Edit `android/app/build.gradle.kts`:
```kotlin
defaultConfig {
    applicationId = "com.dds.firealarm"  // Ganti dengan package ID Anda
    versionCode = 1
    versionName = "1.0.0"
}
```

## 🔐 Signing Configuration

### Generate Production Keystore:
```bash
# Run generate_keystore.bat (Windows)
.\generate_keystore.bat

# Atau manual:
keytool -genkey -v \
  -keystore upload-keystore.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias upload \
  -storepass yourpassword \
  -keypass yourpassword \
  -dname "CN=DDS Fire Alarm, OU=Security, O=DDS Solutions, L=Jakarta, ST=Indonesia, C=ID"
```

### key.properties example:
```properties
storePassword=yourpassword
keyPassword=yourpassword
keyAlias=upload
storeFile=../upload-keystore.jks
```

## 📊 Build Variants

### Debug Build:
- ✅ Fast build time
- ✅ Debug symbols included
- ✅ Connected to Flutter DevTools
- ❌ Larger APK size
- ❌ Not optimized

### Release Build:
- ✅ Optimized code
- ✅ Smaller APK size
- ✅ Better performance
- ❌ Longer build time
- ❌ No debug symbols

## 🐛 Common Issues & Solutions

### Issue: "Keystore file not found"
**Solution**:
1. Generate keystore dengan `generate_keystore.bat`
2. Pastikan file `upload-keystore.jks` ada di root project
3. Check `android/key.properties` path

### Issue: "No matching client found for package name"
**Solution**:
1. Update `google-services.json` dari Firebase Console
2. Match application ID dengan Firebase project
3. Clean dan rebuild project

### Issue: "Kotlin daemon compilation failed"
**Solution**:
```bash
# Clear Kotlin daemon cache
cd android
./gradlew clean

# Atau kill Kotlin daemon
pkill -f kotlin

# Restart build
flutter clean
flutter pub get
flutter build apk --release
```

### Issue: Out of Memory
**Solution**:
Edit `android/gradle.properties`:
```properties
org.gradle.jvmargs=-Xmx4g -XX:MaxPermSize=512m
```

## 📱 Distribusi APK

### Via Email/Cloud Storage:
1. Upload APK ke Google Drive/Dropbox
2. Share link ke user
3. User download dan install

### Via Website:
1. Upload APK ke web server
2. Create QR code untuk link
3. User scan QR dan download

### Via ADB (Developer):
```bash
# Install ke connected device
adb install app-release.apk

# List installed packages
adb packages | grep dds

# Uninstall
adb uninstall com.example.flutter_application_1
```

## 📈 Build Optimization

### Reduce APK Size:
```bash
# Build split APK
flutter build apk --split-per-abi --release

# Enable shrinking di build.gradle
isMinifyEnabled = true
isShrinkResources = true
```

### Speed Up Build:
```bash
# Use build cache
export GRADLE_USER_HOME=$HOME/.gradle

# Parallel builds
export GRADLE_OPTS="-Dorg.gradle.parallel=true"

# Build cache configuration
org.gradle.caching=true
org.gradle.configureondemand=true
```

## 📱 Testing Checklist

Sebelum release:
- [ ] Test di multiple Android versions
- [ ] Test di different screen sizes
- [ ] Verify permissions
- [ ] Test Firebase connection
- [ ] Test offline functionality
- [ ] Check notification
- [ ] Verify memory usage
- [ ] Test install/uninstall

## 🚀 Deployment

### Google Play Store:
1. Build App Bundle: `flutter build appbundle --release`
2. Upload ke Google Play Console
3. Complete store listing
4. Submit for review

### Direct Distribution:
1. Build APK: `flutter build apk --release`
2. Sign APK (jika tidak auto-signed)
3. Distribusi via email, web, atau file sharing
4. Provide installation guide

---

**Tips**: Gunakan `flutter analyze` sebelum build untuk check error dan warning.