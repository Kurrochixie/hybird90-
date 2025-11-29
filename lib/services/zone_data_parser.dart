import 'package:flutter/material.dart';
import '../utils/checksum_utils.dart';
// 🔥 REMOVED: system_status_utils.dart import (OBSOLETE - deleted file)

/// Model untuk data zona individual dari agent
class ZoneDevice {
  final String address;
  final String status;
  final String? trouble;
  final String? alarm;
  final bool isActive;
  final DateTime timestamp;
  final ZoneDeviceType type;

  ZoneDevice({
    required this.address,
    required this.status,
    this.trouble,
    this.alarm,
    required this.isActive,
    required this.timestamp,
    this.type = ZoneDeviceType.unknown,
  });

  factory ZoneDevice.fromJson(Map<String, dynamic> json) {
    return ZoneDevice(
      address: json['address'] ?? '',
      status: json['status'] ?? '',
      trouble: json['trouble'],
      alarm: json['alarm'],
      isActive: json['isActive'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: _parseDeviceType(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'status': status,
      'trouble': trouble,
      'alarm': alarm,
      'isActive': isActive,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
    };
  }

  static ZoneDeviceType _parseDeviceType(String? status) {
    if (status == null) return ZoneDeviceType.unknown;

    switch (status.toLowerCase()) {
      case 'online_normal':
        return ZoneDeviceType.onlineNormal;
      case 'offline':
        return ZoneDeviceType.offline;
      case 'trouble_detected':
        return ZoneDeviceType.trouble;
      case 'active_with_alarm':
        return ZoneDeviceType.alarm;
      case 'communication_error':
        return ZoneDeviceType.communicationError;
      default:
        return ZoneDeviceType.unknown;
    }
  }

  /// Get human readable status description
  String get statusDescription {
    switch (type) {
      case ZoneDeviceType.onlineNormal:
        return 'Online - Normal';
      case ZoneDeviceType.offline:
        return 'Offline';
      case ZoneDeviceType.trouble:
        return 'Trouble Detected';
      case ZoneDeviceType.alarm:
        return 'Alarm Active';
      case ZoneDeviceType.communicationError:
        return 'Communication Error';
      case ZoneDeviceType.unknown:
        return 'Unknown Status';
    }
  }

  /// Get color for UI indication
  Color get statusColor {
    switch (type) {
      case ZoneDeviceType.onlineNormal:
        return Colors.green;
      case ZoneDeviceType.offline:
        return Colors.grey;
      case ZoneDeviceType.trouble:
        return Colors.orange;
      case ZoneDeviceType.alarm:
        return Colors.red;
      case ZoneDeviceType.communicationError:
        return Colors.purple;
      case ZoneDeviceType.unknown:
        return Colors.blueGrey;
    }
  }
}

/// Tipe zona device
enum ZoneDeviceType {
  onlineNormal,
  offline,
  trouble,
  alarm,
  communicationError,
  unknown,
}

/// Model untuk hasil parsing lengkap
class ZoneParsingResult {
  final String cycleType;
  final String checksum;
  final String status;
  final int totalDevices;
  final int deviceCount;
  final String? deviceRange;
  final List<ZoneDevice> devices;
  final Map<String, dynamic> rawData;
  final DateTime timestamp;

  ZoneParsingResult({
    required this.cycleType,
    required this.checksum,
    required this.status,
    required this.totalDevices,
    required this.deviceCount,
    this.deviceRange,
    required this.devices,
    required this.rawData,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'cycleType': cycleType,
      'checksum': checksum,
      'status': status,
      'totalDevices': totalDevices,
      'deviceCount': deviceCount,
      'deviceRange': deviceRange,
      'devices': devices.map((device) => device.toJson()).toList(),
      'rawData': rawData,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get human readable status
  String get statusDescription {
    switch (status.toLowerCase()) {
      case 'all_devices_online':
        return 'All Devices Online';
      case 'system_stable_no_alarm':
        return 'System Stable - No Alarm';
      case 'alarm_detected':
        return 'Alarm Detected';
      case 'partial_alarm':
        return 'Partial Alarm';
      case 'communication_error':
        return 'Communication Error';
      case 'data_corrupted':
        return 'Data Corrupted';
      default:
        return status;
    }
  }

  /// Get severity level for notifications
  int get severityLevel {
    switch (status.toLowerCase()) {
      case 'alarm_detected':
        return 4; // Critical
      case 'partial_alarm':
        return 3; // High
      case 'communication_error':
        return 2; // Medium
      case 'data_corrupted':
        return 2; // Medium
      case 'system_stable_no_alarm':
        return 1; // Low
      case 'all_devices_online':
        return 0; // Normal
      default:
        return 1; // Default to low
    }
  }
}

/// Advanced Zone Data Parser untuk parsing data dari agent
class ZoneDataParser {
  static const String _tag = 'ZONE_PARSER';
  static const int stx = 0x02; // Start of Text
  static const int etx = 0x03; // End of Text

  /// Parse raw data string dari agent
  static ZoneParsingResult parseRawData(String rawData) {
    try {
      

      // Step 1: Validate basic structure
      if (!_validateBasicStructure(rawData)) {
        
        return _createErrorResult('INVALID_STRUCTURE', 'Data structure invalid');
      }

      // Step 2: Extract and validate checksum
      final checksum = _extractChecksum(rawData);
      if (checksum == null) {
        
        return _createErrorResult('CHECKSUM_ERROR', 'Checksum extraction failed');
      }

      // Step 3: Extract device data
      final deviceData = _extractDeviceData(rawData);
      if (deviceData.isEmpty) {
        
        return _createErrorResult('NO_DEVICE_DATA', 'No device data found');
      }

      // Step 4: Validate checksum
      final calculatedChecksum = ChecksumUtils.calculateChecksum(deviceData);
      if (checksum != calculatedChecksum) {
        
        return _createErrorResult('CHECKSUM_MISMATCH', 'Checksum validation failed');
      }

      

      // Step 5: Parse devices and determine cycle type
      final devices = _parseDevices(deviceData);
      final cycleType = _determineCycleType(devices);
      final status = _determineSystemStatus(devices);
      final deviceRange = _determineDeviceRange(devices);

      // Step 6: Create result
      final result = ZoneParsingResult(
        cycleType: cycleType,
        checksum: checksum,
        status: status,
        totalDevices: 63, // Maximum devices
        deviceCount: devices.length,
        deviceRange: deviceRange,
        devices: devices,
        rawData: {
          'raw_input': rawData,
          'extracted_checksum': checksum,
          'calculated_checksum': calculatedChecksum,
          'device_data_hex': deviceData,
        },
        timestamp: DateTime.now(),
      );

      
      return result;

    } catch (e, stackTrace) {
      
      
      return _createErrorResult('PARSING_ERROR', 'Parsing failed: $e');
    }
  }

  /// Validate basic structure of raw data
  static bool _validateBasicStructure(String rawData) {
    // Must start with STX and end with ETX
    if (!rawData.contains(String.fromCharCode(stx)) ||
        !rawData.contains(String.fromCharCode(etx))) {
      return false;
    }

    // Must have at least checksum + one device
    final cleanData = rawData.replaceAll(RegExp(r'[^\x02\x03]'), '');
    final parts = cleanData.split(String.fromCharCode(stx));

    return parts.length >= 2; // At least checksum + one device
  }

  /// Extract checksum from data
  static String? _extractChecksum(String rawData) {
    try {
      // Find first 4-digit hex sequence after STX
      final regex = RegExp(r'\x02([0-9A-Fa-f]{4})');
      final match = regex.firstMatch(rawData);

      return match?.group(1)?.toUpperCase();
    } catch (e) {
      
      return null;
    }
  }

  /// Extract device data (everything after checksum)
  static String _extractDeviceData(String rawData) {
    try {
      // Remove control characters and extract only device data
      String cleanData = rawData;

      // Remove ETX and everything after it
      final etxIndex = cleanData.indexOf(String.fromCharCode(etx));
      if (etxIndex != -1) {
        cleanData = cleanData.substring(0, etxIndex);
      }

      // Remove checksum and keep only device data
      final checksumRegex = RegExp(r'\x02[0-9A-Fa-f]{4}');
      cleanData = cleanData.replaceAll(checksumRegex, '');

      // Remove remaining STX characters
      cleanData = cleanData.replaceAll(String.fromCharCode(stx), '');

      return cleanData.trim();
    } catch (e) {
      
      return '';
    }
  }

  /// Calculate checksum from device data
  
  /// Parse individual devices from device data
  static List<ZoneDevice> _parseDevices(String deviceData) {
    final List<ZoneDevice> devices = [];

    // Split by STX and process each device
    final deviceParts = deviceData.split(String.fromCharCode(stx));

    for (String devicePart in deviceParts) {
      if (devicePart.isEmpty) continue;

      final device = _parseSingleDevice(devicePart);
      if (device != null) {
        devices.add(device);
      }
    }

    
    return devices;
  }

  /// Parse single device from device data part
  static ZoneDevice? _parseSingleDevice(String devicePart) {
    try {
      // Pattern 1: ZONA OFF (2 digit address only)
      final addressOnlyRegex = RegExp(r'^([0-9A-Fa-f]{2})$');
      final addressMatch = addressOnlyRegex.firstMatch(devicePart);

      if (addressMatch != null) {
        final address = addressMatch.group(1)!.toUpperCase();

        return ZoneDevice(
          address: address,
          status: 'offline',
          isActive: false,
          timestamp: DateTime.now(),
          type: ZoneDeviceType.offline,
        );
      }

      // Pattern 2: ZONA AKTIF (6+ characters: address + status)
      if (devicePart.length >= 6) {
        final address = devicePart.substring(0, 2).toUpperCase();
        final statusData = devicePart.substring(2);

        return _parseDeviceWithStatus(address, statusData);
      }

      
      return null;
    } catch (e) {
      
      return null;
    }
  }

  /// Parse device with status data
  static ZoneDevice _parseDeviceWithStatus(String address, String statusData) {
    try {
      String status = 'unknown';
      String? trouble;
      String? alarm;

      // Decode status based on length and content
      if (statusData.length >= 4) {
        // Extract trouble and alarm status
        final troubleHex = statusData.substring(0, 2);
        final alarmHex = statusData.substring(2, 4);

        trouble = _decodeStatus(troubleHex);
        alarm = _decodeStatus(alarmHex);

        // Determine overall status
        if (alarm != '00' || trouble != '00') {
          status = 'active_with_alarm';
        } else {
          status = 'online_normal';
        }
      }

      return ZoneDevice(
        address: address,
        status: status,
        trouble: trouble,
        alarm: alarm,
        isActive: true,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      
      return ZoneDevice(
        address: address,
        status: 'communication_error',
        isActive: false,
        timestamp: DateTime.now(),
        type: ZoneDeviceType.communicationError,
      );
    }
  }

  /// Decode 2-digit status hex to readable format
  static String _decodeStatus(String hexStatus) {
    try {
      final status = int.parse(hexStatus, radix: 16);

      // Convert to binary and check individual bits
      String binary = status.toRadixString(2).padLeft(8, '0');

      if (binary == '00000000') return '00'; // All normal
      if (binary == '11111111') return 'FF'; // All active

      // Return hex value for custom status codes
      return hexStatus.toUpperCase();
    } catch (e) {
      
      return '00'; // Default to normal
    }
  }

  /// Determine cycle type based on parsed devices
  static String _determineCycleType(List<ZoneDevice> devices) {
    if (devices.isEmpty) return 'NO_DATA';

    final activeDevices = devices.where((d) => d.isActive).length;
    final alarmDevices = devices.where((d) => d.type == ZoneDeviceType.alarm).length;
    final troubleDevices = devices.where((d) => d.type == ZoneDeviceType.trouble).length;
    final offlineDevices = devices.where((d) => d.type == ZoneDeviceType.offline).length;

    if (activeDevices == devices.length && alarmDevices == 0 && troubleDevices == 0) {
      return 'health_check'; // All online, no issues
    } else if (activeDevices == devices.length && (alarmDevices > 0 || troubleDevices > 0)) {
      return 'status_report'; // Online with issues
    } else if (activeDevices < devices.length && offlineDevices > 0) {
      return 'partial_status'; // Some devices offline
    } else if (devices.length == 63) {
      return 'full_health_check'; // All 63 devices present
    } else {
      return 'unknown_cycle';
    }
  }

  /// Determine overall system status
  static String _determineSystemStatus(List<ZoneDevice> devices) {
    if (devices.isEmpty) return 'no_data';

    // Count alarm and trouble devices
    final totalAlarmZones = devices.where((d) => d.type == ZoneDeviceType.alarm).length;
    final totalTroubleZones = devices.where((d) => d.type == ZoneDeviceType.trouble).length;

    // Create system flags
    final systemFlags = {
      'Alarm': totalAlarmZones > 0,
      'Trouble': totalTroubleZones > 0,
      'Drill': false,
      'Silenced': false,
      'Supervisory': false,
      'Disabled': false,
    };

    // 🔥 REPLACED: SystemStatusUtils with simple logic (systemStatusUtils.dart deleted)
    // Simple status determination based on zone counts
    if (totalAlarmZones > 0) return 'SYSTEM ALARM';
    if (totalTroubleZones > 0) return 'SYSTEM TROUBLE';
    if (systemFlags['Drill'] == true) return 'SYSTEM DRILL';
    if (systemFlags['Silenced'] == true) return 'SYSTEM SILENCED';
    if (systemFlags['Disabled'] == true) return 'SYSTEM DISABLED';
    return 'SYSTEM NORMAL';
  }

  /// Determine device range
  static String? _determineDeviceRange(List<ZoneDevice> devices) {
    if (devices.isEmpty) return null;

    final addresses = devices.map((d) => d.address).toList();
    addresses.sort();

    if (addresses.length <= 1) return addresses.first;

    return '${addresses.first}-${addresses.last}';
  }

  /// Create error result
  static ZoneParsingResult _createErrorResult(String cycleType, String status) {
    return ZoneParsingResult(
      cycleType: cycleType,
      checksum: 'ERROR',
      status: status,
      totalDevices: 0,
      deviceCount: 0,
      devices: [],
      rawData: {
        'error': true,
        'error_type': cycleType,
        'error_message': status,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Convert to JSON output format
  static Map<String, dynamic> toJsonOutput(ZoneParsingResult result) {
    final output = <String, dynamic>{
      'cycle_type': result.cycleType,
      'checksum': result.checksum,
      'status': result.status,
      'timestamp': result.timestamp.toIso8601String(),
    };

    // Add device information
    if (result.devices.isNotEmpty) {
      output['devices'] = result.devices.map((device) => device.toJson()).toList();
    }

    // Add range information
    if (result.deviceRange != null) {
      output['device_range'] = result.deviceRange!;
    }

    output['total_devices'] = result.totalDevices.toString();
    output['device_count'] = result.deviceCount.toString();

    return output;
  }

  /// Generate example training data from result
  static String generateTrainingExample(ZoneParsingResult result) {
    final buffer = StringBuffer();

    // Add ETX at beginning
    buffer.write(String.fromCharCode(stx));

    // Add checksum (placeholder - would be calculated)
    buffer.write('40DF'); // Example checksum

    // Add STX at beginning of device data
    buffer.write(String.fromCharCode(stx));

    // Generate device data based on result
    if (result.devices.isNotEmpty) {
      for (int i = 0; i < result.devices.length; i++) {
        final device = result.devices[i];

        if (i > 0) buffer.write(String.fromCharCode(stx));

        if (device.type == ZoneDeviceType.offline) {
          // ZONA OFF: address only
          buffer.write(device.address);
        } else {
          // ZONA AKTIF: address + status
          buffer.write(device.address);
          buffer.write(device.trouble ?? '00');
          buffer.write(device.alarm ?? '00');
        }
      }
    }

    // Add ETX at end
    buffer.write(String.fromCharCode(etx));

    return buffer.toString();
  }
}