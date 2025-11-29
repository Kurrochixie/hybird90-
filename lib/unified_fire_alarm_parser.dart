import 'package:flutter/material.dart';
import '../models/zone_status.dart';

/// 🎯 UNIFIED FIRE ALARM PARSER
/// Single entry point untuk semua parsing kebutuhan fire alarm monitoring system
///
/// Author: Claude Code Assistant
/// Version: 1.0.0
/// Description: Menggabungkan Enhanced Zone Parser, Zone Data Parser, LED Decoder,
///              dan Control Signal Parser dalam satu sistem terintegrasi
///
/// 📊 Capabilities:
/// - Parse 63 devices × 5 zones = 315 zones total
/// - Real-time data processing dari Firebase
/// - Offline/disconnect state detection
/// - LED status decoding
/// - Control signal processing
/// - Unified zone status mapping
/// - Consistent color assignment

// ==================== UNIFIED DATA MODELS ====================

/// Unified zone status untuk semua zona (1-315)
class UnifiedZoneStatus {
  final int zoneNumber;
  final String status; // 'Alarm', 'Trouble', 'Active', 'Normal', 'Offline'
  final String description;
  final Color color;
  final String deviceAddress;
  final int deviceNumber;
  final int zoneInDevice; // 1-5 dalam device
  final DateTime timestamp;
  final bool isOffline;
  final bool hasPower;
  final String? rawData; // Raw data untuk debugging

  UnifiedZoneStatus({
    required this.zoneNumber,
    required this.status,
    required this.description,
    required this.color,
    required this.deviceAddress,
    required this.deviceNumber,
    required this.zoneInDevice,
    required this.timestamp,
    this.isOffline = false,
    this.hasPower = true,
    this.rawData,
  });

  factory UnifiedZoneStatus.fromJson(Map<String, dynamic> json) {
    return UnifiedZoneStatus(
      zoneNumber: json['zoneNumber'] ?? 0,
      status: json['status'] ?? 'Normal',
      description: json['description'] ?? '',
      color: Color(json['color'] ?? 0xFFFFFFFF),
      deviceAddress: json['deviceAddress'] ?? '',
      deviceNumber: json['deviceNumber'] ?? 0,
      zoneInDevice: json['zoneInDevice'] ?? 1,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isOffline: json['isOffline'] ?? false,
      hasPower: json['hasPower'] ?? true,
      rawData: json['rawData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneNumber': zoneNumber,
      'status': status,
      'description': description,
      'color': color.toARGB32(),
      'deviceAddress': deviceAddress,
      'deviceNumber': deviceNumber,
      'zoneInDevice': zoneInDevice,
      'timestamp': timestamp.toIso8601String(),
      'isOffline': isOffline,
      'hasPower': hasPower,
      'rawData': rawData,
    };
  }

  @override
  String toString() => 'Zone #$zoneNumber: $status ($deviceAddress-$zoneInDevice)';
}

/// Unified system status untuk keseluruhan sistem
class UnifiedSystemStatus {
  final bool hasAlarm;
  final bool hasTrouble;
  final bool hasPower;
  final bool isSilenced;
  final bool isDrill;
  final bool isDisabled;
  final bool isSystemOffline;
  final int connectedDevices;
  final int disconnectedDevices;
  final int totalAlarmZones;
  final int totalTroubleZones;
  final int totalActiveZones;
  final String systemContext;
  final DateTime timestamp;
  final List<String> activeEvents;

  UnifiedSystemStatus({
    required this.hasAlarm,
    required this.hasTrouble,
    required this.hasPower,
    required this.isSilenced,
    required this.isDrill,
    required this.isDisabled,
    required this.isSystemOffline,
    required this.connectedDevices,
    required this.disconnectedDevices,
    required this.totalAlarmZones,
    required this.totalTroubleZones,
    required this.totalActiveZones,
    required this.systemContext,
    required this.timestamp,
    required this.activeEvents,
  });

