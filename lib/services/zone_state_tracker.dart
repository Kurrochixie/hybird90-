import 'firebase_log_handler.dart';
import 'smart_change_detector.dart';

/// Zone state enumeration for trouble logging
enum ZoneState {
  normal,      // Data normal diterima
  trouble,     // Data masalah diterima
  disconnected, // Tidak ada data
  ignored      // Address luar range aktif
}

/// State change callback function signature
typedef ZoneStateChangeCallback = void Function(String zoneName, ZoneState oldState, ZoneState newState);

/// Tracks zone state changes and triggers automatic trouble logging
class ZoneStateTracker {
  static final ZoneStateTracker _instance = ZoneStateTracker._internal();
  factory ZoneStateTracker() => _instance;
  ZoneStateTracker._internal();

  FirebaseLogHandler? _logHandler;
  final SmartChangeDetector _changeDetector = SmartChangeDetector();

  // Previous state tracking untuk setiap zone
  final Map<String, ZoneState> _previousStates = {};

  // Additional tracking for smart change detection
  final Map<String, String> _lastRawStatus = {};

  // Callback untuk state changes
  ZoneStateChangeCallback? _stateChangeCallback;

  // Active module count (dari interface settings)
  int _activeModuleCount = 30; // Default value

  /// Set callback untuk state change notifications
  void setStateChangeCallback(ZoneStateChangeCallback callback) {
    _stateChangeCallback = callback;
  }

  /// Set FirebaseLogHandler instance (to avoid circular dependency)
  void setLogHandler(FirebaseLogHandler logHandler) {
    _logHandler = logHandler;
  }

  /// Get FirebaseLogHandler instance (lazy initialization)
  FirebaseLogHandler get logHandler {
    _logHandler ??= FirebaseLogHandler();
    return _logHandler!;
  }

  /// Update active module count dari interface settings
  void updateActiveModuleCount(int count) {
    if (_activeModuleCount != count) {
      
      _activeModuleCount = count;

      // Re-evaluate semua states saat module count berubah
      _reevaluateAllZoneStates();
    }
  }

  /// Get current active module count
  int get activeModuleCount => _activeModuleCount;

  /// Get maximum zones based on active modules (5 zones per module)
  int get maxActiveZones => _activeModuleCount * 5;

  /// Detect zone state berdasarkan address dan data
  ZoneState detectZoneState(int address, Map<String, dynamic>? data) {
    // Check jika address luar range aktif
    if (address > _activeModuleCount) {
      return ZoneState.ignored;
    }

    // Check jika tidak ada data
    if (data == null || data.isEmpty) {
      return ZoneState.disconnected;
    }

    // Check jika data menunjukkan trouble
    if (isTroubleData(data)) {
      return ZoneState.trouble;
    }

    // Default ke normal
    return ZoneState.normal;
  }

  /// Check jika zone data menunjukkan trouble condition
  bool isTroubleData(Map<String, dynamic> data) {
    // Logic untuk detect trouble data
    // Berdasarkan format data dari fire alarm system

    // Check key trouble indicators
    final troubleIndicators = [
      'trouble', 'fault', 'error', 'failure',
      'offline', 'malfunction', 'defect'
    ];

    // Check status field
    final statusData = data['status']?.toString().toLowerCase() ?? '';
    if (troubleIndicators.any((String indicator) => statusData.contains(indicator))) {
      return true;
    }

    // Check other common trouble fields
    for (String key in data.keys) {
      final valueData = data[key]?.toString().toLowerCase() ?? '';
      if (troubleIndicators.any((String indicator) => valueData.contains(indicator))) {
        return true;
      }
    }

    return false;
  }

