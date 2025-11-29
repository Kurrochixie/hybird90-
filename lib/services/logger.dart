import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Enhanced logging framework for the application
/// Provides different log levels and can be configured for production
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

class AppLogger {
  static LogLevel _currentLogLevel = kDebugMode ? LogLevel.debug : LogLevel.info;
  static bool _enableConsoleOutput = true;
  static bool _enableDeveloperLog = true;
  static final List<LogEntry> _logHistory = [];
  static const int _maxLogHistory = 1000;

  /// Configure the logger with desired settings
  static void configure({
    LogLevel? minLevel,
    bool? enableConsoleOutput,
    bool? enableDeveloperLog,
  }) {
    _currentLogLevel = minLevel ?? (kDebugMode ? LogLevel.debug : LogLevel.info);
    _enableConsoleOutput = enableConsoleOutput ?? true;
    _enableDeveloperLog = enableDeveloperLog ?? true;
  }

  /// Log a debug message
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log Firebase operations
  static void firebase(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: 'FIREBASE', error: error, stackTrace: stackTrace);
  }

  /// Log Network operations
  static void network(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: 'NETWORK', error: error, stackTrace: stackTrace);
  }

  /// Log Audio operations
  static void audio(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: 'AUDIO', error: error, stackTrace: stackTrace);
  }

  /// Log Performance metrics
  static void performance(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag ?? 'PERFORMANCE', error: error, stackTrace: stackTrace);
  }

  /// Log Authentication operations
  static void auth(String message, {Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: 'AUTH', error: error, stackTrace: stackTrace);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    // Check if we should log this level
    if (level.index < _currentLogLevel.index) {
      return;
    }

    final timestamp = DateTime.now();
    final entry = LogEntry(
      level: level,
      message: message,
      tag: tag,
      timestamp: timestamp,
      error: error,
      stackTrace: stackTrace,
    );

    // Add to history
    _addToHistory(entry);

    // Output to console if enabled
    if (_enableConsoleOutput) {
      _printToConsole(entry);
    }

    // Send to developer log if enabled
    if (_enableDeveloperLog) {
      _sendToDeveloperLog(entry);
    }

    // In production, send critical errors to crash reporting
    if (!kDebugMode && (level == LogLevel.error || level == LogLevel.fatal)) {
      _sendToCrashReporting(entry);
    }
  }

  /// Add entry to log history with size limit
  static void _addToHistory(LogEntry entry) {
    _logHistory.add(entry);

    // Remove old entries if we exceed the limit
    while (_logHistory.length > _maxLogHistory) {
      _logHistory.removeAt(0);
    }
  }

  /// Print formatted log to console
  static void _printToConsole(LogEntry entry) {
    final levelString = entry.level.name.toUpperCase().padRight(7);
    final timestampString = entry.timestamp.toIso8601String().substring(11, 19);
    final tagString = entry.tag != null ? '[${entry.tag}] ' : '';

    final formattedMessage = '$timestampString $levelString $tagString${entry.message}';

    if (entry.error != null) {
      
      if (entry.stackTrace != null) {
        
      }
    } else {
      
    }
  }

  /// Send to developer log for debugging
  static void _sendToDeveloperLog(LogEntry entry) {
    final logMessage = '${entry.level.name}: ${entry.message}';
    developer.log(
      logMessage,
      name: entry.tag ?? 'APP',
      time: entry.timestamp,
      level: entry.level.index * 100, // Convert to int for developer.log
      error: entry.error,
      stackTrace: entry.stackTrace,
    );
  }

  /// Send critical errors to crash reporting service
  static void _sendToCrashReporting(LogEntry entry) {
    
    // This could be Firebase Crashlytics, Sentry, etc.
    if (AppConstants.enableDebugLogs) {
      debug('CRASH REPORTING: ${entry.message}', error: entry.error);
    }
  }

  /// Get log history for debugging
  static List<LogEntry> getLogHistory({LogLevel? minLevel}) {
    if (minLevel == null) return List.from(_logHistory);

    return _logHistory.where((entry) => entry.level.index >= minLevel.index).toList();
  }

  /// Get recent logs within a time window
  static List<LogEntry> getRecentLogs(Duration window) {
    final cutoff = DateTime.now().subtract(window);
    return _logHistory.where((entry) => entry.timestamp.isAfter(cutoff)).toList();
  }

  /// Clear log history
  static void clearLogHistory() {
    _logHistory.clear();
  }

  /// Export logs to string for debugging
  static String exportLogs({LogLevel? minLevel}) {
    final logs = getLogHistory(minLevel: minLevel);
    final buffer = StringBuffer();

    for (final log in logs) {
      buffer.writeln(log.toString());
    }

    return buffer.toString();
  }

  /// Get current log level
  static LogLevel get currentLogLevel => _currentLogLevel;

  /// Check if a specific log level is enabled
  static bool isLevelEnabled(LogLevel level) {
    return level.index >= _currentLogLevel.index;
  }
}

