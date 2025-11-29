import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../services/logger.dart';

/// WebSocket Settings Service untuk persistent storage
/// Independent dari Firebase settings
class WebSocketSettingsService {
  WebSocketSettingsService._(); // Private constructor

  // SharedPreferences keys
  static const String _esp32IPKey = 'websocket_esp32_ip';
  static const String _modeEnabledKey = 'websocket_mode_enabled';
  static const String _autoConnectKey = 'websocket_auto_connect';
  static const String _reconnectAttemptsKey = 'websocket_reconnect_attempts';
  static const String _lastUsedIPKey = 'websocket_last_used_ip';

  /// Get ESP32 IP address
  static Future<String> getESP32IP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_esp32IPKey) ?? WebSocketConstants.defaultESP32IP;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting ESP32 IP from settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return WebSocketConstants.defaultESP32IP;
    }
  }

  /// Save ESP32 IP address
  static Future<bool> saveESP32IP(String ip) async {
    try {
      if (ip.isEmpty || !_isValidIP(ip)) {
        AppLogger.warning('Invalid IP address format: $ip', tag: 'WS_SETTINGS');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_esp32IPKey, ip);

      if (success) {
        AppLogger.info('ESP32 IP saved: $ip', tag: 'WS_SETTINGS');

        // Also save as last used IP
        await prefs.setString(_lastUsedIPKey, ip);
      } else {
        AppLogger.error('Failed to save ESP32 IP', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving ESP32 IP',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get WebSocket mode enabled status
  static Future<bool> getWebSocketMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_modeEnabledKey) ?? false;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting WebSocket mode from settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Set WebSocket mode enabled status
  static Future<bool> setWebSocketMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_modeEnabledKey, enabled);

      if (success) {
        AppLogger.info('WebSocket mode set to: $enabled', tag: 'WS_SETTINGS');
      } else {
        AppLogger.error('Failed to set WebSocket mode', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error setting WebSocket mode',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get auto-connect setting
  static Future<bool> getAutoConnect() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_autoConnectKey) ?? true; // Default to true
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting auto-connect setting',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return true;
    }
  }

  /// Set auto-connect setting
  static Future<bool> setAutoConnect(bool autoConnect) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_autoConnectKey, autoConnect);

      if (success) {
        AppLogger.info('Auto-connect set to: $autoConnect', tag: 'WS_SETTINGS');
      } else {
        AppLogger.error('Failed to set auto-connect', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error setting auto-connect',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Reset to Firebase mode (clear WebSocket mode preference)
  static Future<bool> resetToFirebaseMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final futures = <Future<bool>>[];

      // Clear WebSocket mode preference
      futures.add(prefs.remove(_modeEnabledKey));

      // Reset other WebSocket-related settings to defaults
      futures.add(prefs.setBool(_autoConnectKey, true)); // Default auto-connect on
      futures.add(prefs.setInt(_reconnectAttemptsKey, 0)); // Reset attempts
      futures.add(prefs.remove(_lastUsedIPKey)); // Clear last used IP

      final results = await Future.wait(futures);
      final success = results.every((result) => result);

      if (success) {
        AppLogger.info('Reset to Firebase mode successful', tag: 'WS_SETTINGS');
      } else {
        AppLogger.warning('Some settings failed to reset', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error resetting to Firebase mode',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get reconnect attempts count
  static Future<int> getReconnectAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_reconnectAttemptsKey) ?? 0;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting reconnect attempts',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return 0;
    }
  }

  /// Increment reconnect attempts count
  static Future<bool> incrementReconnectAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getReconnectAttempts();
      final success = await prefs.setInt(_reconnectAttemptsKey, current + 1);

      if (success) {
        AppLogger.info('Reconnect attempts incremented to: ${current + 1}', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error incrementing reconnect attempts',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Reset reconnect attempts count
  static Future<bool> resetReconnectAttempts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_reconnectAttemptsKey, 0);

      if (success) {
        AppLogger.info('Reconnect attempts reset', tag: 'WS_SETTINGS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error resetting reconnect attempts',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get last used IP address
  static Future<String> getLastUsedIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUsedIPKey) ?? WebSocketConstants.defaultESP32IP;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting last used IP',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return WebSocketConstants.defaultESP32IP;
    }
  }

  /// Clear all WebSocket settings
  static Future<bool> clearAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final keysToRemove = [
        _esp32IPKey,
        _modeEnabledKey,
        _autoConnectKey,
        _reconnectAttemptsKey,
        _lastUsedIPKey,
      ];

      for (final key in keysToRemove) {
        await prefs.remove(key);
      }

      AppLogger.info('All WebSocket settings cleared', tag: 'WS_SETTINGS');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing WebSocket settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get all settings as map for debugging
  static Future<Map<String, dynamic>> getAllSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      return {
        'esp32IP': prefs.getString(_esp32IPKey) ?? WebSocketConstants.defaultESP32IP,
        'webSocketMode': prefs.getBool(_modeEnabledKey) ?? false,
        'autoConnect': prefs.getBool(_autoConnectKey) ?? true,
        'reconnectAttempts': prefs.getInt(_reconnectAttemptsKey) ?? 0,
        'lastUsedIP': prefs.getString(_lastUsedIPKey) ?? WebSocketConstants.defaultESP32IP,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting all settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return {};
    }
  }

  /// Validate IP address format
  static bool _isValidIP(String ip) {
    if (ip.isEmpty) return false;

    final parts = ip.split('.');
    if (parts.length != 4) return false;

    for (final part in parts) {
      try {
        final value = int.parse(part);
        if (value < 0 || value > 255) return false;
      } catch (e) {
        return false;
      }
    }

    return true;
  }

  /// Validate settings integrity
  static Future<bool> validateSettings() async {
    try {
      final settings = await getAllSettings();
      final esp32IP = settings['esp32IP'] as String;
      final lastUsedIP = settings['lastUsedIP'] as String;

      // Validate IP addresses
      if (!_isValidIP(esp32IP)) {
        AppLogger.warning('Invalid ESP32 IP in settings: $esp32IP', tag: 'WS_SETTINGS');
        return false;
      }

      if (!_isValidIP(lastUsedIP)) {
        AppLogger.warning('Invalid last used IP in settings: $lastUsedIP', tag: 'WS_SETTINGS');
        return false;
      }

      // Validate numeric values
      final reconnectAttempts = settings['reconnectAttempts'] as int;
      if (reconnectAttempts < 0) {
        AppLogger.warning('Invalid reconnect attempts: $reconnectAttempts', tag: 'WS_SETTINGS');
        return false;
      }

      AppLogger.info('WebSocket settings validation passed', tag: 'WS_SETTINGS');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error validating settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Initialize default settings if not exists
  static Future<void> initializeDefaults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      bool needsSave = false;

      // Set default ESP32 IP if not exists
      if (!prefs.containsKey(_esp32IPKey)) {
        await prefs.setString(_esp32IPKey, WebSocketConstants.defaultESP32IP);
        needsSave = true;
      }

      // Set default mode if not exists
      if (!prefs.containsKey(_modeEnabledKey)) {
        await prefs.setBool(_modeEnabledKey, false);
        needsSave = true;
      }

      // Set default auto-connect if not exists
      if (!prefs.containsKey(_autoConnectKey)) {
        await prefs.setBool(_autoConnectKey, true);
        needsSave = true;
      }

      // Reset reconnect attempts
      if (!prefs.containsKey(_reconnectAttemptsKey)) {
        await prefs.setInt(_reconnectAttemptsKey, 0);
        needsSave = true;
      }

      if (needsSave) {
        AppLogger.info('WebSocket settings initialized with defaults', tag: 'WS_SETTINGS');
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error initializing default settings',
        tag: 'WS_SETTINGS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}