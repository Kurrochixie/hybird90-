import 'package:flutter/material.dart';
import 'dart:async';
import '../services/logger.dart';
import '../unified_fire_alarm_parser.dart';
import '../models/zone_status.dart';

/// Centralized Bell Management Service
/// Handles bell status tracking, $85/$84 confirmation processing, and real-time updates
class BellManager extends ChangeNotifier {
  static const String _tag = 'BELL_MANAGER';

  // Bell status state
  final Map<String, BellStatus> _deviceBellStatus = {};
  final List<BellConfirmationStatus> _bellConfirmations = [];

  // Bell analytics
  final int _totalDevices = 63;
  int _activeBells = 0;
  final int _mutedBells = 0;
  DateTime _lastBellActivity = DateTime.now();

  // Bell control state
  bool _isSystemMuted = false;
  bool _isBellPaused = false;
  DateTime? _muteStartTime;

  // Streams for real-time updates
  final StreamController<BellSystemStatus> _bellStatusController =
      StreamController<BellSystemStatus>.broadcast();
  final StreamController<BellConfirmationStatus> _confirmationController =
      StreamController<BellConfirmationStatus>.broadcast();

  // Timers
  Timer? _statusUpdateTimer;

  BellManager() {
    _initializeStatusMonitoring();
  }

  // ============= GETTERS =============

  /// Get current bell system status
  BellSystemStatus get currentStatus => _calculatePerModuleBellStatus();

  /// Get active bell devices
  List<String> get activeBellDevices => _deviceBellStatus.entries
      .where((entry) => entry.value.isActive && !entry.value.isMuted)
      .map((entry) => entry.key)
      .toList();

  /// Get all device bell status
  Map<String, BellStatus> get deviceBellStatus => Map.unmodifiable(_deviceBellStatus);

  /// Bell status stream for real-time UI updates
  Stream<BellSystemStatus> get bellStatusStream => _bellStatusController.stream;

  /// Bell confirmation stream for $85/$84 codes
  Stream<BellConfirmationStatus> get confirmationStream => _confirmationController.stream;

  /// System mute status
  bool get isSystemMuted => _isSystemMuted;

  /// Bell pause status
  bool get isBellPaused => _isBellPaused;

  // ============= BELL PROCESSING =============

  /// Process zone data and update bell status
  void processZoneData(Map<String, ZoneStatus> zones) {
    try {
      AppLogger.debug('Processing ${zones.length} zones for bell status', tag: _tag);

      // Group zones by device address
      final Map<int, List<ZoneStatus>> deviceZones = {};
      for (final zone in zones.values) {
        final deviceAddr = zone.deviceAddress;
        if (!deviceZones.containsKey(deviceAddr)) {
          deviceZones[deviceAddr] = [];
        }
        deviceZones[deviceAddr]!.add(zone);
      }

      // Process each device for bell status
      _activeBells = 0;
      for (final entry in deviceZones.entries) {
        final deviceAddr = entry.key;
        final deviceZones = entry.value;
        final deviceId = 'device_${deviceAddr.toString().padLeft(2, '0')}';

        // Check if any zone in this device has alarm (triggers bell)
        final hasAlarm = deviceZones.any((zone) => zone.hasAlarm);
        final hasActiveBell = hasAlarm && !_isSystemMuted && !_isBellPaused;

        // Update device bell status
        final previousStatus = _deviceBellStatus[deviceId];
        final currentStatus = BellStatus(
          deviceId: deviceId,
          deviceAddress: deviceAddr,
          isActive: hasActiveBell,
          isMuted: _isSystemMuted,
          hasAlarm: hasAlarm,
          lastActivation: hasActiveBell ? DateTime.now() : previousStatus?.lastActivation,
          totalActivations: previousStatus?.totalActivations ?? 0 + (hasActiveBell && !(previousStatus?.isActive ?? false) ? 1 : 0),
        );

        _deviceBellStatus[deviceId] = currentStatus;

        if (hasActiveBell) {
          _activeBells++;
          if (currentStatus.lastActivation != null) {
            _lastBellActivity = currentStatus.lastActivation!;
          }
        }
      }

      // Cleanup devices that no longer exist
      final activeDeviceIds = deviceZones.keys.map((addr) => 'device_${addr.toString().padLeft(2, '0')}').toSet();
      _deviceBellStatus.removeWhere((key, value) => !activeDeviceIds.contains(key));

      _notifyStatusChange();

      AppLogger.debug('Bell status updated: $_activeBells active bells', tag: _tag);

    } catch (e, stackTrace) {
      AppLogger.error('Error processing zone data for bell status', tag: _tag, error: e, stackTrace: stackTrace);
    }
  }

