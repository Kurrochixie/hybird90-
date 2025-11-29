/// App-wide constants used throughout the application
/// Centralized to avoid magic numbers and improve maintainability
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  // ===========================================
  // UI DIMENSIONS & BREAKPOINTS
  // ===========================================
  static const double smallScreenBreakpoint = 412.0;
  static const double mediumScreenBreakpoint = 600.0;
  static const double largeScreenBreakpoint = 900.0;

  // Heights
  static const double recentStatusHeightSmall = 250.0;
  static const double recentStatusHeightLarge = 300.0;
  static const double buttonHeight = 48.0;
  static const double appBarHeight = 56.0;

  // Widths
  static const double maxContentWidth = 1200.0;
  static const double sideNavWidth = 280.0;
  static const double zoneCardWidth = 200.0;

  // ===========================================
  // DURATIONS & TIMING
  // ===========================================
  static const Duration shortDelay = Duration(milliseconds: 100);
  static const Duration mediumDelay = Duration(milliseconds: 300);
  static const Duration longDelay = Duration(milliseconds: 500);
  static const Duration debounceDelay = Duration(milliseconds: 250);

  // Timers
  static const Duration cleanupTimerPeriod = Duration(minutes: 30);
  static const Duration statusCheckInterval = Duration(seconds: 5);
  static const Duration reconnectDelay = Duration(seconds: 10);
  static const Duration notificationTimeout = Duration(seconds: 30);

  // ===========================================
  // SYSTEM CONFIGURATION
  // ===========================================
  static const int maxRetryAttempts = 3;
  static const int maxZones = 315;
  static const int zonesPerRow = 16;
  static const int maxRecentLogs = 100;
  static const int maxCachedItems = 500;

  // Data refresh intervals
  static const Duration dataRefreshInterval = Duration(seconds: 2);
  static const Duration slowDataRefreshInterval = Duration(seconds: 5);
  static const Duration backgroundRefreshInterval = Duration(minutes: 1);

  // ===========================================
  // FIRE ALARM SYSTEM SPECIFIC
  // ===========================================
  // AABBCC System Constants
  static const int addressByteLength = 2; // AA
  static const int statusByteLength = 4; // BBCC
  static const int totalMessageLength = 6; // AABBCC (6 bytes)

  // Status bits
  static const int alarmBitMask = 0x01;
  static const int bellBitMask = 0x02;
  static const int troubleBitMask = 0x04;
  static const int acknowledgeBitMask = 0x08;

  // Zone status thresholds
  static const int criticalZoneThreshold = 10;
  static const int warningZoneThreshold = 5;

  // ===========================================
  // AUDIO CONFIGURATION
  // ===========================================
  static const double defaultVolume = 0.8;
  static const double maxVolume = 1.0;
  static const double minVolume = 0.0;
  static const double volumeStep = 0.1;

  // Audio priority values (lower = higher priority)
  static const int troubleAudioPriority = 1;
  static const int fireAlarmAudioPriority = 2;
  static const int bellOnlyAudioPriority = 3;

  // Audio file paths (if any)
  static const String fireAlarmSoundPath = 'assets/audio/fire_alarm.mp3';
  static const String troubleSoundPath = 'assets/audio/trouble_beep.mp3';
  static const String bellSoundPath = 'assets/audio/bell.mp3';

  // ===========================================
  // NETWORK & API CONFIGURATION
  // ===========================================
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 25);

  // Retry delays
  static const Duration initialRetryDelay = Duration(seconds: 1);
  static const Duration maxRetryDelay = Duration(seconds: 30);
  static const double retryDelayMultiplier = 2.0;

  // ===========================================
  // CACHE CONFIGURATION
  // ===========================================
  static const Duration defaultCacheExpiry = Duration(hours: 1);
  static const Duration longCacheExpiry = Duration(hours: 24);
  static const Duration shortCacheExpiry = Duration(minutes: 5);

  // Cache cleanup intervals
  static const Duration cacheCleanupInterval = Duration(minutes: 15);
  static const double maxCacheSizeMB = 50.0;

  // ===========================================
  // FILE & STORAGE CONFIGURATION
  // ===========================================
  static const int maxLogFileSize = 10 * 1024 * 1024; // 10MB
  static const int maxBackupFiles = 7; // Keep 7 days of backups
  static const Duration backupInterval = Duration(hours: 24);

  // ===========================================
  // NOTIFICATION CONFIGURATION
  // ===========================================
  static const int maxNotifications = 50;
  static const Duration notificationDisplayDuration = Duration(seconds: 5);
  static const Duration vibrationDuration = Duration(milliseconds: 500);

  // ===========================================
  // VALIDATION RULES
  // ===========================================
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 100;

  // ===========================================
  // DEBUG & DEVELOPMENT
  // ===========================================
  static const bool enableDebugLogs = true;
  static const bool enablePerformanceMonitoring = false;
  static const Duration debugLogFlushInterval = Duration(seconds: 10);

  // ===========================================
  // UI CONFIGURATION
  // ===========================================
  static const int defaultCrossAxisCount = 2;
  static const double defaultChildAspectRatio = 1.0;
  static const double defaultSpacing = 8.0;
  static const double defaultRunSpacing = 8.0;

  // Animation durations
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);

  // ===========================================
  // FIREBASE CONFIGURATION
  // ===========================================
  static const String firebaseDatabaseUrl = 'firebase-rtdb.firebaseio.com';
  static const String defaultFirebaseRegion = 'asia-southeast1';

  // Firebase paths
  static const String zonesPath = '/zones';
  static const String systemStatusPath = '/system_status';
  static const String logsPath = '/logs';
  static const String settingsPath = '/settings';
  static const String usersPath = '/users';

  // ===========================================
  // ERROR MESSAGES
  // ===========================================
  static const String genericErrorMessage = 'An unexpected error occurred';
  static const String networkErrorMessage = 'Network connection failed';
  static const String authErrorMessage = 'Authentication failed';
  static const String permissionErrorMessage = 'Permission denied';

  // ===========================================
  // SUCCESS MESSAGES
  // ===========================================
  static const String loginSuccessMessage = 'Login successful';
  static const String logoutSuccessMessage = 'Logout successful';
  static const String settingsSavedMessage = 'Settings saved successfully';
  static const String dataUpdatedMessage = 'Data updated successfully';
}

