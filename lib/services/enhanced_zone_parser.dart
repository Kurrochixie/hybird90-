import 'package:flutter/foundation.dart';
import '../models/zone_status.dart';
import '../utils/checksum_utils.dart';
import '../utils/background_parser.dart';

/// Enhanced model untuk 63 devices dengan 5 zones per device
class EnhancedDevice {
  final String address;
  final bool isConnected;
  final List<ZoneStatus> zones; // 5 zones per device
  final DeviceStatus deviceStatus;
  final DateTime timestamp;

  EnhancedDevice({
    required this.address,
    required this.isConnected,
    required this.zones,
    required this.deviceStatus,
    required this.timestamp,
  });

  factory EnhancedDevice.fromJson(Map<String, dynamic> json) {
    return EnhancedDevice(
      address: json['address'] ?? '',
      isConnected: json['isConnected'] ?? false,
      zones: (json['zones'] as List<dynamic>?)
          ?.map((zone) => ZoneStatus.fromJson(zone))
          .toList() ?? [],
      deviceStatus: DeviceStatus.fromJson(json['deviceStatus'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'isConnected': isConnected,
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'deviceStatus': deviceStatus.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get total active zones across all devices
  int get totalActiveZones {
    return zones.where((zone) => zone.isActive).length;
  }

  /// Get trouble zones
  List<ZoneStatus> get troubleZones {
    return zones.where((zone) => zone.hasTrouble).toList();
  }

  /// Get alarm zones
  List<ZoneStatus> get alarmZones {
    return zones.where((zone) => zone.hasAlarm).toList();
  }
}


/// Device status overall
class DeviceStatus {
  final bool hasPower;
  final bool hasTrouble;
  final bool hasAlarm;
  final bool outputBellActive;
  final String? lastError;

  DeviceStatus({
    required this.hasPower,
    required this.hasTrouble,
    required this.hasAlarm,
    this.outputBellActive = false,
    this.lastError,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      hasPower: json['hasPower'] ?? false,
      hasTrouble: json['hasTrouble'] ?? false,
      hasAlarm: json['hasAlarm'] ?? false,
      outputBellActive: json['outputBellActive'] ?? false,
      lastError: json['lastError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasPower': hasPower,
      'hasTrouble': hasTrouble,
      'hasAlarm': hasAlarm,
      'outputBellActive': outputBellActive,
      'lastError': lastError,
    };
  }
}

/// Master control signal data
class MasterControlSignal {
  final String signal;
  final String checksum;
  final DateTime timestamp;
  final ControlSignalType type;

  MasterControlSignal({
    required this.signal,
    required this.checksum,
    required this.timestamp,
    this.type = ControlSignalType.unknown,
  });

  factory MasterControlSignal.fromJson(Map<String, dynamic> json) {
    return MasterControlSignal(
      signal: json['signal'] ?? '',
      checksum: json['checksum'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: MasterControlSignal._parseControlType(json['signal']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signal': signal,
      'checksum': checksum,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
    };
  }

  static ControlSignalType _parseControlType(String? signal) {
    if (signal == null) return ControlSignalType.unknown;

    switch (signal) {
      case '4037':
        return ControlSignalType.buzzerControl;
      case '4038':
        return ControlSignalType.backlightControl;
      case '4039':
        return ControlSignalType.lcdControl;
      case '403A':
        return ControlSignalType.systemReset;
      default:
        return ControlSignalType.unknown;
    }
  }
}

/// Control signal types
enum ControlSignalType {
  buzzerControl,
  backlightControl,
  lcdControl,
  systemReset,
  unknown,
}

/// Enhanced parsing result untuk 63 devices
class EnhancedParsingResult {
  final String cycleType;
  final String checksum;
  final String status;
  final int totalDevices;
  final int connectedDevices;
  final int disconnectedDevices;
  final List<EnhancedDevice> devices;
  final MasterControlSignal? masterSignal;
  final Map<String, dynamic> rawData;
  final DateTime timestamp;

  EnhancedParsingResult({
    required this.cycleType,
    required this.checksum,
    required this.status,
    required this.totalDevices,
    required this.connectedDevices,
    required this.disconnectedDevices,
    required this.devices,
    this.masterSignal,
    required this.rawData,
    required this.timestamp,
  });

  /// Get total active zones across all devices
  int get totalActiveZones {
    return devices.fold(0, (total, device) => total + device.totalActiveZones);
  }

  /// Get total trouble zones
  int get totalTroubleZones {
    return devices.fold(0, (total, device) => total + device.troubleZones.length);
  }

  /// Get total alarm zones
  int get totalAlarmZones {
    return devices.fold(0, (total, device) => total + device.alarmZones.length);
  }

  /// Get severity level
  int get severityLevel {
    switch (status.toLowerCase()) {
      case 'all_slaves_connected_normal':
        return 0; // Normal
      case 'partial_connection_with_alarm':
        return 3; // High
      case 'partial_connection_disconnected':
        return 2; // Medium
      case 'all_slaves_disconnected':
        return 4; // Critical
      default:
        return 1; // Low
    }
  }
}

/// Master control signal types
enum MasterControlType {
  resetSystem,
  activateAlarm,
  deactivateAlarm,
  silenceAlarm,
  systemTest,
  unknown,
}

// ============= BACKGROUND PROCESSING FUNCTIONS =============
// NOTE: _parseCompleteDataStreamInBackground removed - unused method

/// Synchronous version of complete data stream parsing for compute
EnhancedParsingResult _parseCompleteDataStreamSync(String rawData) {
  try {
    

    // Step 1: Validate basic structure
    if (!_validateBasicStructureSync(rawData)) {
      
      return _createErrorResultSync('INVALID_STRUCTURE', 'Invalid data structure');
    }

    // Step 2: Extract messages
    final messages = _extractMessagesSync(rawData);

    if (messages.isEmpty) {
      
      return _createErrorResultSync('NO_MESSAGES', 'No valid messages found');
    }

    // Step 3: Process all messages
    EnhancedParsingResult? lastResult;
    List<EnhancedDevice> allDevices = [];

    for (String message in messages) {
      final result = _parseSingleMessageSync(message);
      if (result.devices.isNotEmpty) {
        allDevices.addAll(result.devices);
        lastResult = result;
      }
    }

    if (lastResult == null) {
      
      return _createErrorResultSync('NO_DEVICE_DATA', 'No valid device data found');
    }

    
    return lastResult;

  } catch (e, stackTrace) {
    
    
    return _createErrorResultSync('PARSING_ERROR', 'Background parsing failed: $e');
  }
}

/// Synchronous validation for compute
bool _validateBasicStructureSync(String rawData) {
  // Must start with STX and end with ETX
  if (!rawData.contains(String.fromCharCode(0x02)) ||
      !rawData.contains(String.fromCharCode(0x03))) {
    return false;
  }

  // Must have at least checksum + one message
  final cleanData = rawData.replaceAll(RegExp(r'[^\x02\x03]'), '');
  final parts = cleanData.split(String.fromCharCode(0x03));

  return parts.length >= 2; // At least checksum + one message
}

/// Synchronous message extraction for compute
List<String> _extractMessagesSync(String rawData) {
  final List<String> messages = [];

  // Remove STX and ETX markers, then split by STX
  String cleanData = rawData.replaceAll(String.fromCharCode(0x02), '');
  final parts = cleanData.split(String.fromCharCode(0x03));

  for (String part in parts) {
    if (part.isNotEmpty && part.length >= 4) { // Minimum checksum + data
      messages.add(String.fromCharCode(0x02) + part + String.fromCharCode(0x03));
    }
  }

  return messages;
}

/// Synchronous message parsing for compute
EnhancedParsingResult _parseSingleMessageSync(String message) {
  try {
    // Extract checksum (first 4 chars after stx)
    final checksum = message.substring(1, 5).toUpperCase();

    // Extract and validate message data
    final messageData = message.substring(6, message.length - 1); // Remove STX, checksum, ETX
    final calculatedChecksum = ChecksumUtils.calculateChecksum(messageData);

    if (checksum != calculatedChecksum) {
      return _createErrorResultSync('CHECKSUM_MISMATCH', 'Checksum validation failed');
    }

    // Determine message type and parse
    if (messageData.startsWith('FF')) {
      // Slave pooling data
      final deviceData = messageData.substring(2);
      return _parseSlavePoolingDataSync(deviceData, checksum);
    } else if (messageData.startsWith('AA')) {
      // Master control signal
      return _parseMasterControlSignalSync(messageData, checksum);
    } else if (messageData.length == 4 && _isMasterStatusData(messageData)) {
      // 🔥 NEW: Master status data (header ignored, focus on status byte)
      return _parseMasterStatusDataSync(messageData, checksum);
    } else {
      return _createErrorResultSync('UNKNOWN_MESSAGE_TYPE', 'Unknown message type');
    }
  } catch (e) {
    return _createErrorResultSync('MESSAGE_PARSING_ERROR', 'Message parsing failed: $e');
  }
}

/// 🔥 NEW: Helper method to detect master status data (header ignored)
/// Detects 4-character data where last 2 characters are valid hex status byte
bool _isMasterStatusData(String data) {
  try {
    // Must be exactly 4 characters
    if (data.length != 4) return false;

    // Exclude existing patterns
    if (data.startsWith('FF') || data.startsWith('AA')) return false;

    // Try to parse last 2 characters as hex (status byte)
    String statusByte = data.substring(2);
    int.parse(statusByte, radix: 16);

    
    return true;
  } catch (e) {
    // If parsing fails, it's not valid master status data
    return false;
  }
}

/// Synchronous checksum calculation for compute

/// Synchronous master control parsing for compute
EnhancedParsingResult _parseMasterControlSignalSync(String signalData, String checksum) {
  final controlCode = signalData.substring(2, 4);

  final result = EnhancedParsingResult(
    cycleType: 'master_control',
    checksum: checksum,
    status: 'MASTER_CONTROL',
    totalDevices: 0,
    connectedDevices: 0,
    disconnectedDevices: 0,
    devices: [],
    rawData: {
      'signal_data': signalData,
      'checksum': checksum,
      'type': 'master_control',
      'control_code': controlCode,
    },
    timestamp: DateTime.now(),
  );

  return result;
}

/// 🔥 NEW: Synchronous master status parsing (header ignored, status byte focused)
/// Parses format like "41FF", "42BD", etc. where only last 2 digits matter
EnhancedParsingResult _parseMasterStatusDataSync(String masterData, String checksum) {
  try {
    

    // ❌ IGNORE: 2 digit pertama (header)
    // ✅ FOCUS: 2 digit terakhir sebagai status byte
    String statusByte = masterData.substring(2);  // "FF", "BD", "00", etc.
    String headerIgnored = masterData.substring(0, 2); // For logging only

    int statusValue = int.parse(statusByte, radix: 16);

    

    // Decode 7 LED indicators from status byte (FIXED: Bit 0=ON, Bit 1=OFF)
    Map<String, bool> indicators = {
      'disabled': (statusValue & 0x01) == 0,       // Bit 0: 0=ON, 1=OFF
      'silenced': (statusValue & 0x02) == 0,       // Bit 1: 0=ON, 1=OFF
      'drill_active': (statusValue & 0x04) == 0,    // Bit 2: 0=ON, 1=OFF
      'trouble_active': (statusValue & 0x08) == 0, // Bit 3: 0=ON, 1=OFF
      'alarm_active': (statusValue & 0x10) == 0,   // Bit 4: 0=ON, 1=OFF
      'dc_power': (statusValue & 0x20) == 0,       // Bit 5: 0=ON, 1=OFF
      'ac_power': (statusValue & 0x40) == 0,       // Bit 6: 0=ON, 1=OFF
    };

    

    // Create master signal for LED extraction
    final masterSignal = MasterControlSignal(
      signal: statusByte,
      checksum: checksum, // 🔥 FIXED: Include required checksum parameter
      timestamp: DateTime.now(),
      type: ControlSignalType.unknown, // Use default type
    );

    final result = EnhancedParsingResult(
      cycleType: 'master_status',
      checksum: checksum,
      status: 'MASTER_STATUS',
      totalDevices: 0,
      connectedDevices: 0,
      disconnectedDevices: 0,
      devices: [],
      masterSignal: masterSignal, // 🔥 KEY: Include master signal for LED extraction
      rawData: {
        'type': 'master_status',
        'raw_data': masterData,           // Full "41FF"
        'header': headerIgnored,           // "41" (for reference)
        'status_byte': statusByte,        // "FF" only
        'status_value': statusValue,      // 255
        'indicators': indicators,          // 7 LED states
      },
      timestamp: DateTime.now(),
    );

    
    return result;

  } catch (e) {
    
    return _createErrorResultSync('MASTER_STATUS_PARSE_ERROR', 'Master status parsing failed: $e');
  }
}


/// Synchronous error result creation for compute
EnhancedParsingResult _createErrorResultSync(String cycleType, String status) {
  return EnhancedParsingResult(
    cycleType: cycleType,
    checksum: '0000',
    status: status,
    totalDevices: 0,
    connectedDevices: 0,
    disconnectedDevices: 0,
    devices: [],
    rawData: {'error': status},
    timestamp: DateTime.now(),
  );
}

/// Parse Firebase format data (4-char per device) and convert to expected format
EnhancedParsingResult _parseFirebaseFormatSync(String deviceData, String checksum) {
  try {
    

    final List<EnhancedDevice> devices = [];

    // Parse each device from Firebase format (4 chars per device)
    int deviceCount = 0;
    int position = 0;

    while (position + 4 <= deviceData.length && deviceCount < 63) {
      final deviceDataPart = deviceData.substring(position, position + 4);
      final deviceAddress = (deviceCount + 1).toString().padLeft(2, '0');

      // 🔥 KEY CONVERSION: 4-char to 6-char format
      String troubleByte = '00';  // Default: no trouble
      String alarmByte = '00';    // Default: no alarm

      if (deviceDataPart.length >= 2) {
        // Extract from 4-char format: first 2 chars = combined status
        final statusHex = deviceDataPart.substring(0, 2);

        if (statusHex.length == 2) {
          // Split combined status into trouble and alarm bytes
          final statusValue = int.tryParse(statusHex, radix: 16) ?? 0;
          troubleByte = ((statusValue >> 8) & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
          alarmByte = (statusValue & 0xFF).toRadixString(16).padLeft(2, '0').toUpperCase();
        }
      }

      

      // Convert to expected 6-char format for consistent processing
      final convertedDeviceData = deviceAddress + troubleByte + alarmByte;

      final device = _parseSingleEnhancedDeviceSync(convertedDeviceData, deviceCount + 1);
      devices.add(device);

      deviceCount++;
      position += 4; // Move to next 4-char chunk
    }

    

    // Calculate statistics for EnhancedParsingResult
    final connectedDevices = devices.where((d) => d.isConnected).length;

    return EnhancedParsingResult(
      cycleType: 'firebase_4char_format',
      checksum: checksum,
      status: 'success',
      totalDevices: devices.length,
      connectedDevices: connectedDevices,
      disconnectedDevices: devices.length - connectedDevices,
      devices: devices,
      masterSignal: null,
      rawData: {'status': 'firebase_format_processed'},
      timestamp: DateTime.now(),
    );

  } catch (e, stackTrace) {
    
    
    return _createErrorResultSync('FIREBASE_PARSING_ERROR', 'Firebase format parsing failed: $e');
  }
}


/// Synchronous version of slave pooling data parsing for compute
EnhancedParsingResult _parseSlavePoolingDataSync(String deviceData, String checksum) {
  try {
    

    // 🔥 DETECT FIREBACE FORMAT vs EXPECTED FORMAT
    final isFirebaseFormat = deviceData.length < 378 && deviceData.length >= 4;

    if (isFirebaseFormat) {
      
      return _parseFirebaseFormatSync(deviceData, checksum);
    }

    // Expected format: 63 devices × 6 chars = 378 chars minimum
    if (deviceData.length < 378) {
      
      return _createErrorResultSync('INCOMPLETE_SLAVE_DATA', 'Incomplete slave data');
    }

    final List<EnhancedDevice> devices = [];
    int connectedCount = 0;
    int disconnectedCount = 0;

    // Parse each device (6 chars per device) - This is the heavy computation
    for (int i = 0; i < 63 && i * 6 < deviceData.length; i++) {
      final deviceStart = i * 6;
      if (deviceStart + 6 > deviceData.length) break;

      final deviceDataPart = deviceData.substring(deviceStart, deviceStart + 6);
      final device = _parseSingleEnhancedDeviceSync(deviceDataPart, i + 1);

      devices.add(device);
      if (device.isConnected) {
        connectedCount++;
      } else {
        disconnectedCount++;
      }
    }

    final status = _determineDeviceConnectivityStatusSync(connectedCount, disconnectedCount);

    final result = EnhancedParsingResult(
      cycleType: 'slave_pooling',
      checksum: checksum,
      status: status,
      totalDevices: 63,
      connectedDevices: connectedCount,
      disconnectedDevices: disconnectedCount,
      devices: devices,
      rawData: {
        'slave_data': deviceData,
        'checksum': checksum,
        'device_count': devices.length,
      },
      timestamp: DateTime.now(),
    );

    
    return result;

  } catch (e) {
    
    return _createErrorResultSync('SLAVE_PARSING_ERROR', 'Background slave parsing failed: $e');
  }
}

/// Synchronous version of single enhanced device parsing - CORRECTED VERSION
EnhancedDevice _parseSingleEnhancedDeviceSync(String deviceData, int deviceNumber) {
  if (deviceData.length != 6) {
    throw Exception('Invalid device data length: ${deviceData.length}');
  }

  final address = deviceData.substring(0, 2).toUpperCase();
  final deviceAddress = int.parse(address, radix: 16);
  final troubleByteStr = deviceData.substring(2, 4); // Correct: Separate trouble byte
  final alarmByteStr = deviceData.substring(4, 6);    // Correct: Separate alarm byte

  // Parse separate trouble and alarm bytes
  final troubleValue = int.parse(troubleByteStr, radix: 16);
  final alarmValue = int.parse(alarmByteStr, radix: 16);
  final List<ZoneStatus> zones = [];

  // Parse 5 zones with 1-bit per zone (CORRECT LOGIC)
  for (int zoneNum = 1; zoneNum <= 5; zoneNum++) {
    final int bitMask = 1 << (zoneNum - 1); // 0x01, 0x02, 0x04, 0x08, 0x10

    final bool hasTrouble = (troubleValue & bitMask) != 0;
    final bool hasAlarm = (alarmValue & bitMask) != 0;
    final bool isActive = hasTrouble || hasAlarm;

    // CORRECT: Priority logic - Alarm overrides trouble
    String description;
    if (hasAlarm) {
      description = 'Zone $zoneNum - Alarm Active';
    } else if (hasTrouble) {
      description = 'Zone $zoneNum - Trouble Detected';
    } else {
      description = 'Zone $zoneNum - Normal';
    }

    final globalZoneNum = ZoneStatusUtils.calculateGlobalZoneNumber(deviceAddress, zoneNum);
    zones.add(ZoneStatus(
      globalZoneNumber: globalZoneNum,
      zoneInDevice: zoneNum,
      deviceAddress: deviceAddress,
      isActive: isActive,
      hasTrouble: hasTrouble && !hasAlarm, // CORRECT: No double counting
      hasAlarm: hasAlarm,
      description: description,
    ));
  }

  // Determine device connection status
  final isConnected = zones.any((zone) => zone.isActive);

  // CORRECT: Bell status from bit 5 of alarm byte
  final bool bellActive = (alarmValue & 0x20) != 0;

  // Parse device overall status
  final deviceStatus = DeviceStatus(
    hasPower: isConnected,
    hasTrouble: zones.any((zone) => zone.hasTrouble),
    hasAlarm: zones.any((zone) => zone.hasAlarm),
    outputBellActive: bellActive, // CORRECT: Proper bell detection
  );

  

  return EnhancedDevice(
    address: address,
    isConnected: isConnected,
    zones: zones,
    deviceStatus: deviceStatus,
    timestamp: DateTime.now(),
  );
}

/// DEPRECATED: Old incorrect zone status mapping - REMOVED
/// Using correct 1-bit per zone logic in _parseSingleEnhancedDeviceSync instead

/// Top-level system status determination for compute
String _determineDeviceConnectivityStatusSync(int connectedCount, int disconnectedCount) {
  if (connectedCount == 0) {
    return 'ALL_DEVICES_OFFLINE';
  } else if (disconnectedCount == 0) {
    return 'ALL_DEVICES_ONLINE';
  } else if (connectedCount > disconnectedCount) {
    return 'MOSTLY_ONLINE';
  } else {
    return 'MOSTLY_OFFLINE';
  }
}

/// Enhanced Zone Parser untuk 63 devices dengan 5 zones
class EnhancedZoneParser {
  static const String _tag = 'ENHANCED_ZONE_PARSER';
  static const int stx = 0x02;
  static const int etx = 0x03;

  /// Parse complete data stream for 63 devices (with background processing for large data)
  static Future<EnhancedParsingResult> parseCompleteDataStream(String rawData) async {
    try {
      

      // For small data (< 1000 chars), parse directly to avoid overhead
      if (rawData.length < 1000) {
        return _parseCompleteDataStreamSync(rawData);
      }

      // For large data, use advanced background processing to prevent UI blocking
      

      // Check system resources first
      final hasResources = await BackgroundParser.checkSystemResources();
      if (!hasResources) {
        
        return _parseCompleteDataStreamSync(rawData);
      }

      // Use background parser with progress reporting
      return await BackgroundParser.parseDeviceDataInBackground(
        rawData,
        onProgress: (progress) {
          
        },
      );

    } catch (e) {
      
      // Fallback to synchronous parsing if compute fails
      try {
        
        return _parseCompleteDataStreamSync(rawData);
      } catch (fallbackError) {
        
        return _createErrorResult('PARSING_ERROR', 'Parsing failed: $fallbackError');
      }
    }
  }

  
  
  
  
  
  
  
  
  
  /// Create error result
  static EnhancedParsingResult _createErrorResult(String cycleType, String status) {
    return EnhancedParsingResult(
      cycleType: cycleType,
      checksum: 'ERROR',
      status: status,
      totalDevices: 0,
      connectedDevices: 0,
      disconnectedDevices: 0,
      devices: [],
      rawData: {
        'error': true,
        'error_type': cycleType,
        'error_message': status,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Generate training examples
  static String generateTrainingExample(EnhancedParsingResult result) {
    final buffer = StringBuffer();

    // Add STX start
    buffer.write(String.fromCharCode(stx));

    // Add example checksum (40DF for 63 devices)
    buffer.write('40DF');

    // Add STX for device data start
    buffer.write(String.fromCharCode(stx));

    // Generate slave pooling data based on result
    if (result.devices.isNotEmpty) {
      for (int i = 0; i < result.devices.length; i++) {
        if (i > 0) buffer.write(String.fromCharCode(stx)); // Separator

        final device = result.devices[i];
        final address = device.address;

        // Generate 5-zone status byte
        int statusByte = 0;
        for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
          if (zoneIndex < device.zones.length) {
            final zone = device.zones[zoneIndex];
            if (zone.hasAlarm) {
              statusByte |= (1 << zoneIndex); // Set bit for alarm
            }
            // Add other status mappings as needed
          }
        }

        // Format: Address (2) + Status (4) = 6 chars
        final statusHex = statusByte.toRadixString(16).toUpperCase().padLeft(4, '0');
        buffer.write('$address$statusHex');
      }
    }

    // Add ETX end
    buffer.write(String.fromCharCode(etx));

    return buffer.toString();
  }

  /// Get system summary
  static String getSystemSummary(EnhancedParsingResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== ENHANCED ZONE PARSER SUMMARY ===');
    buffer.writeln('Cycle Type: ${result.cycleType}');
    buffer.writeln('System Status: ${result.status}');
    buffer.writeln('Total Devices: ${result.totalDevices}');
    buffer.writeln('Connected: ${result.connectedDevices}');
    buffer.writeln('Disconnected: ${result.disconnectedDevices}');
    buffer.writeln('Active Zones: ${result.totalActiveZones}');
    buffer.writeln('Trouble Zones: ${result.totalTroubleZones}');
    buffer.writeln('Alarm Zones: ${result.totalAlarmZones}');

    if (result.masterSignal != null) {
      buffer.writeln('Master Signal: ${result.masterSignal!.signal} (${result.masterSignal!.type})');
    }

    return buffer.toString();
  }

  // ==================== LED STATUS PROCESSING ====================

  /// 🔥 UPDATED: Extract LED status from parsed data with master status priority
  static LEDStatusData extractLEDStatusFromDeviceData(EnhancedParsingResult result) {
    try {
      

      // Priority 1: Master Status Data (INDEPENDENT from device data)
      if (result.cycleType == 'master_status' && result.rawData['indicators'] != null) {
        final indicators = result.rawData['indicators'] as Map<String, bool>;
        String statusByte = result.rawData['status_byte'] as String? ?? '??';

        

        final ledStatus = LEDStatusData(
          acPowerOn: indicators['ac_power'] ?? false,
          dcPowerOn: indicators['dc_power'] ?? false,
          alarmOn: indicators['alarm_active'] ?? false,
          troubleOn: indicators['trouble_active'] ?? false,
          drillOn: indicators['drill_active'] ?? false,
          silencedOn: indicators['silenced'] ?? false,
          disabledOn: indicators['disabled'] ?? false,
          timestamp: DateTime.now(),
          rawData: 'master_status_$statusByte', // Only status byte, not full data
        );

        
        
        return ledStatus;
      }

      // Priority 2: Master Control Signal (existing AABBCC logic)
      if (result.masterSignal != null) {
        final masterSignal = result.masterSignal!;

        

        // Extract LED status from master signal using existing AABBCC algorithm
        bool acPowerOn = false, dcPowerOn = false, alarmOn = false, troubleOn = false;
        bool drillOn = false, silencedOn = false, disabledOn = false;

        _extractLEDFromMasterSignal(masterSignal,
            acPower: (value) => acPowerOn = value,
            dcPower: (value) => dcPowerOn = value,
            alarm: (value) => alarmOn = value,
            trouble: (value) => troubleOn = value,
            drill: (value) => drillOn = value,
            silenced: (value) => silencedOn = value,
            disabled: (value) => disabledOn = value);

        

        final ledStatus = LEDStatusData(
          acPowerOn: acPowerOn,
          dcPowerOn: dcPowerOn,
          alarmOn: alarmOn,
          troubleOn: troubleOn,
          drillOn: drillOn,
          silencedOn: silencedOn,
          disabledOn: disabledOn,
          timestamp: DateTime.now(),
          rawData: 'control_signal_${masterSignal.signal}',
        );

        
        return ledStatus;
      }

      // Priority 3: No LED data available (default OFF state)
      

      final ledStatus = LEDStatusData(
        acPowerOn: false,
        dcPowerOn: false,
        alarmOn: false,
        troubleOn: false,
        drillOn: false,
        silencedOn: false,
        disabledOn: false,
        timestamp: DateTime.now(),
        rawData: 'no_led_data',
      );

      
      return ledStatus;

    } catch (e) {
      
      // Return default LED status (all OFF)
      return LEDStatusData(
        acPowerOn: false,
        dcPowerOn: false,
        alarmOn: false,
        troubleOn: false,
        drillOn: false,
        silencedOn: false,
        disabledOn: false,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Extract LED status from master signal using AABBCC algorithm
  static void _extractLEDFromMasterSignal(MasterControlSignal signal, {
    required Function(bool) acPower,
    required Function(bool) dcPower,
    required Function(bool) alarm,
    required Function(bool) trouble,
    required Function(bool) drill,
    required Function(bool) silenced,
    required Function(bool) disabled,
  }) {
    try {
      // 🔥 FIXED: Use correct property 'signal' instead of 'signalData'
      if (signal.signal.isNotEmpty && signal.signal.length >= 4) {
        String ledHexData = signal.signal;

        

        // Apply AABBCC algorithm
        // Format: AA (address) + BB (trouble/alarm) + CC (LED status)
        if (ledHexData.length >= 4) {
          String ledByteHex = ledHexData.substring(2, 4); // Extract CC - LED status byte
          int ledByteValue = int.parse(ledByteHex, radix: 16);

          

          // Bit decoding (0=ON, 1=OFF) - Correct bit order per specification
          disabled((ledByteValue & (1 << 0)) == 0);     // Bit 0
          silenced((ledByteValue & (1 << 1)) == 0);     // Bit 1
          drill((ledByteValue & (1 << 2)) == 0);        // Bit 2
          trouble((ledByteValue & (1 << 3)) == 0);      // Bit 3
          alarm((ledByteValue & (1 << 4)) == 0);        // Bit 4
          dcPower((ledByteValue & (1 << 5)) == 0);      // Bit 5
          acPower((ledByteValue & (1 << 6)) == 0);      // Bit 6

          String binary = ledByteValue.toRadixString(2).padLeft(8, '0');
          
          
        }
      }
    } catch (e) {
      
    }
  }
}

/// LED Status Data model for communication between Enhanced Zone Parser and LED Decoder
class LEDStatusData {
  final bool acPowerOn;
  final bool dcPowerOn;
  final bool alarmOn;
  final bool troubleOn;
  final bool drillOn;
  final bool silencedOn;
  final bool disabledOn;
  final DateTime timestamp;
  final String? rawData;

  LEDStatusData({
    required this.acPowerOn,
    required this.dcPowerOn,
    required this.alarmOn,
    required this.troubleOn,
    required this.drillOn,
    required this.silencedOn,
    required this.disabledOn,
    required this.timestamp,
    this.rawData,
  });

  /// Convert to LED decoder compatible format
  Map<String, dynamic> toLEDDecoderFormat() {
    return {
      'AC Power': acPowerOn,
      'DC Power': dcPowerOn,
      'Alarm': alarmOn,
      'Trouble': troubleOn,
      'Drill': drillOn,
      'Silenced': silencedOn,
      'Disabled': disabledOn,
      'timestamp': timestamp.toIso8601String(),
      'rawData': rawData,
    };
  }

  @override
  String toString() {
    return 'LEDStatus(AC: $acPowerOn, DC: $dcPowerOn, Alarm: $alarmOn, Trouble: $troubleOn, Drill: $drillOn, Silence: $silencedOn, Disable: $disabledOn)';
  }
}