# Panduan Integrasi ESP32 Bridge dengan Aplikasi Flutter

## Overview
Panduan ini menjelaskan cara mengintegrasikan ESP32 Bridge dengan aplikasi Flutter yang sudah Anda miliki untuk menampilkan data real-time dari master device.

## File yang Telah Dibuat

### 1. **lib/esp32_bridge_service.dart** - Service untuk Firebase
Service yang menghandle semua komunikasi dengan Firebase Realtime Database:
- Real-time listeners untuk sensor data, alarm, status, dan logs
- Auto-reconnection dan error handling
- Methods untuk mengambil data spesifik
- Command sending ke ESP32 (jika diperlukan)

### 2. **lib/esp32_bridge_page.dart** - Halaman Monitoring UI
Halaman Flutter lengkap untuk monitoring ESP32 Bridge:
- Real-time data display
- Alarm notifications
- System logs viewer
- Device status monitoring
- Manual command sending

## Langkah Integrasi

### 1. Update pubspec.yaml
Pastikan dependencies berikut ada di pubspec.yaml:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.24.2
  firebase_database: ^10.4.0
  firebase_auth: ^4.15.3
```

### 2. Update Firebase Configuration
Pastikan Firebase sudah dikonfigurasi di aplikasi Flutter Anda:
- `android/app/google-services.json` sudah ada
- `ios/Runner/GoogleService-Info.plist` sudah ada (untuk iOS)
- Firebase initialization di main.dart

### 3. Initialize Service di Main App
Tambahkan initialization di main.dart atau di tempat yang sesuai:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'esp32_bridge_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Initialize ESP32 Bridge Service
  final bridgeService = ESP32BridgeService();
  await bridgeService.initialize();
  
  runApp(MyApp());
}
```

### 4. Tambahkan ke Navigation
Tambahkan ESP32BridgePage ke navigation Anda:

```dart
import 'esp32_bridge_page.dart';

// Di dalam widget Anda
MaterialApp(
  home: MyHomePage(),
  routes: {
    '/esp32_bridge': (context) => ESP32BridgePage(),
  },
)

// Atau sebagai drawer item
Drawer(
  child: ListView(
    children: [
      ListTile(
        title: Text('ESP32 Bridge'),
        leading: Icon(Icons.device_hub),
        onTap: () {
          Navigator.pushNamed(context, '/esp32_bridge');
        },
      ),
      // Menu items lainnya
    ],
  ),
)
```

### 5. Customization untuk Aplikasi Anda

#### A. Integrasi dengan Halaman Home Anda
Anda bisa menambahkan widget mini monitoring di halaman home:

```dart
class ESP32BridgeStatusWidget extends StatelessWidget {
  final ESP32BridgeService _bridgeService = ESP32BridgeService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _bridgeService.deviceStatusStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Connecting to ESP32 Bridge...'),
            ),
          );
        }

        final status = snapshot.data!;
        return Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.device_hub, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('ESP32 Bridge Status', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                Text('Status: ${status['status'] ?? 'Unknown'}'),
                Text('Last Update: ${_formatTime(status['timestamp'])}'),
                if (status['wifiSignal'] != null)
                  Text('WiFi: ${status['wifiSignal']} dBm'),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
```

#### B. Alarm Notification Integration
Tambahkan alarm handling ke notification service yang sudah ada:

```dart
class ESP32AlarmHandler {
  static final ESP32BridgeService _bridgeService = ESP32BridgeService();

  static void initialize() {
    // Listen untuk alarm aktif
    _bridgeService.alarmDataStream.listen((alarmData) {
      alarmData.forEach((key, value) {
        if (value['isActive'] == true) {
          _handleActiveAlarm(key, Map<String, dynamic>.from(value));
        }
      });
    });
  }

  static void _handleActiveAlarm(String alarmType, Map<String, dynamic> alarmData) {
    final zone = alarmData['zone'] ?? 'Unknown';
    final message = '🚨 ALARM AKTIF: $alarmType di $zone';
    
    // Trigger notification yang sudah ada
    // Gunakan notification service yang sudah Anda punya
    NotificationService.showAlarmNotification(
      title: 'Fire Alarm System',
      body: message,
      alarmType: alarmType,
      zone: zone,
    );
  }
}
```

#### C. Data Integration dengan Fire Alarm Data
Integrasikan dengan fire_alarm_data.dart yang sudah ada:

```dart
// Di fire_alarm_data.dart, tambahkan method untuk mengambil data dari ESP32
class FireAlarmData {
  static final ESP32BridgeService _bridgeService = ESP32BridgeService();

  static Stream<Map<String, dynamic>> getESP32SensorData() {
    return _bridgeService.sensorDataStream;
  }

  static Stream<Map<String, dynamic>> getESP32AlarmData() {
    return _bridgeService.alarmDataStream;
  }

  // Method untuk mengconvert data ESP32 ke format FireAlarmData
  static List<FireAlarmData> convertFromESP32Data(Map<String, dynamic> esp32Data) {
    List<FireAlarmData> result = [];
    
    esp32Data.forEach((key, value) {
      if (value is Map && value['isActive'] == true) {
        result.add(FireAlarmData(
          zone: value['zone'] ?? key,
          alarmType: value['alarmType'] ?? key,
          timestamp: DateTime.tryParse(value['timestamp']) ?? DateTime.now(),
          isActive: true,
        ));
      }
    });
    
    return result;
  }
}
```