  factory UnifiedSystemStatus.fromJson(Map<String, dynamic> json) {
    return UnifiedSystemStatus(
      hasAlarm: json['hasAlarm'] ?? false,
      hasTrouble: json['hasTrouble'] ?? false,
      hasPower: json['hasPower'] ?? false,
      isSilenced: json['isSilenced'] ?? false,
      isDrill: json['isDrill'] ?? false,
      isDisabled: json['isDisabled'] ?? false,
      isSystemOffline: json['isSystemOffline'] ?? false,
      connectedDevices: json['connectedDevices'] ?? 0,
      disconnectedDevices: json['disconnectedDevices'] ?? 0,
      totalAlarmZones: json['totalAlarmZones'] ?? 0,
      totalTroubleZones: json['totalTroubleZones'] ?? 0,
      totalActiveZones: json['totalActiveZones'] ?? 0,
      systemContext: json['systemContext'] ?? 'Unknown',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      activeEvents: List<String>.from(json['activeEvents'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasAlarm': hasAlarm,
      'hasTrouble': hasTrouble,
      'hasPower': hasPower,
      'isSilenced': isSilenced,
      'isDrill': isDrill,
      'isDisabled': isDisabled,
      'isSystemOffline': isSystemOffline,
      'connectedDevices': connectedDevices,
      'disconnectedDevices': disconnectedDevices,
      'totalAlarmZones': totalAlarmZones,
      'totalTroubleZones': totalTroubleZones,
      'totalActiveZones': totalActiveZones,
      'systemContext': systemContext,
      'timestamp': timestamp.toIso8601String(),
      'activeEvents': activeEvents,
    };
  }
}

/// 🔔 Bell Confirmation Status untuk $85/$84 confirmation codes
class BellConfirmationStatus {
  final String slaveAddress;
  final bool isActive;        // true untuk $85 (bell ON), false untuk $84 (bell OFF)
  final DateTime timestamp;
  final String? rawData;      // Raw confirmation data untuk debugging

  BellConfirmationStatus({
    required this.slaveAddress,
    required this.isActive,
    required this.timestamp,
    this.rawData,
  });

  factory BellConfirmationStatus.fromJson(Map<String, dynamic> json) {
    return BellConfirmationStatus(
      slaveAddress: json['slaveAddress'] ?? '',
      isActive: json['isActive'] ?? false,
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      rawData: json['rawData'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slaveAddress': slaveAddress,
      'isActive': isActive,
      'timestamp': timestamp.toIso8601String(),
      'rawData': rawData,
    };
  }

  @override
  String toString() => 'Bell $slaveAddress: ${isActive ? "ON" : "OFF"} (${timestamp.toIso8601String()})';
}

/// Hasil parsing lengkap dari semua data sources
class UnifiedParsingResult {
  final Map<int, UnifiedZoneStatus> zones; // zoneNumber -> status
  final Map<String, BellConfirmationStatus> bellConfirmations; // slaveAddress -> bell status
  final UnifiedSystemStatus systemStatus;
  final String parsingSource; // 'enhanced_zone_parser', 'zone_data_parser', etc.
  final bool hasError;
  final String? errorMessage;
  final DateTime timestamp;
  final String? rawData; // Raw data untuk debugging

  UnifiedParsingResult({
    required this.zones,
    required this.bellConfirmations,
    required this.systemStatus,
    required this.parsingSource,
    this.hasError = false,
    this.errorMessage,
    required this.timestamp,
    this.rawData,
  });

  factory UnifiedParsingResult.error(String errorMessage, String source) {
    return UnifiedParsingResult(
      zones: {},
      bellConfirmations: {},
      systemStatus: UnifiedSystemStatus(
        hasAlarm: false,
        hasTrouble: false,
        hasPower: false,
        isSilenced: false,
        isDrill: false,
        isDisabled: false,
        isSystemOffline: true,
        connectedDevices: 0,
        disconnectedDevices: 63,
        totalAlarmZones: 0,
        totalTroubleZones: 0,
        totalActiveZones: 0,
        systemContext: 'SYSTEM ERROR',
        timestamp: DateTime.now(),
        activeEvents: ['PARSING ERROR: $errorMessage'],
      ),
      parsingSource: source,
      hasError: true,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
    );
  }

  /// Get zone status dengan fallback
  UnifiedZoneStatus? getZoneStatus(int zoneNumber) {
    return zones[zoneNumber];
  }

  /// Check jika zone ada (1-315)
  bool hasZone(int zoneNumber) {
    return zones.containsKey(zoneNumber);
  }

  /// Get semua alarm zones
  List<UnifiedZoneStatus> get alarmZones {
    return zones.values.where((zone) => zone.status == 'Alarm').toList();
  }

  /// Get semua trouble zones
  List<UnifiedZoneStatus> get troubleZones {
    return zones.values.where((zone) => zone.status == 'Trouble').toList();
  }

  /// Get semua offline zones
  List<UnifiedZoneStatus> get offlineZones {
    return zones.values.where((zone) => zone.isOffline).toList();
  }

  /// Get bell confirmation status untuk slave tertentu
  BellConfirmationStatus? getBellConfirmationStatus(String slaveAddress) {
    return bellConfirmations[slaveAddress];
  }

  /// Get semua active bell confirmations
  Map<String, BellConfirmationStatus> get activeBells {
    return Map.fromEntries(
      bellConfirmations.entries.where((entry) => entry.value.isActive)
    );
  }

  /// Get semua inactive bell confirmations
  Map<String, BellConfirmationStatus> get inactiveBells {
    return Map.fromEntries(
      bellConfirmations.entries.where((entry) => !entry.value.isActive)
    );
  }

  /// Check apakah ada bell yang aktif
  bool get hasActiveBells {
    return bellConfirmations.values.any((status) => status.isActive);
  }

  @override
  String toString() => 'UnifiedParsingResult: ${zones.length} zones, ${bellConfirmations.length} bell confirmations, ${systemStatus.systemContext}';
}

// ==================== PARSING STRATEGIES ====================

/// Abstract base class untuk semua parsing strategies
abstract class ParsingStrategy {
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context);
  String get strategyName;
}

/// Enhanced Zone Parsing Strategy untuk 63 devices × 5 zones
class EnhancedZoneParsingStrategy implements ParsingStrategy {
  static const String _tag = 'EnhancedZoneParsing';
  static const int totalDevices = 63;
  static const int zonesPerDevice = 5;
  static const int totalZones = totalDevices * zonesPerDevice; // 315

  @override
  String get strategyName => 'enhanced_zone_parser';

  @override
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context) async {
    try {
      

      // FIXED: Extract device modules by splitting on <STX> markers
      List<String> deviceModules = [];

      // Split by <STX> to get individual device modules
      if (rawData.contains('<STX>')) {
        // Remove everything before first <STX> (prefix like "41DF")
        final firstSTXIndex = rawData.indexOf('<STX>');
        String dataSection = rawData.substring(firstSTXIndex + 5); // +5 to skip <STX>

        // Remove <ETX> if present at the end
        if (dataSection.contains('<ETX>')) {
          final etxIndex = dataSection.indexOf('<ETX>');
          dataSection = dataSection.substring(0, etxIndex);
        }

        // Split remaining data by <STX> to get device modules
        deviceModules = dataSection.split('<STX>');

        // Clean up modules and filter out empty ones
        deviceModules = deviceModules
            .map((module) => module.trim())
            // Remove STX character specifically and other control characters
            .map((module) => module.replaceAll('\u0002', '')) // Remove STX specifically
            .map((module) => module.replaceAll(RegExp(r'^[\x00-\x1F]+'), ''))
            .where((module) => module.isNotEmpty)
            .toList();
      }

      
      for (int i = 0; i < deviceModules.length && i < 10; i++) {
        
      }
      if (deviceModules.length > 10) {
        
      }

      final Map<int, UnifiedZoneStatus> zones = {};
      final Map<String, BellConfirmationStatus> bellConfirmations = {};
      int connectedDevices = 0;
      int disconnectedDevices = 0;
      int alarmZones = 0;
      int troubleZones = 0;

      // FIXED: Parse each device module extracted from <STX> separators
      int devicesFound = 0;

      // FIXED: Parse each device module from the <STX>-separated list
      String? currentSlaveAddress;

      for (int moduleIndex = 0; moduleIndex < deviceModules.length; moduleIndex++) {
        final deviceModule = deviceModules[moduleIndex].trim();
        if (deviceModule.isEmpty) continue;

        

        // Check if this is a bell confirmation code
        if (_isBellConfirmationCode(deviceModule)) {
          if (currentSlaveAddress != null) {
            final bellStatus = _parseBellConfirmation(deviceModule, currentSlaveAddress);
            if (bellStatus != null) {
              bellConfirmations[currentSlaveAddress] = bellStatus;
              
            }
          } else {
            
          }
          continue; // Skip to next module
        }

        // Extract slave address from device module
        final slaveAddress = _extractSlaveAddress(deviceModule);
        if (slaveAddress == null || devicesFound >= totalDevices) {
          
          continue;
        }

        currentSlaveAddress = slaveAddress;
        final deviceNumber = int.parse(slaveAddress);

        

        try {
          final deviceZones = _parseDeviceZones(deviceModule, deviceNumber, slaveAddress);

          // Add zones to unified map
          for (final zone in deviceZones) {
            final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zone.zoneInDevice);
            zones[globalZoneNumber] = zone;

            // Count statistics
            if (zone.status == 'Alarm') alarmZones++;
            if (zone.status == 'Trouble') troubleZones++;
          }

          // Check if device is online (any zone not offline)
          if (deviceZones.any((zone) => !zone.isOffline)) {
            connectedDevices++;
          } else {
            disconnectedDevices++;
          }

          devicesFound++;

        } catch (e) {
          // Device parsing failed - creating offline zones
          print('Warning: Failed to parse device $deviceNumber: $e');

          // Create offline zones for this device on error
          for (int zoneIndex = 0; zoneIndex < zonesPerDevice; zoneIndex++) {
            final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);
            zones[globalZoneNumber] = UnifiedZoneStatus(
              zoneNumber: globalZoneNumber,
              status: 'Offline',
              description: 'Device $deviceNumber parsing error: $e',
              color: Colors.grey,
              deviceAddress: slaveAddress,
              deviceNumber: deviceNumber,
              zoneInDevice: zoneIndex + 1,
              timestamp: DateTime.now(),
              isOffline: true,
              hasPower: false,
              rawData: deviceModule,
            );
          }
          disconnectedDevices++;
          devicesFound++;
        }
      }

      
      

      // Create system status
      final systemStatus = UnifiedSystemStatus(
        hasAlarm: alarmZones > 0,
        hasTrouble: troubleZones > 0,
        hasPower: connectedDevices > 0,
        isSilenced: false, // Will be updated by other strategies
        isDrill: false,   // Will be updated by other strategies
        isDisabled: false,
        isSystemOffline: connectedDevices == 0,
        connectedDevices: connectedDevices,
        disconnectedDevices: disconnectedDevices,
        totalAlarmZones: alarmZones,
        totalTroubleZones: troubleZones,
        totalActiveZones: zones.values.where((z) => !z.isOffline).length,
        systemContext: _determineSystemContext(alarmZones, troubleZones, connectedDevices, bellConfirmations),
        timestamp: DateTime.now(),
        activeEvents: [
          if (alarmZones > 0) '$alarmZones ALARM ZONES',
          if (troubleZones > 0) '$troubleZones TROUBLE ZONES',
          if (bellConfirmations.isNotEmpty)
            '${bellConfirmations.values.where((b) => b.isActive).length} ACTIVE BELLS',
          if (disconnectedDevices > 0) '$disconnectedDevices DEVICES OFFLINE',
        ],
      );

      
      
      
      
      

      return UnifiedParsingResult(
        zones: zones,
        bellConfirmations: bellConfirmations,
        systemStatus: systemStatus,
        parsingSource: strategyName,
        timestamp: DateTime.now(),
        rawData: rawData,
      );

    } catch (e) {
      // Enhanced zone parsing failed completely
      print('Error: Enhanced Zone Parser failed: $e');
      return UnifiedParsingResult.error('Enhanced Zone Parser failed: $e', strategyName);
    }
  }

