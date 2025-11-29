
/// ⏱️ TIMING CONSTANTS - Centralized Time Configuration
///
/// Berisi semua konstanta untuk timing, delays, intervals, dan duration
/// Menggantikan magic numbers untuk waktu yang tersebar di seluruh codebase
///
/// Author: Claude Code Assistant
/// Version: 1.0.0

class TimingConstants {
  // ==================== DATA REFRESH INTERVALS ====================

  /// Main data refresh interval from Firebase
  static const Duration dataRefreshInterval = Duration(milliseconds: 500);

  /// System status refresh interval
  static const Duration systemStatusRefreshInterval = Duration(seconds: 1);

  /// Zone data refresh interval
  static const Duration zoneDataRefreshInterval = Duration(milliseconds: 100);

  /// LED status refresh interval
  static const Duration ledStatusRefreshInterval = Duration(milliseconds: 100);

  /// Quick update interval for critical changes
  static const Duration quickUpdateInterval = Duration(milliseconds: 50);

  // ==================== TIMEOUT VALUES ====================

  /// Firebase connection timeout
  static const Duration firebaseConnectionTimeout = Duration(seconds: 10);

  /// HTTP request timeout
  static const Duration httpRequestTimeout = Duration(seconds: 15);

  /// Authentication timeout
  static const Duration authTimeout = Duration(seconds: 30);

  /// Data processing timeout
  static const Duration dataProcessingTimeout = Duration(seconds: 5);

  /// Loading state timeout
  static const Duration loadingTimeout = Duration(seconds: 10);

  // ==================== ANIMATION DURATIONS ====================

  /// Instant animation (for immediate changes)
  static const Duration animationInstant = Duration(milliseconds: 0);

  /// Fast animation duration
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Normal animation duration
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Slow animation duration
  static const Duration animationSlow = Duration(milliseconds: 500);

  /// Very slow animation duration
  static const Duration animationVerySlow = Duration(milliseconds: 1000);

  // ==================== DEBOUNCE TIMING ====================

  /// Search debounce duration
  static const Duration searchDebounce = Duration(milliseconds: 300);

  /// Input field debounce duration
  static const Duration inputDebounce = Duration(milliseconds: 500);

  /// Button click debounce duration
  static const Duration buttonClickDebounce = Duration(milliseconds: 200);

  /// Scroll debounce duration
  static const Duration scrollDebounce = Duration(milliseconds: 100);

  // ==================== NOTIFICATION TIMING ====================

  /// Notification display duration
  static const Duration notificationDisplayDuration = Duration(seconds: 3);

  /// Toast message duration
  static const Duration toastMessageDuration = Duration(seconds: 2);

  /// Error message display duration
  static const Duration errorMessageDuration = Duration(seconds: 5);

  /// Success message display duration
  static const Duration successMessageDuration = Duration(seconds: 3);

  // ==================== AUDIO TIMING ====================

  /// Audio fade in duration
  static const Duration audioFadeInDuration = Duration(milliseconds: 500);

  /// Audio fade out duration
  static const Duration audioFadeOutDuration = Duration(milliseconds: 300);

  /// Audio delay between repeat plays
  static const Duration audioRepeatDelay = Duration(seconds: 2);

  /// Alarm sound duration
  static const Duration alarmSoundDuration = Duration(seconds: 5);

  /// Trouble sound duration
  static const Duration troubleSoundDuration = Duration(seconds: 3);

  // ==================== MONITORING TIMING ====================

  /// Zone status check interval
  static const Duration zoneStatusCheckInterval = Duration(milliseconds: 200);

  /// System health check interval
  static const Duration systemHealthCheckInterval = Duration(seconds: 5);

  /// Connection status check interval
  static const Duration connectionStatusCheckInterval = Duration(seconds: 2);

  /// Background task interval
  static const Duration backgroundTaskInterval = Duration(seconds: 10);

  // ==================== RETRY TIMING ====================

  /// Immediate retry delay
  static const Duration immediateRetryDelay = Duration(milliseconds: 100);

  /// Short retry delay
  static const Duration shortRetryDelay = Duration(seconds: 1);

  /// Medium retry delay
  static const Duration mediumRetryDelay = Duration(seconds: 5);

  /// Long retry delay
  static const Duration longRetryDelay = Duration(seconds: 15);

  /// Legacy compatibility aliases
  static const Duration retryDelayShort = shortRetryDelay;
  static const Duration retryDelayMedium = mediumRetryDelay;
  static const Duration retryDelayLong = longRetryDelay;

  /// Maximum retry delay (exponential backoff cap)
  static const Duration maxRetryDelay = Duration(minutes: 1);

  // ==================== CACHE TIMING ====================

  /// Data cache expiration duration
  static const Duration dataCacheExpiration = Duration(minutes: 5);

  /// Image cache expiration duration
  static const Duration imageCacheExpiration = Duration(hours: 1);

  /// Configuration cache expiration duration
  static const Duration configCacheExpiration = Duration(hours: 24);

  /// Session cache expiration duration
  static const Duration sessionCacheExpiration = Duration(hours: 12);

  // ==================== RATE LIMITING ====================