## Struktur Data di Firebase

### 1. Sensor Data
```
/devices/ESP32_Bridge_001/sensors/temperature/
{
  "deviceId": "ESP32_Bridge_001",
  "sensorType": "temperature",
  "value": 25.5,
  "unit": "Celsius",
  "location": "room1",
  "timestamp": "2025-10-14T15:30:00"
}
```

### 2. Alarm Data
```
/devices/ESP32_Bridge_001/alarms/fire/
{
  "deviceId": "ESP32_Bridge_001",
  "alarmType": "fire",
  "zone": "zone1",
  "isActive": true,
  "severity": "high",
  "timestamp": "2025-10-14T15:30:00"
}
```

### 3. Device Status
```
/status/ESP32_Bridge_001/
{
  "deviceId": "ESP32_Bridge_001",
  "status": "online",
  "message": "Heartbeat - listening for master data",
  "dataCount": 1234,
  "lastData": "TEMP:25.5,HUM:65.2",
  "wifiSignal": -45,
  "freeHeap": 234567,
  "timestamp": "2025-10-14T15:30:00"
}
```

### 4. System Logs
```
/logs/ESP32_Bridge_001/1728901800000/
{
  "deviceId": "ESP32_Bridge_001",
  "level": "info",
  "message": "Master data: TEMP:25.5,HUM:65.2",
  "timestamp": "2025-10-14T15:30:00"
}
```

## Testing Integration

### 1. Test dengan Data Mock
Untuk testing tanpa ESP32, Anda bisa tambahkan data mock ke Firebase:

```javascript
// Di Firebase Console -> Realtime Database
{
  "devices": {
    "ESP32_Bridge_001": {
      "sensors": {
        "temperature": {
          "deviceId": "ESP32_Bridge_001",
          "sensorType": "temperature",
          "value": 25.5,
          "unit": "Celsius",
          "timestamp": "2025-10-14T15:30:00"
        }
      },
      "alarms": {
        "test_alarm": {
          "deviceId": "ESP32_Bridge_001",
          "alarmType": "test",
          "zone": "test_zone",
          "isActive": false,
          "timestamp": "2025-10-14T15:30:00"
        }
      }
    }
  },
  "status": {
    "ESP32_Bridge_001": {
      "deviceId": "ESP32_Bridge_001",
      "status": "online",
      "message": "Test status",
      "timestamp": "2025-10-14T15:30:00"
    }
  }
}
```

### 2. Test Real-time Updates
1. Buka aplikasi Flutter
2. Buka Firebase Console
3. Ubah data secara manual
4. Pastikan UI terupdate otomatis

### 3. Test Alarm Notifications
1. Set alarm `isActive: true` di Firebase
2. Pastikan notification muncul di aplikasi
3. Test dengan berbagai tipe alarm

## Troubleshooting

### 1. Firebase Connection Issues
- Pastikan google-services.json sudah benar
- Cek Firebase project settings
- Verify database rules

### 2. Real-time Updates Not Working
- Pastikan internet connection stable
- Cek Firebase database URL di service
- Verify stream listeners properly initialized

### 3. Data Format Issues
- Pastikan data structure sesuai dengan yang diharapkan
- Cek data parsing di service
- Validate JSON format

### 4. Performance Issues
- Implement proper stream cancellation
- Limit data queries dengan `.limitToLast()`
- Use efficient widget rebuilding

## Best Practices

### 1. Error Handling
```dart
try {
  await _bridgeService.initialize();
} catch (e) {
  // Handle error gracefully
  print('Failed to initialize ESP32 Bridge: $e');
  // Show user-friendly error message
}
```

### 2. Resource Management
```dart
@override
void dispose() {
  _sensorSubscription?.cancel();
  _alarmSubscription?.cancel();
  _statusSubscription?.cancel();
  _logsSubscription?.cancel();
  super.dispose();
}
```

### 3. UI Updates
```dart
if (mounted) {
  setState(() {
    // Update UI state
  });
}
```

### 4. Data Validation
```dart
if (data is Map && data['value'] != null) {
  // Process valid data
} else {
  // Handle invalid data
  print('Invalid sensor data received');
}
```

## Next Steps

1. **Customize UI** - Sesuaikan tampilan dengan design aplikasi Anda
2. **Add Features** - Tambahkan fitur spesifik sesuai kebutuhan
3. **Integration Testing** - Test dengan ESP32 hardware
4. **Performance Optimization** - Optimasi untuk production
5. **Security** - Implement authentication dan authorization

---

**Catatan:** Pastikan untuk mengubah device ID di ESP32BridgeService jika menggunakan device ID yang berbeda dari "ESP32_Bridge_001".