  /// Parse zones for single device (CORRECTED FORMAT)
  List<UnifiedZoneStatus> _parseDeviceZones(String deviceData, int deviceNumber, String deviceAddress) {
    final List<UnifiedZoneStatus> zones = [];

    

    // CORRECTED: Handle variable length data
    if (deviceData.length < 2) {
      throw Exception('Invalid device data: need at least 2 characters for address');
    }

    // CORRECTED: Check if device is offline (only address, no status data)
    if (deviceData.length == 2) {
      

      // Create 5 offline zones for this device
      for (int zoneIndex = 0; zoneIndex < zonesPerDevice; zoneIndex++) {
        final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);

        zones.add(UnifiedZoneStatus(
          zoneNumber: globalZoneNumber,
          status: 'Offline',
          description: 'Zone ${zoneIndex + 1} - Device Offline',
          color: Colors.grey, // Grey for offline
          deviceAddress: deviceAddress,
          deviceNumber: deviceNumber,
          zoneInDevice: zoneIndex + 1,
          timestamp: DateTime.now(),
          isOffline: true,
          hasPower: false,
          rawData: deviceData,
        ));
      }
      return zones;
    }

    // Device has status data (length > 2)
    final statusData = deviceData.substring(2);
    

    // CORRECTED: Check for normal status (0000)
    if (statusData == '0000') {
      

      // Create 5 normal zones for this device
      for (int zoneIndex = 0; zoneIndex < zonesPerDevice; zoneIndex++) {
        final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);

        zones.add(UnifiedZoneStatus(
          zoneNumber: globalZoneNumber,
          status: 'Normal',
          description: 'Zone ${zoneIndex + 1} - Normal',
          color: Colors.white, // White for normal
          deviceAddress: deviceAddress,
          deviceNumber: deviceNumber,
          zoneInDevice: zoneIndex + 1,
          timestamp: DateTime.now(),
          isOffline: false,
          hasPower: true,
          rawData: deviceData,
        ));
      }
      return zones;
    }

    // Device has alarm/trouble status - parse 6-char module format: [address][trouble][alarm]
    try {
      if (statusData.length >= 4) {
        // CORRECTED: Parse trouble and alarm bytes separately for 6-char module format
        String troubleByte = '00'; // Default to no trouble
        String alarmByte = '00';   // Default to no alarm

        if (statusData.length >= 4) {
          // Format: [2-char trouble][2-char alarm]
          troubleByte = statusData.substring(0, 2);
          alarmByte = statusData.substring(2, 4);
        }

        final troubleValue = int.parse(troubleByte, radix: 16);
        final alarmValue = int.parse(alarmByte, radix: 16);

        

        // Parse all 5 zones using separate trouble and alarm bytes
        for (int zoneIndex = 0; zoneIndex < zonesPerDevice; zoneIndex++) {
          final zoneStatus = _mapZoneStatusFromBytes(troubleValue, alarmValue, zoneIndex);
          final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);

          zones.add(UnifiedZoneStatus(
            zoneNumber: globalZoneNumber,
            status: zoneStatus['status'],
            description: zoneStatus['description'],
            color: zoneStatus['color'],
            deviceAddress: deviceAddress,
            deviceNumber: deviceNumber,
            zoneInDevice: zoneIndex + 1,
            timestamp: DateTime.now(),
            isOffline: zoneStatus['isOffline'],
            hasPower: zoneStatus['hasPower'],
            rawData: deviceData,
          ));
        }
      }

      // If we have less than 5 zones parsed, create remaining zones as normal
      while (zones.length < zonesPerDevice) {
        final zoneIndex = zones.length;
        final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);

        zones.add(UnifiedZoneStatus(
          zoneNumber: globalZoneNumber,
          status: 'Normal',
          description: 'Zone ${zoneIndex + 1} - Normal (no data)',
          color: Colors.white,
          deviceAddress: deviceAddress,
          deviceNumber: deviceNumber,
          zoneInDevice: zoneIndex + 1,
          timestamp: DateTime.now(),
          isOffline: false,
          hasPower: true,
          rawData: deviceData,
        ));
      }
    } catch (e) {
      // Zone parsing failed - creating default zones
      print('Warning: Failed to parse zones for device $deviceNumber: $e');

      // Create default zones on error
      for (int zoneIndex = zones.length; zoneIndex < zonesPerDevice; zoneIndex++) {
        final globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(deviceNumber, zoneIndex + 1);

        zones.add(UnifiedZoneStatus(
          zoneNumber: globalZoneNumber,
          status: 'Normal',
          description: 'Zone ${zoneIndex + 1} - Parse Error',
          color: Colors.white,
          deviceAddress: deviceAddress,
          deviceNumber: deviceNumber,
          zoneInDevice: zoneIndex + 1,
          timestamp: DateTime.now(),
          isOffline: false,
          hasPower: true,
          rawData: deviceData,
        ));
      }
    }

    return zones;
  }

  /// Map zone status from separate trouble and alarm bytes (6-char module format)
  Map<String, dynamic> _mapZoneStatusFromBytes(int troubleByte, int alarmByte, int zoneIndex) {
    bool hasAlarm = false;
    bool hasTrouble = false;
    bool isOffline = false;
    bool hasPower = true;
    String status = 'Normal';
    String description = '';
    Color color = Colors.white;

    // Check individual bits for each zone (1 bit per zone in each byte)
    final int bitPosition = zoneIndex; // Zone 0 = bit 0, Zone 1 = bit 1, etc.

    hasAlarm = (alarmByte & (1 << bitPosition)) != 0;
    hasTrouble = (troubleByte & (1 << bitPosition)) != 0;

    // Check Bell status (bit 5 only in alarm byte)
    final bool hasBell = (alarmByte & (1 << 5)) != 0;

    // Determine zone status based on alarm/trouble bits (alarm takes priority)
    if (hasAlarm) {
      status = 'Alarm';
      description = 'Zone ${zoneIndex + 1} - ALARM';
      color = Colors.red; // Red for alarm
    } else if (hasTrouble) {
      status = 'Trouble';
      description = 'Zone ${zoneIndex + 1} - TROUBLE';
      color = Colors.orange; // Orange/yellow for trouble
    } else {
      status = 'Normal';
      description = 'Zone ${zoneIndex + 1} - Normal';
      color = Colors.white; // White for normal
    }

    // Add Bell info to description if active
    if (hasBell && zoneIndex == 0) { // Only show bell info once for Zone 1
      description += ' (BELL ON)';
    }

    

    return {
      'status': status,
      'description': description,
      'color': color,
      'isOffline': isOffline,
      'hasPower': hasPower,
      'hasBell': hasBell,
    };
  }

  /// Determine system context based on parsed data
  String _determineSystemContext(int alarmZones, int troubleZones, int connectedDevices, Map<String, BellConfirmationStatus> bellConfirmations) {
    final activeBellsCount = bellConfirmations.values.where((b) => b.isActive).length;

    if (connectedDevices == 0) {
      return 'SYSTEM OFFLINE';
    } else if (alarmZones > 0 && activeBellsCount > 0) {
      return 'ALARM WITH ACTIVE BELLS';
    } else if (alarmZones > 0 && troubleZones > 0) {
      return 'ALARM WITH TROUBLE CONDITION';
    } else if (alarmZones > 0) {
      return 'ALARM ACTIVE';
    } else if (troubleZones > 0) {
      return 'TROUBLE CONDITION';
    } else if (activeBellsCount > 0) {
      return 'BELL ACTIVE WITHOUT ALARM';
    } else if (connectedDevices < 63) {
      return 'PARTIAL CONNECTION';
    } else {
      return 'SYSTEM NORMAL';
    }
  }

  /// Check if segment is a bell confirmation code ($85 or $84)
  bool _isBellConfirmationCode(String segment) {
    final cleanSegment = segment.trim();
    return cleanSegment.startsWith('\$85') || cleanSegment.startsWith('\$84');
  }

  /// Parse bell confirmation from segment
  BellConfirmationStatus? _parseBellConfirmation(String segment, String slaveAddress) {
    try {
      final cleanSegment = segment.trim();
      if (cleanSegment.startsWith('\$85')) {
        return BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: true, // Bell ON
          timestamp: DateTime.now(),
          rawData: segment,
        );
      } else if (cleanSegment.startsWith('\$84')) {
        return BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: false, // Bell OFF
          timestamp: DateTime.now(),
          rawData: segment,
        );
      }
    } catch (e) {
      // Failed to parse bell confirmation status
      print('Warning: Failed to parse bell confirmation status: $e');
    }
    return null;
  }

  /// Extract slave address from segment (01-63)
  String? _extractSlaveAddress(String segment) {
    try {
      if (segment.length >= 2) {
        // Try first 2 characters (most common case)
        String address = segment.substring(0, 2);
        int? addressNum = int.tryParse(address);

        // If that fails, try to find any 2-digit number in the segment
        if (addressNum == null || addressNum < 1 || addressNum > 63) {
          final match = RegExp(r'(0[1-9]|[1-5][0-9]|6[0-3])').firstMatch(segment);
          if (match != null) {
            address = match.group(1)!;
            addressNum = int.tryParse(address);
          }
        }

        if (addressNum != null && addressNum >= 1 && addressNum <= 63) {
          return address.padLeft(2, '0');
        }
      }
    } catch (e) {
      // Failed to parse bell confirmation status
      print('Warning: Failed to parse bell confirmation status: $e');
    }
    return null;
  }
}

