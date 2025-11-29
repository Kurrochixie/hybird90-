import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../core/fire_alarm_data.dart';
import '../services/websocket_service.dart';
import '../services/fire_alarm_websocket_manager.dart';
import '../services/ip_configuration_service.dart';
import '../services/logger.dart';

/// Model for WebSocket debug message
class WebSocketDebugMessage {
  final DateTime timestamp;
  final String type; // 'received' or 'sent'
  final String data;
  final String? error;

  WebSocketDebugMessage({
    required this.timestamp,
    required this.type,
    required this.data,
    this.error,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'type': type,
      'data': data,
      'error': error,
    };
  }

  factory WebSocketDebugMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketDebugMessage(
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
      data: json['data'],
      error: json['error'],
    );
  }
}

/// Model for connection statistics
class ConnectionStatistics {
  final int messagesReceived;
  final int messagesSent;
  final int errorsCount;
  final int reconnectAttempts;
  final DateTime? connectedAt;
  final Duration uptime;

  ConnectionStatistics({
    required this.messagesReceived,
    required this.messagesSent,
    required this.errorsCount,
    required this.reconnectAttempts,
    this.connectedAt,
    required this.uptime,
  });
}

/// WebSocket Debug Controller for state management
class WebSocketDebugController extends ChangeNotifier {
  final List<WebSocketDebugMessage> _messages = [];
  final List<WebSocketDebugMessage> _sentMessages = [];
  bool _autoScroll = true;
  bool _showTimestamps = true;
  bool _showRawData = true;
  bool _showParsedData = true;
  String _messageFilter = '';
  int _maxMessages = 1000;

  List<WebSocketDebugMessage> get messages => _messages;
  List<WebSocketDebugMessage> get sentMessages => _sentMessages;
  bool get autoScroll => _autoScroll;
  bool get showTimestamps => _showTimestamps;
  bool get showRawData => _showRawData;
  bool get showParsedData => _showParsedData;
  String get messageFilter => _messageFilter;
  int get maxMessages => _maxMessages;

  List<WebSocketDebugMessage> get filteredMessages {
    if (_messageFilter.isEmpty) return _messages;
    return _messages.where((msg) =>
      msg.data.toLowerCase().contains(_messageFilter.toLowerCase()) ||
      msg.type.toLowerCase().contains(_messageFilter.toLowerCase())
    ).toList();
  }

  void addMessage(WebSocketDebugMessage message) {
    _messages.add(message);

    // Limit message history
    if (_messages.length > _maxMessages) {
      _messages.removeAt(0);
    }

    if (_autoScroll) {
      // Auto-scroll will be handled by the UI
      notifyListeners();
    } else {
      notifyListeners();
    }
  }

  void addSentMessage(WebSocketDebugMessage message) {
    _sentMessages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _sentMessages.clear();
    notifyListeners();
  }

  void toggleAutoScroll() {
    _autoScroll = !_autoScroll;
    notifyListeners();
  }

  void setAutoScroll(bool value) {
    _autoScroll = value;
    notifyListeners();
  }

  void toggleTimestamps() {
    _showTimestamps = !_showTimestamps;
    notifyListeners();
  }

  void setShowTimestamps(bool value) {
    _showTimestamps = value;
    notifyListeners();
  }

  void toggleRawData() {
    _showRawData = !_showRawData;
    notifyListeners();
  }

  void setShowRawData(bool value) {
    _showRawData = value;
    notifyListeners();
  }

  void setMessageFilter(String filter) {
    _messageFilter = filter;
    notifyListeners();
  }

  void setMaxMessages(int max) {
    _maxMessages = max;
    notifyListeners();
  }

  void toggleParsedData() {
    _showParsedData = !_showParsedData;
    notifyListeners();
  }

  void setShowParsedData(bool value) {
    _showParsedData = value;
    notifyListeners();
  }