  /// Rate limit window for API calls
  static const Duration rateLimitWindow = Duration(minutes: 1);

  /// Password reset rate limit window
  static const Duration passwordResetRateLimitWindow = Duration(minutes: 5);

  /// Email verification rate limit window
  static const Duration emailVerificationRateLimitWindow = Duration(minutes: 10);

  // ==================== IDLE TIMEOUTS ====================

  /// User session idle timeout
  static const Duration userSessionIdleTimeout = Duration(minutes: 30);

  /// Auto-logout timeout
  static const Duration autoLogoutTimeout = Duration(hours: 2);

  /// Screen saver timeout
  static const Duration screenSaverTimeout = Duration(minutes: 5);

  // ==================== BACKGROUND PROCESSING ====================

  /// Background task execution interval
  static const Duration backgroundTaskExecutionInterval = Duration(minutes: 1);

  /// Data sync interval
  static const Duration dataSyncInterval = Duration(minutes: 5);

  /// Cleanup task interval
  static const Duration cleanupTaskInterval = Duration(hours: 1);

  /// Log cleanup interval
  static const Duration logCleanupInterval = Duration(hours: 24);

  // ==================== PERFORMANCE MONITORING ====================

  /// Performance check interval
  static const Duration performanceCheckInterval = Duration(seconds: 30);

  /// Memory cleanup interval
  static const Duration memoryCleanupInterval = Duration(minutes: 5);

  /// Garbage collection suggestion interval
  static const Duration garbageCollectionInterval = Duration(minutes: 10);

  // ==================== DEBUG & DEVELOPMENT ====================

  /// Debug print throttle duration
  static const Duration debugPrintThrottleDuration = Duration(milliseconds: 500);

  /// Development hot reload simulation delay
  static const Duration hotReloadSimulationDelay = Duration(milliseconds: 200);

  /// Test wait duration
  static const Duration testWaitDuration = Duration(milliseconds: 100);

  // ==================== LEGACY COMPATIBILITY ====================

  /// Legacy delay for home page updates (50ms)
  static const Duration legacyHomeUpdateDelay = Duration(milliseconds: 50);

  /// Legacy animation duration (300ms)
  static const Duration legacyAnimationDuration = Duration(milliseconds: 300);

  /// Legacy short delay (100ms)
  static const Duration legacyShortDelay = Duration(milliseconds: 100);

  // ==================== TIMING HELPERS ====================

  /// Get appropriate refresh interval based on priority
  static Duration getRefreshIntervalForPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return quickUpdateInterval;
      case 'high':
        return Duration(milliseconds: 100);
      case 'normal':
        return dataRefreshInterval;
      case 'low':
        return Duration(seconds: 1);
      default:
        return dataRefreshInterval;
    }
  }

  /// Get retry delay with exponential backoff
  static Duration getRetryDelay(int attemptNumber) {
    final delay = Duration(milliseconds: 100 * (1 << attemptNumber));
    return delay > maxRetryDelay ? maxRetryDelay : delay;
  }

  /// Check if duration is within reasonable bounds
  static bool isValidDuration(Duration duration) {
    return duration >= Duration.zero && duration <= Duration(hours: 24);
  }

  /// Format duration for human-readable display
  static String formatDuration(Duration duration) {
    if (duration.inMilliseconds < 1000) {
      return '${duration.inMilliseconds}ms';
    } else if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  // ==================== VALIDATION ====================

  /// Validate timing configuration
  static bool validateConfiguration() {
    // Check for negative durations
    final allDurations = [
      dataRefreshInterval,
      firebaseConnectionTimeout,
      animationFast,
      animationNormal,
      animationSlow,
      notificationDisplayDuration,
      retryDelayShort,
      retryDelayMedium,
      retryDelayLong,
    ];

    for (final duration in allDurations) {
      if (duration.isNegative) {
        
        return false;
      }
    }

    // Check logical ordering
    if (animationFast >= animationNormal || animationNormal >= animationSlow) {
      
      return false;
    }

    if (retryDelayShort >= retryDelayMedium || retryDelayMedium >= retryDelayLong) {
      
      return false;
    }

    
    return true;
  }

  // ==================== DEBUG INFO ====================

  /// Get timing configuration info
  static Map<String, dynamic> getTimingInfo() {
    return {
      'refreshIntervals': {
        'data': dataRefreshInterval.inMilliseconds,
        'systemStatus': systemStatusRefreshInterval.inMilliseconds,
        'zoneData': zoneDataRefreshInterval.inMilliseconds,
      },
      'timeouts': {
        'firebase': firebaseConnectionTimeout.inSeconds,
        'http': httpRequestTimeout.inSeconds,
        'auth': authTimeout.inSeconds,
      },
      'animations': {
        'fast': animationFast.inMilliseconds,
        'normal': animationNormal.inMilliseconds,
        'slow': animationSlow.inMilliseconds,
      },
      'retryDelays': {
        'short': shortRetryDelay.inSeconds,
        'medium': mediumRetryDelay.inSeconds,
        'long': longRetryDelay.inSeconds,
      },
      'validationPassed': validateConfiguration(),
    };
  }
}