  /// Process zone state change dan trigger logging jika perlu
  void processZoneStateChange(String zoneName, int address, Map<String, dynamic>? newData) {
    final currentState = detectZoneState(address, newData);
    final zoneKey = '${zoneName}_$address';
    final previousState = _previousStates[zoneKey] ?? ZoneState.normal;

    // Jika state tidak berubah, tidak perlu logging
    if (currentState == previousState) {
      return;
    }

    

    // Update previous state
    _previousStates[zoneKey] = currentState;

    // Trigger logging untuk state changes yang relevan (kecuali ignored)
    if (currentState != ZoneState.ignored && previousState != ZoneState.ignored) {
      final logStatus = mapStateToLogStatus(currentState);
      _logHandler?.addTroubleLogSimple(
        zone: zoneName,
        status: logStatus,
        user: 'System'
      );

      
    }

    // Trigger callback untuk state changes (termasuk untuk LED indicator)
    _stateChangeCallback?.call(zoneName, previousState, currentState);
  }

  /// Map ZoneState ke string untuk log display
  String mapStateToLogStatus(ZoneState state) {
    switch (state) {
      case ZoneState.trouble:
        return 'TROUBLE';
      case ZoneState.normal:
        return 'FIXED';
      case ZoneState.disconnected:
        return 'DISCONNECTED';
      case ZoneState.ignored:
        return 'IGNORED'; // Should not be logged
    }
  }

  /// Get current state untuk specific zone
  ZoneState getCurrentZoneState(String zoneName, int address) {
    final zoneKey = '${zoneName}_$address';
    return _previousStates[zoneKey] ?? ZoneState.normal;
  }

  /// Check apakah ada zones yang DISCONNECTED
  bool hasDisconnectedZones() {
    return _previousStates.values.any((ZoneState state) => state == ZoneState.disconnected);
  }

  /// Get count dari disconnected zones
  int getDisconnectedZoneCount() {
    return _previousStates.values
        .where((ZoneState state) => state == ZoneState.disconnected)
        .length;
  }

  /// Get list dari disconnected zone names
  List<String> getDisconnectedZoneNames() {
    final disconnectedZones = <String>[];
    _previousStates.forEach((zoneKey, stateData) {
      if (stateData == ZoneState.disconnected) {
        final zoneName = zoneKey.replaceAll(RegExp(r'_\d+$'), '');
        if (!disconnectedZones.contains(zoneName)) {
          disconnectedZones.add(zoneName);
        }
      }
    });
    return disconnectedZones;
  }

  /// Re-evaluate semua zone states saat module count berubah
  void _reevaluateAllZoneStates() {
    

    // Clear ignored states untuk address yang sekarang aktif
    _previousStates.removeWhere((zoneKey, state) {
      if (state == ZoneState.ignored) {
        final address = _extractAddressFromZoneKey(zoneKey);
        return address <= _activeModuleCount;
      }
      return false;
    });

    
  }

  /// Extract address dari zone key
  int _extractAddressFromZoneKey(String zoneKey) {
    final parts = zoneKey.split('_');
    if (parts.length >= 2) {
      return int.tryParse(parts.last) ?? 0;
    }
    return 0;
  }

  /// Process raw slave data with smart change detection
  /// Returns true if any meaningful changes were detected
  Future<bool> processRawSlaveData(String slaveId, String rawData) async {
    try {
      // Use SmartChangeDetector to detect actual changes
      final changedZones = await _changeDetector.detectChanges(slaveId, rawData);

      if (changedZones.isEmpty) {
        return false; // No meaningful changes detected
      }

      

      // Process each changed zone
      bool hasSignificantChanges = false;
      for (final zoneKey in changedZones) {
        final parts = zoneKey.split('_');
        if (parts.length >= 2) {
          final zoneId = parts.last;
          final currentStatus = _changeDetector.getCurrentStatus(slaveId, zoneId);

          // Convert to zone state and process
          final zoneState = _parseStatusToZoneState(currentStatus ?? '0000');
          final zoneName = "Zone $zoneId (Slave $slaveId)";
          final address = int.tryParse(zoneId) ?? 1;

          // Only process if this is a significant state change
          if (_isSignificantStateChange(zoneKey, zoneState)) {
            _processSignificantChange(zoneName, address, zoneState, currentStatus);
            hasSignificantChanges = true;
          }
        }
      }

      return hasSignificantChanges;
    } catch (e) {
      // Error checking significant changes - assume no significant changes
      print('Warning: Error checking for significant zone changes: $e');
      return false;
    }
  }