  Future<void> exportMessages() async {
    try {
      final allMessages = [..._messages, ..._sentMessages];
      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'total_messages': allMessages.length,
        'messages': allMessages.map((m) => m.toJson()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      await Share.share(
        jsonString,
        subject: 'WebSocket Debug Export - ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error exporting messages',
        tag: 'WEBSOCKET_DEBUG',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}

/// WebSocket Debug Page
class WebSocketDebugPage extends StatefulWidget {
  const WebSocketDebugPage({super.key});

  @override
  State<WebSocketDebugPage> createState() => _WebSocketDebugPageState();
}

class _WebSocketDebugPageState extends State<WebSocketDebugPage> {
  late WebSocketDebugController _debugController;
  late FireAlarmData _fireAlarmData;
  late FireAlarmWebSocketManager _webSocketManager;
  StreamSubscription? _messageSubscription;
  StreamSubscription? _statusSubscription;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  final TextEditingController _ipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _debugController = WebSocketDebugController();
    _fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);
    _webSocketManager = FireAlarmWebSocketManager(_fireAlarmData);

    // Initialize IP from IPConfigurationService
    _initializeIP();

    _setupWebSocketListeners();
    _loadSavedPreferences();
  }

  /// Initialize IP controller with saved configuration
  Future<void> _initializeIP() async {
    try {
      final savedIP = await IPConfigurationService.getESP32IP();
      _ipController.text = savedIP;
      AppLogger.info('Initialized debug page with IP: $savedIP', tag: 'WS_DEBUG');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error initializing IP in debug page',
        tag: 'WS_DEBUG',
        error: e,
        stackTrace: stackTrace,
      );
      _ipController.text = IPConfigurationService.defaultIP;
    }
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusSubscription?.cancel();
    _webSocketManager.dispose();
    _messageController.dispose();
    _messageScrollController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  void _setupWebSocketListeners() {
    // Listen to WebSocket messages
    _messageSubscription = _webSocketManager.webSocketService.messageStream.listen(
      (message) {
        final debugMessage = WebSocketDebugMessage(
          timestamp: DateTime.now(),
          type: 'received',
          data: message.data,
        );
        _debugController.addMessage(debugMessage);
      },
      onError: (error) {
        final errorMessage = WebSocketDebugMessage(
          timestamp: DateTime.now(),
          type: 'error',
          data: '',
          error: error.toString(),
        );
        _debugController.addMessage(errorMessage);
      },
    );

    // Listen to WebSocket status changes
    _statusSubscription = _webSocketManager.webSocketService.statusStream.listen(
      (status) {
        final statusMessage = WebSocketDebugMessage(
          timestamp: DateTime.now(),
          type: 'status',
          data: status.name,
        );
        _debugController.addMessage(statusMessage);
      },
    );
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _debugController.setAutoScroll(prefs.getBool('ws_debug_auto_scroll') ?? true);
      _debugController.setShowTimestamps(prefs.getBool('ws_debug_show_timestamps') ?? true);
      _debugController.setShowRawData(prefs.getBool('ws_debug_show_raw_data') ?? true);
      _debugController.setShowParsedData(prefs.getBool('ws_debug_show_parsed_data') ?? true);
      _debugController.setMaxMessages(prefs.getInt('ws_debug_max_messages') ?? 1000);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error loading preferences',
        tag: 'WEBSOCKET_DEBUG',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('ws_debug_auto_scroll', _debugController.autoScroll);
      await prefs.setBool('ws_debug_show_timestamps', _debugController.showTimestamps);
      await prefs.setBool('ws_debug_show_raw_data', _debugController.showRawData);
      await prefs.setBool('ws_debug_show_parsed_data', _debugController.showParsedData);
      await prefs.setInt('ws_debug_max_messages', _debugController.maxMessages);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving preferences',
        tag: 'WEBSOCKET_DEBUG',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Send message via WebSocket
      _webSocketManager.webSocketService.sendMessage(message).then((success) {
        if (success) {
          final sentMessage = WebSocketDebugMessage(
            timestamp: DateTime.now(),
            type: 'sent',
            data: message,
          );
          _debugController.addSentMessage(sentMessage);
          _messageController.clear();
        } else {
          AppLogger.warning('Failed to send WebSocket message', tag: 'WEBSOCKET_DEBUG');
        }
      });
    }
  }

  Future<void> _scrollToBottom() async {
    if (_messageScrollController.hasClients) {
      await _messageScrollController.animateTo(
        _messageScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _debugController,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WebSocket Debug'),
          backgroundColor: Colors.red.shade700,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Messages'),
                    content: const Text('Are you sure you want to clear all messages?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          _debugController.clearMessages();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _debugController.exportMessages,
            ),
          ],
        ),
        body: Column(
          children: [
            _buildIPConfiguration(),
            _buildConnectionStatus(),
            _buildControlPanel(),
            _buildMessageFilter(),
            Expanded(child: _buildMessageList()),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildIPConfiguration() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.settings_ethernet, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'ESP32 IP Configuration',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                'From Home Page Settings',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    hintText: '192.168.0.2',
                    labelText: 'ESP32 IP Address',
                    prefixIcon: Icon(Icons.lan),
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final newIP = _ipController.text.trim();
                  if (newIP.isNotEmpty) {
                    // Save IP menggunakan IPConfigurationService
                    final saveSuccess = await IPConfigurationService.saveESP32IP(newIP);

                    // Connect dengan IP baru menggunakan FireAlarmWebSocketManager
                    final connectSuccess = await _webSocketManager.updateAndConnect(newIP);

                    if (saveSuccess && connectSuccess) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Connected successfully to $newIP'),
                            backgroundColor: Colors.green,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    } else {
                      String errorMessage = 'Connection failed';
                      if (!saveSuccess) {
                        errorMessage += ' (IP save failed)';
                      }
                      if (!connectSuccess) {
                        errorMessage += ' (connection failed)';
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorMessage),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    }
                  }
                },
                icon: const Icon(Icons.save, size: 16),
                label: const Text('SAVE & CONNECT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Consumer<FireAlarmData>(
      builder: (context, fireAlarmData, child) {
        final isConnected = _webSocketManager.isConnected;
        final isConnecting = _webSocketManager.isConnecting;
        final currentURL = _webSocketManager.currentURL;
        final reconnectAttempts = _webSocketManager.reconnectAttempts;
        final lastErrorType = _webSocketManager.lastErrorType;
        final diagnostics = _webSocketManager.getDiagnostics();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isConnected ? Colors.green.shade50 : Colors.red.shade50,
            border: Border(
              bottom: BorderSide(
                color: isConnected ? Colors.green.shade300 : Colors.red.shade300,
                width: 2,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isConnected ? Icons.wifi : Icons.wifi_off,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnecting ? 'Connecting...' : (isConnected ? 'Connected' : 'Disconnected'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isConnected ? Colors.green.shade700 : Colors.red.shade700,
                    ),
                  ),
                  if (lastErrorType != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getErrorTypeColor(lastErrorType).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getErrorTypeString(lastErrorType),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getErrorTypeColor(lastErrorType),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Connection actions
                  if (isConnected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            await _webSocketManager.disconnectFromESP32();
                            await Future.delayed(const Duration(milliseconds: 500));
                            await _webSocketManager.connectToESP32WithSavedConfig();
                          },
                          tooltip: 'Reconnect',
                        ),
                        IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () => _showDiagnosticsDialog(context, diagnostics),
                          tooltip: 'Connection Diagnostics',
                        ),
                      ],
                    ),
                  if (!isConnected)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: () => _webSocketManager.connectToESP32WithSavedConfig(),
                          tooltip: 'Connect',
                        ),
                        if (reconnectAttempts > 0)
                          IconButton(
                            icon: const Icon(Icons.stop),
                            onPressed: () async {
                              await _webSocketManager.disconnectFromESP32();
                              _webSocketManager.resetConnection();
                            },
                            tooltip: 'Stop Reconnecting',
                          ),
                        IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () => _showDiagnosticsDialog(context, diagnostics),
                          tooltip: 'Connection Diagnostics',
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'URL: $currentURL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (reconnectAttempts > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        'Reconnect attempt #$reconnectAttempts',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (diagnostics['timeSinceLastAttemptMs'] != null && diagnostics['timeSinceLastAttemptMs'] > 0)
                        Text(
                          ' (${(diagnostics['timeSinceLastAttemptMs'] / 1000).toInt()}s ago)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControlPanel() {
    return Consumer<WebSocketDebugController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Auto Scroll'),
                selected: controller.autoScroll,
                onSelected: (value) {
                  controller.toggleAutoScroll();
                  _savePreferences();
                },
              ),
              FilterChip(
                label: const Text('Timestamps'),
                selected: controller.showTimestamps,
                onSelected: (value) {
                  controller.toggleTimestamps();
                  _savePreferences();
                },
              ),
              FilterChip(
                label: const Text('Raw Data'),
                selected: controller.showRawData,
                onSelected: (value) {
                  controller.toggleRawData();
                  _savePreferences();
                },
              ),
              FilterChip(
                label: const Text('Parsed Data'),
                selected: controller.showParsedData,
                onSelected: (value) {
                  controller.toggleParsedData();
                  _savePreferences();
                },
              ),
              if (controller.autoScroll)
                IconButton(
                  icon: const Icon(Icons.arrow_downward),
                  onPressed: _scrollToBottom,
                  tooltip: 'Scroll to Bottom',
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMessageFilter() {
    return Consumer<WebSocketDebugController>(
      builder: (context, controller, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Filter messages...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: controller.setMessageFilter,
          ),
        );
      },
    );
  }