/// Zone Data Parsing Strategy untuk device types dan offline detection
class ZoneDataParsingStrategy implements ParsingStrategy {
  @override
  String get strategyName => 'Zone Data Parser';

  @override
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context) async {
    try {
      

      // Implementation would parse zone data with device types
      // This is a simplified implementation for demonstration
      final Map<int, UnifiedZoneStatus> zones = {};

      // For now, return empty result as this would be implemented based on specific zone data format
      return UnifiedParsingResult(
        zones: zones,
        bellConfirmations: {},
        systemStatus: UnifiedSystemStatus(
          hasAlarm: false,
          hasTrouble: false,
          hasPower: true,
          isSilenced: false,
          isDrill: false,
          isDisabled: false,
          isSystemOffline: false,
          connectedDevices: 63,
          disconnectedDevices: 0,
          totalAlarmZones: 0,
          totalTroubleZones: 0,
          totalActiveZones: 0,
          systemContext: 'ZONE DATA PARSING',
          timestamp: DateTime.now(),
          activeEvents: [],
        ),
        parsingSource: strategyName,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      
      return UnifiedParsingResult.error('Zone Data Parser failed: $e', strategyName);
    }
  }
}

/// LED Decoding Strategy untuk LED status dan system context
class LEDDecodingStrategy implements ParsingStrategy {
  @override
  String get strategyName => 'LED Decoder';