  /// Process raw data for $85/$84 confirmation codes
  void processRawData(String rawData) {
    try {
      AppLogger.debug('Processing raw data for bell confirmations: ${rawData.length} chars', tag: _tag);

      // Look for $85 (bell ON) and $84 (bell OFF) confirmation codes
      final bellOnPattern = RegExp(r'\$85');
      final bellOffPattern = RegExp(r'\$84');

      if (bellOnPattern.hasMatch(rawData)) {
        _processBellConfirmation(rawData, true);
      }

      if (bellOffPattern.hasMatch(rawData)) {
        _processBellConfirmation(rawData, false);
      }

      // Also process 6-character device data for bell status
      _processDeviceBellData(rawData);

    } catch (e, stackTrace) {
      AppLogger.error('Error processing raw bell data', tag: _tag, error: e, stackTrace: stackTrace);
    }
  }

  /// Process 6-character device data for bell status
  void _processDeviceBellData(String rawData) {
    try {
      // Enhanced Zone Parser already processes this, but we can extract bell info
      final deviceDataPattern = RegExp(r'(\d{2})([0-9A-Fa-f]{6})');
      final matches = deviceDataPattern.allMatches(rawData);

      for (final match in matches) {
        final deviceAddr = int.tryParse(match.group(1)!) ?? 0;
        final deviceData = match.group(2)!;

        // Extract bell status from bit 5 of alarm byte (second byte)
        if (deviceData.length >= 6) {
          final alarmByte = int.tryParse(deviceData.substring(2, 4), radix: 16) ?? 0;
          final bellActive = (alarmByte & 0x20) != 0; // Bit 5

          final deviceId = 'device_${deviceAddr.toString().padLeft(2, '0')}';

          final previousStatus = _deviceBellStatus[deviceId];
          final currentStatus = BellStatus(
            deviceId: deviceId,
            deviceAddress: deviceAddr,
            isActive: bellActive && !_isSystemMuted && !_isBellPaused,
            isMuted: _isSystemMuted,
            hasAlarm: (alarmByte & 0x10) != 0, // Bit 4 = alarm
            lastActivation: bellActive ? DateTime.now() : previousStatus?.lastActivation,
            totalActivations: previousStatus?.totalActivations ?? 0 + (bellActive && !(previousStatus?.isActive ?? false) ? 1 : 0),
          );

          _deviceBellStatus[deviceId] = currentStatus;

          if (bellActive) {
            _activeBells++;
            _lastBellActivity = DateTime.now();
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error processing device bell data', tag: _tag, error: e);
    }
  }

  /// Process $85/$84 confirmation codes
  void _processBellConfirmation(String rawData, bool isBellOn) {
    try {
      // Extract device address from the data
      final devicePattern = RegExp(r'(\d{2})');
      final deviceMatch = devicePattern.firstMatch(rawData);

      if (deviceMatch != null) {
        final deviceAddr = int.tryParse(deviceMatch.group(1)!) ?? 0;
        final slaveAddress = deviceAddr.toString().padLeft(2, '0');

        final confirmation = BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: isBellOn,
          timestamp: DateTime.now(),
          rawData: rawData,
        );

        _bellConfirmations.insert(0, confirmation);

        // Keep only last 100 confirmations
        if (_bellConfirmations.length > 100) {
          _bellConfirmations.removeRange(100, _bellConfirmations.length);
        }

        // Broadcast confirmation
        _confirmationController.add(confirmation);

        final confirmationType = confirmation.isActive ? '\$85' : '\$84';
        AppLogger.info('Bell confirmation received: $confirmationType from device $slaveAddress', tag: _tag);

        // CRITICAL: Update per-module bell status immediately
        _updatePerModuleBellStatus();

        // Immediate UI update for real-time response
        _notifyStatusChange();
      }
    } catch (e) {
      AppLogger.error('Error processing bell confirmation', tag: _tag, error: e);
    }
  }

  // ============= BELL CONTROL =============

  /// Toggle system-wide bell mute
  Future<bool> toggleSystemMute() async {
    try {
      _isSystemMuted = !_isSystemMuted;

      if (_isSystemMuted) {
        _muteStartTime = DateTime.now();
        AppLogger.info('🔇 System bell mute activated', tag: _tag);
      } else {
        _muteStartTime = null;
        AppLogger.info('🔔 System bell mute deactivated', tag: _tag);
      }

      // Update all device bell status
      for (final deviceId in _deviceBellStatus.keys) {
        final status = _deviceBellStatus[deviceId]!;
        _deviceBellStatus[deviceId] = status.copyWith(isMuted: _isSystemMuted);
      }

      _recalculateActiveBells();
      _notifyStatusChange();

      return true;
    } catch (e) {
      AppLogger.error('Error toggling system mute', tag: _tag, error: e);
      return false;
    }
  }

  /// Pause bell temporarily
  Future<bool> pauseBell({Duration duration = const Duration(minutes: 5)}) async {
    try {
      _isBellPaused = true;
      AppLogger.info('⏸️ Bell paused for ${duration.inMinutes} minutes', tag: _tag);

      // Set timer to unpause
      Timer(duration, () {
        if (_isBellPaused) {
          resumeBell();
        }
      });

      _recalculateActiveBells();
      _notifyStatusChange();

      return true;
    } catch (e) {
      AppLogger.error('Error pausing bell', tag: _tag, error: e);
      return false;
    }
  }

  /// Resume bell operation
  Future<bool> resumeBell() async {
    try {
      _isBellPaused = false;
      AppLogger.info('▶️ Bell resumed', tag: _tag);

      _recalculateActiveBells();
      _notifyStatusChange();

      return true;
    } catch (e) {
      AppLogger.error('Error resuming bell', tag: _tag, error: e);
      return false;
    }
  }

  // ============= LED-BASED RESET =============

  /// Reset all bell status when LED alarm turns OFF (synchronized with zones)
  void resetAllBellStatus() {
    try {
      AppLogger.info('Resetting all bell status - clearing confirmations and device status', tag: _tag);

      // Clear all bell confirmations - CRITICAL FIX for stale $85 data
      _bellConfirmations.clear();

      // Reset active bell count
      _activeBells = 0;

      // Reset device bell status
      _deviceBellStatus.clear();

      // Reset mute/pause states
      _isSystemMuted = false;
      _isBellPaused = false;
      _muteStartTime = null;

      // Update last activity time
      _lastBellActivity = DateTime.now();

      // Notify UI of changes
      _notifyStatusChange();

      AppLogger.info('Bell status reset completed successfully', tag: _tag);
    } catch (e) {
      AppLogger.error('Error resetting bell status: $e', tag: _tag);
      rethrow;
    }
  }

  // ============= BELLS ANALYTICS =============

  /// Get bell analytics
  BellAnalytics getAnalytics() {
    final now = DateTime.now();
    final recentConfirmations = _bellConfirmations.where((conf) =>
        now.difference(conf.timestamp).inMinutes <= 60);

    return BellAnalytics(
      totalDevices: _totalDevices,
      activeBells: _activeBells,
      mutedBells: _mutedBells,
      totalConfirmationsLastHour: recentConfirmations.length,
      averageActivationTime: _calculateAverageActivationTime(),
      mostActiveDevice: _getMostActiveDevice(),
      muteDuration: _muteStartTime != null ? now.difference(_muteStartTime!) : Duration.zero,
      isSystemMuted: _isSystemMuted,
      isBellPaused: _isBellPaused,
    );
  }

  /// Get bell history
  List<BellConfirmationStatus> getBellHistory({int limit = 50}) {
    return _bellConfirmations.take(limit).toList();
  }

  // ============= PRIVATE METHODS =============

  /// Validate and count active bell confirmations ($85/$84)
  int _validateBellConfirmations() {
    if (_bellConfirmations.isEmpty) return 0;

    // Only count confirmations from the last 5 seconds to avoid stale data
    final fiveSecondsAgo = DateTime.now().subtract(const Duration(seconds: 5));

    return _bellConfirmations
        .where((confirmation) => confirmation.timestamp.isAfter(fiveSecondsAgo))
        .length;
  }

  /// Calculate bell status using per-module logic (independent LED indicators)
  BellSystemStatus _calculatePerModuleBellStatus() {
    // Priority 1: Drill mode override (highest priority)
    if (_isSystemMuted || _isBellPaused) {
      return _createStatusObject(0); // All bells OFF when muted/paused
    }

    // Priority 2: Per-module confirmation codes (authoritative)
    final activeBellsCount = _getPerModuleActiveBellCount();
    return _createStatusObject(activeBellsCount);
  }

  /// Count active bells per-module based on $85 confirmation codes
  int _getPerModuleActiveBellCount() {
    if (_bellConfirmations.isEmpty) return 0;

    // Count unique modules with recent $85 confirmations
    final twoSecondsAgo = DateTime.now().subtract(const Duration(seconds: 2));

    final activeModules = _bellConfirmations
        .where((conf) => conf.isActive && conf.timestamp.isAfter(twoSecondsAgo))
        .map((conf) => conf.slaveAddress)
        .toSet();

    return activeModules.length;
  }

  /// Check if specific module's bell is currently active (for LED ke-6)
  bool _isModuleBellActive(String slaveAddress) {
    if (_bellConfirmations.isEmpty) return false;

    // Check for very recent $85 for this specific module (last 1-2 seconds)
    final twoSecondsAgo = DateTime.now().subtract(const Duration(seconds: 2));

    return _bellConfirmations
        .any((conf) => conf.slaveAddress == slaveAddress &&
                     conf.isActive &&
                     conf.timestamp.isAfter(twoSecondsAgo));
  }

  /// Create status object with consistent parameters
  BellSystemStatus _createStatusObject(int activeCount) {
    return BellSystemStatus(
      totalDevices: _totalDevices,
      activeBells: activeCount,
      mutedBells: _mutedBells,
      isSystemMuted: _isSystemMuted,
      isBellPaused: _isBellPaused,
      lastBellActivity: _lastBellActivity,
      deviceBellStatus: Map.unmodifiable(_deviceBellStatus),
      recentConfirmations: List.unmodifiable(_bellConfirmations.take(10)),
    );
  }

  /// Update device bell status per-module (for LED display)
  void _updatePerModuleBellStatus() {
    // Clear all device bell status first
    _deviceBellStatus.forEach((deviceId, status) {
      _deviceBellStatus[deviceId] = status.copyWith(isActive: false);
    });

    // Set bell status only for modules with recent $85
    final twoSecondsAgo = DateTime.now().subtract(const Duration(seconds: 2));
    _bellConfirmations
        .where((conf) => conf.isActive && conf.timestamp.isAfter(twoSecondsAgo))
        .forEach((conf) {
      final deviceId = 'device_${conf.slaveAddress}';
      if (_deviceBellStatus.containsKey(deviceId)) {
        _deviceBellStatus[deviceId] = _deviceBellStatus[deviceId]!.copyWith(
          isActive: true,
          lastActivation: conf.timestamp,
        );
      }
    });
  }

  /// Initialize status monitoring
  void _initializeStatusMonitoring() {
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 1), (_) {
      _notifyStatusChange();
    });
  }

