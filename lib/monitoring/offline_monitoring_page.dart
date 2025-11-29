import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/logger.dart';
import '../core/fire_alarm_data.dart';
import '../models/zone_status.dart';
import '../services/websocket_mode_manager.dart';
import '../services/offline_settings_service.dart';
import '../services/offline_performance_manager.dart';
import '../services/fire_alarm_websocket_manager.dart';
import '../widgets/blinking_tab_header.dart';

class OfflineMonitoringPage extends StatefulWidget {
  final String ip;
  final int port;
  final String projectName;
  final int moduleCount;

  const OfflineMonitoringPage({
    super.key,
    required this.ip,
    required this.port,
    required this.projectName,
    required this.moduleCount,
  });

  @override
  State<OfflineMonitoringPage> createState() => _OfflineMonitoringPageState();
}

class _OfflineMonitoringPageState extends State<OfflineMonitoringPage> with WidgetsBindingObserver {
  
  
  int _displayModules = 63; // Default display all modules (matches tab_monitoring.dart)
  bool _isConnected = false;
  String _connectionStatus = 'Disconnected';

  // Auto-hide timer state
  bool _showModuleControls = true;
  Timer? _hideControlsTimer;
  static const Duration _autoHideDuration = Duration(seconds: 15);

  // Tab section state
  String _selectedTab = 'recent';
  List<String> _availableDates = [];
  String _selectedDate = '';
  final List<Map<String, dynamic>> _localActivityLogs = [];
    static const int _maxActivityLogs = 100; // Maximum logs to store

  // Performance manager
  late final OfflinePerformanceManager _performanceManager;

  // WebSocket manager for ESP32 communication
  late final FireAlarmWebSocketManager _webSocketManager;

  @override 
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    

    // Adaptive orientation based on device size
    final screenSize = MediaQuery.of(context).size;
    if (screenSize.width < 768) {
      // Mobile: allow both orientations
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Tablet/Desktop: landscape preferred
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    // Adaptive system UI mode
    SystemChrome.setEnabledSystemUIMode(
      screenSize.width < 768
        ? SystemUiMode.edgeToEdge
        : SystemUiMode.immersiveSticky
    );

    // Initialize performance manager
    _performanceManager = OfflinePerformanceManager.instance;

    // Initialize WebSocket manager for ESP32 communication
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);
    _webSocketManager = FireAlarmWebSocketManager(fireAlarmData);

    // 🚀 Enable focused performance mode for maximum responsiveness
    _enableFocusedPerformanceMode();

    // Initialize WebSocket mode manager for offline monitoring
    _initializeWebSocketMode();

    _displayModules = widget.moduleCount; // Start with configured modules

    // Start auto-hide timer for module controls
    _startHideControlsTimer();

