import 'package:flutter/material.dart';
import 'dart:async';
import 'fire_alarm_websocket_manager.dart';
import 'websocket_settings_service.dart';
import '../services/logger.dart';
import '../constants/app_constants.dart';

/// WebSocket Mode Manager untuk menghandle switching antara Firebase dan ESP32 mode
/// Complete independent dari FireAlarmData untuk Firebase protection
class WebSocketModeManager extends ChangeNotifier {
  // Singleton instance
  static WebSocketModeManager? _instance;

  /// Get singleton instance
  static WebSocketModeManager get instance {
    _instance ??= WebSocketModeManager._();
    return _instance!;
  }

  // Private constructor for singleton
  WebSocketModeManager._() {
    _initializeFromSettings();
  }

  // Factory constructor untuk backward compatibility
  factory WebSocketModeManager() {
    return instance;
  }

  // WebSocket state management
  bool _isWebSocketMode = false;
  bool _isConnecting = false;
  bool _isConnected = false;
  String _esp32IP = WebSocketConstants.defaultESP32IP;
  String? _lastError;

  // WebSocket Manager
  FireAlarmWebSocketManager? _webSocketManager;

  // FireAlarmData reference for cache invalidation
  dynamic _fireAlarmData;

  // Getters
  bool get isWebSocketMode => _isWebSocketMode;
  bool get isConnecting => _isConnecting;
  bool get isConnected => _isConnected;
  String get esp32IP => _esp32IP;
  String? get lastError => _lastError;
  bool get isFirebaseMode => !_isWebSocketMode;

  /// Force reset to Firebase mode and reinitialize
  Future<void> forceResetToFirebaseMode() async {
    AppLogger.info('Force resetting to Firebase mode...', tag: 'WS_MODE_MANAGER');
    await _initializeFromSettings(forceFirebaseMode: true);
  }

  // Getter untuk external access to WebSocket manager
  FireAlarmWebSocketManager? get webSocketManager => _webSocketManager;