  /// Recalculate active bell count
  void _recalculateActiveBells() {
    _activeBells = _deviceBellStatus.values
        .where((status) => status.isActive && !status.isMuted)
        .length;
  }

  /// Notify status change
  void _notifyStatusChange() {
    _bellStatusController.add(currentStatus);
    notifyListeners();
  }

  /// Calculate average activation time
  Duration _calculateAverageActivationTime() {
    final activeBells = _deviceBellStatus.values.where((s) => s.isActive);
    if (activeBells.isEmpty) return Duration.zero;

    final totalMs = activeBells
        .map((bell) => bell.lastActivation?.millisecondsSinceEpoch ?? 0)
        .reduce((a, b) => a + b);

    final averageMs = totalMs / activeBells.length;
    return Duration(milliseconds: averageMs.toInt());
  }

  /// Get most active device
  String _getMostActiveDevice() {
    if (_deviceBellStatus.isEmpty) return 'None';

    String mostActiveDevice = 'None';
    int maxActivations = 0;

    for (final entry in _deviceBellStatus.entries) {
      if (entry.value.totalActivations > maxActivations) {
        maxActivations = entry.value.totalActivations;
        mostActiveDevice = entry.key;
      }
    }

    return mostActiveDevice;
  }

  // ============= DISPOSE =============

