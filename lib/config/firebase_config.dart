import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 🔥 FIREBASE CONFIGURATION - Centralized Firebase Settings
///
/// Berisi semua konfigurasi Firebase termasuk endpoints, paths, dan settings
/// Menggantikan hardcoded Firebase configuration yang tersebar
///
/// Author: Claude Code Assistant
/// Version: 1.0.0

class FirebaseConfig {
  // ==================== FIREBASE ENDPOINTS ====================

  /// Main database URL from environment variable
  static String get databaseUrl {
    final url = dotenv.env['FIREBASE_DATABASE_URL'] ?? '';
    if (url.isEmpty) {
      throw Exception('FIREBASE_DATABASE_URL not found in environment variables');
    }
    return url;
  }

  /// API key from environment variable
  static String get apiKey {
    final key = dotenv.env['FIREBASE_API_KEY'] ?? '';
    if (key.isEmpty) {
      throw Exception('FIREBASE_API_KEY not found in environment variables');
    }
    return key;
  }

  /// Auth domain from environment variable
  static String get authDomain {
    final domain = dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
    if (domain.isEmpty) {
      throw Exception('FIREBASE_AUTH_DOMAIN not found in environment variables');
    }
    return domain;
  }

  /// Project ID from environment variable
  static String get projectId {
    final id = dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
    if (id.isEmpty) {
      throw Exception('FIREBASE_PROJECT_ID not found in environment variables');
    }
    return id;
  }

  /// Storage bucket from environment variable
  static String get storageBucket {
    final bucket = dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
    if (bucket.isEmpty) {
      
      return '';
    }
    return bucket;
  }

  /// Messaging sender ID from environment variable
  static String get messagingSenderId {
    final senderId = dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
    if (senderId.isEmpty) {
      
      return '';
    }
    return senderId;
  }

  /// App ID from environment variable
  static String get appId {
    final id = dotenv.env['FIREBASE_APP_ID'] ?? '';
    if (id.isEmpty) {
      
      return '';
    }
    return id;
  }

  // ==================== DATABASE PATHS ====================

  /// Real-time data path for device status
  static const String realTimeDataPath = 'realtime_data';

  /// System status path
  static const String systemStatusPath = 'system_status';

  /// LED status path
  static const String ledStatusPath = 'led_status';

  /// Control signals path
  static const String controlSignalsPath = 'control_signals';

  /// Zone configuration path
  static const String zoneConfigPath = 'zone_config';

  /// User settings path
  static const String userSettingsPath = 'user_settings';

  /// History logs path
  static const String historyLogsPath = 'history';

  /// Troubleshooting logs path
  static const String troubleshootingPath = 'troubleshooting';

  /// Authentication logs path
  static const String authLogsPath = 'auth_logs';

  /// System logs path
  static const String systemLogsPath = 'system_logs';

  // ==================== SPECIFIC FIREBASE PATHS ====================

  /// Fire alarm system main path
  static const String fireAlarmSystemPath = 'fire_alarm_system';

  /// Device data path
  static const String deviceDataPath = 'devices';

  /// Zone data path
  static const String zoneDataPath = 'zones';

  /// Alarm status path
  static const String alarmStatusPath = 'alarm_status';

  /// Buzzer control path
  static const String buzzerControlPath = 'buzzer_control';

  /// Bell control path
  static const String bellControlPath = 'bell_control';

  /// Notification settings path
  static const String notificationSettingsPath = 'notification_settings';

  /// Audio settings path
  static const String audioSettingsPath = 'audio_settings';

  /// Interface settings path
  static const String interfaceSettingsPath = 'interface_settings';

  // ==================== HISTORY SPECIFIC PATHS ====================

  /// History - Status logs path
  static const String historyStatusPath = 'history/statusLogs';

  /// History - Connection logs path
  static const String historyConnectionPath = 'history/connectionLogs';

  /// History - Trouble logs path
  static const String historyTroublePath = 'history/troubleLogs';

  /// History - Fire logs path
  static const String historyFirePath = 'history/fireLogs';

  // ==================== AUTHENTICATION PATHS ====================

  /// User profiles path
  static const String userProfilesPath = 'users';

  /// User sessions path
  static const String userSessionsPath = 'sessions';

  /// Password reset requests path
  static const String passwordResetPath = 'password_reset';

  /// Email verification path
  static const String emailVerificationPath = 'email_verification';

  // ==================== FIREBASE STORAGE PATHS ====================

  /// User profile images path
  static const String userProfileImagesPath = 'profile_images';

  /// System log files path
  static const String systemLogFilesPath = 'system_logs';

  /// Backup files path
  static const String backupFilesPath = 'backups';

  /// Configuration files path
  static const String configFilesPath = 'configurations';

  // ==================== FIREBASE MESSAGING ====================

  /// FCM topic for system alerts
  static const String systemAlertsTopic = 'system_alerts';

  /// FCM topic for alarm notifications
  static const String alarmNotificationsTopic = 'alarm_notifications';

  /// FCM topic for maintenance notifications
  static const String maintenanceTopic = 'maintenance';

  /// FCM topic for updates
  static const String updatesTopic = 'updates';

  // ==================== DATABASE QUERIES & OPERATIONS ====================

