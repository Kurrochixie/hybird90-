import 'dart:async';
import 'package:flutter/material.dart';
import 'enhanced_zone_parser.dart'; // For LEDStatusData

/// LED Status model for decoded LED data
class LEDStatus {
  final String rawData;
  final int firstByte;
  final int ledByte;
  final String ledBinary;
  final LEDStatusData ledStatus;
  final SystemContext systemContext;
  final DateTime timestamp;

  LEDStatus({
    required this.rawData,
    required this.firstByte,
    required this.ledByte,
    required this.ledBinary,
    required this.ledStatus,
    required this.systemContext,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LEDStatus.fromJson(Map<String, dynamic> json) {
    // Create LEDStatusData from map since enhanced_zone_parser version doesn't have fromJson
    final ledStatusMap = json['ledStatus'] as Map<String, dynamic>? ?? {};
    final ledStatusData = LEDStatusData(
      acPowerOn: ledStatusMap['AC Power'] ?? false,
      dcPowerOn: ledStatusMap['DC Power'] ?? false,
      alarmOn: ledStatusMap['Alarm'] ?? false,
      troubleOn: ledStatusMap['Trouble'] ?? false,
      drillOn: ledStatusMap['Drill'] ?? false,
      silencedOn: ledStatusMap['Silenced'] ?? false,
      disabledOn: ledStatusMap['Disabled'] ?? false,
      timestamp: ledStatusMap['timestamp'] != null
          ? DateTime.tryParse(ledStatusMap['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      rawData: ledStatusMap['rawData']?.toString(),
    );

    return LEDStatus(
      rawData: json['rawData'] ?? '',
      firstByte: json['firstByte'] ?? 0,
      ledByte: json['ledByte'] ?? 0,
      ledBinary: json['ledBinary'] ?? '',
      ledStatus: ledStatusData,
      systemContext: SystemContext.values.firstWhere(
        (e) => e.toString() == json['systemContext'],
        orElse: () => SystemContext.systemNormal,
      ),
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    // Convert LEDStatusData to map since enhanced_zone_parser version doesn't have toJson
    final ledStatusMap = {
      'AC Power': ledStatus.acPowerOn,
      'DC Power': ledStatus.dcPowerOn,
      'Alarm': ledStatus.alarmOn,
      'Trouble': ledStatus.troubleOn,
      'Drill': ledStatus.drillOn,
      'Silenced': ledStatus.silencedOn,
      'Disabled': ledStatus.disabledOn,
      'timestamp': ledStatus.timestamp.toIso8601String(),
      'rawData': ledStatus.rawData,
    };

    return {
      'rawData': rawData,
      'firstByte': firstByte,
      'ledByte': ledByte,
      'ledBinary': ledBinary,
      'ledStatus': ledStatusMap,
      'systemContext': systemContext.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LEDStatus(rawData: $rawData, context: $systemContext, timestamp: $timestamp)';
  }
}

/// Local LEDStatusData class removed to avoid conflicts with enhanced_zone_parser.dart
/// Using LEDStatusData from enhanced_zone_parser.dart which includes timestamp and rawData fields

/// LED Types enumeration
enum LEDType {
  disabled,     // Bit 0
  silenced,     // Bit 1
  drill,        // Bit 2
  trouble,      // Bit 3
  alarm,        // Bit 4
  dcPower,      // Bit 5
  acPower,      // Bit 6
}

/// System Context enumeration
enum SystemContext {
  systemDisabledMaintenance,  // DISABLED = true
  systemSilencedManual,      // SILENCED = true
  alarmWithTroubleCondition, // ALARM + TROUBLE = true
  alarmWithDrillActive,     // ALARM + DRILL = true
  fullAlarmActive,           // ALARM = true only
  troubleConditionOnly,      // TROUBLE = true only
  supervisoryPreAlarm,       // SUPERVISORY = true only
  systemNormal,              // All LEDs OFF
}

/// LED Status Decoder Service
class LEDStatusDecoder {
  static const String _tag = 'LED_DECODER';

  // Stream controllers for real-time updates
  final StreamController<LEDStatus?> _ledStatusController =
      StreamController<LEDStatus?>.broadcast();
  final StreamController<String?> _rawLEDDataController =
      StreamController<String?>.broadcast();

  LEDStatus? _currentLEDStatus;

  // Track all subscriptions for proper cleanup
  final List<StreamSubscription> _subscriptions = [];

  /// Stream untuk mendapatkan update status LED real-time
  Stream<LEDStatus?> get ledStatusStream => _ledStatusController.stream;

  /// Stream untuk mendapatkan data mentah LED
  Stream<String?> get rawLEDDataStream => _rawLEDDataController.stream;

  /// Get current LED status
  LEDStatus? get currentLEDStatus => _currentLEDStatus;

  /// Start monitoring LED data from Firebase (OBSOLETE - replaced by Zone Parser)
  void startMonitoring() {
    
    

    // 🔥 REMOVED: All Firebase listeners for Path A & B (system_status/led_status, system_status/data)
    // LED data now comes exclusively from Path C (all_slave_data/raw_data) via Zone Parser

    // Keep the method for backward compatibility but don't start any listeners
    
  }

  
  /// 🔥 REMOVED: Manual LED data processing (Path A & B - OBSOLETE)
  /// LED data processing now comes from Path C via Zone Parser
  LEDStatus? processManualLEDData(String rawData) {
    
    

    // Return current LED status if available
    return _currentLEDStatus;
  }

  /// Get LED color for specific LED type
  Color? getLEDColor(LEDType ledType) {
    if (_currentLEDStatus == null) {
      
      return null;
    }
    final color = _getLEDColorFromData(_currentLEDStatus!.ledStatus, ledType);
    final isOn = _getLEDStatusFromData(_currentLEDStatus!.ledStatus, ledType);
    
    return color;
  }

  /// Get LED status for specific LED type
  bool? getLEDStatus(LEDType ledType) {
    if (_currentLEDStatus == null) {
      
      return null;
    }
    final status = _getLEDStatusFromData(_currentLEDStatus!.ledStatus, ledType);
    
    return status;
  }

  /// Get current system context
  SystemContext? get currentSystemContext => _currentLEDStatus?.systemContext;

  /// Check if system is in alarm state
  bool get isSystemInAlarm => _currentLEDStatus?.ledStatus.alarmOn ?? false;

  /// Check if system is in trouble state
  bool get isSystemInTrouble => _currentLEDStatus?.ledStatus.troubleOn ?? false;

  /// Check if system is silenced
  bool get isSystemSilenced => _currentLEDStatus?.ledStatus.silencedOn ?? false;

  /// Check if system is disabled
  bool get isSystemDisabled => _currentLEDStatus?.ledStatus.disabledOn ?? false;

  /// Get power status summary
  PowerStatus get powerStatus {
    if (_currentLEDStatus == null) {
      return PowerStatus.unknown;
    }
    
    bool acOn = _currentLEDStatus!.ledStatus.acPowerOn;
    bool dcOn = _currentLEDStatus!.ledStatus.dcPowerOn;
    
    if (acOn && dcOn) {
      return PowerStatus.bothOn;
    } else if (acOn && !dcOn) {
      return PowerStatus.acOnly;
    } else if (!acOn && dcOn) {
      return PowerStatus.dcOnly;
    } else {
      return PowerStatus.bothOff;
    }
  }

  /// 🔥 FIXED: Connect to Zone Parser data stream (Path C - Single Source of Truth)
  void connectToZoneParser(Stream<Map<String, dynamic>> zoneParserStream) {
    

    // Cancel existing Firebase monitoring first
    stopFirebaseMonitoring();

    final zoneParserSubscription = zoneParserStream.listen((Map<String, dynamic> result) {
      try {
        

        // Convert zone parser result to LED status
        _processZoneParserLEDData(result);
      } catch (e) {
        
      }
    });

    _subscriptions.add(zoneParserSubscription);
    
  }

  /// 🔥 FIXED: Process LED data from Zone Parser result - Type Safe (PUBLIC)
  void processZoneParserLEDData(Map<String, dynamic> parserResult) {
    _processZoneParserLEDData(parserResult);
  }

  /// 🔥 FIXED: Internal method for LED data processing
  void _processZoneParserLEDData(Map<String, dynamic> parserResult) {
    try {
      

      // 🔥 FIXED: Direct conversion from Map<String, dynamic> to LEDStatusData
      final ledStatusData = _convertMapToLEDStatusData(parserResult);

      // Convert LEDStatusData to LEDStatus using existing logic
      final ledStatus = _convertLEDStatusDataToLEDStatus(ledStatusData);

      // Update current status
      _currentLEDStatus = ledStatus;

      // Broadcast update
      if (!_ledStatusController.isClosed) {
        _ledStatusController.add(ledStatus);
      }

      // Broadcast raw data for compatibility
      if (!_rawLEDDataController.isClosed && ledStatus.rawData.isNotEmpty) {
        _rawLEDDataController.add(ledStatus.rawData);
      }

      
      

    } catch (e, stackTrace) {
      
      
    }
  }

  /// Convert map data to LEDStatusData
  LEDStatusData _convertMapToLEDStatusData(Map<String, dynamic> data) {
    return LEDStatusData(
      acPowerOn: data['AC Power'] ?? false,
      dcPowerOn: data['DC Power'] ?? false,
      alarmOn: data['Alarm'] ?? false,
      troubleOn: data['Trouble'] ?? false,
      drillOn: data['Drill'] ?? false,
      silencedOn: data['Silenced'] ?? false,
      disabledOn: data['Disabled'] ?? false,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      rawData: data['rawData']?.toString(),
    );
  }

  /// Convert LEDStatusData to LEDStatus (existing format)
  LEDStatus _convertLEDStatusDataToLEDStatus(LEDStatusData ledData) {
    // Convert to existing LEDStatus format for compatibility
    return LEDStatus(
      rawData: ledData.rawData ?? 'ZONE_PARSER_DATA',
      firstByte: 0, // Not applicable from zone parser
      ledByte: _convertLEDStatusToByte(ledData),
      ledBinary: _convertLEDStatusToBinary(ledData),
      ledStatus: ledData, // Use LEDStatusData directly from enhanced_zone_parser
      systemContext: _determineSystemContextFromZoneData(ledData),
      timestamp: ledData.timestamp,
    );
  }

  /// Convert LEDStatusData to byte value
  int _convertLEDStatusToByte(LEDStatusData ledData) {
    int ledByte = 0xFF; // Default all OFF (1 = OFF)

    if (!ledData.disabledOn) ledByte &= ~(1 << 0);   // Bit 0
    if (!ledData.silencedOn) ledByte &= ~(1 << 1);   // Bit 1
    if (!ledData.drillOn) ledByte &= ~(1 << 2);      // Bit 2
    if (!ledData.troubleOn) ledByte &= ~(1 << 3);    // Bit 3
    if (!ledData.alarmOn) ledByte &= ~(1 << 4);      // Bit 4
    if (!ledData.dcPowerOn) ledByte &= ~(1 << 5);    // Bit 5
    if (!ledData.acPowerOn) ledByte &= ~(1 << 6);    // Bit 6

    return ledByte;
  }

  /// Convert LEDStatusData to binary string
  String _convertLEDStatusToBinary(LEDStatusData ledData) {
    int ledByte = _convertLEDStatusToByte(ledData);
    return ledByte.toRadixString(2).padLeft(8, '0');
  }

  /// Convert to legacy LEDStatusData format (REMOVED - LEDStatusDataLegacy not defined)
  // LEDStatusDataLegacy class was removed to avoid conflicts
  // Using LEDStatusData from enhanced_zone_parser.dart instead

  /// Helper method to get LED color from LEDStatusData (enhanced_zone_parser version)
  Color _getLEDColorFromData(LEDStatusData ledData, LEDType ledType) {
    bool isOn = _getLEDStatusFromData(ledData, ledType);
    if (!isOn) return Colors.grey.shade300; // OFF color (White/Grey)

    switch (ledType) {
      case LEDType.acPower:
        return Colors.green;    // AC Power ON - Green
      case LEDType.dcPower:
        return Colors.green;    // DC Power ON - Green
      case LEDType.alarm:
        return Colors.red;      // Alarm ON - Red
      case LEDType.trouble:
        return Colors.orange;   // Trouble ON - Orange
      case LEDType.drill:
        return Colors.red;      // Drill ON - Red
      case LEDType.silenced:
        return Colors.yellow;   // Silenced ON - Yellow
      case LEDType.disabled:
        return Colors.yellow;   // Disabled ON - Yellow
    }
  }

  /// Helper method to get LED status from LEDStatusData (enhanced_zone_parser version)
  bool _getLEDStatusFromData(LEDStatusData ledData, LEDType ledType) {
    switch (ledType) {
      case LEDType.acPower:
        return ledData.acPowerOn;
      case LEDType.dcPower:
        return ledData.dcPowerOn;
      case LEDType.alarm:
        return ledData.alarmOn;
      case LEDType.trouble:
        return ledData.troubleOn;
      case LEDType.drill:
        return ledData.drillOn;
      case LEDType.silenced:
        return ledData.silencedOn;
      case LEDType.disabled:
        return ledData.disabledOn;
    }
  }

  /// 🔥 REMOVED: System context from zone data (Path A & B - OBSOLETE)
  /// System context now comes from Path C via Zone Parser
  SystemContext _determineSystemContextFromZoneData(LEDStatusData ledData) {
    
    

    // Return default context
    return SystemContext.systemNormal;
  }

  /// 🔥 REMOVED: Stop Firebase monitoring (Path A & B - OBSOLETE)
  /// LED decoder now only uses Zone Parser connection (Path C)
  void stopFirebaseMonitoring() {
    try {
      
      

      // Keep subscriptions for Zone Parser connection
      
    } catch (e) {
      
    }
  }

  /// Stop monitoring (complete stop - Zone Parser only)
  void stopMonitoring() {
    try {
      

      // Cancel all subscriptions (Zone Parser only)
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      // Close stream controllers safely
      if (!_ledStatusController.isClosed) {
        _ledStatusController.close();
      }
      if (!_rawLEDDataController.isClosed) {
        _rawLEDDataController.close();
      }

      // Clear current status
      _currentLEDStatus = null;

      
    } catch (e) {
      
    }
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Power status enumeration
enum PowerStatus {
  bothOn,    // AC and DC both ON
  acOnly,    // Only AC ON
  dcOnly,    // Only DC ON (running on battery)
  bothOff,   // Both OFF
  unknown,   // Status unknown
}

/// Extension methods for LED status
extension LEDStatusExtensions on LEDStatus {
  /// Get human readable status summary
  String get statusSummary {
    switch (systemContext) {
      case SystemContext.systemDisabledMaintenance:
        return 'System Disabled - Maintenance';
      case SystemContext.systemSilencedManual:
        return 'System Silenced - Manual';
      case SystemContext.alarmWithTroubleCondition:
        return 'Alarm with Trouble';
      case SystemContext.alarmWithDrillActive:
        return 'Alarm with Drill';
      case SystemContext.fullAlarmActive:
        return 'Full Alarm Active';
      case SystemContext.troubleConditionOnly:
        return 'Trouble Condition';
      case SystemContext.supervisoryPreAlarm:
        return 'Supervisory Pre-Alarm';
      case SystemContext.systemNormal:
        return 'System Normal';
    }
  }

  /// Get priority level for notifications
  int get priorityLevel {
    switch (systemContext) {
      case SystemContext.fullAlarmActive:
      case SystemContext.alarmWithTroubleCondition:
        return 4; // Highest priority
      case SystemContext.alarmWithDrillActive:
        return 3;
      case SystemContext.troubleConditionOnly:
        return 2;
      case SystemContext.systemSilencedManual:
        return 1;
      case SystemContext.systemDisabledMaintenance:
      case SystemContext.systemNormal:
        return 0; // Lowest priority
      case SystemContext.supervisoryPreAlarm:
        return 2;
    }
  }
}