  @override
  void dispose() {
    AppLogger.info('Disposing Bell Manager', tag: _tag);

    _statusUpdateTimer?.cancel();
    _statusUpdateTimer = null;

    _bellStatusController.close();
    _confirmationController.close();

    _deviceBellStatus.clear();
    _bellConfirmations.clear();

    super.dispose();
  }
}

// ============= DATA MODELS =============

/// Bell system status for UI updates
class BellSystemStatus {
  final int totalDevices;
  final int activeBells;
  final int mutedBells;
  final bool isSystemMuted;
  final bool isBellPaused;
  final DateTime lastBellActivity;
  final Map<String, BellStatus> deviceBellStatus;
  final List<BellConfirmationStatus> recentConfirmations;

  const BellSystemStatus({
    required this.totalDevices,
    required this.activeBells,
    required this.mutedBells,
    required this.isSystemMuted,
    required this.isBellPaused,
    required this.lastBellActivity,
    required this.deviceBellStatus,
    required this.recentConfirmations,
  });

  @override
  String toString() {
    return 'BellSystemStatus(activeBells: $activeBells, muted: $isSystemMuted, paused: $isBellPaused)';
  }
}

/// Individual device bell status
class BellStatus {
  final String deviceId;
  final int deviceAddress;
  final bool isActive;
  final bool isMuted;
  final bool hasAlarm;
  final DateTime? lastActivation;
  final int totalActivations;