  /// Initialize mode dari saved settings
  Future<void> _initializeFromSettings({bool forceFirebaseMode = false}) async {
    try {
      // Force reset to Firebase mode if requested
      if (forceFirebaseMode) {
        await WebSocketSettingsService.resetToFirebaseMode();
        AppLogger.info(
          'Force reset to Firebase mode completed',
          tag: 'WS_MODE_MANAGER',
        );
      }

      _esp32IP = await WebSocketSettingsService.getESP32IP();
      _isWebSocketMode = await WebSocketSettingsService.getWebSocketMode();

      AppLogger.info(
        'WebSocket mode initialized: mode=$_isWebSocketMode, ip=$_esp32IP, forceReset=$forceFirebaseMode',
        tag: 'WS_MODE_MANAGER',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error initializing WebSocket mode settings',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Initialize WebSocket manager dengan FireAlarmData
  Future<void> initializeManager(dynamic fireAlarmData) async {
    try {
      // Store FireAlarmData reference for cache invalidation
      _fireAlarmData = fireAlarmData;

      // Create WebSocket manager dengan FireAlarmData reference
      _webSocketManager = FireAlarmWebSocketManager(fireAlarmData);

      // Listen ke WebSocket status changes
      _webSocketManager!.addListener(_onWebSocketStatusChanged);

      AppLogger.info('WebSocket manager initialized', tag: 'WS_MODE_MANAGER');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error initializing WebSocket manager',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Toggle antara Firebase mode dan WebSocket mode
  Future<bool> toggleMode() async {
    try {
      AppLogger.info(
        'Toggling mode from ${_isWebSocketMode ? "WebSocket" : "Firebase"} to ${_isWebSocketMode ? "Firebase" : "WebSocket"}',
        tag: 'WS_MODE_MANAGER',
      );

      if (_isWebSocketMode) {
        // Switch ke Firebase mode (disconnect WebSocket)
        await _switchToFirebaseMode();
      } else {
        // Switch ke WebSocket mode (connect ESP32)
        await _switchToWebSocketMode();
      }

      // Save mode ke settings
      await WebSocketSettingsService.setWebSocketMode(_isWebSocketMode);

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _lastError = e.toString();
      AppLogger.error(
        'Error toggling WebSocket mode',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
      notifyListeners();
      return false;
    }
  }

  /// Switch ke Firebase mode (disconnect ESP32)
  Future<void> _switchToFirebaseMode() async {
    try {
      AppLogger.info('Switching to Firebase mode', tag: 'WS_MODE_MANAGER');

      _isConnecting = true;
      notifyListeners();

      // Disconnect dari ESP32
      if (_webSocketManager != null) {
        await _webSocketManager!.disconnectFromESP32();
      }

      _isWebSocketMode = false;
      _isConnecting = false;
      _isConnected = false;
      _lastError = null;

      AppLogger.info('Successfully switched to Firebase mode', tag: 'WS_MODE_MANAGER');
    } catch (e, stackTrace) {
      _lastError = e.toString();
      AppLogger.error(
        'Error switching to Firebase mode',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Switch ke WebSocket mode (connect ESP32)
  Future<void> _switchToWebSocketMode() async {
    try {
      AppLogger.info('Switching to WebSocket mode', tag: 'WS_MODE_MANAGER');

      _isConnecting = true;
      _lastError = null;
      notifyListeners();

      // Connect ke ESP32
      if (_webSocketManager != null) {
        final success = await _webSocketManager!.connectToESP32(_esp32IP);

        if (success) {
          _isWebSocketMode = true;
          AppLogger.info('Successfully switched to WebSocket mode', tag: 'WS_MODE_MANAGER');

          // 🚀 FORCE CACHE INVALIDATION and PENDING DATA PROCESSING
          await _invalidateCacheAndProcessPending();
        } else {
          throw Exception('Failed to connect to ESP32');
        }
      } else {
        throw Exception('WebSocket manager not initialized');
      }
    } catch (e, stackTrace) {
      _lastError = e.toString();
      AppLogger.error(
        'Error switching to WebSocket mode',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } finally {
      _isConnecting = false;
      notifyListeners();
    }
  }

  /// Handle WebSocket status changes dari manager
  void _onWebSocketStatusChanged() {
    if (_webSocketManager != null) {
      final wasConnected = _isConnected;
      _isConnected = _webSocketManager!.isConnected;

      // Log status change
      if (wasConnected != _isConnected) {
        AppLogger.info(
          'WebSocket status changed: ${wasConnected ? "connected" : "disconnected"} -> ${_isConnected ? "connected" : "disconnected"}',
          tag: 'WS_MODE_MANAGER',
        );
      }

      notifyListeners();
    }
  }

  /// Update ESP32 IP address
  Future<bool> updateESP32IP(String newIP) async {
    try {
      // Validate IP format
      if (!_isValidIP(newIP)) {
        _lastError = 'Invalid IP address format';
        notifyListeners();
        return false;
      }

      AppLogger.info('Updating ESP32 IP from $_esp32IP to $newIP', tag: 'WS_MODE_MANAGER');

      // Disconnect dulu jika connected
      if (_isConnected && _webSocketManager != null) {
        await _webSocketManager!.disconnectFromESP32();
      }

      // Update IP
      _esp32IP = newIP;

      // Save ke settings
      await WebSocketSettingsService.saveESP32IP(newIP);

      // Reconnect jika dalam WebSocket mode
      if (_isWebSocketMode && _webSocketManager != null) {
        _isConnecting = true;
        notifyListeners();

        final success = await _webSocketManager!.connectToESP32(_esp32IP);
        _isConnecting = false;

        if (!success) {
          _lastError = 'Failed to reconnect with new IP';
          notifyListeners();
          return false;
        }
      }

      AppLogger.info('ESP32 IP updated successfully to $newIP', tag: 'WS_MODE_MANAGER');
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      _lastError = e.toString();
      AppLogger.error(
        'Error updating ESP32 IP',
        tag: 'WS_MODE_MANAGER',
        error: e,
        stackTrace: stackTrace,
      );
      notifyListeners();
      return false;
    }
  }

  /// Validate IP address format
  bool _isValidIP(String ip) {
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

  /// Get current status text untuk display
  String getStatusText() {
    if (_isConnecting) {
      return 'Connecting...';
    } else if (_isWebSocketMode) {
      if (_isConnected) {
        return 'ESP32 Connected';
      } else {
        return 'ESP32 Disconnected';
      }
    } else {
      return 'Firebase Connected'; // Assuming Firebase is connected
    }
  }

  /// Get status color untuk display
  Color getStatusColor() {
    if (_isConnecting) {
      return Colors.orange;
    } else if (_isWebSocketMode) {
      return _isConnected ? Colors.green : Colors.grey;
    } else {
      return Colors.green; // Firebase connected color
    }
  }

  /// Get connection mode text
  String getConnectionModeText() {
    return _isWebSocketMode ? 'Offline' : 'Online';
  }

  /// Get connection mode color
  Color getConnectionModeColor() {
    return _isWebSocketMode ? Colors.grey : Colors.green;
  }

  /// Get diagnostics info
  Map<String, dynamic> getDiagnostics() {
    final diagnostics = {
      'isWebSocketMode': _isWebSocketMode,
      'isConnecting': _isConnecting,
      'isConnected': _isConnected,
      'esp32IP': _esp32IP,
      'lastError': _lastError,
      'statusText': getStatusText(),
      'connectionModeText': getConnectionModeText(),
      'hasWebSocketManager': _webSocketManager != null,
    };

    // Add WebSocket manager diagnostics
    if (_webSocketManager != null) {
      diagnostics['webSocketManager'] = _webSocketManager!.getDiagnostics();
    }

    return diagnostics;
  }

  /// Invalidate cache and process pending WebSocket data when switching to WebSocket mode
  Future<void> _invalidateCacheAndProcessPending() async {
    try {
      AppLogger.info('🧹 Invalidating cache and processing pending WebSocket data', tag: 'WS_MODE_MANAGER');

      if (_fireAlarmData != null) {
        // Force cache invalidation in FireAlarmData
        await _fireAlarmData.invalidateZoneCache();

        // Process any pending WebSocket data with force processing
        if (_fireAlarmData.pendingWebSocketData.isNotEmpty) {
          AppLogger.info('📦 Processing ${_fireAlarmData.pendingWebSocketData.length} pending WebSocket data items', tag: 'WS_MODE_MANAGER');

          // Process pending data in reverse order (oldest first)
          final pendingData = List<String>.from(_fireAlarmData.pendingWebSocketData.reversed);
          _fireAlarmData.clearPendingWebSocketData();

          for (final data in pendingData) {
            try {
              await _fireAlarmData.processWebSocketData(data, forceProcess: true);
              AppLogger.debug('✅ Processed pending WebSocket data: ${data.substring(0, data.length > 50 ? 50 : data.length)}...', tag: 'WS_MODE_MANAGER');
            } catch (e) {
              AppLogger.warning('⚠️ Error processing pending WebSocket data: $e', tag: 'WS_MODE_MANAGER');
            }
          }
        }

        // Force UI update
        _fireAlarmData.notifyListeners();
      }

      AppLogger.info('✅ Cache invalidation and pending data processing completed', tag: 'WS_MODE_MANAGER');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Error during cache invalidation', tag: 'WS_MODE_MANAGER', error: e, stackTrace: stackTrace);
    }
  }

  /// Dispose resources
  @override
  void dispose() {
    AppLogger.info('Disposing WebSocket mode manager', tag: 'WS_MODE_MANAGER');

    _webSocketManager?.removeListener(_onWebSocketStatusChanged);
    _webSocketManager?.dispose();

    super.dispose();
  }
}