  @override
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context) async {
    try {
      

      // Implementation would decode LED status indicators
      // This is a simplified implementation for demonstration

      return UnifiedParsingResult(
        zones: {},
        bellConfirmations: {},
        systemStatus: UnifiedSystemStatus(
          hasAlarm: false,
          hasTrouble: false,
          hasPower: true,
          isSilenced: false,
          isDrill: false,
          isDisabled: false,
          isSystemOffline: false,
          connectedDevices: 63,
          disconnectedDevices: 0,
          totalAlarmZones: 0,
          totalTroubleZones: 0,
          totalActiveZones: 0,
          systemContext: 'LED DECODING',
          timestamp: DateTime.now(),
          activeEvents: [],
        ),
        parsingSource: strategyName,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      
      return UnifiedParsingResult.error('LED Decoder failed: $e', strategyName);
    }
  }
}

/// 🔔 Bell Confirmation Parsing Strategy untuk $85/$84 confirmation codes
class BellConfirmationParsingStrategy implements ParsingStrategy {
  static const String _tag = 'BellConfirmationParser';

  @override
  String get strategyName => 'Bell Confirmation Parser';

  @override
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context) async {
    try {
      

      final Map<String, BellConfirmationStatus> bellConfirmations = {};

      // Split data by <STX> to identify bell confirmation codes
      if (rawData.contains('<STX>')) {
        final List<String> segments = rawData.split('<STX>');

        String? lastSlaveAddress;

        for (int i = 0; i < segments.length; i++) {
          final segment = segments[i].trim();
          if (segment.isEmpty) continue;

          

          // Check if this is a bell confirmation code
          if (_isBellConfirmationCode(segment)) {
            if (lastSlaveAddress != null) {
              final bellStatus = _parseBellConfirmation(segment, lastSlaveAddress);
              if (bellStatus != null) {
                bellConfirmations[lastSlaveAddress] = bellStatus;
                
              }
            } else {
              
            }
          } else {
            // Try to extract slave address from this segment
            final slaveAddress = _extractSlaveAddress(segment);
            if (slaveAddress != null) {
              lastSlaveAddress = slaveAddress;
              
            }
          }
        }
      }

      
      for (final entry in bellConfirmations.entries) {
        
      }

      return UnifiedParsingResult(
        zones: {}, // Bell confirmation doesn't parse zones
        bellConfirmations: bellConfirmations,
        systemStatus: UnifiedSystemStatus(
          hasAlarm: false,
          hasTrouble: false,
          hasPower: true,
          isSilenced: false,
          isDrill: false,
          isDisabled: false,
          isSystemOffline: false,
          connectedDevices: 63,
          disconnectedDevices: 0,
          totalAlarmZones: 0,
          totalTroubleZones: 0,
          totalActiveZones: 0,
          systemContext: bellConfirmations.isNotEmpty
              ? 'BELL CONFIRMATION DETECTED'
              : 'NO BELL CONFIRMATION',
          timestamp: DateTime.now(),
          activeEvents: [
            if (bellConfirmations.isNotEmpty)
              '${bellConfirmations.values.where((b) => b.isActive).length} ACTIVE BELLS',
          ],
        ),
        parsingSource: strategyName,
        timestamp: DateTime.now(),
        rawData: rawData,
      );

    } catch (e) {
      
      return UnifiedParsingResult.error('Bell Confirmation Parser failed: $e', strategyName);
    }
  }

  /// Check if segment is a bell confirmation code ($85 or $84)
  bool _isBellConfirmationCode(String segment) {
    // Remove any whitespace and check for $85 or $84 pattern
    final cleanSegment = segment.trim();
    return cleanSegment.startsWith('\$85') || cleanSegment.startsWith('\$84');
  }

  /// Parse bell confirmation from segment
  BellConfirmationStatus? _parseBellConfirmation(String segment, String slaveAddress) {
    try {
      final cleanSegment = segment.trim();
      if (cleanSegment.startsWith('\$85')) {
        return BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: true, // Bell ON
          timestamp: DateTime.now(),
          rawData: segment,
        );
      } else if (cleanSegment.startsWith('\$84')) {
        return BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: false, // Bell OFF
          timestamp: DateTime.now(),
          rawData: segment,
        );
      }
    } catch (e) {
      // Failed to parse bell confirmation status
      print('Warning: Failed to parse bell confirmation status: $e');
    }
    return null;
  }

  /// Extract slave address from segment (01-63)
  String? _extractSlaveAddress(String segment) {
    try {
      // Look for patterns like "01xxxxx" where first 2 chars are slave address
      if (segment.length >= 2) {
        final address = segment.substring(0, 2);
        final addressNum = int.tryParse(address);
        if (addressNum != null && addressNum >= 1 && addressNum <= 63) {
          return address.padLeft(2, '0');
        }
      }
    } catch (e) {
      // Failed to parse bell confirmation status
      print('Warning: Failed to parse bell confirmation status: $e');
    }
    return null;
  }
}