/// Represents a single log entry
class LogEntry {
  final LogLevel level;
  final String message;
  final String? tag;
  final DateTime timestamp;
  final Object? error;
  final StackTrace? stackTrace;

  LogEntry({
    required this.level,
    required this.message,
    this.tag,
    required this.timestamp,
    this.error,
    this.stackTrace,
  });

  @override
  String toString() {
    final levelString = level.name.toUpperCase();
    final timestampString = timestamp.toIso8601String();
    final tagString = tag != null ? ' [$tag]' : '';
    final errorString = error != null ? '\nError: $error' : '';
    final stackTraceString = stackTrace != null ? '\nStackTrace: $stackTrace' : '';

    return '$timestampString $levelString$tagString $message$errorString$stackTraceString';
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'level': level.name,
      'message': message,
      'tag': tag,
      'timestamp': timestamp.toIso8601String(),
      'error': error?.toString(),
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Extension methods for convenient logging
extension LoggerExtensions on String {
  /// Log this string as a debug message
  void logDebug({String? tag}) {
    AppLogger.debug(this, tag: tag);
  }

  /// Log this string as an info message
  void logInfo({String? tag}) {
    AppLogger.info(this, tag: tag);
  }

  /// Log this string as a warning message
  void logWarning({String? tag}) {
    AppLogger.warning(this, tag: tag);
  }

  /// Log this string as an error message
  void logError({String? tag, Object? error, StackTrace? stackTrace}) {
    AppLogger.error(this, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log this string as a fatal error message
  void logFatal({String? tag, Object? error, StackTrace? stackTrace}) {
    AppLogger.fatal(this, tag: tag, error: error, stackTrace: stackTrace);
  }
}

/// Performance timer for measuring execution time
class PerformanceTimer {
  final String name;
  final Stopwatch _stopwatch;
  final String? tag;

  PerformanceTimer(this.name, {this.tag}) : _stopwatch = Stopwatch()..start();

  /// Stop the timer and log the elapsed time
  void stop() {
    _stopwatch.stop();
    AppLogger.performance(
      'Operation "$name" completed in ${_stopwatch.elapsedMilliseconds}ms',
      tag: tag,
    );
  }

  /// Get current elapsed time without stopping
  Duration get elapsed => _stopwatch.elapsed;

  /// Log current elapsed time without stopping
  void logElapsed() {
    AppLogger.performance(
      'Operation "$name" elapsed time: ${_stopwatch.elapsedMilliseconds}ms',
      tag: tag,
    );
  }
}

/// Helper method to create and measure performance of functions
T measurePerformance<T>(
  String operationName,
  T Function() function, {
  String? tag,
}) {
  final timer = PerformanceTimer(operationName, tag: tag);
  try {
    final result = function();
    timer.stop();
    return result;
  } catch (e, stackTrace) {
    timer.stop();
    AppLogger.error(
      'Operation "$operationName" failed',
      tag: tag,
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}

/// Helper method to create and measure performance of async functions
Future<T> measurePerformanceAsync<T>(
  String operationName,
  Future<T> Function() function, {
  String? tag,
}) async {
  final timer = PerformanceTimer(operationName, tag: tag);
  try {
    final result = await function();
    timer.stop();
    return result;
  } catch (e, stackTrace) {
    timer.stop();
    AppLogger.error(
      'Operation "$operationName" failed',
      tag: tag,
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
}