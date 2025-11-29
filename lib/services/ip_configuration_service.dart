import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

/// IP Configuration Service untuk ESP32 WebSocket connection
/// Berdasarkan implementasi System 2 yang simple dan reliable
class IPConfigurationService {
  static const String _ipKey = 'esp32_ip';
  static const String _portKey = 'esp32_port';
  static const String _lastConnectedIPKey = 'last_connected_esp32_ip';

  // Default configuration berdasarkan System 2
  static const String defaultIP = '192.168.0.2';
  static const int defaultPort = 81;
  static const String defaultWebSocketURL = 'ws://$defaultIP:$defaultPort';

  /// Get ESP32 IP from SharedPreferences
  static Future<String> getESP32IP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIP = prefs.getString(_ipKey);

      if (savedIP != null && savedIP.isNotEmpty && _isValidIP(savedIP)) {
        AppLogger.info('Loaded ESP32 IP from settings: $savedIP', tag: 'IP_CONFIG');
        return savedIP;
      } else {
        // Use default if no valid saved IP
        AppLogger.info('No valid saved IP found, using default: $defaultIP', tag: 'IP_CONFIG');
        await saveESP32IP(defaultIP); // Save default for next time
        return defaultIP;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading ESP32 IP from settings',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return defaultIP;
    }
  }

  /// Save ESP32 IP to SharedPreferences
  static Future<bool> saveESP32IP(String ip) async {
    try {
      if (!_isValidIP(ip)) {
        AppLogger.warning('Invalid IP format, not saving: $ip', tag: 'IP_CONFIG');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setString(_ipKey, ip);

      if (success) {
        AppLogger.info('Saved ESP32 IP to settings: $ip', tag: 'IP_CONFIG');
      } else {
        AppLogger.warning('Failed to save ESP32 IP to settings', tag: 'IP_CONFIG');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving ESP32 IP to settings',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get ESP32 Port from SharedPreferences
  static Future<int> getESPPort() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPort = prefs.getInt(_portKey);

      if (savedPort != null && savedPort > 0 && savedPort <= 65535) {
        AppLogger.info('Loaded ESP32 port from settings: $savedPort', tag: 'IP_CONFIG');
        return savedPort;
      } else {
        AppLogger.info('No valid saved port found, using default: $defaultPort', tag: 'IP_CONFIG');
        await saveESPPort(defaultPort);
        return defaultPort;
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading ESP32 port from settings',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return defaultPort;
    }
  }

  /// Save ESP32 Port to SharedPreferences
  static Future<bool> saveESPPort(int port) async {
    try {
      if (port <= 0 || port > 65535) {
        AppLogger.warning('Invalid port number, not saving: $port', tag: 'IP_CONFIG');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setInt(_portKey, port);

      if (success) {
        AppLogger.info('Saved ESP32 port to settings: $port', tag: 'IP_CONFIG');
      } else {
        AppLogger.warning('Failed to save ESP32 port to settings', tag: 'IP_CONFIG');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving ESP32 port to settings',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get complete WebSocket URL for ESP32
  static Future<String> getWebSocketURL() async {
    final ip = await getESP32IP();
    final port = await getESPPort();
    final url = 'ws://$ip:$port';

    AppLogger.info('Generated WebSocket URL: $url', tag: 'IP_CONFIG');
    return url;
  }

  /// Get WebSocket URL with specific IP (for testing)
  static String getWebSocketURLWithIP(String ip) {
    return 'ws://$ip:$defaultPort';
  }

  /// Save last successfully connected IP
  static Future<void> saveLastConnectedIP(String ip) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastConnectedIPKey, ip);
      AppLogger.info('Saved last connected IP: $ip', tag: 'IP_CONFIG');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving last connected IP',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get last successfully connected IP
  static Future<String?> getLastConnectedIP() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastIP = prefs.getString(_lastConnectedIPKey);

      if (lastIP != null && lastIP.isNotEmpty) {
        AppLogger.info('Retrieved last connected IP: $lastIP', tag: 'IP_CONFIG');
        return lastIP;
      }

      return null;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error retrieving last connected IP',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Test connectivity to ESP32
  static Future<bool> testConnectivity(String ip, {int port = defaultPort}) async {
    try {
      if (!_isValidIP(ip)) {
        AppLogger.warning('Invalid IP for connectivity test: $ip', tag: 'IP_CONFIG');
        return false;
      }

      AppLogger.info('Testing connectivity to $ip:$port', tag: 'IP_CONFIG');

      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 5));
      socket.destroy();

      AppLogger.info('Connectivity test successful for $ip:$port', tag: 'IP_CONFIG');
      return true;
    } catch (e) {
      AppLogger.warning(
        'Connectivity test failed for $ip:$port - ${e.toString()}',
        tag: 'IP_CONFIG',
      );
      return false;
    }
  }

  /// Validate IPv4 address format
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

  /// Validate port number
  static bool isValidPort(int port) {
    return port > 0 && port <= 65535;
  }

  /// Clear all saved configuration (for reset)
  static Future<bool> clearConfiguration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ipKey);
      await prefs.remove(_portKey);
      await prefs.remove(_lastConnectedIPKey);

      AppLogger.info('Cleared all IP configuration', tag: 'IP_CONFIG');
      return true;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing IP configuration',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get current configuration status
  static Future<Map<String, dynamic>> getConfigurationStatus() async {
    try {
      final ip = await getESP32IP();
      final port = await getESPPort();
      final lastConnectedIP = await getLastConnectedIP();

      return {
        'currentIP': ip,
        'currentPort': port,
        'lastConnectedIP': lastConnectedIP,
        'webSocketURL': 'ws://$ip:$port',
        'isDefaultIP': ip == defaultIP,
        'isDefaultPort': port == defaultPort,
        'hasLastConnected': lastConnectedIP != null,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting configuration status',
        tag: 'IP_CONFIG',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'error': e.toString(),
        'currentIP': defaultIP,
        'currentPort': defaultPort,
        'webSocketURL': defaultWebSocketURL,
      };
    }
  }
}