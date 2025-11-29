import 'dart:async';

/// Smart Change Detector for zone status monitoring
/// Reduces unnecessary logging by tracking state changes and implementing debouncing
class SmartChangeDetector {
  static final SmartChangeDetector _instance = SmartChangeDetector._internal();
  factory SmartChangeDetector() => _instance;
  SmartChangeDetector._internal();

  // State tracking for all zones (format: "slaveX_zoneY")
  final Map<String, String> _lastZoneStatus = {};
  final Map<String, DateTime> _lastUpdateTime = {};

  // Debouncing configuration
  final Duration _debounceDuration = const Duration(seconds: 3);
  final Map<String, Timer?> _debounceTimers = {};

  // Statistics
  int _totalUpdatesProcessed = 0;
  int _actualChangesDetected = 0;
  int _logsSuppressed = 0;

  /// Parse slave data and detect changes
  /// Returns list of zones that actually changed (after debouncing)
  Future<List<String>> detectChanges(String slaveId, String rawData) async {
    _totalUpdatesProcessed++;

    try {
      // Parse the raw data format: "C53F<STX>010000<STX>020000...<STX>630000<ETX>"
      final zoneStatuses = _parseZoneData(rawData);
      final changedZones = <String>[];

      

      for (final entry in zoneStatuses.entries) {
        final zoneId = "${slaveId}_${entry.key}";
        final newStatus = entry.value;
        final zoneKey = zoneId;

        // Check if this is an actual change
        if (_isActualChange(zoneKey, newStatus)) {
          // Schedule debounced check
          final hasScheduledTimer = await _scheduleDebouncedCheck(zoneKey, newStatus);
          if (hasScheduledTimer) {
            changedZones.add(zoneKey);
          }
        }
      }

      // Update statistics
      if (_totalUpdatesProcessed % 100 == 0) {
        _logStatistics();
      }

      return changedZones;

    } catch (e) {
      
      return [];
    }
  }

  /// Parse raw zone data into status map
  Map<String, String> _parseZoneData(String rawData) {
    final zoneStatuses = <String, String>{};

    // Remove prefix and suffix
    String cleanData = rawData;
    if (cleanData.startsWith('C53F')) {
      cleanData = cleanData.substring(4);
    }
    if (cleanData.endsWith('\x03')) { // ETX
      cleanData = cleanData.substring(0, cleanData.length - 1);
    }

    // Split by STX (Start of Text character)
    final parts = cleanData.split('\x02');

    for (int i = 0; i < parts.length; i++) {
      final part = parts[i].trim();
      if (part.isNotEmpty) {
        try {
          // Extract zone number and status
          final zoneNum = (i + 1).toString().padLeft(2, '0');
          final status = _parseStatus(part);
          zoneStatuses[zoneNum] = status;
        } catch (e) {
          
        }
      }
    }

    return zoneStatuses;
  }

  /// Parse status from raw data
  String _parseStatus(String rawData) {
    // Parse the AABBCC format properly
    // AA = address, BB = trouble status, CC = alarm+bell status

    

    if (rawData.length >= 6) {
      // Extract trouble status (BB bytes - positions 3-4)
      final troubleStatus = rawData.substring(2, 4);

      // Convert to proper status logic
      if (troubleStatus == '0000') {
        return 'NORMAL'; // No trouble
      } else {
        return 'TROUBLE'; // Any non-zero value = trouble
      }
    }

    
    return 'NORMAL';
  }

  /// Check if this is an actual change worth logging
  bool _isActualChange(String zoneKey, String newStatus) {
    final lastStatus = _lastZoneStatus[zoneKey];

    // First time seeing this zone
    if (lastStatus == null) {
      _lastZoneStatus[zoneKey] = newStatus;
      _lastUpdateTime[zoneKey] = DateTime.now();
      return true;
    }

    // Status actually changed
    if (lastStatus != newStatus) {
      return true;
    }

    return false;
  }

  /// Schedule debounced check for zone status change
  Future<bool> _scheduleDebouncedCheck(String zoneKey, String newStatus) async {
    // Cancel existing timer if any
    _debounceTimers[zoneKey]?.cancel();

    // Create new timer
    final completer = Completer<bool>();

    _debounceTimers[zoneKey] = Timer(_debounceDuration, () {
      _finalizeZoneChange(zoneKey, newStatus);
      completer.complete(true);
      _debounceTimers.remove(zoneKey);
    });

    return completer.future;
  }

  /// Finalize the zone status change after debounce
  void _finalizeZoneChange(String zoneKey, String newStatus) {
    final oldStatus = _lastZoneStatus[zoneKey] ?? '0000';
    final lastUpdate = _lastUpdateTime[zoneKey] ?? DateTime.fromMillisecondsSinceEpoch(0);
    final now = DateTime.now();

    // Only proceed if this is still different from last logged state
    if (oldStatus != newStatus) {
      _lastZoneStatus[zoneKey] = newStatus;
      _lastUpdateTime[zoneKey] = now;
      _actualChangesDetected++;

      
    } else {
      _logsSuppressed++;
      
    }
  }

  /// Get current status for a zone
  String? getCurrentStatus(String slaveId, String zoneId) {
    return _lastZoneStatus["${slaveId}_$zoneId"];
  }

  /// Get all current statuses for a slave
  Map<String, String> getSlaveStatuses(String slaveId) {
    final slaveStatuses = <String, String>{};
    for (final entry in _lastZoneStatus.entries) {
      if (entry.key.startsWith('${slaveId}_')) {
        final zoneId = entry.key.substring('${slaveId}_'.length);
        slaveStatuses[zoneId] = entry.value;
      }
    }
    return slaveStatuses;
  }

  /// Force immediate status update (bypass debouncing)
  void forceUpdateStatus(String slaveId, String zoneId, String newStatus) {
    final zoneKey = "${slaveId}_$zoneId";
    _debounceTimers[zoneKey]?.cancel();
    _debounceTimers.remove(zoneKey);
    _finalizeZoneChange(zoneKey, newStatus);
  }

  /// Clear all cached states (for testing/reset)
  void clearAllStates() {
    _lastZoneStatus.clear();
    _lastUpdateTime.clear();

    // Cancel all timers
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();

    
  }

  /// Get performance statistics
  Map<String, dynamic> getStatistics() {
    return {
      'totalUpdatesProcessed': _totalUpdatesProcessed,
      'actualChangesDetected': _actualChangesDetected,
      'logsSuppressed': _logsSuppressed,
      'suppressionRate': _totalUpdatesProcessed > 0
          ? '${((_logsSuppressed / _totalUpdatesProcessed) * 100).toStringAsFixed(2)}%'
          : '0%',
      'activeZones': _lastZoneStatus.length,
      'activeTimers': _debounceTimers.length,
    };
  }

  /// Log statistics periodically
  void _logStatistics() {
    final stats = getStatistics();
    
    
    
    
    
    
  }

  /// Dispose resources
  void dispose() {
    // Cancel all timers
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();

    
  }
}