import 'enhanced_zone_parser.dart';
import '../models/zone_status.dart' as models;

/// System Status Data Model
class SystemStatusData {
  final bool hasAlarm;
  final bool hasTrouble;
  final bool hasSupervisory;
  final Map<String, bool> systemFlags;
  final List<DeviceStatus> devices;
  final DateTime timestamp;

  const SystemStatusData({
    required this.hasAlarm,
    required this.hasTrouble,
    required this.hasSupervisory,
    required this.systemFlags,
    required this.devices,
    required this.timestamp,
  });

  factory SystemStatusData.empty() {
    return SystemStatusData(
      hasAlarm: false,
      hasTrouble: false,
      hasSupervisory: false,
      systemFlags: {
        'Alarm': false,
        'Trouble': false,
        'Drill': false,
        'Silenced': false,
        'Supervisory': false,
        'Disabled': false,
      },
      devices: [],
      timestamp: DateTime.now(),
    );
  }

  /// Get unified system status text
  String getSystemStatusText() {
    if (hasAlarm) return 'SYSTEM ALARM';
    if (hasTrouble) return 'SYSTEM TROUBLE';
    if (hasSupervisory) return 'SYSTEM SUPERVISORY';
    return 'SYSTEM NORMAL';
  }

  /// Get unified system status color
  String getSystemStatusColorKey() {
    if (hasAlarm) return 'Alarm';
    if (hasTrouble) return 'Trouble';
    if (hasSupervisory) return 'Supervisory';
    return 'Normal';
  }
}

/// Device Status Model
class DeviceStatus {
  final int address;
  final List<models.ZoneStatus> zones;
  final bool isConnected;

  const DeviceStatus({
    required this.address,
    required this.zones,
    required this.isConnected,
  });

  bool get hasAlarmZones => zones.any((zone) => zone.hasAlarm);
  bool get hasTroubleZones => zones.any((zone) => zone.hasTrouble);
}

/// System Status Extractor - Converts Enhanced Zone Parser results to System Status
class SystemStatusExtractor {
  static const String _tag = 'SYSTEM_STATUS_EXTRACTOR';

  /// Extract system status from Enhanced Zone Parser result
  static SystemStatusData extractFromParsingResult(EnhancedParsingResult parsingResult) {
    try {
      

      final List<DeviceStatus> devices = [];
      bool hasSystemAlarm = false;
      bool hasSystemTrouble = false;
      bool hasSystemSupervisory = false;

      // Process each device from Enhanced Zone Parser
      for (final enhancedDevice in parsingResult.devices) {
        final deviceStatus = _convertEnhancedDeviceToDeviceStatus(enhancedDevice);
        devices.add(deviceStatus);

        // Aggregate system-level status
        if (deviceStatus.hasAlarmZones) hasSystemAlarm = true;
        if (deviceStatus.hasTroubleZones) hasSystemTrouble = true;
              }

      // Create unified system flags
      final systemFlags = {
        'Alarm': hasSystemAlarm,
        'Trouble': hasSystemTrouble,
        'Drill': false,
        'Silenced': false,
        'Supervisory': hasSystemSupervisory,
        'Disabled': false
      };

      final systemStatusData = SystemStatusData(
        hasAlarm: hasSystemAlarm,
        hasTrouble: hasSystemTrouble,
        hasSupervisory: hasSystemSupervisory,
        systemFlags: systemFlags,
        devices: devices,
        timestamp: DateTime.now(),
      );

      
      
      

      return systemStatusData;

    } catch (e) {
      
      return SystemStatusData.empty();
    }
  }

  /// Convert Enhanced Device to Device Status
  static DeviceStatus _convertEnhancedDeviceToDeviceStatus(EnhancedDevice enhancedDevice) {
    final List<models.ZoneStatus> zones = [];

    // Convert EnhancedDevice zones to ZoneStatus
    for (final enhancedZone in enhancedDevice.zones) {
      // FIXED: Correct zone number mapping formula
      final globalZoneNum = enhancedZone.zoneNumber;
      final zoneInDevice = ((globalZoneNum - 1) % 5) + 1; // FIXED: Proper zone calculation
      final deviceAddress = ((globalZoneNum - 1) / 5).floor() + 1; // FIXED: Proper device calculation

      

      zones.add(models.ZoneStatus(
        globalZoneNumber: globalZoneNum,
        zoneInDevice: zoneInDevice,
        deviceAddress: deviceAddress,
        isActive: enhancedZone.isActive,
        hasAlarm: enhancedZone.hasAlarm,
        hasTrouble: enhancedZone.hasTrouble,
        description: enhancedZone.description,
      ));
    }

    // Debug: Show device status summary
    final alarmZones = zones.where((zone) => zone.hasAlarm).length;
    final troubleZones = zones.where((zone) => zone.hasTrouble).length;
    

    return DeviceStatus(
      address: int.tryParse(enhancedDevice.address) ?? 1, // Parse hex/dec address with fallback
      zones: zones,
      isConnected: enhancedDevice.isConnected,
    );
  }

  /// Extract system status directly from raw hex data (fallback method)
  static Future<SystemStatusData> extractFromRawHexData(String rawData) async {
    try {
      

      // Use Enhanced Zone Parser to parse raw data
      final parsingResult = await EnhancedZoneParser.parseCompleteDataStream(rawData);

      // Convert parsing result to system status
      return extractFromParsingResult(parsingResult);

    } catch (e) {
      
      return SystemStatusData.empty();
    }
  }

  /// Validate system status consistency
  static bool validateSystemStatus(SystemStatusData systemStatus) {
    try {
      // Basic validation - lebih toleran untuk parsing yang sedang berjalan
      if (systemStatus.devices.isEmpty) {
        
        return true; // Ubah dari false ke true untuk initial setup
      }

      // Check for logical inconsistencies
      final hasActiveAlarms = systemStatus.devices.any((device) => device.hasAlarmZones);
      final hasActiveTroubles = systemStatus.devices.any((device) => device.hasTroubleZones);

      if (hasActiveAlarms != systemStatus.hasAlarm) {
        
        return false;
      }

      if (hasActiveTroubles != systemStatus.hasTrouble) {
        
        return false;
      }

      
      return true;

    } catch (e) {
      
      return false;
    }
  }

  /// Get detailed debug information
  static String getDebugInfo(SystemStatusData systemStatus) {
    final buffer = StringBuffer();
    buffer.writeln('=== SYSTEM STATUS DEBUG INFO ===');
    buffer.writeln('Timestamp: ${systemStatus.timestamp}');
    buffer.writeln('Has Alarm: ${systemStatus.hasAlarm}');
    buffer.writeln('Has Trouble: ${systemStatus.hasTrouble}');
    buffer.writeln('Has Supervisory: ${systemStatus.hasSupervisory}');
    buffer.writeln('Total Devices: ${systemStatus.devices.length}');
    buffer.writeln('System Flags: ${systemStatus.systemFlags}');

    buffer.writeln('\nDEVICE DETAILS:');
    for (final device in systemStatus.devices) {
      buffer.writeln('  Device ${device.address.toString().padLeft(2, '0')}: Connected=${device.isConnected}');
      if (device.hasAlarmZones) buffer.writeln('    ⚠️ HAS ALARM ZONES');
      if (device.hasTroubleZones) buffer.writeln('    ⚠️ HAS TROUBLE ZONES');

      for (final zone in device.zones) {
        if (zone.isActive) {
          buffer.writeln('    Zone ${zone.zoneNumber}: ${zone.description}');
        }
      }
    }

    return buffer.toString();
  }
}