  /// Parse raw status to ZoneState
  ZoneState _parseStatusToZoneState(String? rawStatus) {
    if (rawStatus == 'NORMAL' || rawStatus == '0000') {
      return ZoneState.normal;
    } else if (rawStatus == 'TROUBLE') {
      return ZoneState.trouble;
    }
    // For legacy format with numeric codes (any non-zero = trouble)
    if (rawStatus != null && rawStatus != '0000') {
      return ZoneState.trouble;
    }
    return ZoneState.normal;
  }

  /// Check if this is a significant state change worth logging
  bool _isSignificantStateChange(String zoneKey, ZoneState newState) {
    final previousState = _previousStates[zoneKey] ?? ZoneState.normal;

    // Same state = not significant
    if (previousState == newState) {
      return false;
    }

    // Normal -> Trouble or Trouble -> Normal = significant
    if ((previousState == ZoneState.normal && newState == ZoneState.trouble) ||
        (previousState == ZoneState.trouble && newState == ZoneState.normal)) {
      return true;
    }

    // Other changes (disconnected, etc.) = also significant
    return true;
  }

  /// Process significant state change with enhanced logging
  void _processSignificantChange(String zoneName, int address, ZoneState newState, String? rawStatus) {
    final zoneKey = '${zoneName}_$address';
    final previousState = _previousStates[zoneKey] ?? ZoneState.normal;

    

    // Update state tracking
    _previousStates[zoneKey] = newState;
    if (rawStatus != null) {
      _lastRawStatus[zoneKey] = rawStatus;
    }

    // Trigger logging for significant changes
    if (newState != ZoneState.ignored && previousState != ZoneState.ignored) {
      final logStatus = mapStateToLogStatus(newState);
      _logHandler?.addTroubleLogSimple(
        zone: zoneName,
        status: logStatus,
        user: 'System'
      );

      
    }

    // Trigger callback for UI updates
    _stateChangeCallback?.call(zoneName, previousState, newState);
  }

  /// Get current raw status for a zone
  String? getCurrentRawStatus(String zoneName, int address) {
    final zoneKey = '${zoneName}_$address';
    return _lastRawStatus[zoneKey];
  }

  /// Get smart change detector statistics
  Map<String, dynamic> getSmartDetectionStatistics() {
    return _changeDetector.getStatistics();
  }

  /// Clear all tracked states (untuk testing/reset)
  void clearAllStates() {
    _previousStates.clear();
    _lastRawStatus.clear();
    _changeDetector.clearAllStates();
    
  }

  /// Get debugging info
  String getDebugInfo() {
    final buffer = StringBuffer();
    buffer.writeln('=== ZoneStateTracker Debug Info ===');
    buffer.writeln('Active Modules: $_activeModuleCount');
    buffer.writeln('Max Active Zones: $maxActiveZones');
    buffer.writeln('Total Tracked Zones: ${_previousStates.length}');

    final stateCounts = <ZoneState, int>{};
    for (final stateData in _previousStates.values) {
      stateCounts[stateData] = (stateCounts[stateData] ?? 0) + 1;
    }

    buffer.writeln('State Distribution:');
    for (final entry in stateCounts.entries) {
      buffer.writeln('  ${entry.key.name}: $entry.value');
    }

    // Add Smart Change Detection statistics
    buffer.writeln('\n=== Smart Change Detection Statistics ===');
    final smartStats = getSmartDetectionStatistics();
    for (final entry in smartStats.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }

    return buffer.toString();
  }
}