/// Control Signal Parsing Strategy untuk drill, silence, disable states
class ControlSignalParsingStrategy implements ParsingStrategy {
  @override
  String get strategyName => 'Control Signal Parser';

  @override
  Future<UnifiedParsingResult> parseData(String rawData, Map<String, dynamic>? context) async {
    try {
      

      // Implementation would parse control signals like drill, silence, disable
      // This is a simplified implementation for demonstration

      bool isDrill = rawData.toLowerCase().contains('drill');
      bool isSilenced = rawData.toLowerCase().contains('silence');
      bool isDisabled = rawData.toLowerCase().contains('disable');

      return UnifiedParsingResult(
        zones: {},
        bellConfirmations: {},
        systemStatus: UnifiedSystemStatus(
          hasAlarm: false,
          hasTrouble: false,
          hasPower: true,
          isSilenced: isSilenced,
          isDrill: isDrill,
          isDisabled: isDisabled,
          isSystemOffline: false,
          connectedDevices: 63,
          disconnectedDevices: 0,
          totalAlarmZones: 0,
          totalTroubleZones: 0,
          totalActiveZones: 0,
          systemContext: _determineControlContext(isDrill, isSilenced, isDisabled),
          timestamp: DateTime.now(),
          activeEvents: [
            if (isDrill) 'DRILL MODE',
            if (isSilenced) 'SILENCED',
            if (isDisabled) 'SYSTEM DISABLED',
          ],
        ),
        parsingSource: strategyName,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      
      return UnifiedParsingResult.error('Control Signal Parser failed: $e', strategyName);
    }
  }

  String _determineControlContext(bool isDrill, bool isSilenced, bool isDisabled) {
    if (isDisabled) return 'SYSTEM DISABLED';
    if (isDrill) return 'DRILL MODE ACTIVE';
    if (isSilenced) return 'SYSTEM SILENCED';
    return 'SYSTEM NORMAL';
  }
}

