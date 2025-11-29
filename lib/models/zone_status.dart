class ZoneStatus {
  /// Zone unique identifier (1-315 for global system)
  final int globalZoneNumber;

  /// Zone number within device (1-5)
  final int zoneInDevice;

  /// Parent device address (1-63)
  final int deviceAddress;

  /// Zone is active/configured
  final bool isActive;

  /// Zone has fire alarm condition (Priority 1)
  final bool hasAlarm;

  /// Zone has trouble/maintenance condition (Priority 2)
  final bool hasTrouble;

  /// Zone has supervisory condition
  final bool hasSupervisory;

  /// Custom zone description/name
  final String description;

  /// Last update timestamp
  final DateTime lastUpdate;

  /// Zone type classification
  final ZoneType zoneType;

  /// Additional metadata
  final Map<String, dynamic> metadata;

  ZoneStatus({
    required this.globalZoneNumber,
    required this.zoneInDevice,
    required this.deviceAddress,
    required this.isActive,
    required this.hasAlarm,
    required this.hasTrouble,
    this.hasSupervisory = false,
    this.description = '',
    DateTime? lastUpdate,
    this.zoneType = ZoneType.unknown,
    this.metadata = const {},
  }) : lastUpdate = lastUpdate ?? DateTime.now();

  /// Create empty/inactive zone
  factory ZoneStatus.empty({
    required int globalZoneNumber,
    required int zoneInDevice,
    required int deviceAddress,
  }) {
    return ZoneStatus(
      globalZoneNumber: globalZoneNumber,
      zoneInDevice: zoneInDevice,
      deviceAddress: deviceAddress,
      isActive: false,
      hasAlarm: false,
      hasTrouble: false,
      description: 'Zone $globalZoneNumber',
      zoneType: ZoneType.inactive,
    );
  }

  /// Create zone with alarm condition
  factory ZoneStatus.alarm({
    required int globalZoneNumber,
    required int zoneInDevice,
    required int deviceAddress,
    String description = '',
  }) {
    return ZoneStatus(
      globalZoneNumber: globalZoneNumber,
      zoneInDevice: zoneInDevice,
      deviceAddress: deviceAddress,
      isActive: true,
      hasAlarm: true,
      hasTrouble: false,
      description: description.isNotEmpty ? description : 'Zone $globalZoneNumber - ALARM',
      zoneType: ZoneType.unknown,
    );
  }

  /// Create zone with trouble condition
  factory ZoneStatus.trouble({
    required int globalZoneNumber,
    required int zoneInDevice,
    required int deviceAddress,
    String description = '',
  }) {
    return ZoneStatus(
      globalZoneNumber: globalZoneNumber,
      zoneInDevice: zoneInDevice,
      deviceAddress: deviceAddress,
      isActive: true,
      hasAlarm: false,
      hasTrouble: true,
      description: description.isNotEmpty ? description : 'Zone $globalZoneNumber - TROUBLE',
      zoneType: ZoneType.trouble,
    );
  }

  /// Get current zone status with priority logic
  ZoneStatusType get currentStatus {
    if (!isActive) return ZoneStatusType.inactive;
    if (hasAlarm) return ZoneStatusType.alarm;      // Priority 1: Life safety
    if (hasTrouble) return ZoneStatusType.trouble;  // Priority 2: Maintenance
    if (hasSupervisory) return ZoneStatusType.supervisory; // Priority 3
    return ZoneStatusType.normal;                   // Priority 4
  }

  /// Get status display text
  String get statusText {
    switch (currentStatus) {
      case ZoneStatusType.alarm:
        return 'ALARM';
      case ZoneStatusType.trouble:
        return 'TROUBLE';
      case ZoneStatusType.supervisory:
        return 'SUPERVISORY';
      case ZoneStatusType.normal:
        return 'NORMAL';
      case ZoneStatusType.inactive:
        return 'INACTIVE';
    }
  }

  /// Get status color key for UI
  String get statusColorKey {
    switch (currentStatus) {
      case ZoneStatusType.alarm:
        return 'Alarm';
      case ZoneStatusType.trouble:
        return 'Trouble';
      case ZoneStatusType.supervisory:
        return 'Supervisory';
      case ZoneStatusType.normal:
        return 'Normal';
      case ZoneStatusType.inactive:
        return 'Disabled';
    }
  }

  /// Get zone number (alias for globalZoneNumber for backward compatibility)
  int get zoneNumber => globalZoneNumber;

  /// Check if zone needs attention
  bool get needsAttention => hasAlarm || hasTrouble || hasSupervisory;

  /// Check if zone is in critical state (alarm only)
  bool get isCritical => hasAlarm;

  /// Create copy with updated values
  ZoneStatus copyWith({
    int? globalZoneNumber,
    int? zoneInDevice,
    int? deviceAddress,
    bool? isActive,
    bool? hasAlarm,
    bool? hasTrouble,
    bool? hasSupervisory,
    String? description,
    DateTime? lastUpdate,
    ZoneType? zoneType,
    Map<String, dynamic>? metadata,
  }) {
    return ZoneStatus(
      globalZoneNumber: globalZoneNumber ?? this.globalZoneNumber,
      zoneInDevice: zoneInDevice ?? this.zoneInDevice,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      isActive: isActive ?? this.isActive,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      hasTrouble: hasTrouble ?? this.hasTrouble,
      hasSupervisory: hasSupervisory ?? this.hasSupervisory,
      description: description ?? this.description,
      lastUpdate: lastUpdate ?? DateTime.now(),
      zoneType: zoneType ?? this.zoneType,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'globalZoneNumber': globalZoneNumber,
      'zoneInDevice': zoneInDevice,
      'deviceAddress': deviceAddress,
      'isActive': isActive,
      'hasAlarm': hasAlarm,
      'hasTrouble': hasTrouble,
      'hasSupervisory': hasSupervisory,
      'description': description,
      'lastUpdate': lastUpdate.millisecondsSinceEpoch,
      'zoneType': zoneType.name,
      'currentStatus': currentStatus.name,
      'statusText': statusText,
      'statusColorKey': statusColorKey,
      'metadata': metadata,
    };
  }

  /// Create from JSON
  factory ZoneStatus.fromJson(Map<String, dynamic> json) {
    return ZoneStatus(
      globalZoneNumber: json['globalZoneNumber'] as int,
      zoneInDevice: json['zoneInDevice'] as int,
      deviceAddress: json['deviceAddress'] as int,
      isActive: json['isActive'] as bool,
      hasAlarm: json['hasAlarm'] as bool,
      hasTrouble: json['hasTrouble'] as bool,
      hasSupervisory: json['hasSupervisory'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      lastUpdate: DateTime.fromMillisecondsSinceEpoch(json['lastUpdate'] as int? ?? 0),
      zoneType: ZoneType.values.firstWhere(
        (type) => type.name == json['zoneType'],
        orElse: () => ZoneType.unknown,
      ),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  String toString() {
    return 'ZoneStatus($globalZoneNumber: $statusText${description.isNotEmpty ? ' - $description' : ''})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ZoneStatus &&
      other.globalZoneNumber == globalZoneNumber &&
      other.zoneInDevice == zoneInDevice &&
      other.deviceAddress == deviceAddress &&
      other.isActive == isActive &&
      other.hasAlarm == hasAlarm &&
      other.hasTrouble == hasTrouble &&
      other.hasSupervisory == hasSupervisory &&
      other.description == description &&
      other.zoneType == zoneType;
  }

  @override
  int get hashCode {
    return Object.hash(
      globalZoneNumber,
      zoneInDevice,
      deviceAddress,
      isActive,
      hasAlarm,
      hasTrouble,
      hasSupervisory,
      description,
      zoneType,
    );
  }
}

/// Zone status types with priority hierarchy
enum ZoneStatusType {
  inactive,  // Zone not configured/offline
  normal,    // Zone operational, no issues
  supervisory, // Zone supervisory condition
  trouble,   // Zone trouble/maintenance needed
  alarm,     // Zone fire alarm (highest priority)
}

/// Zone classification types
enum ZoneType {
  unknown,     // Unknown zone type
  inactive,    // Inactive/disabled zone
  heat,        // Heat detector
  smoke,       // Smoke detector
  manual,      // Manual pull station
  waterflow,   // Water flow switch
  supervisory, // Supervisory device
  trouble,     // Trouble monitoring
  relay,       // Relay output
  input,       // General input
  output,      // General output
}

/// Zone status utility functions
class ZoneStatusUtils {
  /// Calculate global zone number from device address and zone in device
  static int calculateGlobalZoneNumber(int deviceAddress, int zoneInDevice) {
    return ((deviceAddress - 1) * 5) + zoneInDevice;
  }

  /// Extract device address from global zone number
  static int getDeviceAddress(int globalZoneNumber) {
    return ((globalZoneNumber - 1) / 5).floor() + 1;
  }

  /// Extract zone in device from global zone number
  static int getZoneInDevice(int globalZoneNumber) {
    return ((globalZoneNumber - 1) % 5) + 1;
  }

  /// Validate zone numbers are within expected ranges
  static bool isValidZoneNumber(int globalZoneNumber) {
    return globalZoneNumber >= 1 && globalZoneNumber <= 315; // 63 devices × 5 zones
  }

  /// Validate device address
  static bool isValidDeviceAddress(int deviceAddress) {
    return deviceAddress >= 1 && deviceAddress <= 63;
  }

  /// Validate zone in device
  static bool isValidZoneInDevice(int zoneInDevice) {
    return zoneInDevice >= 1 && zoneInDevice <= 5;
  }

  /// Sort zones by priority (alarm first, then by global zone number)
  static List<ZoneStatus> sortByPriority(List<ZoneStatus> zones) {
    final sorted = List<ZoneStatus>.from(zones);
    sorted.sort((a, b) {
      // First sort by status priority
      final statusComparison = a.currentStatus.index.compareTo(b.currentStatus.index);
      if (statusComparison != 0) return statusComparison;

      // Then by global zone number
      return a.globalZoneNumber.compareTo(b.globalZoneNumber);
    });
    return sorted;
  }

  /// Filter zones by status type
  static List<ZoneStatus> filterByStatus(List<ZoneStatus> zones, ZoneStatusType status) {
    return zones.where((zone) => zone.currentStatus == status).toList();
  }

  /// Count zones by status type
  static Map<ZoneStatusType, int> countByStatus(List<ZoneStatus> zones) {
    final counts = <ZoneStatusType, int>{};
    for (final status in ZoneStatusType.values) {
      counts[status] = 0;
    }
    for (final zone in zones) {
      counts[zone.currentStatus] = (counts[zone.currentStatus] ?? 0) + 1;
    }
    return counts;
  }
}