  /// Default query limit for list operations
  static const int defaultQueryLimit = 100;

  /// Maximum query limit
  static const int maxQueryLimit = 1000;

  /// Default query limit for history logs
  static const int historyQueryLimit = 50;

  /// Batch operation size
  static const int batchOperationSize = 500;

  /// Pagination size for large datasets
  static const int paginationSize = 20;

  // ==================== FIREBASE RULES & SECURITY ====================

  /// Read permission level for public data
  static const String publicReadPermission = 'public';

  /// Read permission level for authenticated users
  static const String authReadPermission = 'auth';

  /// Read permission level for admin users
  static const String adminReadPermission = 'admin';

  /// Write permission level for authenticated users
  static const String authWritePermission = 'auth';

  /// Write permission level for admin users
  static const String adminWritePermission = 'admin';

  // ==================== OFFLINE CAPABILITY ====================

  /// Enable offline persistence
  static const bool enableOfflinePersistence = true;

  /// Cache size in bytes
  static const int cacheSizeBytes = 10 * 1024 * 1024; // 10MB

  /// Enable offline data sync
  static const bool enableOfflineSync = true;

  /// Offline data sync interval
  static const Duration offlineSyncInterval = Duration(minutes: 5);

  // ==================== PERFORMANCE SETTINGS ====================

  /// Connection timeout for Firebase operations
  static const Duration connectionTimeout = Duration(seconds: 10);

  /// Read timeout for Firebase operations
  static const Duration readTimeout = Duration(seconds: 30);

  /// Write timeout for Firebase operations
  static const Duration writeTimeout = Duration(seconds: 30);

  /// Retry attempts for failed operations
  static const int maxRetryAttempts = 3;

  /// Retry delay between attempts
  static const Duration retryDelay = Duration(seconds: 1);

  // ==================== PATH BUILDERS ====================

  /// Build complete path for device data
  static String buildDeviceDataPath(String deviceId) {
    return '$realTimeDataPath/$deviceDataPath/$deviceId';
  }

  /// Build complete path for zone data
  static String buildZoneDataPath(String deviceId, int zoneNumber) {
    return '$realTimeDataPath/$deviceDataPath/$deviceId/$zoneDataPath/$zoneNumber';
  }

  /// Build complete path for user settings
  static String buildUserSettingsPath(String userId) {
    return '$userSettingsPath/$userId';
  }

  /// Build complete path for history logs
  static String buildHistoryLogPath(String logType) {
    return '$historyLogsPath/$logType';
  }

  /// Build complete path for troubleshooting logs
  static String buildTroubleshootingLogPath(String timestamp) {
    return '$troubleshootingPath/$timestamp';
  }

  // ==================== VALIDATION ====================

  /// Validate Firebase configuration
  static bool validateConfiguration() {
    try {
      // Check required environment variables
      final requiredVars = [
        'FIREBASE_DATABASE_URL',
        'FIREBASE_API_KEY',
        'FIREBASE_AUTH_DOMAIN',
        'FIREBASE_PROJECT_ID',
      ];

      for (final varName in requiredVars) {
        final value = dotenv.env[varName] ?? '';
        if (value.isEmpty) {
          
          return false;
        }
      }

      // Validate database URL format
      final url = databaseUrl;
      if (!url.startsWith('https://') || !url.endsWith('.firebaseio.com/') && !url.endsWith('.firebaseio.database.firebaseio.com/')) {
        
        return false;
      }

      // Validate API key format
      final key = apiKey;
      if (key.length < 20) {
        
        return false;
      }

      
      return true;
    } catch (e) {
      
      return false;
    }
  }

  // ==================== DEBUG INFO ====================

  /// Get Firebase configuration info (without sensitive data)
  static Map<String, dynamic> getFirebaseInfo() {
    return {
      'databaseUrl': databaseUrl.replaceAll(RegExp(r'/[^/]*\.json$'), '/***'),
      'projectId': projectId,
      'authDomain': authDomain,
      'hasStorageBucket': storageBucket.isNotEmpty,
      'hasMessagingSenderId': messagingSenderId.isNotEmpty,
      'hasAppId': appId.isNotEmpty,
      'realTimeDataPath': realTimeDataPath,
      'systemStatusPath': systemStatusPath,
      'ledStatusPath': ledStatusPath,
      'historyLogsPath': historyLogsPath,
      'enableOfflinePersistence': enableOfflinePersistence,
      'cacheSizeBytes': cacheSizeBytes,
      'validationPassed': validateConfiguration(),
    };
  }

  /// Get all Firebase paths
  static Map<String, String> getAllPaths() {
    return {
      'realTimeDataPath': realTimeDataPath,
      'systemStatusPath': systemStatusPath,
      'ledStatusPath': ledStatusPath,
      'controlSignalsPath': controlSignalsPath,
      'zoneConfigPath': zoneConfigPath,
      'userSettingsPath': userSettingsPath,
      'historyLogsPath': historyLogsPath,
      'historyStatusPath': historyStatusPath,
      'historyConnectionPath': historyConnectionPath,
      'historyTroublePath': historyTroublePath,
      'historyFirePath': historyFirePath,
      'userProfilesPath': userProfilesPath,
      'passwordResetPath': passwordResetPath,
    };
  }
}