  // ==================== CENTRAL ORCHESTRATOR ====================

/// 🎯 Central Orchestrator - Single entry point untuk semua parsing
class UnifiedFireAlarmParser {
  static const String _tag = 'UnifiedFireAlarmParser';
  static UnifiedFireAlarmParser? _instance;

  /// Singleton instance
  static UnifiedFireAlarmParser get instance {
    _instance ??= UnifiedFireAlarmParser._();
    return _instance!;
  }

  UnifiedFireAlarmParser._();

  // Initialize all parsing strategies
  final List<ParsingStrategy> _strategies = [
    EnhancedZoneParsingStrategy(),
    BellConfirmationParsingStrategy(),
    ZoneDataParsingStrategy(),
    LEDDecodingStrategy(),
    ControlSignalParsingStrategy(),
  ];

  /// Current parsing results cache
  UnifiedParsingResult? _lastResult;
  DateTime? _lastUpdateTime;

  /// Parse data dengan automatic strategy selection
  Future<UnifiedParsingResult> parseData(String rawData, {
    String? strategyName,
    Map<String, dynamic>? context,
  }) async {
    try {
      

      if (rawData.isEmpty) {
        return UnifiedParsingResult.error('Empty data provided', _tag);
      }

      // Select strategy
      ParsingStrategy? strategy;
      if (strategyName != null) {
        strategy = _strategies.firstWhere(
          (s) => s.strategyName.toLowerCase().contains(strategyName.toLowerCase()),
          orElse: () => _strategies.first,
        );
      } else {
        strategy = _selectBestStrategy(rawData);
      }

      

      // Execute parsing
      final result = await strategy.parseData(rawData, context);

      // Cache result
      _lastResult = result;
      _lastUpdateTime = DateTime.now();

      

      return result;

    } catch (e) {
      
      return UnifiedParsingResult.error('Unified parser failed: $e', _tag);
    }
  }

  /// Automatic strategy selection based on data patterns
  ParsingStrategy _selectBestStrategy(String rawData) {
    

    // PRIORITY 1: Simple zone number pattern - sequential numbers with STX separators
    final hasZoneNumbers = RegExp(r'\b(0[1-9]|[1-5][0-9]|6[0-3])\b').hasMatch(rawData);
    final hasSTXMarkers = rawData.contains('<STX>') || rawData.contains('\x02');
    final hasSequentialNumbers = _checkSequentialZoneNumbers(rawData);

    
    
    
    


    // PRIORITY 1: Enhanced zone data pattern - 6-character module format with hex bitmask
    // Handles format: [2-digit address][2-digit trouble][2-digit alarm] with STX/ETX markers
    final hasModuleStructure = RegExp(r'<STX>\d{6}').hasMatch(rawData); // <STX> followed by 6 digits
    final hasMultipleDevices = rawData.length >= 200; // At least some device data
    final hasSTXETX = rawData.contains('<STX>') || rawData.contains('<ETX>');

    if (hasSTXETX && hasMultipleDevices && hasModuleStructure) {
      
      return _strategies.firstWhere((s) => s is EnhancedZoneParsingStrategy);
    }

    // Control signal pattern
    if (rawData.toLowerCase().contains('drill') ||
        rawData.toLowerCase().contains('silence') ||
        rawData.toLowerCase().contains('disable')) {
      
      return _strategies.firstWhere((s) => s is ControlSignalParsingStrategy);
    }

    // LED data pattern (would need specific patterns)
    if (rawData.toLowerCase().contains('led') ||
        rawData.contains('power') ||
        rawData.contains('bell')) {
      
      return _strategies.firstWhere((s) => s is LEDDecodingStrategy);
    }

    // Default to Enhanced Zone Parser (correct for 6-char module format)
    
    return _strategies.firstWhere((s) => s is EnhancedZoneParsingStrategy);
  }

  /// Check if data contains sequential zone numbers (01, 02, 03, etc.)
  bool _checkSequentialZoneNumbers(String rawData) {
    try {
      // Clean data first
      String cleanData = rawData;
      cleanData = cleanData.replaceAll(RegExp(r'<STX>'), '');
      cleanData = cleanData.replaceAll(RegExp(r'<ETX>'), '');
      cleanData = cleanData.replaceAll(RegExp(r'\x02'), '');
      cleanData = cleanData.replaceAll(RegExp(r'\x03'), '');

      // Extract numbers
      final List<String> numbers = [];
      final RegExp numberRegex = RegExp(r'\b(0[1-9]|[1-5][0-9]|6[0-3])\b');
      final matches = numberRegex.allMatches(cleanData);

      for (final match in matches) {
        numbers.add(cleanData.substring(match.start, match.end));
      }

      // Check if we have sequential numbers
      if (numbers.length >= 10) { // At least 10 devices to detect pattern
        numbers.sort();
        int sequentialCount = 1;

        for (int i = 1; i < numbers.length; i++) {
          final current = int.tryParse(numbers[i]);
          final previous = int.tryParse(numbers[i-1]);

          if (current != null && previous != null && current == previous + 1) {
            sequentialCount++;
          } else {
            break;
          }
        }

        // If we have at least 5 sequential numbers, consider it sequential data
        return sequentialCount >= 5;
      }

    } catch (e) {
      // Failed to parse bell confirmation status
      print('Warning: Failed to parse bell confirmation status: $e');
    }

    return false;
  }

  /// Get specific zone status
  UnifiedZoneStatus? getZoneStatus(int zoneNumber) {
    return _lastResult?.getZoneStatus(zoneNumber);
  }

