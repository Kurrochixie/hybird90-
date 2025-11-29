import 'package:flutter/material.dart';
import 'dart:async';
import 'websocket_service.dart';
import 'logger.dart';
import 'ip_configuration_service.dart';
import '../core/fire_alarm_data.dart';

/// WebSocket Manager untuk FireAlarmData
/// Menangani koneksi WebSocket ke ESP32 tanpa mengubah FireAlarmData class
class FireAlarmWebSocketManager extends ChangeNotifier {
  final FireAlarmData _fireAlarmData;
  final WebSocketService _webSocketService = WebSocketService();
  StreamSubscription<WebSocketMessage>? _messageSubscription;
  StreamSubscription<WebSocketStatus>? _statusSubscription;

  FireAlarmWebSocketManager(this._fireAlarmData);

  // Getters
  bool get isConnected => _webSocketService.isConnected;
  bool get isConnecting => _webSocketService.isConnecting;
  String get currentURL => _webSocketService.currentURL;
  int get reconnectAttempts => _webSocketService.reconnectAttempts;
  WebSocketErrorType? get lastErrorType => _webSocketService.lastErrorType;
  WebSocketService get webSocketService => _webSocketService;

  /// Connect ke ESP32 via WebSocket dengan IP Configuration Service
  Future<bool> connectToESP32(String? esp32IP) async {
    try {
      // Gunakan IP yang diberikan atau ambil dari konfigurasi tersimpan
      final targetIP = esp32IP ?? await IPConfigurationService.getESP32IP();

      AppLogger.info('Connecting to ESP32 via WebSocket: $targetIP', tag: 'FIRE_ALARM_WS');

      // Test konektivitas terlebih dahulu
      final connectivityTest = await IPConfigurationService.testConnectivity(targetIP);
      if (!connectivityTest) {
        AppLogger.warning('Connectivity test failed for $targetIP', tag: 'FIRE_ALARM_WS');
        // Continue dengan connection attempt meskipun test gagal
      }

      // Generate WebSocket URL menggunakan IPConfigurationService
      final url = IPConfigurationService.getWebSocketURLWithIP(targetIP);

      // Connect ke WebSocket
      final success = await _webSocketService.connect(url, autoReconnect: true);

      if (success) {
        // Setup listeners setelah berhasil connect
        _setupWebSocketListeners();

        // Save last successful connection
        await IPConfigurationService.saveLastConnectedIP(targetIP);

        AppLogger.info('WebSocket connected successfully to $targetIP', tag: 'FIRE_ALARM_WS');
        notifyListeners();
      } else {
        AppLogger.error('Failed to connect WebSocket to $targetIP', tag: 'FIRE_ALARM_WS');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error connecting to ESP32',
        tag: 'FIRE_ALARM_WS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Connect ke ESP32 menggunakan konfigurasi tersimpan
  Future<bool> connectToESP32WithSavedConfig() async {
    return await connectToESP32(null); // null akan gunakan saved config
  }

  /// Update dan connect dengan IP baru
  Future<bool> updateAndConnect(String newIP) async {
    // Validasi IP terlebih dahulu
    if (!_isValidIP(newIP)) {
      AppLogger.error('Invalid IP format: $newIP', tag: 'FIRE_ALARM_WS');
      return false;
    }

    // Disconnect dulu jika sudah connected
    if (isConnected) {
      await disconnectFromESP32();
    }

    // Save IP baru
    final saveSuccess = await IPConfigurationService.saveESP32IP(newIP);
    if (!saveSuccess) {
      AppLogger.warning('Failed to save new IP: $newIP', tag: 'FIRE_ALARM_WS');
      // Continue dengan connection attempt meskipun save gagal
    }

    // Connect dengan IP baru
    return await connectToESP32(newIP);
  }

  /// Disconnect dari ESP32 WebSocket
  Future<void> disconnectFromESP32() async {
    try {
      AppLogger.info('Disconnecting from ESP32 WebSocket', tag: 'FIRE_ALARM_WS');

      // Cancel subscriptions
      await _messageSubscription?.cancel();
      _messageSubscription = null;
      await _statusSubscription?.cancel();
      _statusSubscription = null;

      // Disconnect WebSocket service
      await _webSocketService.disconnect();

      AppLogger.info('WebSocket disconnected successfully', tag: 'FIRE_ALARM_WS');
      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error disconnecting from ESP32',
        tag: 'FIRE_ALARM_WS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Setup WebSocket message listeners
  void _setupWebSocketListeners() {
    // Cancel existing subscriptions
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();

    // Listen untuk status changes
    _statusSubscription = _webSocketService.statusStream.listen((status) {
      AppLogger.debug('WebSocket status: $status', tag: 'FIRE_ALARM_WS');
      notifyListeners();
    });

    // Listen untuk incoming messages
    _messageSubscription = _webSocketService.messageStream.listen((message) {
      _handleWebSocketMessage(message);
    });
  }

  /// Handle incoming WebSocket message dari ESP32 (simplified - no async complexity)
  void _handleWebSocketMessage(WebSocketMessage message) {
    try {
      AppLogger.debug('WebSocket message received: ${message.data}', tag: 'FIRE_ALARM_WS');

      // Parse data dari ESP32 (synchronous)
      final esp32Data = _parseESP32Data(message.data);

      if (esp32Data != null) {
        // Update FireAlarmData dengan parsed data (async handled by FireAlarmData)
        _updateFireAlarmData(esp32Data);
      }

    } catch (e, stackTrace) {
      AppLogger.error(
        'Error handling WebSocket message',
        tag: 'FIRE_ALARM_WS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Parse data dari ESP32 with message type filtering (synchronous)
  Map<String, dynamic>? _parseESP32Data(dynamic data) {
    try {
      // Handle different data formats from ESP32
      if (data is Map<String, dynamic>) {
        return _parseJSONData(data);
      } else if (data is String) {
        return _parseStringData(data);
      }

      AppLogger.warning('Unknown ESP32 data format: ${data.runtimeType}', tag: 'FIRE_ALARM_WS');
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Error parsing ESP32 data', tag: 'FIRE_ALARM_WS', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse JSON data from ESP32 - FIXED: No more duplicate parsing
  Map<String, dynamic>? _parseJSONData(Map<String, dynamic> jsonData) {
    try {
      // 🔥 FILTER OUT SYSTEM STATUS MESSAGES
      if (jsonData.containsKey('messageType')) {
        final messageType = jsonData['messageType'] as String?;
        if (messageType == 'systemStatus' ||
            messageType == 'connectionStatus' ||
            messageType == 'acknowledgment') {
          AppLogger.info('Filtering system message: type=$messageType', tag: 'FIRE_ALARM_WS');
          return null;
        }
      }

      final type = jsonData['type'] as String? ?? 'unknown';
      final command = jsonData['command'] as String?;

      // 🔥 FILTER OUT CONTROL COMMAND TYPES
      if (_isNonZoneMessageType(type, command)) {
        AppLogger.info('Filtering non-zone message: type=$type, command=$command', tag: 'FIRE_ALARM_WS');
        return null;
      }

      // 🔥 CRITICAL FIX: Look for actual zone data in the 'data' field
      final dataField = jsonData['data'] as String?;
      if (dataField != null) {
        AppLogger.info('🔥 Found data field: "${dataField.substring(0, dataField.length > 100 ? 100 : dataField.length)}..."', tag: 'FIRE_ALARM_WS');

        // ✅ FIXED: Extract raw data and let FireAlarmData handle the parsing
        // This avoids duplicate parsing conflict
        AppLogger.info('✅ Zone data extracted, will be processed by FireAlarmData.processWebSocketData()', tag: 'FIRE_ALARM_WS');

        return {
          'raw': dataField,
          'format': 'hex',
          'source': 'websocket_json',
          'dataField': dataField, // Keep original for FireAlarmData processing
        };
      }

      // Fallback: Check for other zone data indicators
      final hasZoneData = jsonData.containsKey('raw') ||
                         jsonData.containsKey('zones') ||
                         jsonData.containsKey('address') && jsonData.containsKey('trouble');

      if (!hasZoneData) {
        AppLogger.info('JSON message lacks zone data indicators, filtering out', tag: 'FIRE_ALARM_WS');
        return null;
      }

      AppLogger.info('Zone data detected in JSON message (legacy format), processing...', tag: 'FIRE_ALARM_WS');
      return jsonData;

    } catch (e, stackTrace) {
      AppLogger.error('❌ Error parsing JSON data', tag: 'FIRE_ALARM_WS', error: e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Parse string data from ESP32
  Map<String, dynamic>? _parseStringData(String stringData) {
    // 🔥 FILTER OUT CONTROL COMMANDS
    if (_isControlCommand(stringData)) {
      AppLogger.info('Filtering control command: $stringData', tag: 'FIRE_ALARM_WS');
      return null;
    }

    // 🔥 FILTER OUT SHORT MESSAGES (likely status/control)
    if (stringData.length < 4) {
      AppLogger.info('Filtering short message (${stringData.length} chars): $stringData', tag: 'FIRE_ALARM_WS');
      return null;
    }

    // Check if this looks like zone data (hex patterns, STX/ETX, etc.)
    final looksLikeZoneData = _looksLikeZoneData(stringData);

    if (!looksLikeZoneData) {
      AppLogger.info('String message doesn\'t match zone data patterns, filtering out', tag: 'FIRE_ALARM_WS');
      return null;
    }

    AppLogger.info('Zone data detected in string message, processing...', tag: 'FIRE_ALARM_WS');
    return {
      'raw': stringData,
      'format': 'hex',
      'source': 'websocket_string',
    };
  }

  /// Check if message type is non-zone data
  bool _isNonZoneMessageType(String type, String? command) {
    final nonZoneTypes = {
      'esp_command',
      'control_signal',
      'bell_confirmation',
      'system_status',
      'connection_status',
      'acknowledgment',
    };

    final controlCommands = {'r', 'd', 's', 'a'};

    return nonZoneTypes.contains(type) ||
           (command != null && controlCommands.contains(command.toLowerCase()));
  }

  /// Check if string is a control command
  bool _isControlCommand(String data) {
    final controlCommands = {'r', 'd', 's', 'a', 'reset', 'drill', 'silence', 'acknowledge'};
    final cleanData = data.toLowerCase().trim();

    return controlCommands.contains(cleanData) ||
           cleanData.startsWith('cmd:') ||
           cleanData.startsWith('ctrl:');
  }

  /// Check if string looks like zone data (FIXED - very lenient like reference system)
  bool _looksLikeZoneData(String data) {
    // 🔥 CRITICAL FIX: Make this very forgiving like the reference system
    // The reference system likely accepts most data and tries to parse it

    // Check for STX/ETX markers (strong indicators of zone data)
    final hasStxEtx = data.contains('<STX>') || data.contains('<ETX>') ||
                      data.contains(String.fromCharCode(0x02)) ||
                      data.contains(String.fromCharCode(0x03));

    // Check for user's specific data pattern: "41DF <STX>012300..."
    final hasUserPattern = RegExp(r'[0-9A-Fa-f]{4}\s*<STX>\d{6}').hasMatch(data);

    // Check for zone module patterns (01 23 45, 01ABCD, etc.)
    final hasZoneModules = RegExp(r'\b(0[1-9]|[1-5][0-9]|6[0-3])\s*[0-9A-Fa-f]{4}\b').hasMatch(data);

    // Check for hex patterns (zone data typically uses hex)
    final hexPattern = RegExp(r'[0-9A-Fa-f]{4,}');

    // Check for reasonable length (zone data is typically longer)
    final hasReasonableLength = data.length >= 8; // Reduced threshold

    // ✅ CRITICAL FIX: Very flexible matching - accept if ANY pattern matches
    // This is the key difference from reference system
    if (hasStxEtx) {
      
      return true;
    }

    if (hasUserPattern) {
      
      return true;
    }

    if (hasZoneModules) {
      
      return true;
    }

    if (hexPattern.hasMatch(data) && hasReasonableLength) {
      
      return true;
    }

    // 🚨 LAST RESORT: If data is long and has any hex-like content, accept it
    if (data.length >= 20 && RegExp(r'[0-9A-Fa-f]').hasMatch(data)) {
      
      return true;
    }

    
    return false;
  }

  /// Update FireAlarmData dengan data dari ESP32
  Future<void> _updateFireAlarmData(Map<String, dynamic> esp32Data) async {
    try {
      AppLogger.info('ESP32 Data received: ${esp32Data.toString()}', tag: 'FIRE_ALARM_WS');

      // Extract raw data for processing
      final rawData = esp32Data['raw'] as String? ?? '';
      final format = esp32Data['format'] as String? ?? 'unknown';

      if (rawData.isNotEmpty) {
        AppLogger.info('Processing WebSocket data: format=$format, raw=$rawData', tag: 'FIRE_ALARM_WS');

        // 🔥 INTEGRATE: Use FireAlarmData's WebSocket processing
        await _fireAlarmData.processWebSocketData(rawData);

        AppLogger.info('WebSocket data processed successfully', tag: 'FIRE_ALARM_WS');
      }

      // Notify WebSocket manager listeners
      notifyListeners();

    } catch (e, stackTrace) {
      AppLogger.error('Error updating FireAlarm data from WebSocket', tag: 'FIRE_ALARM_WS', error: e, stackTrace: stackTrace);
    }
  }

  
  /// Get WebSocket connection diagnostics
  Map<String, dynamic> getDiagnostics() {
    final diagnostics = _webSocketService.getDiagnostics();
    diagnostics['manager'] = {
      'hasFireAlarmData': true, // FireAlarmData exists if manager is created
      'hasMessageSubscription': _messageSubscription != null,
      'hasStatusSubscription': _statusSubscription != null,
    };
    return diagnostics;
  }

  /// Reset WebSocket connection state
  void resetConnection() {
    _webSocketService.resetConnectionState();
    notifyListeners();
  }

  /// Send data ke ESP32 via WebSocket
  Future<bool> sendToESP32(Map<String, dynamic> data) async {
    try {
      return await _webSocketService.sendJSON(data);
    } catch (e, stackTrace) {
      AppLogger.error('Error sending data to ESP32', tag: 'FIRE_ALARM_WS', error: e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get recent WebSocket messages for debugging
  List<Map<String, dynamic>> getRecentMessages() {
    // This would be implemented with a message history buffer
    return [];
  }

  /// Validate IPv4 address format
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

  @override
  void dispose() {
    AppLogger.info('Disposing FireAlarmWebSocketManager', tag: 'FIRE_ALARM_WS');

    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _webSocketService.dispose();

    super.dispose();
  }
}