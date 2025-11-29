# Zone Data Parser Documentation

## 📋 Overview

Advanced Zone Data Parser untuk parsing data dari agent/fire alarm system dengan format protokol kustom.

## 🔧 Features

### Core Parsing Capabilities
- **Protocol Validation**: Memvalidasi struktur STX/ETX protocol
- **Checksum Validation**: XOR checksum validation untuk data integrity
- **Multi-device Parsing**: Support hingga 63 devices (01-63)
- **Status Recognition**: Otomatis deteksi tipe status device
- **Error Handling**: Comprehensive error handling dengan logging

### Device Status Types
- `online_normal`: Device online & normal
- `offline`: Device offline/tidak ada respons
- `trouble_detected`: Device mendeteksi trouble
- `active_with_alarm`: Device aktif dengan alarm
- `communication_error`: Error komunikasi dengan device

### Parsing Patterns Support
1. **ZONA OFF**: `XX` (2 digit address only)
2. **ZONA AKTIF**: `XXXXXX` (6 digit: address + 4 digit status)

## 📊 Protocol Specification

### Data Format
```
[ETX][CHECKSUM][STX][ADDR][STX][ADDR]...[ETX]
 0x02    4HEX   0x02   2HEX   ...   0x02   2HEX   0x03
```

### Control Characters
- `STX` (0x02): Start of Text marker
- `ETX` (0x03): End of Text marker

### Device Data Format
- **ZONA OFF**: `ADDR` (2 digit alamat)
- **ZONA AKTIF**: `ADDR` + `TROUBLE` (2 digit) + `ALARM` (2 digit)

### Status Hex Codes
- `00`: Normal/OK
- `01-FF`: Various status codes
- `85`: Trouble detected (example)
- `FF`: All alarms active

## 🔍 Usage Examples

### Basic Usage
```dart
import '../services/zone_data_parser.dart';

// Parse raw data string
String rawData = '\x02\x0340DF\x01\x02\x03\x04\x05';
ZoneParsingResult result = ZoneDataParser.parseRawData(rawData);

// Check parsing result
if (result.devices.isNotEmpty) {
  print('Parsed ${result.deviceCount} devices');
  print('System status: ${result.status}');

  for (var device in result.devices) {
    print('Device ${device.address}: ${device.statusDescription}');
  }
}
```

### Advanced Usage with Training Data
```dart
// Generate training examples
ZoneParserExamples.runAllExamples();

// Custom parsing with validation
ZoneParsingResult result = ZoneDataParser.parseRawData(userData);

if (result.cycleType == 'health_check') {
  // Handle health check cycle
  _handleHealthCheck(result);
} else if (result.cycleType == 'status_report') {
  // Handle status report cycle
  _handleStatusReport(result);
}
```

## 🚨 Error Handling

### Parsing Errors
- `INVALID_STRUCTURE`: Data structure tidak valid
- `CHECKSUM_ERROR`: Checksum extraction failed
- `CHECKSUM_MISMATCH`: Checksum validation failed
- `NO_DEVICE_DATA`: Tidak ada data device
- `PARSING_ERROR`: Error saat parsing

### Validation Levels
- **Checksum Validation**: XOR checksum untuk setiap device
- **Structure Validation**: Validasi STX/ETX markers
- **Range Validation**: Validasi range alamat (01-63)

## 📈 Performance Considerations

### Optimizations
1. **Efficient Parsing**: Single-pass parsing algorithm
2. **Memory Management**: Minimal object creation
3. **Error Recovery**: Fast failure recovery
4. **Logging**: Comprehensive debug logging

### Best Practices
```dart
// Batch processing untuk multiple data
class ZoneBatchProcessor {
  final List<String> rawBuffer = [];

  void processBatch() {
    for (String data in rawBuffer) {
      final result = ZoneDataParser.parseRawData(data);
      _handleResult(result);
    }
    rawBuffer.clear();
  }
}
```

## 🔧 Integration Guide

### Firebase Integration
```dart
// Listen untuk data zona dari Firebase
FirebaseDatabase.instance.ref('agent/zone_data').onValue.listen((event) {
  final data = event.snapshot.value?.toString();
  if (data != null) {
    final result = ZoneDataParser.parseRawData(data);
    _updateUIWithResult(result);
  }
});
```

### Real-time Processing
```dart
StreamSubscription<ZoneParsingResult> _zoneStream;

void startZoneMonitoring() {
  _zoneStream = FirebaseSafetyHelper.listenToValue(
    FirebaseDatabase.instance.ref('agent/zone_data'),
    onData: (data) {
      if (data != null) {
        final result = ZoneDataParser.parseRawData(data['raw_data'] ?? '');
        _processZoneResult(result);
      }
    },
    tag: 'ZONE_MONITORING',
  );
}
```

## 📱 UI Integration

### Device Status Display
```dart
Widget buildDeviceStatus(ZoneDevice device) {
  return Container(
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: device.statusColor.withOpacity(0.1),
      border: Border.all(color: device.statusColor),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Text('Zone ${device.address}', style: TextStyle(fontWeight: FontWeight.bold)),
        Text(device.statusDescription),
        if (device.isActive)
          Icon(Icons.circle, color: device.statusColor, size: 12),
      ],
    ),
  );
}
```

### System Status Overview
```dart
Widget buildSystemStatus(ZoneParsingResult result) {
  return Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.dns, color: _getStatusColor(result.status)),
              SizedBox(width: 8),
              Text('System Status: ${result.statusDescription}'),
            ],
          ),
          SizedBox(height: 8),
          Text('Devices: ${result.deviceCount}/63'),
          Text('Range: ${result.deviceRange ?? "Unknown"}'),
          if (result.deviceRange != null)
            Text('Checksum: ${result.checksum}'),
        ],
      ),
    ),
  );
}
```

## ⚠️ Troubleshooting

### Common Issues
1. **Checksum Mismatch**
   - Cause: Data corruption atau transmission error
   - Solution: Request data ulang dari agent

2. **Invalid Structure**
   - Cause: Protocol violation
   - Solution: Periksa format data dari agent

3. **Parse Errors**
   - Cause: Unexpected data format
   - Solution: Validasi input data sebelum parsing

### Debug Logging
```dart
// Enable verbose logging
ZoneDataParser.parseRawData(rawData);

// Check individual components
final checksum = ZoneDataParser._extractChecksum(rawData);
final deviceData = ZoneDataParser._extractDeviceData(rawData);
print('Debug: Checksum=$checksum, DeviceData=$deviceData');
```

## 📚 Dependencies

### Required
- `dart:convert` - Untuk encoding/decoding
- `flutter/material.dart` - Untuk UI components

### Optional
- `firebase_database` - Untuk Firebase integration
- Provider package - Untuk state management

## 🔄 Version History

### v1.0.0 - Initial Release
- Basic protocol parsing
- Checksum validation
- Multi-device support

### v1.1.0 - Enhanced Features
- Improved error handling
- Training data generation
- Performance optimizations

## 📄 License

Internal use only - Property of [Your Company Name]

---

**Note**: Parser ini dirancang khusus untuk protocol zona kustom. Sesuaikan implementasi dengan spesifikasi protokol aktual dari agent/fire alarm system Anda.