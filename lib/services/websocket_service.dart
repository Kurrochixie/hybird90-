import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/logger.dart';

/// WebSocket service untuk ESP32 Direct connection
/// Enhanced version dengan proper logging menggunakan AppLogger
class WebSocketService {
  static const String _tag = 'WEBSOCKET_SERVICE';
  WebSocketChannel? _channel;
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _shouldReconnect = true;
  String _currentURL = '';
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _baseReconnectDelay = Duration(seconds: 2);
  static const Duration _maxReconnectDelay = Duration(seconds: 30);
  static const Duration _connectionTimeout = Duration(seconds: 10);

  Timer? _reconnectTimer;
  Timer? _connectionTimeoutTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  DateTime? _lastConnectionAttempt;
  WebSocketErrorType? _lastErrorType;

  // Stream controllers untuk events
  final StreamController<WebSocketMessage> _messageController =
      StreamController<WebSocketMessage>.broadcast();
  final StreamController<WebSocketStatus> _statusController =
      StreamController<WebSocketStatus>.broadcast();

  // Public streams
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  Stream<WebSocketStatus> get statusStream => _statusController.stream;

  // Getters
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get shouldReconnect => _shouldReconnect;
  String get currentURL => _currentURL;
  int get reconnectAttempts => _reconnectAttempts;
  WebSocketErrorType? get lastErrorType => _lastErrorType;
  DateTime? get lastConnectionAttempt => _lastConnectionAttempt;
  Duration get timeSinceLastAttempt => _lastConnectionAttempt != null
      ? DateTime.now().difference(_lastConnectionAttempt!)
      : Duration.zero;

  /// Connect ke WebSocket server dengan enhanced error handling
  Future<bool> connect(String url, {bool autoReconnect = true}) async {
    if (_isConnected) {
      AppLogger.info('Already connected to WebSocket', tag: _tag);
      return true;
    }

    if (_isConnecting) {
      AppLogger.warning('Connection already in progress', tag: _tag);
      return false;
    }

    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    _connectionTimeoutTimer?.cancel();

    try {
      _isConnecting = true;
      _currentURL = url;
      _shouldReconnect = autoReconnect;
      _lastConnectionAttempt = DateTime.now();
      _lastErrorType = null;

      AppLogger.info('Connecting to WebSocket: $url (attempt #${_reconnectAttempts + 1})', tag: _tag);
      _emitStatus(WebSocketStatus.connecting);

      // Validate URL format
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('ws') && !uri.scheme.startsWith('wss'))) {
        throw WebSocketException('Invalid WebSocket URL scheme: ${uri.scheme}');
      }

      // Create WebSocket connection with authentication
      // Prepare authentication info to send after connection
      final apiKey = dotenv.env['WEBSOCKET_API_KEY'];
      final hasApiKey = apiKey != null && apiKey.isNotEmpty && apiKey != 'your_websocket_api_key_here';

      if (hasApiKey) {
        AppLogger.info('🔐 WebSocket API key authentication prepared', tag: _tag);
      } else {
        AppLogger.warning('⚠️ WebSocket API key not configured - using insecure connection', tag: _tag);
      }

      // Generate authentication token
      final authToken = _generateAuthToken();

      _channel = WebSocketChannel.connect(
        uri,
        protocols: ['ESP32-FireAlarm'],
      );

      // Send authentication message immediately after connection
      if (hasApiKey || authToken.isNotEmpty) {
        Future.delayed(Duration(milliseconds: 100), () {
          if (_isConnected || _isConnecting) {
            _sendAuthenticationMessage(apiKey, authToken);
          }
        });
      }

      // Setup connection timeout
      _connectionTimeoutTimer = Timer(_connectionTimeout, () {
        if (_isConnecting) {
          AppLogger.warning('Connection timeout after ${_connectionTimeout.inSeconds}s', tag: _tag);
          _handleConnectionTimeout();
        }
      });