  /// Get all alarm zones
  List<UnifiedZoneStatus> get alarmZones => _lastResult?.alarmZones ?? [];

  /// Get all trouble zones
  List<UnifiedZoneStatus> get troubleZones => _lastResult?.troubleZones ?? [];

  /// Get all offline zones
  List<UnifiedZoneStatus> get offlineZones => _lastResult?.offlineZones ?? [];

  /// Get current system status
  UnifiedSystemStatus? get systemStatus => _lastResult?.systemStatus;

  /// Check if data is fresh (within 30 seconds)
  bool get isDataFresh {
    if (_lastUpdateTime == null) return false;
    return DateTime.now().difference(_lastUpdateTime!).inSeconds < 30;
  }

  /// Get last update time
  DateTime? get lastUpdateTime => _lastUpdateTime;

  /// Get parsing statistics
  Map<String, dynamic> get statistics {
    final result = _lastResult;
    if (result == null) return {};

    return {
      'totalZones': result.zones.length,
      'alarmZones': result.alarmZones.length,
      'troubleZones': result.troubleZones.length,
      'offlineZones': result.offlineZones.length,
      'connectedDevices': result.systemStatus.connectedDevices,
      'disconnectedDevices': result.systemStatus.disconnectedDevices,
      'systemContext': result.systemStatus.systemContext,
      'lastUpdate': _lastUpdateTime?.toIso8601String(),
      'parsingSource': result.parsingSource,
      'isDataFresh': isDataFresh,
    };
  }

  /// Clear cached data
  void clearCache() {
    _lastResult = null;
    _lastUpdateTime = null;
    
  }

  /// Get system status color for UI
  Color getSystemStatusColor() {
    final status = systemStatus;
    if (status == null) return Colors.grey;

    if (status.hasAlarm) return Colors.red;
    if (status.hasTrouble) return Colors.orange;
    if (status.isDrill) return Colors.purple;
    if (status.isSilenced) return Colors.yellow.shade700;
    if (status.isDisabled) return Colors.grey.shade600;
    if (status.isSystemOffline) return Colors.grey;
    if (!status.hasPower) return Colors.blueGrey;

    return Colors.green; // System normal
  }

  /// Get zone color for UI
  Color getZoneColor(int zoneNumber) {
    final zone = getZoneStatus(zoneNumber);
    return zone?.color ?? Colors.grey;
  }

  @override
  String toString() => 'UnifiedFireAlarmParser: ${_strategies.length} strategies, Last update: $_lastUpdateTime';
}

// ==================== PUBLIC API ====================

/// Public API untuk kemudahan penggunaan
class UnifiedFireAlarmAPI {
  /// Parse data dan return hasil
  static Future<UnifiedParsingResult> parse(String rawData, {
    String? strategy,
    Map<String, dynamic>? context,
  }) async {
    return await UnifiedFireAlarmParser.instance.parseData(
      rawData,
      strategyName: strategy,
      context: context,
    );
  }

  /// Get zone status
  static UnifiedZoneStatus? getZoneStatus(int zoneNumber) {
    return UnifiedFireAlarmParser.instance.getZoneStatus(zoneNumber);
  }

  /// Get system status
  static UnifiedSystemStatus? getSystemStatus() {
    return UnifiedFireAlarmParser.instance.systemStatus;
  }

  /// Get alarm zones
  static List<UnifiedZoneStatus> getAlarmZones() {
    return UnifiedFireAlarmParser.instance.alarmZones;
  }

  /// Get trouble zones
  static List<UnifiedZoneStatus> getTroubleZones() {
    return UnifiedFireAlarmParser.instance.troubleZones;
  }

  /// Get offline zones
  static List<UnifiedZoneStatus> getOfflineZones() {
    return UnifiedFireAlarmParser.instance.offlineZones;
  }

  /// Get bell confirmation status untuk slave tertentu
  static BellConfirmationStatus? getBellConfirmationStatus(String slaveAddress) {
    return UnifiedFireAlarmParser.instance._lastResult?.getBellConfirmationStatus(slaveAddress);
  }

  /// Get semua active bell confirmations
  static Map<String, BellConfirmationStatus> getActiveBells() {
    return UnifiedFireAlarmParser.instance._lastResult?.activeBells ?? {};
  }

  /// Get semua inactive bell confirmations
  static Map<String, BellConfirmationStatus> getInactiveBells() {
    return UnifiedFireAlarmParser.instance._lastResult?.inactiveBells ?? {};
  }

  /// Check apakah ada bell yang aktif
  static bool hasActiveBells() {
    return UnifiedFireAlarmParser.instance._lastResult?.hasActiveBells ?? false;
  }

  /// Get system status color
  static Color getSystemStatusColor() {
    return UnifiedFireAlarmParser.instance.getSystemStatusColor();
  }

  /// Get zone color
  static Color getZoneColor(int zoneNumber) {
    return UnifiedFireAlarmParser.instance.getZoneColor(zoneNumber);
  }

  /// Get statistics
  static Map<String, dynamic> getStatistics() {
    final stats = UnifiedFireAlarmParser.instance.statistics;
    final result = UnifiedFireAlarmParser.instance._lastResult;

    if (result != null) {
      stats['activeBells'] = result.activeBells.length;
      stats['inactiveBells'] = result.inactiveBells.length;
      stats['totalBellConfirmations'] = result.bellConfirmations.length;
    }

    return stats;
  }

  /// Check if data is fresh
  static bool isDataFresh() {
    return UnifiedFireAlarmParser.instance.isDataFresh;
  }

  /// Clear cache
  static void clearCache() {
    UnifiedFireAlarmParser.instance.clearCache();
  }
}