  const BellStatus({
    required this.deviceId,
    required this.deviceAddress,
    required this.isActive,
    required this.isMuted,
    required this.hasAlarm,
    this.lastActivation,
    this.totalActivations = 0,
  });

  BellStatus copyWith({
    String? deviceId,
    int? deviceAddress,
    bool? isActive,
    bool? isMuted,
    bool? hasAlarm,
    DateTime? lastActivation,
    int? totalActivations,
  }) {
    return BellStatus(
      deviceId: deviceId ?? this.deviceId,
      deviceAddress: deviceAddress ?? this.deviceAddress,
      isActive: isActive ?? this.isActive,
      isMuted: isMuted ?? this.isMuted,
      hasAlarm: hasAlarm ?? this.hasAlarm,
      lastActivation: lastActivation ?? this.lastActivation,
      totalActivations: totalActivations ?? this.totalActivations,
    );
  }

  String get deviceDisplayName => 'Device ${deviceAddress.toString().padLeft(2, '0')}';

  @override
  String toString() {
    return 'BellStatus(device: $deviceId, active: $isActive, muted: $isMuted)';
  }
}

/// Bell analytics data
class BellAnalytics {
  final int totalDevices;
  final int activeBells;
  final int mutedBells;
  final int totalConfirmationsLastHour;
  final Duration averageActivationTime;
  final String mostActiveDevice;
  final Duration muteDuration;
  final bool isSystemMuted;
  final bool isBellPaused;

  const BellAnalytics({
    required this.totalDevices,
    required this.activeBells,
    required this.mutedBells,
    required this.totalConfirmationsLastHour,
    required this.averageActivationTime,
    required this.mostActiveDevice,
    required this.muteDuration,
    required this.isSystemMuted,
    required this.isBellPaused,
  });
}