    // Initialize tab section with sample data
    _initializeTabSection();
  }

  void _initializeWebSocketMode() async {
    try {
      // 🚀 Initialize WebSocket connection for offline mode (singleton)
      final wsManager = WebSocketModeManager.instance;
      final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

      // Configure offline mode settings
      await OfflineSettingsService.saveIndividualSettings(
        ip: widget.ip,
        port: widget.port,
        projectName: widget.projectName,
        moduleCount: widget.moduleCount,
        isConfigured: true,
      );

      await wsManager.initializeManager(fireAlarmData);

      // Connect to ESP32 using provided IP and port
      await _webSocketManager.connectToESP32(widget.ip);

      // Set project name in FireAlarmData
      if (mounted) {
        fireAlarmData.projectName = widget.projectName;

        // Update connection status
        setState(() {
          _isConnected = true;
          _connectionStatus = 'Connected';
        });
      }

      AppLogger.info('WebSocket mode initialized for ${widget.ip}:${widget.port}');
    } catch (e) {
      AppLogger.error('Failed to initialize WebSocket mode', error: e);
      if (mounted) {
        setState(() {
          _isConnected = false;
          _connectionStatus = 'Connection Failed';
        });
      }
    }
  }

  /// Initialize tab section with sample data
  void _initializeTabSection() {
    // Add some sample activity logs for demonstration

    final sampleLogs = [
      _parseWebSocketToActivityLog({'status': 'Connected'}, 'connection'),
      _parseWebSocketToActivityLog({'module': '01'}, 'module_update'),
      _parseWebSocketToActivityLog({'status': 'System Normal'}, 'system_status'),
      _parseWebSocketToActivityLog({'zone': '001', 'status': 'Normal'}, 'zone_update'),
    ];

    for (final log in sampleLogs) {
      _addActivityLog(log);
    }

    // Alarm zones are extracted directly in _buildFireAlarmTab() when needed

    AppLogger.info('Tab section initialized with ${_localActivityLogs.length} activity logs');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // When app is resumed, ensure landscape mode for offline monitoring
        if (mounted) {
          
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
          // Also ensure immersive mode
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        }
        break;

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        // Don't restore orientations here - keep landscape until user manually leaves
        
        break;

      case AppLifecycleState.hidden:
        // App is hidden but not destroyed
        
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Restore user preferred orientations when leaving the page
    _restoreUserPreferredOrientations();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 🚀 Dispose performance manager
    _performanceManager.dispose();

    // Dispose WebSocket manager
    _webSocketManager.dispose();

    // Cancel auto-hide timer to prevent memory leaks
    _hideControlsTimer?.cancel();

    super.dispose();
  }

  
  void _incrementModules() {
    setState(() {
      if (_displayModules < 63) {
        _displayModules++;
      }
    });
  }

  void _decrementModules() {
    setState(() {
      if (_displayModules > 1) {
        _displayModules--;
      }
    });
  }

  /// Auto-hide controls timer methods
  void _startHideControlsTimer() {
    _hideControlsTimer = Timer(_autoHideDuration, () {
      if (mounted) {
        _hideControls();
      }
    });
  }

  void _hideControls() {
    setState(() {
      _showModuleControls = false;
    });
  }

  /// Parse WebSocket data to activity log format
  Map<String, dynamic> _parseWebSocketToActivityLog(dynamic data, String eventType) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd/MM/yyyy').format(now);
    final timeStr = DateFormat('HH:mm:ss').format(now);

    String activity;
    switch (eventType) {
      case 'zone_update':
        activity = 'Zone ${data['zone'] ?? 'Unknown'} status changed to ${data['status'] ?? 'Unknown'}';
        break;
      case 'system_status':
        activity = 'System status: ${data['status'] ?? 'Unknown'}';
        break;
      case 'connection':
        activity = 'Connection: ${data['status'] ?? 'Unknown'}';
        break;
      case 'module_update':
        activity = 'Module ${data['module'] ?? 'Unknown'} updated';
        break;
      default:
        activity = 'System event: $eventType';
    }

    return {
      'date': dateStr,
      'time': timeStr,
      'activity': activity,
      'timestamp': now.millisecondsSinceEpoch.toString(),
      'type': eventType,
      'data': data,
    };
  }

  /// Extract active alarm zones from FireAlarmData
  List<Map<String, dynamic>> _extractAlarmZones() {
    final List<Map<String, dynamic>> alarmZones = [];

    // Get zone status from fireAlarmData
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

    // Get zones with actual alarm status from zone data (like trouble zones)
    final alarmZoneNumbers = fireAlarmData.activeAlarmZones;

    if (alarmZoneNumbers.isNotEmpty) {
      for (final zoneNumber in alarmZoneNumbers) {
        // Skip zones outside display range
        if (zoneNumber > _displayModules * 5) continue;

        final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNumber);

        // Calculate module and zone in module numbers
        final moduleNumber = ((zoneNumber - 1) / 5).floor() + 1;
        final zoneInModule = ((zoneNumber - 1) % 5) + 1;

        alarmZones.add({
          'zoneNumber': zoneNumber,
          'moduleNumber': moduleNumber,
          'zoneInModule': zoneInModule,
          'area': 'Module ${moduleNumber.toString().padLeft(2, '0')} - Zone $zoneInModule',
          'status': zoneStatus?['status'] ?? 'Alarm',
          'timestamp': zoneStatus?['timestamp']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'bellType': fireAlarmData.getSystemStatus('Alarm'),
        });
      }
    }

    return alarmZones;
  }

  /// Extract active trouble zones from FireAlarmData
  List<Map<String, dynamic>> _extractTroubleZones() {
    final List<Map<String, dynamic>> troubleZones = [];

    // Get zone status from fireAlarmData
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

    // Get zones with actual trouble status from zone data (not LED status)
    final troubleZoneNumbers = fireAlarmData.activeTroubleZones;

    if (troubleZoneNumbers.isNotEmpty) {
      for (final zoneNumber in troubleZoneNumbers) {
        // Skip zones outside display range
        if (zoneNumber > _displayModules * 5) continue;

        final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNumber);

        // Calculate module and zone in module numbers
        final moduleNumber = ((zoneNumber - 1) / 5).floor() + 1;
        final zoneInModule = ((zoneNumber - 1) % 5) + 1;

        troubleZones.add({
          'zoneNumber': zoneNumber,
          'moduleNumber': moduleNumber,
          'zoneInModule': zoneInModule,
          'area': 'Module ${moduleNumber.toString().padLeft(2, '0')} - Zone $zoneInModule',
          'status': zoneStatus?['status'] ?? 'Trouble',
          'timestamp': zoneStatus?['timestamp']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
          'bellType': false, // Trouble zones don't typically have bell activation
        });
      }
    }

    return troubleZones;
  }

  /// Add activity log to buffer with size limit
  void _addActivityLog(Map<String, dynamic> log) {
    setState(() {
      _localActivityLogs.insert(0, log);
      if (_localActivityLogs.length > _maxActivityLogs) {
        _localActivityLogs.removeLast();
      }
      _updateAvailableDates();
    });
  }

  /// Update available dates from activity logs
  void _updateAvailableDates() {
    final Set<String> dates = _localActivityLogs
        .map((log) => log['date'] as String)
        .toSet();

    setState(() {
      _availableDates = dates.toList()..sort((a, b) => _compareDates(b, a));
      if (_selectedDate.isEmpty && _availableDates.isNotEmpty) {
        _selectedDate = _availableDates.first;
      }
    });
  }

  /// Compare dates in dd/MM/yyyy format
  int _compareDates(String date1, String date2) {
    try {
      final parts1 = date1.split('/');
      final parts2 = date2.split('/');

      final day1 = int.parse(parts1[0]);
      final month1 = int.parse(parts1[1]);
      final year1 = int.parse(parts1[2]);

      final day2 = int.parse(parts2[0]);
      final month2 = int.parse(parts2[1]);
      final year2 = int.parse(parts2[2]);

      final dateTime1 = DateTime(year1, month1, day1);
      final dateTime2 = DateTime(year2, month2, day2);

      return dateTime1.compareTo(dateTime2);
    } catch (e) {
      return 0;
    }
  }

  /// Enable focused performance mode for optimal WebSocket responsiveness
  Future<void> _enableFocusedPerformanceMode() async {
    try {
      await _performanceManager.initialize();
      await _performanceManager.setPerformanceMode(OfflinePerformanceMode.focused);

      AppLogger.info('✅ Focused performance mode enabled - WebSocket priority activated');
    } catch (e) {
      AppLogger.error('Failed to enable focused performance mode', error: e);
    }
  }

  void _restoreUserPreferredOrientations() {
    

    // Restore to flexible orientations, allowing the system to decide based on device orientation.
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Also restore system UI to normal mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // 🔄 Restore normal performance mode when leaving
    _restoreNormalPerformanceMode();

    // Force a short delay to ensure orientation change takes effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        
      }
    });
  }

  /// Restore normal performance mode when exiting offline monitoring
  Future<void> _restoreNormalPerformanceMode() async {
    try {
      await _performanceManager.setPerformanceMode(OfflinePerformanceMode.normal);
      AppLogger.info('✅ Normal performance mode restored');
    } catch (e) {
      AppLogger.error('Failed to restore normal performance mode', error: e);
    }
  }

  
  
  
  // 🎯 UPDATED: Helper methods untuk responsive design - lebih konservatif untuk mencegah overflow
  int _calculateCrossAxisCount(double screenWidth) {
    // Enhanced responsive calculation for better device coverage
    // Using breakpoint-based design for optimal user experience
    if (screenWidth < 360) {
      return 2; // Small phones (iPhone SE, etc.) - minimal density
    } else if (screenWidth < 480) {
      return 3; // Regular phones - balanced density
    } else if (screenWidth < 600) {
      return 4; // Large phones - good density
    } else if (screenWidth < 768) {
      return 5; // Small tablets/landscape phones - moderate density
    } else if (screenWidth < 900) {
      return 6; // Tablets - good balance
    } else if (screenWidth < 1024) {
      return 7; // Large tablets - high density
    } else if (screenWidth < 1200) {
      return 8; // Small desktop - very good density
    } else if (screenWidth < 1600) {
      return 10; // Standard desktop - maximum density
    } else {
      return 12; // Large desktop/4K - ultra high density
    }
  }

  
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          // Restore user preferred orientations when page is popped
          _restoreUserPreferredOrientations();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Consumer<FireAlarmData>(
            builder: (context, fireAlarmData, child) {
              // Calculate total configured zones count (5 zones per module)
              final totalConfiguredZones = widget.moduleCount * 5;

              return Container(
                width: double.infinity,
                padding: _getResponsivePadding(context),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
  
                            // Header info (Project info dengan offline-specific controls)
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: _getContainerPadding(context),
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                children: [
                                  // First row: Back button, module controls, and project info
                                  Row(
                                    children: [
                                      // Back Button (dipindahkan dari container atas)
                                      IconButton(
                                        onPressed: () {
                                          // Restore orientations before navigating back
                                          _restoreUserPreferredOrientations();
                                          Navigator.of(context).pop();
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new,
                                          color: Colors.black87,
                                          size: 22,
                                        ),
                                        padding: const EdgeInsets.all(10),
                                        constraints: const BoxConstraints(
                                          minWidth: 45,
                                          minHeight: 45,
                                        ),
                                      ),

                                      // Spacer
                                      const SizedBox(width: 15),

                                      // Module Controls (dipindahkan dari baris 2)
                                      AnimatedOpacity(
                                        opacity: _showModuleControls ? 1.0 : 0.0,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            border: Border.all(color: Colors.grey.shade400),
                                            borderRadius: BorderRadius.circular(8),
                                            color: Colors.white,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Decrease button
                                              InkWell(
                                                onTap: _decrementModules,
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: _displayModules > 1 ? Colors.red.shade100 : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Icon(
                                                    Icons.remove,
                                                    size: 18,
                                                    color: _displayModules > 1 ? Colors.red : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'MODULES',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey.shade600,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$_displayModules',
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(width: 12),
                                              // Increase button
                                              InkWell(
                                                onTap: _incrementModules,
                                                child: Container(
                                                  width: 28,
                                                  height: 28,
                                                  decoration: BoxDecoration(
                                                    color: _displayModules < 63 ? Colors.green.shade100 : Colors.grey.shade200,
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Icon(
                                                    Icons.add,
                                                    size: 18,
                                                    color: _displayModules < 63 ? Colors.green : Colors.grey,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),

                                      // Spacer antara module controls dan project info
                                      const SizedBox(width: 20),

                                      // Project Info di dalam Expanded
                                      Expanded(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                                          children: [
                                            Column(
                                              children: [
                                                const Text(
                                                  'PROJECT',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  widget.projectName,
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                const Text(
                                                  'STATUS',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  fireAlarmData.getSystemStatusWithTroubleDetection(),
                                                  style: TextStyle(
                                                    color: fireAlarmData.getSystemStatusColorWithTroubleDetection(),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                const Text(
                                                  'ACTIVE ZONES',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  '$totalConfiguredZones',
                                                  style: const TextStyle(
                                                    color: Colors.black87,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              children: [
                                                const Text(
                                                  'CONNECTION',
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _isConnected ? Colors.green.shade100 : Colors.red.shade100,
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _isConnected ? Colors.green : Colors.red,
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Container(
                                                        width: 8,
                                                        height: 8,
                                                        decoration: BoxDecoration(
                                                          color: _isConnected ? Colors.green : Colors.red,
                                                          shape: BoxShape.circle,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _connectionStatus,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.bold,
                                                          color: _isConnected ? Colors.green.shade700 : Colors.red.shade700,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Modules container
                            Flexible(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(_getContainerPadding(context)),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _buildDynamicGrid(
                                  context,
                                  BoxConstraints(
                                    maxWidth: MediaQuery.of(context).size.width - (_getContainerPadding(context) * 2) - 40,
                                    maxHeight: 400,
                                  ),
                                  fireAlarmData,
                                ),
                              ),
                            ),

                            const SizedBox(height: 10),

                            // 🎯 TAB SECTION (Activity Logs & Status)
                            _buildTabSection(),

                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDynamicGrid(BuildContext context, BoxConstraints constraints, FireAlarmData fireAlarmData) {
    final crossAxisCount = _calculateCrossAxisCount(constraints.maxWidth);
    final spacing = _getGridSpacing(context);
    final moduleWidth = (constraints.maxWidth - (crossAxisCount - 1) * spacing) / crossAxisCount;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: spacing,
      runSpacing: spacing,
      children: List.generate(_displayModules, (index) {
        final moduleNumber = index + 1;
        return SizedBox(
          width: moduleWidth,
          child: IndividualModuleContainer(
            moduleNumber: moduleNumber,
            fireAlarmData: fireAlarmData,
            onZoneTap: (zoneNumber) => _showZoneDetailDialog(context, zoneNumber, fireAlarmData),
            onModuleTap: (moduleNumber) => _showModuleDetailDialog(context, moduleNumber, fireAlarmData),
          ),
        );
      }),
    );
  }

  
  
  
  
  /// Build tab section with headers and content
  Widget _buildTabSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabHeaders(),
          const SizedBox(height: 16),
          _buildTabContent(),
        ],
      ),
    );
  }

  /// Check if alarm icon should be shown based on active alarm zones or bell status
  bool _shouldShowAlarmIcon(FireAlarmData fireAlarmData) {
    return fireAlarmData.activeAlarmZones.isNotEmpty ||
           fireAlarmData.getSystemStatus('Alarm') ||
           fireAlarmData.getSystemStatus('ALARM DRILL') ||
           fireAlarmData.hasActiveBells();
  }

  /// Check if trouble icon should be shown based on active trouble zones
  bool _shouldShowTroubleIcon(FireAlarmData fireAlarmData) {
    return fireAlarmData.activeTroubleZones.isNotEmpty;
  }

  /// Build tab headers (Recent Status, Fire Alarm)
  Widget _buildTabHeaders() {
    return Consumer<FireAlarmData>(
      builder: (context, fireAlarmData, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 'recent';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedTab == 'recent'
                      ? const Color.fromARGB(255, 19, 137, 47) // Green theme
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedTab == 'recent'
                          ? const Color.fromARGB(255, 19, 137, 47)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'RECENT STATUS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _selectedTab == 'recent'
                        ? Colors.white
                        : Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 'fire_alarm';
                  // Alarm zones are extracted directly in _buildFireAlarmTab() when needed
                });
              },
              child: BlinkingTabHeader(
                shouldBlink: _shouldShowAlarmIcon(fireAlarmData),
                blinkColor: Colors.red,
                enableGlow: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'fire_alarm'
                        ? Colors.red.shade600
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 'fire_alarm'
                            ? Colors.red.shade600
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_shouldShowAlarmIcon(fireAlarmData)) ...[
                        Icon(
                          Icons.local_fire_department,
                          size: 16,
                          color: _selectedTab == 'fire_alarm'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                      ],
                      if (fireAlarmData.hasActiveBells()) ...[
                        Icon(
                          Icons.notifications_active,
                          size: 16,
                          color: _selectedTab == 'fire_alarm'
                              ? Colors.white
                              : Colors.orange,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'FIRE ALARM',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 'fire_alarm'
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTab = 'trouble';
                  // Trouble zones are extracted directly in _buildTroubleTab() when needed
                });
              },
              child: BlinkingTabHeader(
                shouldBlink: _shouldShowTroubleIcon(fireAlarmData),
                blinkColor: Colors.orange,
                enableGlow: true,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedTab == 'trouble'
                        ? Colors.orange.shade600
                        : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: _selectedTab == 'trouble'
                            ? Colors.orange.shade600
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_shouldShowTroubleIcon(fireAlarmData)) ...[
                        Icon(
                          Icons.warning,
                          size: 16,
                          color: _selectedTab == 'trouble'
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        'TROUBLE',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _selectedTab == 'trouble'
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
          ),
        );
      },
    );
  }

  /// Build tab content based on selected tab
  Widget _buildTabContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic height based on available screen space
        final screenHeight = MediaQuery.of(context).size.height;
        final availableHeight = screenHeight - 300; // Account for header, status bar, and other UI elements
        final dynamicHeight = (availableHeight * 0.6).clamp(300.0, 600.0); // Min 300px, max 600px

        return SizedBox(
          height: dynamicHeight,
          child: _selectedTab == 'recent'
              ? _buildRecentStatusTab()
              : _selectedTab == 'fire_alarm'
                  ? _buildFireAlarmTab()
                  : _buildTroubleTab(),
        );
      },
    );
  }

  /// Build Recent Status tab content
  Widget _buildRecentStatusTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date picker
        _buildLocalDateTabs(),
        const SizedBox(height: 12),
        // Activity logs
        Expanded(
          child: _localActivityLogs.isEmpty
              ? _buildNoDataWidget('No recent activities available')
              : _buildLocalActivityLogs(),
        ),
      ],
    );
  }

  /// Build local date tabs
  Widget _buildLocalDateTabs() {
    if (_availableDates.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text(
            'No activity data available',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableDates.length,
        itemBuilder: (context, index) {
          final date = _availableDates[index];
          final isSelected = date == _selectedDate;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Container(
              width: 100,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color.fromARGB(255, 19, 137, 47)
                    : Colors.white,
                border: Border.all(
                  color: isSelected
                      ? const Color.fromARGB(255, 19, 137, 47)
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  date,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build local activity logs display
  Widget _buildLocalActivityLogs() {
    final dateLogs = _localActivityLogs
        .where((log) => log['date'] == _selectedDate)
        .toList();

    if (dateLogs.isEmpty) {
      return _buildNoDataWidget('No activities for selected date');
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      itemCount: dateLogs.length,
      itemBuilder: (context, index) {
        final log = dateLogs[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log['time'] ?? '',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                log['activity'] ?? '',
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build Fire Alarm tab content
  Widget _buildFireAlarmTab() {
    return Consumer<FireAlarmData>(
      builder: (context, fireAlarmData, child) {
        final alarmZones = _extractAlarmZones();
        final hasActiveAlarm = alarmZones.isNotEmpty;

        // 🔔 NEW: Bell accumulation override pattern (SAMA seperti zones)
        bool hasActiveBells = false;
        if (fireAlarmData.isAccumulationMode) {
          // In accumulation mode, accumulated bell count overrides real-time status
          hasActiveBells = fireAlarmData.accumulatedBellCount > 0;
          
        } else {
          // In real-time mode, use individual bell status
          hasActiveBells = fireAlarmData.hasActiveBells();
          
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with alarm and bell count
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (hasActiveAlarm || hasActiveBells) ? Icons.warning : Icons.check_circle,
                    color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade600 : Colors.green.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (hasActiveAlarm || hasActiveBells) ? 'Active Alerts' : 'No Active Alarms',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade700 : Colors.green.shade700,
                          ),
                        ),
                        if (hasActiveAlarm && hasActiveBells) ...[
                          Text(
                            '${alarmZones.length} zone(s) in alarm state • ${fireAlarmData.accumulatedBellCount} bell(s) ringing',
                            style: TextStyle(
                              fontSize: 14,
                              color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ] else if (hasActiveAlarm) ...[
                          Text(
                            '${alarmZones.length} zone(s) in alarm state',
                            style: TextStyle(
                              fontSize: 14,
                              color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ] else if (hasActiveBells) ...[
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_active,
                                size: 16,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${fireAlarmData.accumulatedBellCount} bell(s) ringing',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade600 : Colors.green.shade600,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          Text(
                            'All zones are normal',
                            style: TextStyle(
                              fontSize: 14,
                              color: (hasActiveAlarm || hasActiveBells) ? Colors.red.shade600 : Colors.green.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 12),
        // Alarm zones list
        Expanded(
          child: !hasActiveAlarm
              ? _buildNoDataWidget('No active alarm zones')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: alarmZones.length,
                  itemBuilder: (context, index) {
                    final zone = alarmZones[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Zone ${zone['zoneNumber']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (zone['bellType'] == true) ...[
                                const SizedBox(width: 6),
                                Icon(
                                  Icons.notifications_active,
                                  color: Colors.red.shade600,
                                  size: 14,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            zone['area'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            zone['status'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
      },
    );
  }

  /// Build Trouble tab content
  Widget _buildTroubleTab() {
    final troubleZones = _extractTroubleZones();
    final hasActiveTrouble = troubleZones.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with trouble count
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasActiveTrouble ? Colors.orange.shade50 : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: hasActiveTrouble ? Colors.orange.shade200 : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: hasActiveTrouble ? Colors.orange.shade600 : Colors.grey.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActiveTrouble
                          ? '${troubleZones.length} Active Trouble Zone${troubleZones.length != 1 ? 's' : ''}'
                          : 'No Active Trouble',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: hasActiveTrouble ? Colors.orange.shade600 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      hasActiveTrouble ? 'System requires attention' : 'All systems operational',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasActiveTrouble ? Colors.orange.shade700 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Trouble zones list
        Expanded(
          child: !hasActiveTrouble
              ? _buildNoDataWidget('No active trouble zones')
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: troubleZones.length,
                  itemBuilder: (context, index) {
                    final zone = troubleZones[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.orange.shade200,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withValues(alpha: 0.08),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade600,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Zone ${zone['zoneNumber']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.warning,
                                color: Colors.orange.shade600,
                                size: 14,
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            zone['area'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            zone['status'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// Build no data widget
  Widget _buildNoDataWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Get responsive padding for main container
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Enhanced responsive padding based on screen size
    double horizontalPadding;
    double verticalPadding;

    if (screenWidth < 360) {
      horizontalPadding = 8.0;  // Small phones
      verticalPadding = 6.0;
    } else if (screenWidth < 480) {
      horizontalPadding = 10.0; // Regular phones
      verticalPadding = 8.0;
    } else if (screenWidth < 768) {
      horizontalPadding = 12.0; // Large phones
      verticalPadding = 10.0;
    } else if (screenWidth < 1024) {
      horizontalPadding = 16.0; // Tablets
      verticalPadding = 12.0;
    } else if (screenWidth < 1200) {
      horizontalPadding = 20.0; // Small desktop
      verticalPadding = 15.0;
    } else {
      horizontalPadding = 25.0; // Large desktop
      verticalPadding = 20.0;
    }

    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
  }

  // Get responsive padding for individual containers
  double _getContainerPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 6.0;  // Small phones
    } else if (screenWidth < 480) {
      return 8.0;  // Regular phones
    } else if (screenWidth < 768) {
      return 10.0; // Large phones
    } else if (screenWidth < 1024) {
      return 12.0; // Tablets
    } else if (screenWidth < 1200) {
      return 16.0; // Small desktop
    } else {
      return 20.0; // Large desktop
    }
  }

  // Enhanced responsive spacing for grid
  double _getGridSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 480) {
      return 4.0;  // Phones - compact spacing
    } else if (screenWidth < 768) {
      return 6.0;  // Large phones
    } else if (screenWidth < 1024) {
      return 8.0;  // Tablets
    } else if (screenWidth < 1200) {
      return 10.0; // Small desktop
    } else {
      return 12.0; // Large desktop
    }
  }

  // Calculate responsive font size based on screen diagonal
  double _calculateResponsiveFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    double baseSize;

    if (screenWidth < 360) {
      baseSize = diagonal / 120; // Small phones - smaller font
    } else if (screenWidth < 480) {
      baseSize = diagonal / 110; // Regular phones
    } else if (screenWidth < 768) {
      baseSize = diagonal / 100; // Large phones
    } else if (screenWidth < 1024) {
      baseSize = diagonal / 90;  // Tablets
    } else if (screenWidth < 1200) {
      baseSize = diagonal / 80;  // Small desktop
    } else {
      baseSize = diagonal / 70;  // Large desktop - larger font
    }

    return baseSize.clamp(10.0, 18.0); // Wider range for better visibility
  }

  // Get responsive header font size
  double _getHeaderFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 12.0; // Small phones
    } else if (screenWidth < 480) {
      return 13.0; // Regular phones
    } else if (screenWidth < 768) {
      return 14.0; // Large phones
    } else if (screenWidth < 1024) {
      return 15.0; // Tablets
    } else if (screenWidth < 1200) {
      return 16.0; // Small desktop
    } else {
      return 18.0; // Large desktop
    }
  }

  // Get responsive title font size
  double _getTitleFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 360) {
      return 14.0; // Small phones
    } else if (screenWidth < 480) {
      return 16.0; // Regular phones
    } else if (screenWidth < 768) {
      return 18.0; // Large phones
    } else if (screenWidth < 1024) {
      return 20.0; // Tablets
    } else if (screenWidth < 1200) {
      return 22.0; // Small desktop
    } else {
      return 24.0; // Large desktop
    }
  }

  
  /// Show zone detail dialog
  void _showZoneDetailDialog(BuildContext context, int zoneNumber, FireAlarmData fireAlarmData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return ZoneDetailDialog(
          zoneNumber: zoneNumber,
          fireAlarmData: fireAlarmData,
        );
      },
    );
  }

  /// Show module detail dialog
  void _showModuleDetailDialog(BuildContext context, int moduleNumber, FireAlarmData fireAlarmData) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (BuildContext context) {
        return ModuleDetailDialog(
          moduleNumber: moduleNumber,
          fireAlarmData: fireAlarmData,
        );
      },
    );
  }
}

// Individual Module Container - Container untuk setiap module (same as tab_monitoring.dart)
class IndividualModuleContainer extends StatelessWidget {
  final int moduleNumber;
  final FireAlarmData fireAlarmData;
  final Function(int)? onZoneTap;
  final Function(int)? onModuleTap;

  const IndividualModuleContainer({
    super.key,
    required this.moduleNumber,
    required this.fireAlarmData,
    this.onZoneTap,
    this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onModuleTap != null ? () => onModuleTap!(moduleNumber) : null,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 2,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Module number
          Text(
            '#${moduleNumber.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // 🎯 HORIZONTAL LAYOUT: Container untuk 6 LEDs dalam 1 baris dengan responsive spacing
          LayoutBuilder(
            builder: (context, ledConstraints) {
              // Calculate responsive spacing based on available container width
              final totalAvailableWidth = ledConstraints.maxWidth - 12.0; // minus horizontal padding
              final baseSpacing = (totalAvailableWidth * 0.01).clamp(0.5, 1.5); // 1% of width, min 0.5, max 1.5
              final bellSpacing = (totalAvailableWidth * 0.02).clamp(1.0, 2.0); // 2% of width, min 1, max 2

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildLED(1, Colors.red)), // Zone 1
                    SizedBox(width: baseSpacing * 0.3),
                    Expanded(child: _buildLED(2, Colors.red)), // Zone 2
                    SizedBox(width: baseSpacing * 0.3),
                    Expanded(child: _buildLED(3, Colors.red)), // Zone 3
                    SizedBox(width: baseSpacing * 0.3),
                    Expanded(child: _buildLED(4, Colors.red)), // Zone 4
                    SizedBox(width: baseSpacing * 0.3),
                    Expanded(child: _buildLED(5, Colors.red)), // Zone 5
                    SizedBox(width: baseSpacing * 0.5), // Extra spacing before bell
                    Expanded(child: _buildLED(6, Colors.yellow)), // Bell
                  ],
                ),
              );
            },
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildLED(int ledIndex, Color activeColor) {
    // Calculate zone number for this module (same as tab_monitoring.dart)
    int zoneNumber;
    String label;

    if (ledIndex <= 5) {
      // Zone LEDs 1-5 - use same calculation as monitoring.dart
      zoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(moduleNumber, ledIndex);
      label = '$zoneNumber'; // Show zone number
    } else {
      // Bell LED 6 - use same calculation as monitoring.dart
      zoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(moduleNumber, 1);
      label = 'B'; // Show 'B' for Bell
    }

    // Determine LED color based on zone status (same as tab_monitoring.dart)
    Color ledColor;

    if (ledIndex == 6) {
      // Special handling for Bell LED (same as tab_monitoring.dart)
      final slaveAddress = moduleNumber.toString().padLeft(2, '0');
      final bellStatus = fireAlarmData.getBellConfirmationStatus(slaveAddress);

      // Bell is active if confirmation received or drill mode is active
      final isBellActive = fireAlarmData.shouldForceAllBellsOnInDrill ||
                          bellStatus?.isActive == true;

      ledColor = isBellActive ? Colors.red : Colors.grey.shade300;
    } else {
      // Zone LEDs 1-5 - use complete status checking like in monitoring.dart
      ledColor = _getZoneColorFromSystem(zoneNumber);
    }

    final isActive = ledColor != Colors.grey.shade300 && ledColor != Colors.white;

      // 🔥 NEW: Calculate responsive LED size to prevent overflow
    // Use LayoutBuilder to get container constraints
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available width for all 6 LEDs
        double totalAvailableWidth = constraints.maxWidth - 13.5; // Account for padding

        // Calculate optimal LED size with minimum and maximum constraints
        double maxLEDSize = 12.0;  // Reduced to fit zone numbers
        double minLEDSize = 8.0;   // Minimum readable size for zone numbers
        double spacingBudget = totalAvailableWidth / 6.0;

        // Use 70% of available space for LED, but clamp between min and max
        double responsiveLEDSize = (spacingBudget * 0.7).clamp(minLEDSize, maxLEDSize);

        // Calculate font size based on LED size
        double fontSize = (responsiveLEDSize * 0.4).clamp(6.0, 8.0);

        // Debug information for responsive sizing
        if (totalAvailableWidth < 90) {

        }

        return Padding(
          padding: const EdgeInsets.only(right: 1.5),
          child: GestureDetector(
            onTap: ledIndex <= 5 && onZoneTap != null ? () => onZoneTap!(zoneNumber) : null,
            child: Container(
              width: responsiveLEDSize,
              height: responsiveLEDSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ledColor,
                border: Border.all(
                  color: Colors.black54,
                  width: 0.5,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: ledColor.withValues(alpha: 0.4),
                    blurRadius: 2,
                    spreadRadius: 0.5,
                  ),
                ] : null,
              ),
            ),
          ),
        );
      },
    );
  }

  // Get zone color based on complete system status (same as monitoring.dart)
  Color _getZoneColorFromSystem(int zoneNumber) {
    // ADD: NO DATA validation (missing validation fix)
    if (!fireAlarmData.hasValidZoneData || fireAlarmData.isInitiallyLoading) {
      return Colors.grey;  // Grey for disconnect/no data
    }

    // Check accumulation mode first
    if (fireAlarmData.isAccumulationMode) {
      if (fireAlarmData.isZoneAccumulatedAlarm(zoneNumber)) {
        return Colors.red;
      }
      if (fireAlarmData.isZoneAccumulatedTrouble(zoneNumber)) {
        return Colors.orange;
      }
    }

    // Check individual zone status
    final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNumber);
    if (zoneStatus != null) {
      final status = zoneStatus['status'] as String?;
      switch (status) {
        case 'Alarm':
          return Colors.red;
        case 'Trouble':
          return Colors.orange;
        case 'Active':
          return Colors.blue.shade200;
        case 'Normal':
          return Colors.white;
        default:
          return Colors.grey.shade300;
      }
    }

    // System status fallback
    if (fireAlarmData.getSystemStatus('Alarm')) return Colors.red;
    if (fireAlarmData.getSystemStatus('Drill')) return Colors.red;
    if (fireAlarmData.getSystemStatus('Silenced')) return Colors.yellow.shade700;

    return Colors.white; // Default normal
  }
}

// Zone Detail Dialog Widget
class ZoneDetailDialog extends StatelessWidget {
  final int zoneNumber;
  final FireAlarmData fireAlarmData;

  const ZoneDetailDialog({
    super.key,
    required this.zoneNumber,
    required this.fireAlarmData,
  });

  @override
  Widget build(BuildContext context) {
    // Get zone information
    final deviceAddress = ZoneStatusUtils.getDeviceAddress(zoneNumber);
    final zoneInDevice = ZoneStatusUtils.getZoneInDevice(zoneNumber);
    final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNumber);
    final moduleNumber = deviceAddress;
    final zoneInModule = zoneInDevice;

    // Local variables for zone status display
    String statusText;
    Color statusColor;
    IconData statusIcon;
    String timestampStr;

    // ADD: NO DATA validation for individual zone status (HIGHEST PRIORITY)
    if (!fireAlarmData.hasValidZoneData || fireAlarmData.isInitiallyLoading) {
      statusText = 'Offline';
      statusColor = Colors.grey;
      statusIcon = Icons.signal_cellular_off;
      timestampStr = 'N/A';
    } else if (zoneStatus != null) {
      // Priority 2: Use actual zone status if data is valid
      final status = zoneStatus['status'] as String?;
      switch (status) {
        case 'Alarm':
          statusText = 'ALARM';
          statusColor = Colors.red;
          statusIcon = Icons.warning;
          break;
        case 'Trouble':
          statusText = 'TROUBLE';
          statusColor = Colors.orange;
          statusIcon = Icons.error;
          break;
        case 'Active':
          statusText = 'ACTIVE';
          statusColor = Colors.blue;
          statusIcon = Icons.info;
          break;
        case 'Normal':
        default:
          // Only show NORMAL if we have valid data
          statusText = 'NORMAL';
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          break;
      }

      // Get timestamp
      if (zoneStatus['timestamp'] != null) {
        try {
          final timestamp = DateTime.fromMillisecondsSinceEpoch(
            int.parse(zoneStatus['timestamp'].toString())
          );
          timestampStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp);
        } catch (e) {
          timestampStr = 'Invalid timestamp';
        }
      } else {
        timestampStr = 'N/A';
      }
    } else {
      // Priority 3: Default to NORMAL when no zone status but system has valid data
      statusText = 'NORMAL';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      timestampStr = 'N/A';
    }

    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with status color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Zone $zoneNumber Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Zone Information Section
                    _buildInfoSection(
                      title: 'Zone Information',
                      children: [
                        _buildInfoRow('Zone Number', '$zoneNumber'),
                        _buildInfoRow('Module/Device', '#${moduleNumber.toString().padLeft(2, '0')}'),
                        _buildInfoRow('Zone in Module', '$zoneInModule'),
                        _buildInfoRow('Status', statusText, statusColor),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Device Information Section
                    _buildInfoSection(
                      title: 'Device Information',
                      children: [
                        _buildInfoRow('Device Address', '$deviceAddress'),
                        _buildInfoRow('Device Type', 'Fire Alarm Module'),
                        _buildInfoRow('Connection', 'Connected via WebSocket'),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Status History Section
                    _buildInfoSection(
                      title: 'Status History',
                      children: [
                        _buildInfoRow('Last Update', timestampStr),
                        _buildInfoRow('Current State', statusText, statusColor),
                        if (zoneStatus != null && zoneStatus['description'] != null)
                          _buildInfoRow('Description', zoneStatus['description'].toString()),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Additional Information
                    _buildInfoSection(
                      title: 'Additional Information',
                      children: [
                        _buildInfoRow('System Status', fireAlarmData.getSystemStatusWithTroubleDetection()),
                        _buildInfoRow('Project', fireAlarmData.projectName.isNotEmpty ? fireAlarmData.projectName : 'Unknown'),
                        _buildInfoRow('Total Zones', '${fireAlarmData.activeAlarmZones.length + fireAlarmData.activeTroubleZones.length} active'),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Footer with close button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Module Detail Dialog Widget
class ModuleDetailDialog extends StatelessWidget {
  final int moduleNumber;
  final FireAlarmData fireAlarmData;

  const ModuleDetailDialog({
    super.key,
    required this.moduleNumber,
    required this.fireAlarmData,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate module zones (1-5 per module)
    final startZone = ((moduleNumber - 1) * 5) + 1;
    final endZone = startZone + 4;

    // Count active zones in this module
    int activeZones = 0;
    int alarmZones = 0;
    int troubleZones = 0;
    int normalZones = 0;

    for (int zoneNum = startZone; zoneNum <= endZone; zoneNum++) {
      final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNum);
      if (zoneStatus != null) {
        final status = zoneStatus['status'] as String?;
        activeZones++;
        switch (status) {
          case 'Alarm':
            alarmZones++;
            break;
          case 'Trouble':
            troubleZones++;
            break;
          case 'Normal':
            normalZones++;
            break;
        }
      } else {
        normalZones++;
      }
    }

    // Check bell status for this module
    final slaveAddress = moduleNumber.toString().padLeft(2, '0');
    final bellStatus = fireAlarmData.getBellConfirmationStatus(slaveAddress);
    final isBellActive = fireAlarmData.shouldForceAllBellsOnInDrill ||
                        bellStatus?.isActive == true;

    // Determine overall module status
    Color moduleStatusColor;
    String moduleStatusText;
    if (alarmZones > 0) {
      moduleStatusColor = Colors.red;
      moduleStatusText = 'ALARM';
    } else if (troubleZones > 0) {
      moduleStatusColor = Colors.orange;
      moduleStatusText = 'TROUBLE';
    } else if (activeZones > 0) {
      moduleStatusColor = Colors.blue;
      moduleStatusText = 'ACTIVE';
    } else {
      moduleStatusColor = Colors.green;
      moduleStatusText = 'NORMAL';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header with module status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: moduleStatusColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: moduleStatusColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'MODULE #$moduleNumber',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: moduleStatusColor,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: moduleStatusColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          moduleStatusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.device_hub,
                        color: moduleStatusColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Device Address: $moduleNumber',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Module Statistics
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zone Statistics',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatusChip('Normal', normalZones, Colors.green),
                              const SizedBox(width: 8),
                              _buildStatusChip('Active', activeZones - normalZones, Colors.blue),
                              const SizedBox(width: 8),
                              _buildStatusChip('Alarm', alarmZones, Colors.red),
                              const SizedBox(width: 8),
                              _buildStatusChip('Trouble', troubleZones, Colors.orange),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Zone List
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Zones in this Module',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(5, (index) {
                            final zoneNum = startZone + index;
                            final zoneStatus = fireAlarmData.getIndividualZoneStatus(zoneNum);

                            // ADD: NO DATA validation for zones in module
                            String status;
                            if (!fireAlarmData.hasValidZoneData || fireAlarmData.isInitiallyLoading) {
                              status = 'Offline';
                            } else {
                              status = zoneStatus?['status'] as String? ?? 'Offline';
                            }

                            final statusColor = _getStatusColor(status);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: statusColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Zone $zoneNum',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Bell Status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: isBellActive ? Colors.red : Colors.grey.shade300,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bell Status',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            isBellActive ? 'ACTIVE' : 'INACTIVE',
                            style: TextStyle(
                              color: isBellActive ? Colors.red : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Close button
            Container(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moduleStatusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Alarm':
        return Colors.red;
      case 'Trouble':
        return Colors.orange;
      case 'Active':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Offline':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}