/// App Dimensions constants for UI consistency
class AppDimensions {
  AppDimensions._();

  // Padding and margins
  static const double paddingXS = 4.0;
  static const double paddingSM = 8.0;
  static const double paddingMD = 16.0;
  static const double paddingLG = 24.0;
  static const double paddingXL = 32.0;

  // Border radius
  static const double radiusXS = 4.0;
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 20.0;

  // Font sizes
  static const double fontXS = 12.0;
  static const double fontSM = 14.0;
  static const double fontMD = 16.0;
  static const double fontLG = 18.0;
  static const double fontXL = 20.0;
  static const double fontXXL = 24.0;

  // Icon sizes
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  // Stroke widths
  static const double strokeXS = 1.0;
  static const double strokeSM = 2.0;
  static const double strokeMD = 3.0;
  static const double strokeLG = 4.0;
}

/// App Colors constants for theme consistency
class AppColors {
  AppColors._();

  // Status colors
  static const int statusNormal = 0xFF00FF00;    // Green
  static const int statusAlarm = 0xFFFF0000;      // Red
  static const int statusTrouble = 0xFFFFA500;    // Orange
  static const int statusAcknowledge = 0xFFFFFF00; // Yellow
  static const int statusOffline = 0xFF808080;    // Gray

  // Background colors
  static const int backgroundLight = 0xFFFAFAFA;
  static const int backgroundDark = 0xFF121212;
  static const int surfaceLight = 0xFFFFFFFF;
  static const int surfaceDark = 0xFF1E1E1E;

  // Text colors
  static const int textPrimaryLight = 0xFF000000;
  static const int textSecondaryLight = 0xFF666666;
  static const int textPrimaryDark = 0xFFFFFFFF;
  static const int textSecondaryDark = 0xFFCCCCCC;
}

/// WebSocket Configuration Constants
class WebSocketConstants {
  WebSocketConstants._();

  static const int defaultPort = 80;
  static const int securePort = 443;
  static const String protocol = 'ws';
  static const String secureProtocol = 'wss';
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const int maxReconnectAttempts = 10;
  static const Duration baseReconnectDelay = Duration(seconds: 2);
  static const Duration maxReconnectDelay = Duration(seconds: 30);
  static const String defaultESP32IP = '192.168.1.100'; // NEW: Default ESP32 IP
}