
/// 🎯 APP CONSTANTS - Centralized Application Configuration
///
/// Berisi semua konstanta utama aplikasi Fire Alarm Monitoring System
/// Termasuk device counts, zone calculations, dan konfigurasi sistem
///
/// Author: Claude Code Assistant
/// Version: 1.0.0

class AppConstants {
  // ==================== DEVICE & ZONE CONFIGURATION ====================

  /// Total number of devices supported by the system
  static const int totalDevices = 63;

  /// Number of zones per device/module
  static const int zonesPerModule = 5;

  /// Total number of zones across all devices (calculated)
  static const int totalZones = totalDevices * zonesPerModule; // 315

  /// Maximum zones for memory protection
  static const int maxZones = totalZones;

  /// Maximum accumulated zones for safety
  static const int maxAccumulatedZones = totalZones;

  // ==================== ZONE CALCULATION HELPERS ====================

  /// Calculate module number from zone number
  /// Zone 1-5 = Module 1, Zone 6-10 = Module 2, etc.
  static int getModuleNumberFromZone(int zoneNumber) {
    return ((zoneNumber - 1) ~/ zonesPerModule) + 1;
  }

  /// Calculate zone number within module from global zone number
  /// Returns 1-5 for zone within module
  static int getZoneNumberWithinModule(int zoneNumber) {
    return ((zoneNumber - 1) % zonesPerModule) + 1;
  }

  /// Calculate device address from module number
  /// Module 1 = Device Address 1, etc.
  static int getDeviceAddressFromModule(int moduleNumber) {
    return moduleNumber;
  }

  /// Calculate global zone number from module and local zone
  static int getGlobalZoneNumber(int moduleNumber, int localZoneNumber) {
    return (moduleNumber - 1) * zonesPerModule + localZoneNumber;
  }

  // ==================== ZONE VALIDATION ====================

  /// Check if zone number is within valid range
  static bool isValidZoneNumber(int zoneNumber) {
    return zoneNumber >= 1 && zoneNumber <= maxZones;
  }

  /// Check if device number is within valid range
  static bool isValidDeviceNumber(int deviceNumber) {
    return deviceNumber >= 1 && deviceNumber <= totalDevices;
  }

  /// Check if module number is within valid range
  static bool isValidModuleNumber(int moduleNumber) {
    return moduleNumber >= 1 && moduleNumber <= totalDevices;
  }

  // ==================== SYSTEM CONFIGURATION ====================

  /// Default active module count (can be overridden by interface settings)
  static const int defaultActiveModules = 10;

  /// Minimum active modules allowed
  static const int minActiveModules = 1;

  /// Maximum active modules allowed
  static const int maxActiveModules = totalDevices;

  // ==================== DATA RANGES ====================

  /// Maximum device address for validation
  static const int maxDeviceAddress = totalDevices;

  /// Maximum zone address for validation
  static const int maxZoneAddress = totalZones;

  // ==================== MEMORY LIMITS ====================

  /// Maximum zones to keep in memory for performance
  static const int maxZonesInMemory = totalZones;

  /// Maximum history entries to keep
  static const int maxHistoryEntries = 1000;

  // ==================== DEBUG & DEVELOPMENT ====================

  /// Enable debug logging for zone calculations
  static const bool enableZoneDebugLogs = false;

  /// Enable performance monitoring
  static const bool enablePerformanceMonitoring = true;

  // ==================== CONFIGURATION VALIDATION ====================

  /// Validate all configuration constants
  static bool validateConfiguration() {
    // Check mathematical consistency
    if (totalZones != totalDevices * zonesPerModule) {
      
      return false;
    }

    // Check ranges
    if (minActiveModules > maxActiveModules) {
      
      return false;
    }

    if (maxActiveModules > totalDevices) {
      
      return false;
    }

    
    return true;
  }

  // ==================== CONFIGURATION INFO ====================

  /// Get system information summary
  static Map<String, dynamic> getSystemInfo() {
    return {
      'totalDevices': totalDevices,
      'zonesPerModule': zonesPerModule,
      'totalZones': totalZones,
      'maxZones': maxZones,
      'defaultActiveModules': defaultActiveModules,
      'validationPassed': validateConfiguration(),
    };
  }
}