  Widget _buildMessageList() {
    return Consumer<WebSocketDebugController>(
      builder: (context, controller, child) {
        final messages = controller.filteredMessages;

        if (messages.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No messages received yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Connect to ESP32 to start receiving messages',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _messageScrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return _buildMessageItem(message);
          },
        );
      },
    );
  }

  Widget _buildMessageItem(WebSocketDebugMessage message) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (message.type) {
      case 'received':
        backgroundColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.arrow_downward;
        break;
      case 'sent':
        backgroundColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.arrow_upward;
        break;
      case 'status':
        backgroundColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.info;
        break;
      case 'error':
        backgroundColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.error;
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
        icon = Icons.message;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 8),
              Text(
                message.type.toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_debugController.showTimestamps)
                Text(
                  DateFormat('HH:mm:ss.SSS').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: message.data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Message copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copy Message',
              ),
            ],
          ),
          if (message.error != null)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Error: ${message.error}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 12,
                ),
              ),
            ),
          if (message.data.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_debugController.showRawData)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Raw Data:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            message.data,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_debugController.showParsedData && _debugController.showRawData)
                    const SizedBox(height: 8),
                  if (_debugController.showParsedData)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Parsed Data:',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          SelectableText(
                            _formatMessage(message.data),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (!_debugController.showRawData && !_debugController.showParsedData)
                    SelectableText(
                      message.data,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatMessage(String data) {
    // Try to format as JSON if possible, otherwise return as-is
    try {
      if (data.trim().startsWith('{')) {
        // Preprocess JSON data to handle control characters
        final sanitizedData = _sanitizeJsonData(data);
        final jsonData = jsonDecode(sanitizedData) as Map<String, dynamic>;

        // Extract key information for display
        final formatted = StringBuffer();

        // Add message type and main metadata
        if (jsonData.containsKey('messageType')) {
          final messageType = jsonData['messageType'];
          formatted.writeln('Message Type: $messageType');

          if (messageType == 'systemStatus') {
            formatted.writeln('⚠️ SYSTEM STATUS MESSAGE (not zone data)');
            final source = jsonData['source'];
            final data = jsonData['data'];
            if (source != null) formatted.writeln('Source: $source');
            if (data is Map) {
              formatted.writeln('Status: ${data['status'] ?? 'N/A'}');
              formatted.writeln('WiFi: ${data['wifiConnected'] == true ? 'Connected' : 'Disconnected'}');
              formatted.writeln('Heap: ${data['freeHeap'] ?? 'N/A'} bytes');
            }
            formatted.writeln('─' * 40);
            formatted.writeln('This message will NOT affect zone display');
            return formatted.toString().trim();
          }
        }

        if (jsonData.containsKey('timestamp')) {
          formatted.writeln('Timestamp: ${jsonData['timestamp']}');
        }
        if (jsonData.containsKey('clients')) {
          formatted.writeln('Clients: ${jsonData['clients']}');
        }
        if (jsonData.containsKey('freeHeap')) {
          formatted.writeln('Free Heap: ${jsonData['freeHeap']} bytes');
        }

        // Parse and display fire alarm data if present
        if (jsonData.containsKey('data')) {
          final fireAlarmData = jsonData['data'].toString();
          formatted.writeln('─' * 40);
          formatted.writeln('Raw Data: $fireAlarmData');
          formatted.writeln('─' * 40);

          // Parse zone data
          final parsedZoneData = _parseFireAlarmData(fireAlarmData);
          if (parsedZoneData.isNotEmpty) {
            formatted.writeln('Parsed Zone Data:');
            formatted.writeln(parsedZoneData);
          }
        }

        // Add any other fields
        jsonData.forEach((key, value) {
          if (!['timestamp', 'clients', 'freeHeap', 'data'].contains(key)) {
            formatted.writeln('$key: $value');
          }
        });

        return formatted.toString().trim();
      } else {
        return data;
      }
    } catch (e) {
      return 'Invalid JSON: $data\nError: $e';
    }
  }

  String _sanitizeJsonData(String jsonData) {
    try {
      // Sanitize JSON data to handle control characters and inconsistent formatting
      String sanitized = jsonData;

      // Step 1: Replace actual ASCII control characters with safe placeholders
      // This prevents JSON parsing errors from unescaped control characters
      sanitized = sanitized
          .replaceAll('\x02', '<STX>')  // Start of Text (ASCII 0x02)
          .replaceAll('\x03', '<ETX>')  // End of Text (ASCII 0x03)
          .replaceAll('\x01', '<SOH>')  // Start of Heading (ASCII 0x01)
          .replaceAll('\x04', '<EOT>')  // End of Transmission (ASCII 0x04)
          .replaceAll('\x0A', '\\n')    // Line Feed (escape for JSON)
          .replaceAll('\x0D', '\\r')    // Carriage Return (escape for JSON)
          .replaceAll('\x09', '\\t');   // Horizontal Tab (escape for JSON)

      // Step 2: Handle malformed JSON in data fields
      // Look for JSON objects and sanitize their string values
      if (sanitized.contains('"data":"')) {
        // Extract and sanitize the data field content
        sanitized = _sanitizeDataField(sanitized);
      }

      return sanitized;
    } catch (e) {
      AppLogger.warning('Error sanitizing JSON data: $e', tag: 'WEBSOCKET_DEBUG');
      return jsonData; // Return original if sanitization fails
    }
  }

  String _sanitizeDataField(String jsonData) {
    try {
      // Find and sanitize the data field content
      final dataFieldRegex = RegExp(r'"data":\s*"([^"]*(?:\\.[^"]*)*)"');
      final matches = dataFieldRegex.allMatches(jsonData);

      String sanitized = jsonData;
      for (final match in matches.toList().reversed) {
        final originalContent = match.group(1)!;

        // Sanitize the data field content
        String sanitizedContent = originalContent;

        // Replace any remaining control characters that might cause JSON issues
        sanitizedContent = sanitizedContent
            .replaceAll('\x02', '<STX>')
            .replaceAll('\x03', '<ETX>')
            .replaceAll('\x01', '<SOH>')
            .replaceAll('\x04', '<EOT>');

        // Handle malformed parts like <STST> -> <STX>
        sanitizedContent = sanitizedContent.replaceAll('<STST>', '<STX>');

        // Replace the original content with sanitized content
        final replacement = '"data":"$sanitizedContent"';
        sanitized = sanitized.replaceRange(match.start, match.end, replacement);
      }

      return sanitized;
    } catch (e) {
      AppLogger.warning('Error sanitizing data field: $e', tag: 'WEBSOCKET_DEBUG');
      return jsonData;
    }
  }

  String _parseFireAlarmData(String data) {
    try {
      // Parse fire alarm data using AABBCC format
      // AA = Address Slave, BB = Status Trouble, CC = Status Alarm + Bell

      // Normalize data by removing markers and cleaning up
      String normalizedData = data;

      // Remove any remaining markers and normalize spacing
      normalizedData = normalizedData
          .replaceAll('<STX>', ' ')
          .replaceAll('<ETX>', '')
          .replaceAll('<SOH>', ' ')
          .replaceAll('<EOT>', '')
          .replaceAll('|FB:OK', '')
          .replaceAll('|TS:', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

      // Split into parts, filtering out empty strings
      final parts = normalizedData.split(' ').where((part) => part.isNotEmpty).toList();
      if (parts.isEmpty) return 'No data to parse';

      final result = StringBuffer();

      // Parse master status (first part)
      if (parts.isNotEmpty) {
        final masterStatus = parts[0];
        result.writeln('Master Status: $masterStatus');

        if (masterStatus.length >= 4) {
          final masterHex = masterStatus.substring(0, 4);
          result.writeln('  Master HEX: 0x$masterHex');
        }
      }

      // Parse device/zone data
      for (int i = 1; i < parts.length; i++) {
        final part = parts[i];

        if (part.length == 6) {
          // AABBCC format detected
          final address = part.substring(0, 2);
          final trouble = part.substring(2, 4);
          final alarm = part.substring(4, 6);

          final addressInt = int.parse(address, radix: 16);
          final troubleInt = int.parse(trouble, radix: 16);
          final alarmInt = int.parse(alarm, radix: 16);

          result.writeln('Device ${addressInt.toString().padLeft(2, '0')} (0x$address):');
          result.writeln('  Address: $address (Slave $addressInt)');
          result.writeln('  Trouble: 0x$trouble ($troubleInt) - ${_decodeTroubleStatus(troubleInt)}');
          result.writeln('  Alarm:   0x$alarm ($alarmInt) - ${_decodeAlarmStatus(alarmInt)}');
          result.writeln('  Overall:  ${_getOverallZoneStatus(troubleInt, alarmInt)}');
          result.writeln('');
        } else if (part.length == 4 && part.startsWith('20')) {
          // Zone status format (20XX)
          final zoneStatus = int.parse(part, radix: 16);
          final zoneNumber = (zoneStatus & 0xF0) >> 4;
          final zoneValue = zoneStatus & 0x0F;

          result.writeln('  Zone ${zoneNumber.toString().padLeft(2, '0')}: 0x$part (${_decodeZoneStatus(zoneValue)})');
        }
      }

      return result.toString().trim();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error parsing fire alarm data',
        tag: 'WEBSOCKET_DEBUG',
        error: e,
        stackTrace: stackTrace,
      );
      return 'Error parsing fire alarm data: $e\nOriginal data: $data';
    }
  }

  String _decodeTroubleStatus(int troubleValue) {
    switch (troubleValue) {
      case 0x00:
        return 'Normal';
      case 0x01:
        return 'Trouble';
      case 0x02:
        return 'Power Loss';
      case 0x03:
        return 'Communication Loss';
      case 0x04:
        return 'Device Fault';
      default:
        return 'Unknown Trouble ($troubleValue)';
    }
  }

  String _decodeAlarmStatus(int alarmValue) {
    switch (alarmValue) {
      case 0x00:
        return 'Normal';
      case 0x01:
        return 'Fire Alarm';
      case 0x02:
        return 'Supervisory';
      case 0x03:
        return 'Security';
      case 0x04:
        return 'Bell Active';
      case 0x05:
        return 'Alarm + Bell';
      case 0x06:
        return 'Trouble Bell';
      default:
        return 'Unknown Alarm ($alarmValue)';
    }
  }

  String _decodeZoneStatus(int zoneValue) {
    switch (zoneValue) {
      case 0x00:
        return 'Normal';
      case 0x01:
        return 'Alarm';
      case 0x02:
        return 'Trouble';
      case 0x03:
        return 'Offline';
      case 0x04:
        return 'Disabled';
      default:
        return 'Unknown Status ($zoneValue)';
    }
  }

  String _getOverallZoneStatus(int troubleValue, int alarmValue) {
    if (alarmValue != 0x00) {
      return 'ALARM';
    } else if (troubleValue != 0x00) {
      return 'TROUBLE';
    } else {
      return 'NORMAL';
    }
  }

  String _getErrorTypeString(WebSocketErrorType? errorType) {
    switch (errorType) {
      case WebSocketErrorType.timeout:
        return 'TIMEOUT';
      case WebSocketErrorType.connectionRefused:
        return 'CONN REFUSED';
      case WebSocketErrorType.network:
        return 'NETWORK';
      case WebSocketErrorType.certificate:
        return 'CERT';
      case WebSocketErrorType.unknown:
        return 'UNKNOWN';
      case WebSocketErrorType.none:
      default:
        return 'NONE';
    }
  }

  Color _getErrorTypeColor(WebSocketErrorType? errorType) {
    switch (errorType) {
      case WebSocketErrorType.timeout:
        return Colors.orange;
      case WebSocketErrorType.connectionRefused:
        return Colors.red;
      case WebSocketErrorType.network:
        return Colors.purple;
      case WebSocketErrorType.certificate:
        return Colors.amber;
      case WebSocketErrorType.unknown:
        return Colors.grey;
      case WebSocketErrorType.none:
      default:
        return Colors.green;
    }
  }

  void _showDiagnosticsDialog(BuildContext context, Map<String, dynamic> diagnostics) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.bug_report, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Connection Diagnostics'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDiagnosticItem('Connection Status', diagnostics['isConnected'] ? 'Connected' : 'Disconnected'),
                _buildDiagnosticItem('Currently Connecting', diagnostics['isConnecting'] ? 'Yes' : 'No'),
                _buildDiagnosticItem('Auto Reconnect', diagnostics['shouldReconnect'] ? 'Enabled' : 'Disabled'),
                _buildDiagnosticItem('Current URL', diagnostics['currentURL'] ?? 'None'),
                _buildDiagnosticItem('Reconnect Attempts', '${diagnostics['reconnectAttempts']}/${diagnostics['maxReconnectAttempts']}'),
                if (diagnostics['lastErrorType'] != null)
                  _buildDiagnosticItem('Last Error', diagnostics['lastErrorType']),
                if (diagnostics['lastConnectionAttempt'] != null)
                  _buildDiagnosticItem('Last Attempt', diagnostics['lastConnectionAttempt']),
                _buildDiagnosticItem('Time Since Last Attempt', diagnostics['timeSinceLastAttemptFormatted'] ?? 'Never'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonEncode(diagnostics)));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diagnostics copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
        color: Colors.grey.shade50,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Enter message to send...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}