      // Setup listeners with enhanced error handling
      _channel!.stream.listen(
        (data) {
          _connectionTimeoutTimer?.cancel();
          if (!_isConnected && _isConnecting) {
            _handleConnectionSuccess();
          }
          _handleMessage(data);
        },
        onError: (error) {
          _connectionTimeoutTimer?.cancel();
          AppLogger.error('WebSocket stream error', tag: _tag, error: error);
          _handleConnectionError(error);
        },
        onDone: () {
          _connectionTimeoutTimer?.cancel();
          AppLogger.info('WebSocket stream closed', tag: _tag);
          _handleConnectionClosed();
        },
        cancelOnError: false,
      );

      // Monitor connectivity changes
      _setupConnectivityMonitoring();

      return true;

    } catch (e, stackTrace) {
      _isConnecting = false;
      _lastErrorType = _classifyError(e);

      AppLogger.error(
        'Failed to connect to WebSocket',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );

      _emitStatus(WebSocketStatus.error);

      // Schedule reconnect if enabled
      if (_shouldReconnect) {
        _scheduleReconnect();
      }

      return false;
    }
  }

  /// Disconnect dari WebSocket dengan cleanup
  Future<void> disconnect() async {
    try {
      _shouldReconnect = false;
      _isConnecting = false;
      _reconnectAttempts = 0;

      // Cancel all timers and subscriptions
      _reconnectTimer?.cancel();
      _connectionTimeoutTimer?.cancel();
      _connectivitySubscription?.cancel();

      if (_channel != null) {
        AppLogger.info('Disconnecting from WebSocket', tag: _tag);
        await _channel!.sink.close();
        _channel = null;
      }

      _isConnected = false;
      _currentURL = '';
      _lastErrorType = null;

      AppLogger.info('WebSocket disconnected', tag: _tag);
      _emitStatus(WebSocketStatus.disconnected);

    } catch (e, stackTrace) {
      AppLogger.error(
        'Error disconnecting WebSocket',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send message ke WebSocket
  Future<bool> sendMessage(String message) async {
    if (!_isConnected || _channel == null) {
      AppLogger.warning('Cannot send message - not connected', tag: _tag);
      return false;
    }

    try {
      _channel!.sink.add(message);
      AppLogger.debug('Message sent: $message', tag: _tag);
      return true;

    } catch (e, stackTrace) {
      AppLogger.error(
        'Error sending message',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Send data dalam format JSON
  Future<bool> sendJSON(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      return await sendMessage(jsonString);

    } catch (e, stackTrace) {
      AppLogger.error(
        'Error encoding JSON',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Enhanced reconnect dengan exponential backoff dan jitter
  Future<bool> _scheduleReconnect() async {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      if (_reconnectAttempts >= _maxReconnectAttempts) {
        AppLogger.warning(
          'Max reconnect attempts ($_maxReconnectAttempts) reached. Stopping reconnection.',
          tag: _tag,
        );
        _emitStatus(WebSocketStatus.error);
      }
      return false;
    }

    _reconnectAttempts++;

    // Calculate exponential backoff with jitter
    final baseDelay = _baseReconnectDelay.inMilliseconds;
    final exponentialDelay = baseDelay * (1 << (_reconnectAttempts - 1)); // 2^(attempts-1)
    final maxDelay = _maxReconnectDelay.inMilliseconds;
    final delay = Duration(milliseconds: (exponentialDelay.clamp(baseDelay, maxDelay)));

    // Add jitter (±25% randomization) to prevent thundering herd
    final jitter = Duration(milliseconds: (delay.inMilliseconds * 0.25 * (DateTime.now().millisecond % 100 / 100)).round());
    final finalDelay = delay + jitter;

    AppLogger.info(
      'Scheduling reconnect #$_reconnectAttempts in ${finalDelay.inSeconds}.${finalDelay.inMilliseconds % 1000}s (base: ${delay.inSeconds}s, jitter: ${jitter.inMilliseconds}ms)',
      tag: _tag,
    );

    _reconnectTimer = Timer(finalDelay, () async {
      if (_shouldReconnect && !_isConnected && !_isConnecting) {
        AppLogger.info('Attempting reconnect #$_reconnectAttempts', tag: _tag);
        await connect(_currentURL);
      }
    });

    return true;
  }

  /// Handle successful connection
  void _handleConnectionSuccess() {
    _isConnecting = false;
    _isConnected = true;
    _reconnectAttempts = 0;
    _lastErrorType = null;

    AppLogger.info('WebSocket connected successfully to $_currentURL', tag: _tag);
    _emitStatus(WebSocketStatus.connected);
  }

  /// Handle connection timeout
  void _handleConnectionTimeout() {
    _isConnecting = false;
    _lastErrorType = WebSocketErrorType.timeout;

    AppLogger.warning('Connection timeout to $_currentURL', tag: _tag);
    _emitStatus(WebSocketStatus.error);

    // Close the channel if it exists
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // Schedule reconnect if enabled
    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  /// Classify error type untuk better handling
  WebSocketErrorType _classifyError(dynamic error) {
    if (error is WebSocketException) {
      if (error.message.contains('Connection refused') || error.message.contains('ECONNREFUSED')) {
        return WebSocketErrorType.connectionRefused;
      } else if (error.message.contains('timeout') || error.message.contains('TIMEOUT')) {
        return WebSocketErrorType.timeout;
      } else if (error.message.contains('certificate') || error.message.contains('SSL') || error.message.contains('TLS')) {
        return WebSocketErrorType.certificate;
      } else if (error.message.contains('network') || error.message.contains('Network is unreachable')) {
        return WebSocketErrorType.network;
      }
    } else if (error is SocketException) {
      if (error.message.contains('Connection refused')) {
        return WebSocketErrorType.connectionRefused;
      } else if (error.message.contains('Network is unreachable') || error.message.contains('Host is unresolved')) {
        return WebSocketErrorType.network;
      }
    } else if (error is TimeoutException) {
      return WebSocketErrorType.timeout;
    } else if (error.toString().contains('certificate') || error.toString().contains('SSL')) {
      return WebSocketErrorType.certificate;
    }

    return WebSocketErrorType.unknown;
  }

  /// Setup connectivity monitoring
  void _setupConnectivityMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      AppLogger.debug('Connectivity changed to $result', tag: _tag);

      if (result != ConnectivityResult.none && !_isConnected && !_isConnecting && _shouldReconnect) {
        AppLogger.info('Network restored, attempting reconnection', tag: _tag);
        _reconnectAttempts = 0; // Reset attempts on network restore
        _scheduleReconnect();
      }
    });
  }

  /// Handle incoming message
  void _handleMessage(dynamic data) {
    try {
      String message = data.toString();
      AppLogger.debug('Message received: $message', tag: _tag);

      // Emit message event
      _messageController.add(WebSocketMessage(
        type: WebSocketMessageType.data,
        data: message,
        timestamp: DateTime.now(),
      ));

    } catch (e, stackTrace) {
      AppLogger.error(
        'Error handling message',
        tag: _tag,
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Handle connection error dengan improved logic
  void _handleConnectionError(dynamic error) {
    _isConnected = false;
    _isConnecting = false;
    _lastErrorType = _classifyError(error);

    AppLogger.error(
      'Connection error',
      tag: _tag,
      error: error,
    );
    _emitStatus(WebSocketStatus.error);

    // Close channel properly
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // Schedule reconnect if enabled and appropriate
    if (_shouldReconnect && _lastErrorType != WebSocketErrorType.certificate) {
      _scheduleReconnect();
    } else if (_lastErrorType == WebSocketErrorType.certificate) {
      AppLogger.warning(
        'Certificate error detected - manual intervention may be required',
        tag: _tag,
      );
    }
  }

  /// Handle connection closed dengan smart reconnect logic
  void _handleConnectionClosed() {
    final wasConnected = _isConnected;
    _isConnected = false;
    _isConnecting = false;

    AppLogger.debug(
      'Connection closed (was connected: $wasConnected, should reconnect: $_shouldReconnect)',
      tag: _tag,
    );
    _emitStatus(WebSocketStatus.disconnected);

    // Close channel properly
    if (_channel != null) {
      _channel!.sink.close();
      _channel = null;
    }

    // Only reconnect if:
    // 1. We should reconnect AND
    // 2. The connection was established before (not a connection failure) AND
    // 3. We have a valid URL
    if (_shouldReconnect && wasConnected && _currentURL.isNotEmpty) {
      AppLogger.info('Unexpected disconnection, scheduling reconnect', tag: _tag);
      _scheduleReconnect();
    } else if (!wasConnected) {
      AppLogger.warning('Connection failed during initial connect', tag: _tag);
    }
  }

  /// Emit status change
  void _emitStatus(WebSocketStatus status) {
    _statusController.add(status);
  }

  /// Generate authentication token for WebSocket connection
  /// Creates a timestamp-based token with device signature
  String _generateAuthToken() {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final deviceId = Platform.isAndroid ? 'android' : 'windows';
      final signature = 'firealarm_${deviceId}_$timestamp';

      // Simple hash (in production, use proper crypto)
      final tokenBytes = signature.codeUnits;
      final hash = tokenBytes.fold<int>(0, (sum, byte) => sum + byte);

      return 'FA_${timestamp}_$hash';
    } catch (e) {
      AppLogger.error('Error generating auth token', tag: _tag, error: e);
      return '';
    }
  }

  /// Send authentication message to ESP32
  void _sendAuthenticationMessage(String? apiKey, String authToken) {
    try {
      final authMessage = <String, dynamic>{
        'type': 'auth',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'token': authToken,
      };

      // Add API key if available
      if (apiKey != null && apiKey.isNotEmpty) {
        authMessage['api_key'] = apiKey;
      }

      final authJson = jsonEncode(authMessage);
      _channel?.sink.add(authJson);

      AppLogger.info('🔐 Authentication message sent', tag: _tag);
      AppLogger.debug('Auth message: $authJson', tag: _tag);
    } catch (e) {
      AppLogger.error('Error sending authentication message', tag: _tag, error: e);
    }
  }

  /// Dispose resources dengan comprehensive cleanup
  void dispose() {
    AppLogger.info('Disposing WebSocket service', tag: _tag);
    disconnect();
    _messageController.close();
    _statusController.close();
    _connectivitySubscription?.cancel();
  }

  /// Get connection diagnostics info
  Map<String, dynamic> getDiagnostics() {
    return {
      'isConnected': _isConnected,
      'isConnecting': _isConnecting,
      'shouldReconnect': _shouldReconnect,
      'currentURL': _currentURL,
      'reconnectAttempts': _reconnectAttempts,
      'maxReconnectAttempts': _maxReconnectAttempts,
      'lastErrorType': _lastErrorType?.toString(),
      'lastConnectionAttempt': _lastConnectionAttempt?.toIso8601String(),
      'timeSinceLastAttempt': timeSinceLastAttempt.inMilliseconds,
      'timeSinceLastAttemptFormatted': '${timeSinceLastAttempt.inSeconds}.${timeSinceLastAttempt.inMilliseconds % 1000}s',
    };
  }

  /// Reset connection state untuk manual retry
  void resetConnectionState() {
    AppLogger.info('Resetting connection state', tag: _tag);
    _reconnectAttempts = 0;
    _lastErrorType = null;
    _lastConnectionAttempt = null;
    _reconnectTimer?.cancel();
    _connectionTimeoutTimer?.cancel();
  }
}

/// WebSocket message data model
class WebSocketMessage {
  final WebSocketMessageType type;
  final String data;
  final DateTime timestamp;

  WebSocketMessage({
    required this.type,
    required this.data,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'WebSocketMessage{type: $type, data: $data, timestamp: $timestamp}';
  }
}

/// WebSocket message types
enum WebSocketMessageType {
  data,
  error,
  status,
}

/// WebSocket connection status
enum WebSocketStatus {
  disconnected,
  connecting,
  connected,
  error,
  reconnecting,
}

/// WebSocket error types untuk better error classification
enum WebSocketErrorType {
  none,
  timeout,
  connectionRefused,
  network,
  certificate,
  unknown,
}