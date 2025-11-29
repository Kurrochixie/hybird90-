import 'package:flutter/material.dart';

/// 🎯 Zone Status Utilities
/// Utility functions untuk zone status management dan calculations
///
/// Author: Claude Code Assistant
/// Version: 1.0.0

class ZoneStatusUtils {
  static const int zonesPerDevice = 5;

  /// Calculate global zone number dari device number dan zone dalam device
  /// Device 1: Zones 1-5, Device 2: Zones 6-10, dst.
  static int calculateGlobalZoneNumber(int deviceNumber, int zoneInDevice) {
    if (deviceNumber < 1 || deviceNumber > 63) {
      throw ArgumentError('Device number must be between 1 and 63');
    }
    if (zoneInDevice < 1 || zoneInDevice > zonesPerDevice) {
      throw ArgumentError('Zone in device must be between 1 and $zonesPerDevice');
    }

    return ((deviceNumber - 1) * zonesPerDevice) + zoneInDevice;
  }

  /// Calculate device number dari global zone number
  static int calculateDeviceNumber(int globalZoneNumber) {
    if (globalZoneNumber < 1 || globalZoneNumber > 315) {
      throw ArgumentError('Global zone number must be between 1 and 315');
    }

    return ((globalZoneNumber - 1) ~/ zonesPerDevice) + 1;
  }

  /// Calculate zone dalam device dari global zone number
  static int calculateZoneInDevice(int globalZoneNumber) {
    if (globalZoneNumber < 1 || globalZoneNumber > 315) {
      throw ArgumentError('Global zone number must be between 1 and 315');
    }

    return ((globalZoneNumber - 1) % zonesPerDevice) + 1;
  }

  /// Format zone number untuk display
  static String formatZoneNumber(int globalZoneNumber) {
    return 'Zone $globalZoneNumber';
  }

  /// Format device address untuk display
  static String formatDeviceAddress(int deviceNumber) {
    return deviceNumber.toString().padLeft(2, '0');
  }

  /// Get zone color berdasarkan status
  static Color getZoneColor(String status) {
    switch (status.toLowerCase()) {
      case 'alarm':
        return Colors.red;
      case 'trouble':
        return Colors.orange;
      case 'normal':
        return Colors.white;
      case 'offline':
        return Colors.grey;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Check if zone status indicates alarm
  static bool isAlarmStatus(String status) {
    return status.toLowerCase() == 'alarm';
  }

  /// Check if zone status indicates trouble
  static bool isTroubleStatus(String status) {
    return status.toLowerCase() == 'trouble';
  }

  /// Check if zone status indicates normal
  static bool isNormalStatus(String status) {
    return status.toLowerCase() == 'normal';
  }

  /// Check if zone status indicates offline
  static bool isOfflineStatus(String status) {
    return status.toLowerCase() == 'offline';
  }

  /// Get priority level untuk status (higher = more important)
  static int getStatusPriority(String status) {
    switch (status.toLowerCase()) {
      case 'alarm':
        return 4;
      case 'trouble':
        return 3;
      case 'active':
        return 2;
      case 'normal':
        return 1;
      case 'offline':
        return 0;
      default:
        return 0;
    }
  }

  /// Compare two zone statuses dan return yang lebih priority
  static String getHigherPriorityStatus(String status1, String status2) {
    final priority1 = getStatusPriority(status1);
    final priority2 = getStatusPriority(status2);

    return priority1 >= priority2 ? status1 : status2;
  }

  /// Check if zone number valid (1-315)
  static bool isValidZoneNumber(int zoneNumber) {
    return zoneNumber >= 1 && zoneNumber <= 315;
  }

  /// Check if device number valid (1-63)
  static bool isValidDeviceNumber(int deviceNumber) {
    return deviceNumber >= 1 && deviceNumber <= 63;
  }

  /// Check if zone in device valid (1-5)
  static bool isValidZoneInDevice(int zoneInDevice) {
    return zoneInDevice >= 1 && zoneInDevice <= zonesPerDevice;
  }
}