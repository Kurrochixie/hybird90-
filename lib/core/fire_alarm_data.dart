import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import '../services/enhanced_notification_service.dart';
import '../services/led_status_decoder.dart';
import '../services/firebase_log_handler.dart';
import '../services/enhanced_zone_parser.dart';
import '../services/system_status_extractor.dart' as extractor;
import '../services/logger.dart';
import '../services/simple_status_manager.dart';
import '../services/websocket_mode_manager.dart';
import '../services/bell_manager.dart';
import '../services/project_info_cache_service.dart';
import '../unified_fire_alarm_parser.dart';
import '../models/zone_status.dart';
import '../di/service_locator.dart';
// 🔥 REMOVED: system_status_utils.dart import (OBSOLETE - deleted file)
import '../utils/memory_manager.dart';

/// 🔥 NEW: Simple LED Persistence for WebSocket mode
/// Handles 7-second persistence for trouble LED blinking
class SimpleLEDPersistence {
  bool _troublePersisted = false;
  DateTime? _troubleStartTime;
  bool _alarmPersisted = false;
  DateTime? _alarmStartTime;
  Timer? _troubleClearTimer;

  /// Get current trouble status with persistence
  bool getTroubleStatus(bool currentTroubleLED) {
    if (currentTroubleLED && !_troublePersisted) {
      _troublePersisted = true;
      _troubleStartTime = DateTime.now();
      
    }

    if (!currentTroubleLED && _troublePersisted && _troubleStartTime != null) {
      // Cancel existing timer if any
      _troubleClearTimer?.cancel();

      // Store current state to avoid closure capture issues
      final bool wasPersisted = _troublePersisted;

      _troubleClearTimer = Timer(Duration(seconds: 7), () {
        if (wasPersisted && _troublePersisted) { // Double-check still OFF and persisted
          _troublePersisted = false;
          _troubleStartTime = null;
          
        }
        _troubleClearTimer = null;
      });
    }

    return _troublePersisted || currentTroubleLED;
  }

  /// Get current alarm status (immediate, no persistence needed for alarm)
  bool getAlarmStatus(bool currentAlarmLED) {
    if (currentAlarmLED && !_alarmPersisted) {
      _alarmPersisted = true;
      _alarmStartTime = DateTime.now();
      
    }

    if (!currentAlarmLED && _alarmPersisted) {
      _alarmPersisted = false;
      _alarmStartTime = null;
      
    }

    return _alarmPersisted || currentAlarmLED;
  }

  /// Reset all persistence (useful for testing or manual reset)
  void reset() {
    _troubleClearTimer?.cancel();
    _troubleClearTimer = null;
    _troublePersisted = false;
    _troubleStartTime = null;
    _alarmPersisted = false;
    _alarmStartTime = null;
    
  }

  /// Get diagnostic info
  Map<String, dynamic> getDiagnostics() {
    return {
      'troublePersisted': _troublePersisted,
      'troubleStartTime': _troubleStartTime?.toIso8601String(),
      'alarmPersisted': _alarmPersisted,
      'alarmStartTime': _alarmStartTime?.toIso8601String(),
    };
  }
}

// Data bersama untuk aplikasi Fire Alarm Monitoring
class FireAlarmData extends ChangeNotifier {
  bool _mounted = true;
  late FirebaseLogHandler _logHandler;

  // 🎯 NEW: Simple Status Manager - Single Authority for Status Determination
  final SimpleStatusManager _simpleStatusManager = SimpleStatusManager();

  // 🔔 NEW: Zone Accumulation Manager - Track zones that ever alarmed during LED ON
  final ZoneAccumulator _zoneAccumulator = ZoneAccumulator();

  // 🔔 NEW: Bell Accumulation Manager - Track bells that ever activated during LED ON (SAME AS ZONE)
  final BellAccumulator _bellAccumulator = BellAccumulator();

  // 🔔 NEW: Bell Manager dependency for LED-based reset mechanism
  late final BellManager _bellManager;

  // 🔥 NEW: LED Persistence Manager - Handle 7-second persistence for LED blinking in WebSocket mode
  final SimpleLEDPersistence _ledPersistence = SimpleLEDPersistence();

  // 🚀 NEW: WebSocket Mode Manager - Handle Firebase/WebSocket mode switching (using singleton)
  // Field removed - now using WebSocketModeManager.instance directly

  /// Invalidate zone cache and reset system state for mode switching
  Future<void> invalidateZoneCache() async {
    try {
      

      // Clear zone cache
      _statusCache.clear();
      _lastCallTime.clear();

      // Reset WebSocket pending data
      _pendingWebSocketData.clear();

      // Reset system status flags but keep data
      _hasWebSocketData = false;

      // Force notification to update UI
      if (_mounted) {
        notifyListeners();
      }


    } catch (e) {
      AppLogger.error('Error invalidating zone cache', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  @override
  void dispose() {
    

    _mounted = false;

    // Perform final memory cleanup
    MemoryManager.performCleanup(force: true);
    

    // Dispose memory manager
    MemoryManager.dispose();

    _logHandler.dispose();

    disposeResources();

    
    super.dispose();
  }
  // Firebase Database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  DatabaseReference get databaseRef => _databaseRef;

  // Get log handler for external access
  FirebaseLogHandler get logHandler => _logHandler;

  // ============= UI CONFIGURATION SECTION =============
  // Centralized UI configuration for consistent design across all pages

  // Logo Configuration
  static const double logoWidth = 160.0;
  static const double logoHeight = 40.0;
  static const double logoLeftPadding = 50.0; // Space for hamburger menu
  static const double logoTopPadding = 10.0;
  static const double logoBottomPadding = 0.0;
  static const double logoContainerMaxHeight = 45.0;
  static const Alignment logoAlignment = Alignment.centerLeft;
  static const String logoAssetPath = 'assets/data/images/LOGO.png';

  // Hamburger Menu Configuration
  static const double hamburgerLeftPadding = 8.0;
  static const double hamburgerTopPadding = 15.0;
  static const double hamburgerIconSize = 28.0;
  static const Color hamburgerIconColor = Colors.black87;

  // Connection Status Configuration
  static const double connectionStatusRightPadding = 15.0;
  static const double connectionStatusTopPadding = 18.0;
  static const double connectionCircleSize = 8.0;
  static const double connectionMaxCircleSize = 10.0;
  static const double connectionFontSize = 8.0;
  static const double connectionMaxFontSize = 12.0;
  static const Color connectionActiveColor = Colors.green;
  static const Color connectionInactiveColor = Colors.grey;

  // Drawer Configuration
  static const double drawerWidth = 280.0;
  static const double drawerHeaderHeight = 180.0;
  static const Color drawerHeaderColor = Color.fromARGB(255, 18, 148, 42);
  static const double drawerLogoSize = 60.0;
  static const double drawerTitleFontSize = 20.0;
  static const double drawerSubtitleFontSize = 14.0;

  // Helper method to get logo container widget (reusable across all pages)
  static Widget getLogoContainer({Widget? child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: logoLeftPadding,
        top: logoTopPadding,
        bottom: logoBottomPadding,
      ),
      constraints: const BoxConstraints(maxHeight: logoContainerMaxHeight),
      child: Align(
        alignment: logoAlignment,
        child:
            child ??
            Image.asset(
              logoAssetPath,
              width: logoWidth,
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: logoWidth,
                  height: logoHeight,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'DDS LOGO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  // Helper method to get header with hamburger, logo, and connection status
  static Widget getCompleteHeader({
    required bool isConnected,
    GlobalKey<ScaffoldState>? scaffoldKey,
  }) {
    return Container(
      color: Colors.white,
      height: 60, // Fixed height for consistent layout
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive sizes based on screen width
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 360;
          final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

          // Responsive logo size
          final responsiveLogoWidth = isSmallScreen
              ? 120.0
              : isMediumScreen
              ? 140.0
              : logoWidth;
          final responsiveLogoHeight = isSmallScreen
              ? 30.0
              : isMediumScreen
              ? 35.0
              : logoHeight;

          // Responsive connection status text
          final showFullConnectionText = screenWidth > 320;

          return Stack(
            children: [
              // Logo in the center-left with responsive sizing
              Positioned(
                left: 50, // Space for hamburger menu
                top: 0,
                bottom: 0,
                child: Center(
                  child: Image.asset(
                    logoAssetPath,
                    width: responsiveLogoWidth,
                    height: responsiveLogoHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: responsiveLogoWidth,
                        height: responsiveLogoHeight,
                        padding: const EdgeInsets.all(8),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            'DDS LOGO',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Hamburger menu on the left
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: hamburgerIconColor,
                      size: hamburgerIconSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Use scaffoldKey if provided, otherwise try to find Scaffold
                      if (scaffoldKey != null &&
                          scaffoldKey.currentState != null) {
                        scaffoldKey.currentState!.openDrawer();
                      } else {
                        // Fallback: try to find Scaffold in context
                        final scaffold = Scaffold.of(context);
                        scaffold.openDrawer();
                      }
                    },
                  ),
                ),
              ),
              // Connection status on the right with responsive layout
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isSmallScreen ? 6 : 8,
                        height: isSmallScreen ? 6 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? connectionActiveColor
                              : connectionInactiveColor,
                        ),
                      ),
                      if (showFullConnectionText) ...[
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'CONNECTED' : 'DISCONNECTED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: isSmallScreen ? 8 : 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============= END UI CONFIGURATION =============

  // Informasi umum sistem
  String projectName = '---PROJECT ID---';
  String panelType = '--- PANEL TYPE ---';
  int numberOfModules = 0; // Start with 0 to indicate not loaded
  int numberOfZones = 0; // Start with 0 to indicate not loaded from Firebase
  String activeZone = '';
  static const String systemVersion = '1.0.0';

  // Fonnte API configuration
  static const String fonnteToken = 'uK4BivaM3UDZN89kkS6A';
  static const String defaultTarget = '6281295865655'; // Default admin number
  static const String fonnteApiUrl = 'https://api.fonnte.com/send';

  // Recent activity and last update time
  String recentActivity = '';
  DateTime lastUpdateTime = DateTime.now();
  DateTime? lastSendTime;

  List<Map<String, dynamic>> activityLogs = [];

  // Firebase connectivity status
  bool isFirebaseConnected = false;

  // Enhanced notification service instance
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  // LED Status Decoder instance
  final LEDStatusDecoder _ledDecoder = LEDStatusDecoder();

  // Enhanced Zone Parser instance
  EnhancedZoneParser? enhancedParser;

  // Track all stream subscriptions for proper cleanup
  final List<StreamSubscription<DatabaseEvent>> _subscriptions = [];

  
  // Individual zone status map from Enhanced Zone Parser with memory management
  final Map<int, Map<String, dynamic>> _zoneStatus = {};
  static const int _maxZoneCacheSize = 1000; // Limit cache size to prevent memory leaks
  final List<int> _zoneAccessOrder = []; // Track access order for LRU eviction

  // 🏷️ MODULE NAMES SUPPORT
  // Module names cache with reactive state management
  final Map<String, String> _moduleNames = {};
  DatabaseReference? _moduleNamesRef;
  StreamSubscription<DatabaseEvent>? _moduleNamesSubscription;

  // 🎯 UNIFIED PARSER INTEGRATION
  UnifiedParsingResult? _lastUnifiedResult;
  DateTime? _lastUnifiedUpdateTime;
  final UnifiedFireAlarmParser _unifiedParser = UnifiedFireAlarmParser.instance;

  // WebSocket pending data storage for mode switching
  final List<String> _pendingWebSocketData = [];

  // WebSocket data state tracking
  bool _hasWebSocketData = false;

  // Zone data status tracking
  bool _hasValidZoneData = false;
  bool _hasNoParsedPacketData = true;
  bool _isInitiallyLoading = true;
  DateTime? _lastValidZoneDataTime;
  static const Duration _noZoneDataTimeout = Duration(seconds: 10);
  static const Duration _initialLoadingTimeout = Duration(seconds: 5);

  // System Status Extractor - Single Source of Truth
  extractor.SystemStatusData _currentSystemStatus = extractor.SystemStatusData.empty();

  // Periodic cleanup timer
  Timer? _cleanupTimer;

  FireAlarmData() {
    

    // 🔔 NEW: Initialize BellManager dependency
    _bellManager = getIt<BellManager>();

    // Initialize memory manager for automatic cleanup
    MemoryManager.initialize(
      cleanupInterval: Duration(minutes: 10), // Cleanup every 10 minutes
      maxMemoryUsage: 50 * 1024 * 1024, // 50MB threshold
    );

    // Initialize log handler
    _logHandler = FirebaseLogHandler();

    // 🚀 CRITICAL FIX: Initialize WebSocket Mode Manager with FireAlarmData reference
    
    _initializeWebSocketModeManager();

    // Don't initialize default modules here, wait for Firebase data
    _initializeFirebaseListeners();
    // Don't sync on startup, wait for Firebase data

    // After setting up listeners, try to fetch initial data
    _fetchInitialData();

    // 🔥 NEW: Connect LED decoder to Zone Parser (Path C) instead of Firebase (Path A & B)
    _connectLEDDecoderToZoneParser();

    // 🏷️ Initialize module names listener
    _initializeModuleNamesListener();

    // Start periodic cleanup timer (every 30 minutes)
    _cleanupTimer = Timer.periodic(Duration(minutes: 30), (timer) {
      if (_mounted) {
        _performPeriodicCacheCleanup();
      }
    });

    // Set timer to end initial loading state
    Timer(_initialLoadingTimeout, () {
      if (_mounted && _isInitiallyLoading) {
        _isInitiallyLoading = false;
        _updateCurrentStatus();
        notifyListeners();
        
      }
    });

    
  }

  
  
  // Check for no zone data condition (called periodically)
  void checkNoZoneDataCondition() {
    try {
      if (_lastValidZoneDataTime == null) {
        // No valid zone data received since app start
        if (!_hasValidZoneData) {
          _hasValidZoneData = false;
          _updateCurrentStatus();
          notifyListeners();
          
        }
      } else {
        final timeSinceLastData = DateTime.now().difference(_lastValidZoneDataTime!);
        if (timeSinceLastData > _noZoneDataTimeout) {
          // More than 10 seconds since last valid zone data
          if (_hasValidZoneData) {
            _hasValidZoneData = false;
            _updateCurrentStatus();
            notifyListeners();
            
          }
        } else if (!_hasValidZoneData && timeSinceLastData <= _noZoneDataTimeout) {
          // We had no zone data but now data is within timeout
          _hasValidZoneData = true;
          _hasNoParsedPacketData = false;
          _updateCurrentStatus();
          notifyListeners();

        }
      }
    } catch (e) {
      AppLogger.error('Error checking no zone data condition', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  // Fetch initial data from Firebase with cache fallback
  void _fetchInitialData() async {
    try {
      bool dataFromFirebase = false;

      // Try to get cached data first
      final cachedModules = await ProjectInfoCacheService.getCachedNumberOfModules();
      final cachedZones = await ProjectInfoCacheService.getCachedNumberOfZones();

      // Load cached data if available
      if (cachedModules != null && cachedZones != null) {
        numberOfModules = cachedModules;
        numberOfZones = cachedZones;
        AppLogger.info(
          'Loaded projectInfo from cache',
          tag: 'FIRE_ALARM_DATA',
        );
      }

      // Try projectInfo from Firebase
      final projectSnapshot = await _databaseRef.child('projectInfo').get();
      if (projectSnapshot.exists) {
        final data = projectSnapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          bool updatedProjectInfo = false;

          // Update if projectInfo has values
          if (data.containsKey('numberOfModules')) {
            final firebaseModules = data['numberOfModules'] as int;
            if (firebaseModules != numberOfModules) {
              numberOfModules = firebaseModules;
              updatedProjectInfo = true;
            }
          }
          if (data.containsKey('numberOfZones')) {
            final firebaseZones = data['numberOfZones'] as int;
            if (firebaseZones != numberOfZones) {
              numberOfZones = firebaseZones;
              updatedProjectInfo = true;
            }
          }
          if (data.containsKey('projectName')) {
            projectName = data['projectName'] as String;
          }
          if (data.containsKey('panelType')) {
            panelType = data['panelType'] as String;
          }
          if (data.containsKey('activeZone')) {
            activeZone = data['activeZone'] as String? ?? '';
          }
          if (data.containsKey('lastUpdateTime')) {
            try {
              String updateTime = data['lastUpdateTime'] as String;
              if (updateTime.length > 20) {
                updateTime = '${updateTime.substring(0, 23)}Z';
              }
              lastUpdateTime = DateTime.parse(updateTime);
            } catch (e) {
              // Invalid date - use current time
              lastUpdateTime = DateTime.now();
            }
          }

          // Save updated projectInfo to cache if changed
          if (updatedProjectInfo) {
            await ProjectInfoCacheService.saveProjectInfoData(
              numberOfModules: numberOfModules,
              numberOfZones: numberOfZones,
            );
            AppLogger.info(
              'Updated projectInfo cache from Firebase',
              tag: 'FIRE_ALARM_DATA',
            );
          }

          dataFromFirebase = true;
        }
      }

      // Generate modules if we have numberOfModules
      if (numberOfModules > 0) {
        _parseActiveZoneToModules(activeZone);
      }

      // Check if we have activity logs, if not, create sample data
      await _fetchActivityLogs();

      // Log data source
      if (dataFromFirebase) {
        AppLogger.info('ProjectInfo loaded from Firebase', tag: 'FIRE_ALARM_DATA');
      } else if (cachedModules != null && cachedZones != null) {
        AppLogger.info('Using cached ProjectInfo (Firebase unavailable)', tag: 'FIRE_ALARM_DATA');
      } else {
        AppLogger.warning('No ProjectInfo data available (cache or Firebase)', tag: 'FIRE_ALARM_DATA');
      }

      notifyListeners();
    } catch (e) {
      AppLogger.error(
        'Error fetching initial data',
        tag: 'FIRE_ALARM_DATA',
        error: e,
      );
    }
  }

  // Fetch activity logs and create sample data if needed
  Future<void> _fetchActivityLogs() async {
    try {
      final logsSnapshot = await _databaseRef.child('history/statusLogs').get();
      if (!logsSnapshot.exists || logsSnapshot.value == null) {
        
        await _createSampleActivityLogs();
      }
    } catch (e) {
      AppLogger.error('Error checking activity logs', error: e, tag: 'FIRE_ALARM_DATA');
      await _createSampleActivityLogs();
    }
  }

  // Create sample activity logs for testing
  Future<void> _createSampleActivityLogs() async {
    try {
      final now = DateTime.now();
      final sampleLogs = [
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 2))),
          'time': '10:30',
          'status': 'SYSTEM RESET',
          'user': 'Admin',
          'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1))),
          'time': '14:15',
          'status': 'DRILL ON',
          'user': 'User1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1))),
          'time': '14:20',
          'status': 'DRILL OFF',
          'user': 'User1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now),
          'time': '09:00',
          'status': 'ALARM ON',
          'user': 'System',
          'timestamp': now.toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now),
          'time': '09:05',
          'status': 'ACKNOWLEDGE ON',
          'user': 'User2',
          'timestamp': now.toIso8601String(),
        },
      ];

      // Write sample logs to Firebase
      for (var log in sampleLogs) {
        await _databaseRef.child('history/statusLogs').push().set(log);
      }


    } catch (e) {
      AppLogger.error('Error creating sample activity logs', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  void _initializeFirebaseListeners() {
    // 🚀 MODE-AWARE: Only listen to Firebase if we're in Firebase mode
    // Listen for Firebase connection status
    final connectionSubscription = _databaseRef.child('.info/connected').onValue.listen((event) {
      // 🚀 MODE CHECK: Skip Firebase updates when in WebSocket mode
      if (!isFirebaseMode) {
        
        return;
      }

      

      final connected = event.snapshot.value as bool? ?? false;
      if (isFirebaseConnected != connected) {
        isFirebaseConnected = connected;

        // Log connection status changes
        if (connected) {
          _logHandler.addConnectionLog(information: 'Firebase Connected');
          _logHandler.addStatusLog(status: 'SYSTEM ONLINE', user: 'SYSTEM');
        } else {
          _logHandler.addConnectionLog(information: 'Firebase Disconnected');
          _logHandler.addStatusLog(status: 'SYSTEM OFFLINE', user: 'SYSTEM');
        }

        notifyListeners();
      }
    });
    _subscriptions.add(connectionSubscription);

    // 🔥 REMOVED: systemStatus listener (Path A & B - OBSOLETE)
    // System status now comes exclusively from Path C (all_slave_data/raw_data)
    // through Enhanced Zone Parser with AABBCC algorithm
    

    // Listen for recent activity changes from Firebase
    final recentActivitySubscription = _databaseRef.child('recentActivity').onValue.listen((event) {
      // 🚀 MODE CHECK: Skip Firebase updates when in WebSocket mode
      if (!isFirebaseMode) {
        
        return;
      }

      final value = event.snapshot.value as String?;
      if (value != null && value != recentActivity) {
        recentActivity = value;
        notifyListeners();
      }
    });
    _subscriptions.add(recentActivitySubscription);

    // 🎯 NEW: Listen for raw zone data using Unified Parser
    final rawDataSubscription = _databaseRef.child('all_slave_data/raw_data').onValue.listen((event) {
      // 🚀 MODE CHECK: Skip Firebase raw data updates when in WebSocket mode
      if (!isFirebaseMode) {
        
        return;
      }

      

      final rawData = event.snapshot.value?.toString();
      if (rawData != null && rawData.isNotEmpty) {
        
        
        

        // Check for specific trouble data pattern
        if (rawData.contains('010100')) {
          
        }
        if (rawData.contains('41DF')) {
          
        }

        // Use unified parser as primary method
        
        _processRawDataWithUnifiedParser(rawData);
        
      } else {
        
      }
    });
    _subscriptions.add(rawDataSubscription);

    // Listen for projectInfo changes from Firebase (including activeZone, numberOfModules, numberOfZones, projectName, panelType, lastUpdateTime)
    final projectInfoSubscription = _databaseRef.child('projectInfo').onValue.listen((event) {
      // 🚀 MODE CHECK: Skip Firebase projectInfo updates when in WebSocket mode
      if (!isFirebaseMode) {
        
        return;
      }

      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        isFirebaseConnected = true;
        bool updated = false;
        bool modulesNeedUpdate = false;

        // Update projectName
        if (data.containsKey('projectName') &&
            projectName != data['projectName']) {
          projectName = data['projectName'];
          updated = true;
        }

        // Update panelType
        if (data.containsKey('panelType') && panelType != data['panelType']) {
          panelType = data['panelType'];
          updated = true;
        }

        // Update numberOfModules if present
        if (data.containsKey('numberOfModules')) {
          int newNumberOfModules = data['numberOfModules'] as int;
          if (numberOfModules != newNumberOfModules) {
            numberOfModules = newNumberOfModules;
            modulesNeedUpdate = true;
            updated = true;
          }
        }

        // Update numberOfZones if present
        if (data.containsKey('numberOfZones')) {
          int newNumberOfZones = data['numberOfZones'] as int;
          if (numberOfZones != newNumberOfZones) {
            numberOfZones = newNumberOfZones;
            updated = true;
          }
        }

        // Update lastUpdateTime if present
        if (data.containsKey('lastUpdateTime')) {
          try {
            String updateTime = data['lastUpdateTime'] as String;
            if (updateTime.length > 20) {
              updateTime = '${updateTime.substring(0, 23)}Z';
            }
            DateTime newLastUpdateTime = DateTime.parse(updateTime);
            if (lastUpdateTime != newLastUpdateTime) {
              lastUpdateTime = newLastUpdateTime;
              updated = true;
            }
          } catch (e) {
            // Invalid date - skip update
          }
        }

        // Update activeZone and parse modules
        if (data.containsKey('activeZone')) {
          String newActiveZone = data['activeZone'] as String? ?? '';
          if (activeZone != newActiveZone || modulesNeedUpdate) {
            activeZone = newActiveZone;
            _parseActiveZoneToModules(activeZone);
            updated = true;
          }
        } else {
          // No activeZone in Firebase, generate default modules if numberOfModules is set
          if (numberOfModules > 0 && (modules.isEmpty || modulesNeedUpdate)) {
            activeZone = '';
            _parseActiveZoneToModules('');
            updated = true;
          }
        }

        if (updated) {
          // Save updated projectInfo to cache
          _saveProjectInfoToCache();
          notifyListeners();
        }
      } else {
        isFirebaseConnected = false;
        // Don't reset numberOfModules and numberOfZones when no Firebase data
        // This allows cache data to persist in WebSocket mode
        projectName = '---PROJECT ID---';
        panelType = '--- PANEL TYPE ---';
        activeZone = '';

        // Only clear modules if we don't have cached data
        if (numberOfModules == 0) {
          modules = [];
        }

        notifyListeners();
      }
    });
    _subscriptions.add(projectInfoSubscription);

    // Listen for history/statusLogs changes from Firebase - Optimized
    final historySubscription = _databaseRef.child('history/statusLogs').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        // Limit processing to prevent UI blocking with large datasets
        const int maxLogsToProcess = 1000;
        int processedCount = 0;

        // Optimized: Use map comprehension for faster processing
        final logs = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          if (processedCount >= maxLogsToProcess) return;

          final action = value['status'] as String? ?? '';
          // Skip WhatsApp notification logs early
          if (action.contains('WhatsApp notification sent')) {
            return;
          }

          final user = value['user']?.toString() ?? '';
          var date = value['date'] as String? ?? '';
          var time = value['time'] as String? ?? '';

          // Optimized: Only parse timestamp if needed
          if (date.isEmpty || time.isEmpty) {
            final timestamp = value['timestamp'] as String?;
            if (timestamp?.isNotEmpty == true) {
              try {
                // Handle large timestamps from Firebase
                String ts = timestamp!;
                if (ts.length > 20) {
                  // If timestamp is too long, it might be microseconds, truncate it
                  ts = '${ts.substring(0, 23)}Z';
                }
                final dt = DateTime.parse(ts);
                date = DateFormat('dd/MM/yyyy').format(dt);
                time = DateFormat('HH:mm').format(dt);
              } catch (e) {
                // Use default values if parsing fails
                
                date = '';
                time = '';
              }
            }
          }

          if (action.isNotEmpty) {
            final timestampStr = (date.isNotEmpty && time.isNotEmpty)
                ? '$date | $time'
                : '';
            final fullActivity = user.isNotEmpty
                ? '[$timestampStr] $action | [ $user ]'
                : '[$timestampStr] $action';

            logs.add({
              'key': key,
              'activity': fullActivity,
              'time': time,
              'date': date,
              'timestamp': value['timestamp'] ?? '',
            });
            processedCount++;
          }
        });

        // Optimized: Sort only if we have logs and limit to recent entries
        if (logs.isNotEmpty) {
          logs.sort((a, b) {
            try {
              String tsA = a['timestamp'] as String;
              String tsB = b['timestamp'] as String;

              // Handle long timestamps
              if (tsA.length > 20) {
                tsA = '${tsA.substring(0, 23)}Z';
              }
              if (tsB.length > 20) {
                tsB = '${tsB.substring(0, 23)}Z';
              }

              return DateTime.parse(tsB).compareTo(DateTime.parse(tsA));
            } catch (e) {
              return 0;
            }
          });

          // Keep only the most recent 500 logs to prevent memory issues
          if (logs.length > 500) {
            logs.removeRange(500, logs.length);
          }
        }

        activityLogs = logs;
        // Optimized: Minimal debug logging
        if (logs.length % 100 == 0) { // Log every 100 entries to reduce spam
          
        }
        notifyListeners();
      } else {
        activityLogs = [];
        notifyListeners();
      }
    });
    _subscriptions.add(historySubscription);
  }

  // 🔥 REMOVED: systemStatus map (OBSOLETE - causes fallback to wrong data)
  // All status indicators now use:
  // 1. Master Status Data (Priority 1: AABBCC algorithm from "41FF", "42BD", etc.)
  // 2. LED Decoder Data (Priority 2: Derived from master status)
  // 3. Simple Status Manager (Priority 3: Zone counts only for Alarm/Trouble)
  // NO FALLBACK TO HARDCODED VALUES!

  // Status indicators are determined by:
  // - AC Power: masterStatusData.acPowerOn (from "41FF" status byte)
  // - DC Power: masterStatusData.dcPowerOn (from "41FF" status byte)
  // - Alarm/Trouble: getSimpleHasAlarmZones() / getSimpleHasTroubleZones()
  // - Other: LED decoder from systemStatusData

  // Data untuk daftar modul dengan 6 zona (5 zona biasa + 1 zona bell)
  List<Map<String, dynamic>> modules = [];

  // Parse activeZone string to modules list
  void _parseActiveZoneToModules(String activeZoneString) {
    // Only generate modules if numberOfModules is greater than 0
    if (numberOfModules <= 0) {
      modules = [];
      return;
    }

    if (activeZoneString.trim().isEmpty) {
      // Generate default modules with ZONA 01, ZONA 02, etc.
      List<Map<String, dynamic>> defaultModules = [];
      int zoneCode = 1;
      for (int i = 1; i <= numberOfModules; i++) {
        List<String> zones = [];
        for (int j = 0; j < 5; j++) {
          String code = zoneCode.toString().padLeft(2, '0');
          zones.add('ZONA $code');
          zoneCode++;
        }
        zones.add('BELL');
        defaultModules.add({
          'number': i.toString().padLeft(2, '0'),
          'zones': zones,
        });
      }
      modules = defaultModules;
      return;
    }

    // Parse activeZone string: "#001#AREA MAKAN, #002#AREA TIDUR, #003#AREA DAPUR, ..."
    List<String> zoneEntries = activeZoneString.split(',');
    Map<int, List<String>> moduleZonesMap = {};

    // First, organize zones by module number
    for (var entry in zoneEntries) {
      entry = entry.trim();
      if (entry.isEmpty) continue;

      // Extract zone code and name - support both 2 and 3 digit formats
      final match = RegExp(r'#(\d{2,3})#(.+)').firstMatch(entry);
      if (match != null) {
        final zoneCode = int.parse(match.group(1)!);
        final zoneName = match.group(2)!;

        // Calculate module number (5 zones per module)
        final moduleNumber = ((zoneCode - 1) ~/ 5 + 1);

        if (!moduleZonesMap.containsKey(moduleNumber)) {
          moduleZonesMap[moduleNumber] = [];
        }

        // Calculate position within module (0-4)
        final positionInModule = (zoneCode - 1) % 5;

        // Ensure list has enough space
        while (moduleZonesMap[moduleNumber]!.length <= positionInModule) {
          moduleZonesMap[moduleNumber]!.add('');
        }

        // Set zone name at correct position
        moduleZonesMap[moduleNumber]![positionInModule] = zoneName;
      }
    }

    // Build modules list with zones and add 'BELL' zone to each module
    List<Map<String, dynamic>> parsedModules = [];

    // Generate all modules from 1 to numberOfModules
    for (int i = 1; i <= numberOfModules; i++) {
      List<String> zones = moduleZonesMap[i] ?? [];

      // Fill empty positions with default zone names
      for (int j = 0; j < 5; j++) {
        if (j >= zones.length || zones[j].isEmpty) {
          if (j >= zones.length) {
            zones.add('');
          }
          int zoneNumber = (i - 1) * 5 + j + 1;
          zones[j] = 'Zone ${zoneNumber.toString().padLeft(2, '0')}';
        }
      }

      // Ensure exactly 5 zones
      zones = zones.take(5).toList();

      parsedModules.add({
        'number': i.toString().padLeft(2, '0'),
        'zones': [...zones, 'BELL'],
      });
    }

    if (parsedModules.isNotEmpty) {
      modules = parsedModules;
    }
  }

  // 🔥 REMOVED: updateSystemStatus method (OBSOLETE - uses systemStatus map)
  // Status updates now come from:
  // 1. Master Status Data (Priority 1: AABBCC algorithm from Path C)
  // 2. LED Decoder (Priority 2: Derived from master status)
  // 3. Simple Status Manager (Priority 3: Zone counts only)
  // Local status updates should use direct LED decoder or simple status manager

  
  // 🔥 REMOVED: _logStatusChange method (OBSOLETE - was used by removed updateSystemStatus)
  // Status logging is now handled by individual services (Button Action Service, etc.)
  // System status changes are logged through proper service channels

  // Log module connections
  void logModuleConnection(int moduleNumber, bool connected) {
    String information = connected
        ? 'Module #${moduleNumber.toString().padLeft(2, '0')} Connected'
        : 'Module #${moduleNumber.toString().padLeft(2, '0')} Disconnected';

    _logHandler.addConnectionLog(information: information);
  }

  // Metode untuk update recent activity
  void updateRecentActivity(String activity, {String? user}) {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('dd/MM/yyyy | HH:mm').format(now);
    final fullActivity = user != null ? '[$formattedDateTime] $activity | ($user)' : '[$formattedDateTime] $activity';
    recentActivity = fullActivity;
    lastUpdateTime = now;
    notifyListeners();
    // Sync to Firebase
    _databaseRef.child('recentActivity').set(fullActivity);
    _databaseRef
        .child('projectInfo/lastUpdateTime')
        .set(lastUpdateTime.toIso8601String());
    // Log to history if user provided
    if (user != null) {
      logHistory(activity, user);
    }
  }

  // Method to log history to Firebase
  void logHistory(String status, String user) {
    final now = DateTime.now();
    final date = DateFormat('dd/MM/yyyy').format(now);
    final time = DateFormat('HH:mm').format(now);
    final timestamp = now.toIso8601String(); // For sorting
    _databaseRef.child('history/statusLogs').push().set({
      'date': date,
      'time': time,
      'status': status,
      'user': user,
      'timestamp': timestamp,
    });
  }

  // Metode untuk mendapatkan status sistem (SINGLE SOURCE OF TRUTH)
  // Aggressive caching and rate limiting to prevent infinite loop
  static final Map<String, bool> _statusCache = {};
  static final Map<String, DateTime> _lastCallTime = {};
  static int _callCount = 0;
  static Timer? _resetTimer;

  bool getSystemStatus(String statusName) {
    // 🚀 MODE-AWARE PRIORITY CHECK
    // 🔥 FIXED: Prioritize LED decoder data over UnifiedParsingResult in WebSocket mode
    // LED decoder has the correct master status from WebSocket extraction
    if (isWebSocketMode && hasLEDDecoderData &&
        ['AC Power', 'DC Power', 'Alarm', 'Trouble', 'Drill', 'Silenced', 'Disabled'].contains(statusName)) {
      final ledStatus = _ledDecoder.currentLEDStatus;
      if (ledStatus != null) {
        switch (statusName) {
          case 'AC Power':
            return ledStatus.ledStatus.acPowerOn;
          case 'DC Power':
            return ledStatus.ledStatus.dcPowerOn;
          case 'Alarm':
            return ledStatus.ledStatus.alarmOn;
          case 'Trouble':
            return ledStatus.ledStatus.troubleOn;
          case 'Drill':
            return ledStatus.ledStatus.drillOn;
          case 'Silenced':
            return ledStatus.ledStatus.silencedOn;
          case 'Disabled':
            return ledStatus.ledStatus.disabledOn;
        }
      }
    }

    // Fallback to original logic if LED decoder not available
    if (isWebSocketMode && _hasWebSocketData && _lastUnifiedResult != null) {
      final result = _lastUnifiedResult!;
      return _getWebSocketSystemStatus(statusName, result);
    }

    // AGGRESSIVE Rate limiting: prevent excessive calls
    _callCount++;
    _resetTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      _callCount = 0;
    });

    // If we've called this method more than 10 times in a second, return cached value immediately
    if (_callCount > 10) {
      return _statusCache[statusName] ?? false;
    }

    // AGGRESSIVE Debouncing: check if we recently called this method (500ms instead of 100ms)
    final now = DateTime.now();
    final lastCall = _lastCallTime[statusName];
    if (lastCall != null && now.difference(lastCall) < const Duration(milliseconds: 500)) {
      // Return cached value immediately to prevent infinite loop
      return _statusCache[statusName] ?? false;
    }

    _lastCallTime[statusName] = now;

    try {
      // Priority 1: Use LED Decoder data for ALL 7 LED indicators (Path C - AABBCC Algorithm)
      // 🔥 FIXED: Include 'Alarm' and 'Trouble' for complete LED independence!
      if (['AC Power', 'DC Power', 'Alarm', 'Trouble', 'Drill', 'Silenced', 'Disabled'].contains(statusName)) {
        if (hasLEDDecoderData) {
          final ledStatus = _ledDecoder.currentLEDStatus;
          if (ledStatus != null) {
            bool? ledFlagStatus;
            switch (statusName) {
              case 'AC Power':
                ledFlagStatus = ledStatus.ledStatus.acPowerOn;
                break;
              case 'DC Power':
                ledFlagStatus = ledStatus.ledStatus.dcPowerOn;
                break;
              case 'Alarm':
                ledFlagStatus = ledStatus.ledStatus.alarmOn; // 🔥 FIXED: Use master status for Alarm LED!
                break;
              case 'Trouble':
                ledFlagStatus = ledStatus.ledStatus.troubleOn; // 🔥 FIXED: Use master status for Trouble LED!
                break;
              case 'Drill':
                ledFlagStatus = ledStatus.ledStatus.drillOn; // 🔥 FIXED: Drill uses dedicated bit 2
                break;
              case 'Silenced':
                ledFlagStatus = ledStatus.ledStatus.silencedOn;
                break;
                            case 'Disabled':
                ledFlagStatus = ledStatus.ledStatus.disabledOn;
                break;
            }
            if (ledFlagStatus != null) {
              // Cache the result and return
              _statusCache[statusName] = ledFlagStatus;
              // DISABLE debug logging to prevent infinite loop spam
              // Temporarily disabled: if (kDebugMode && _callCount % 10 == 0) {
              //   
              // }
              return ledFlagStatus;
            }
          }
        }
        // Fallback to SystemStatusData if LED decoder not available
        final statusFromExtractor = _currentSystemStatus.systemFlags[statusName];
        if (statusFromExtractor != null) {
          _statusCache[statusName] = statusFromExtractor;
          // DISABLE debug logging to prevent infinite loop spam
          return statusFromExtractor;
        }
      }

      // Special case: For testing LED decoder data when available
      if (statusName == 'Trouble' && hasLEDDecoderData) {
        final ledStatus = _ledDecoder.currentLEDStatus;
        if (ledStatus != null) {
          bool ledTrouble = ledStatus.ledStatus.troubleOn;
          _statusCache[statusName] = ledTrouble;
          // DISABLE debug logging to prevent infinite loop spam
          return ledTrouble;
        }
      }

      // 🔥 REMOVED: Zone data check for Alarm/Trouble (VIOLATED INDEPENDENCE!)
      // LED indicators must be 100% independent from zone/module data
      // All 7 indicators (AC Power, DC Power, Alarm, Trouble, Supervisory, Silenced, Disabled)
      // should ONLY come from master status data via LED decoder

      // Priority 3: Use SystemStatusData for other status types
      final statusFromExtractor = _currentSystemStatus.systemFlags[statusName];
      if (statusFromExtractor != null) {
        _statusCache[statusName] = statusFromExtractor;
        // DISABLE debug logging to prevent infinite loop spam
        return statusFromExtractor;
      }

      // 🔥 REMOVED: systemStatus fallback (OBSOLETE - was causing incorrect LED states)
      // No more fallbacks! If not found in SystemStatusData, use LED decoder or Simple Status Manager
      // DISABLE debug logging to prevent infinite loop spam

      // Use LED decoder as final fallback (for AC/DC power indicators)
      bool fallbackResult = false;
      switch (statusName) {
        case 'AC Power':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.acPowerOn ?? false;
          break;
        case 'DC Power':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.dcPowerOn ?? false;
          break;
        case 'Alarm':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.alarmOn ?? false;
          break;
        case 'Trouble':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.troubleOn ?? false;
          break;
        case 'Silenced':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.silencedOn ?? false;
          break;
        case 'Disabled':
          fallbackResult = _ledDecoder.currentLEDStatus?.ledStatus.disabledOn ?? false;
          break;
        default:
          fallbackResult = false;
      }

      // Cache the fallback result
      _statusCache[statusName] = fallbackResult;
      return fallbackResult;

    } catch (e) {
      
      return false;
    }
  }

  /// Get system status from WebSocket data (Unified Parsing Result)
  bool _getWebSocketSystemStatus(String statusName, UnifiedParsingResult result) {
    try {
      // Use the unified parsing result's system status
      final systemStatus = result.systemStatus;

      switch (statusName) {
        case 'AC Power':
          return systemStatus.hasPower;
        case 'DC Power':
          return systemStatus.hasPower; // Use same power status for both AC/DC
        case 'Alarm':
          return systemStatus.hasAlarm;
        case 'Trouble':
          return systemStatus.hasTrouble;
        case 'Drill':
          return systemStatus.isDrill;
        case 'Silenced':
          return systemStatus.isSilenced;
        case 'Disabled':
          return systemStatus.isDisabled;
        default:
          
          return false;
      }
    } catch (e) {
      
      return false;
    }
  }

  // Metode untuk mendapatkan warna status aktif (UNIFIED with getSystemStatus logic)
  Color getActiveColor(String statusName) {
    try {
      // Use the same logic as getSystemStatus to ensure color consistency
      bool isActive = getSystemStatus(statusName);

      if (isActive) {
        // Return correct active colors based on status type
        switch (statusName) {
          case 'AC Power':
          case 'DC Power':
            return Colors.green; // Power indicators use green when active
          case 'Alarm':
            return Colors.red; // Alarm uses red when active
          case 'Trouble':
            return Colors.orange; // Trouble uses orange when active
          case 'Drill':
            return Colors.red; // Drill uses red when active
          case 'Silenced':
            return Colors.yellow.shade700; // Silenced uses yellow when active
          case 'Disabled':
            return Colors.yellow.shade700; // Disabled uses yellow when active (same as Silenced)
          default:
            return Colors.grey; // Default fallback
        }
      } else {
        // Return inactive colors (grey shades)
        switch (statusName) {
          case 'AC Power':
          case 'DC Power':
          case 'Alarm':
          case 'Trouble':
          case 'Drill':
          case 'Silenced':
          case 'Disabled':
            return Colors.grey.shade300; // Standard inactive grey
          default:
            return Colors.grey; // Default fallback
        }
      }
    } catch (e) {
      
      return Colors.grey;
    }
  }

  // Metode untuk mendapatkan warna status tidak aktif (UNIFIED with getActiveColor logic)
  Color getInactiveColor(String statusName) {
    try {
      // Return consistent inactive colors
      switch (statusName) {
        case 'AC Power':
        case 'DC Power':
        case 'Alarm':
        case 'Trouble':
        case 'Drill':
        case 'Silenced':
        case 'Disabled':
          return Colors.grey.shade300; // Standard inactive grey
        default:
          return Colors.grey; // Default fallback
      }
    } catch (e) {
      
      return Colors.grey.shade300;
    }
  }

  // New properties for current status text and color
  String _currentStatusText = 'NO DATA';
  Color _currentStatusColor = Colors.grey;

  bool _isResetting = false;

  bool get isResetting => _isResetting;

  set isResetting(bool value) {
    _isResetting = value;
    _updateCurrentStatus();
    notifyListeners();
  }

  String get currentStatusText => _currentStatusText;
  Color get currentStatusColor => _currentStatusColor;

  // Getters for zone data status
  bool get hasValidZoneData => _hasValidZoneData;
  bool get hasNoParsedPacketData => _hasNoParsedPacketData;
  bool get isInitiallyLoading => _isInitiallyLoading;

  // 🚀 NEW: Mode-aware getters for WebSocket/Firebase switching
  bool get isWebSocketMode => WebSocketModeManager.instance.isWebSocketMode;
  bool get isFirebaseMode => WebSocketModeManager.instance.isFirebaseMode;
  bool get isWebSocketConnecting => WebSocketModeManager.instance.isConnecting;
  bool get isWebSocketConnected => WebSocketModeManager.instance.isConnected;
  String get currentMode => isWebSocketMode ? 'WebSocket' : 'Firebase';
  String get webSocketError => WebSocketModeManager.instance.lastError ?? '';

  // Getter untuk external access to mode manager (singleton instance)
  WebSocketModeManager get modeManager => WebSocketModeManager.instance;

  // Getter dan method untuk pending WebSocket data (for mode manager access)
  List<String> get pendingWebSocketData => _pendingWebSocketData;

  /// Clear pending WebSocket data
  void clearPendingWebSocketData() => _pendingWebSocketData.clear();

  // Static getter untuk singleton instance
  static WebSocketModeManager get modeManagerInstance => WebSocketModeManager.instance;

  // 🎯 NEW: Simple Count-Based Status Manager (Your Exact 4 Rules)
  String get simpleStatusText => _simpleStatusManager.getStatus();
  String get simpleStatusColor => _simpleStatusManager.getColor();
  bool get needsAttention => _simpleStatusManager.getStatus() == 'ALARM' || _simpleStatusManager.getStatus() == 'SYSTEM TROUBLE';

  // Simple count getters
  int get alarmCount => _simpleStatusManager.alarmCount;
  int get troubleCount => _simpleStatusManager.troubleCount;
  bool get hasData => _simpleStatusManager.hasData;

  /// 🔥 NEW: LED-based status methods for UI (WebSocket mode) + Firebase mode compatibility
  String getSimpleSystemStatusWithDetection() {
    // 🚀 MODE CHECK: Use LED status in WebSocket mode, SimpleStatusManager in Firebase mode
    if (WebSocketModeManager.instance.isWebSocketMode) {
      

      // Get current LED states from LED decoder
      final currentAlarmLED = getSystemStatus('Alarm');
      final currentTroubleLED = getSystemStatus('Trouble');
      final currentDrillLED = getSystemStatus('Drill');

      // Apply 7-second persistence for trouble LED blinking
      final persistentAlarm = _ledPersistence.getAlarmStatus(currentAlarmLED);
      final persistentTrouble = _ledPersistence.getTroubleStatus(currentTroubleLED);

      

      // 🔥 NEW: Priority logic: Drill (ALARM DRILL) > Alarm > Trouble > Normal
      if (currentDrillLED) {
        return 'ALARM DRILL';  // Show ALARM DRILL when drill LED is ON
      }

      if (persistentAlarm) {
        return 'ALARM';
      }

      if (persistentTrouble) {
        return 'SYSTEM TROUBLE';
      }

      // If no alarm/trouble, check if we have any data (to distinguish between NORMAL and NO DATA)
      if (_hasWebSocketData || isWebSocketMode) {
        return 'SYSTEM NORMAL';
      } else {
        return 'NO DATA';
      }
    }

    // Firebase mode: use existing SimpleStatusManager logic
    
    return _simpleStatusManager.getStatus();
  }

  Color getSimpleSystemStatusColorWithDetection() {
    final status = getSimpleSystemStatusWithDetection();

    // Consistent color mapping regardless of mode
    switch (status) {
      case 'ALARM':
        return Colors.red;
      case 'ALARM DRILL':
        return Colors.red;  // Same red color as ALARM
      case 'SYSTEM TROUBLE':
        return Colors.orange;
      case 'SYSTEM NORMAL':
        return Colors.green;
      case 'NO DATA':
        return Colors.grey;
      default:
        return Colors.blue; // Fallback
    }
  }

  /// Simple trouble detection using count logic
  bool getSimpleHasTroubleZones() {
    
    return _simpleStatusManager.troubleCount > 0;
  }

  bool getSimpleHasAlarmZones() {
    
    return _simpleStatusManager.alarmCount > 0;
  }

  /// Update simple status from parsing results
  void _updateSimpleStatusFromParsing({
    required int alarmZones,
    required int troubleZones,
    required bool hasFirebaseData,
    required int activeZonesCount,
  }) {
    _simpleStatusManager.updateCounts(
      alarmCount: alarmZones,
      troubleCount: troubleZones,
      hasData: hasFirebaseData,
      hasActiveZones: activeZonesCount > 0, // 🎯 Check if any zones are active/online
    );

    // 🔄 NEW: Update accumulated counts from zone accumulator
    _simpleStatusManager.updateAccumulatedCounts(
      accumulatedAlarmCount: _zoneAccumulator.accumulatedAlarmCount,
      accumulatedTroubleCount: _zoneAccumulator.accumulatedTroubleCount,
      isAccumulationMode: _zoneAccumulator.isAccumulationMode,
    );

    // 🔔 NEW: Update bell accumulated counts from bell accumulator (SAME AS ZONE)
    _simpleStatusManager.updateBellAccumulatedCounts(
      accumulatedBellCount: _bellAccumulator.accumulatedBellCount,
      isBellAccumulationMode: _bellAccumulator.isAccumulationMode,
    );

    
    
  }

  // ============= MEMORY MANAGEMENT FOR ZONE STATUS CACHE =============

  /// Update zone status with LRU cache management
  void _updateZoneStatusInCache(int zoneNumber, Map<String, dynamic> statusData) {
    // Remove from access order if already exists
    _zoneAccessOrder.remove(zoneNumber);

    // Add to end of access order (most recently used)
    _zoneAccessOrder.add(zoneNumber);

    // Update cache
    _zoneStatus[zoneNumber] = statusData;

    // Evict oldest entries if cache is full
    if (_zoneStatus.length > _maxZoneCacheSize) {
      _evictOldestZoneEntries();
    }
  }

  /// Evict oldest zone entries to maintain cache size
  void _evictOldestZoneEntries() {
    final int evictionCount = _zoneStatus.length - _maxZoneCacheSize;

    for (int i = 0; i < evictionCount && _zoneAccessOrder.isNotEmpty; i++) {
      final oldestZone = _zoneAccessOrder.removeAt(0);
      _zoneStatus.remove(oldestZone);
    }

    
  }

  /// Get zone status with LRU access tracking
  Map<String, dynamic>? getZoneStatusFromCache(int zoneNumber) {
    final status = _zoneStatus[zoneNumber];
    if (status != null) {
      // Move to end of access order (most recently used)
      _zoneAccessOrder.remove(zoneNumber);
      _zoneAccessOrder.add(zoneNumber);
    }
    return status;
  }

  /// Clear zone status cache
  void _clearZoneStatusCache() {
    _zoneStatus.clear();
    _zoneAccessOrder.clear();
    
  }

  /// Periodic cleanup of zone status cache
  void _performPeriodicCacheCleanup() {
    // Remove entries older than 1 hour
    final now = DateTime.now();
    final List<int> expiredZones = [];

    for (final entry in _zoneStatus.entries) {
      final timestamp = entry.value['timestamp'] as String?;
      if (timestamp != null) {
        try {
          final updateTime = DateTime.parse(timestamp);
          if (now.difference(updateTime).inHours > 1) {
            expiredZones.add(entry.key);
          }
        } catch (e) {
          // Invalid timestamp, mark for removal
          expiredZones.add(entry.key);
        }
      }
    }

    // Remove expired zones
    for (final zone in expiredZones) {
      _zoneStatus.remove(zone);
      _zoneAccessOrder.remove(zone);
    }

    if (expiredZones.isNotEmpty) {
      
    }
  }

  // Private method to update current status text and color based on systemStatus and zone data
  void _updateCurrentStatus() {
    try {
      

      // Check for system resetting first (highest priority)
      if (_isResetting) {
        _currentStatusText = 'SYSTEM RESETTING';
        _currentStatusColor = Colors.white;
        
        return;
      }

      // Check for initial loading state (highest priority for status)
      if (_isInitiallyLoading) {
        _currentStatusText = 'LOADING DATA';
        _currentStatusColor = Colors.blue;
        
        return;
      }

    // Check for no valid zone data (highest priority for status)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      
      _currentStatusText = 'NO DATA';
      _currentStatusColor = Colors.grey;
      return;
    }
    
    // Check if we have any modules/zones configured
    if (modules.isEmpty && numberOfModules > 0) {
      _currentStatusText = 'SYSTEM CONFIGURING';
      _currentStatusColor = Colors.orange;
      return;
    }
    
    // Check for system statuses from Firebase - CORRECTED PRIORITY LOGIC
    

    // 🔥 REMOVED: Unused systemFlags and zone counts (OBSOLETE)
    // Simple Status Manager now handles all status determination directly
    final unifiedStatus = getSimpleSystemStatusWithDetection();

    _currentStatusText = unifiedStatus;
    _currentStatusColor = getSimpleSystemStatusColorWithDetection();

    

    // 🔥 REMOVED: SystemStatusUtils consistency validation (OBSOLETE)
    // Simple Status Manager is now the single source of truth

    

    // 🔔 NEW: Perform FORCE bell status check to sync with LED alarm
    forceResetBellStatusWhenLEDOff();

    } catch (e) {
      
      

      // Set fallback status to prevent system from being stuck
      _currentStatusText = 'SYSTEM ERROR';
      _currentStatusColor = Colors.red;
    }
  }

  // 🔔 NEW: Bell Confirmation Status Tracking (mengganti sistem lama)
  final Map<String, BellConfirmationStatus> _bellConfirmationStatus = {};

  // Method to check if there are any trouble zones in the system
  bool hasTroubleZones() {
    return getSystemStatus('Trouble');
  }

  // Method to check if there are any alarm zones in the system
  bool hasAlarmZones() {
    return getSystemStatus('Alarm');
  }

  // Method to get list of active alarm zones
  List<Map<String, dynamic>> getActiveAlarmZones() {
    List<Map<String, dynamic>> alarmZones = [];

    // 🔥 FIXED: Use parsed zones from Unified Parser result
    if (_lastUnifiedResult != null) {
      final alarmZoneStatuses = _lastUnifiedResult!.alarmZones;
      

      for (final zone in alarmZoneStatuses) {
        alarmZones.add({
          'zoneNumber': zone.zoneNumber,
          'area': zone.description.isNotEmpty ? zone.description : 'Zone ${zone.zoneNumber}',
          'timestamp': DateFormat('HH:mm:ss').format(zone.timestamp),
          'moduleNumber': zone.deviceNumber,
          'zoneInModule': zone.zoneInDevice,
          'status': zone.status,
          'deviceAddress': zone.deviceAddress,
        });
        
      }
    } else {
      
    }

    // Fallback: Check system status and create basic alarm zone entry if no parsed zones
    if (alarmZones.isEmpty && getSystemStatus('Alarm')) {
      
      alarmZones.add({
        'zoneNumber': 0, // System-wide alarm
        'area': 'SYSTEM ALARM',
        'timestamp': DateFormat('HH:mm:ss').format(DateTime.now()),
        'moduleNumber': 0,
        'zoneInModule': 0,
      });
    }

    
    return alarmZones;
  }

  // 🔔 NEW: Bell Confirmation Status Methods

  /// Get bell confirmation status untuk slave tertentu
  BellConfirmationStatus? getBellConfirmationStatus(String slaveAddress) {
    return _bellConfirmationStatus[slaveAddress];
  }

  /// Get semua active bell confirmations
  Map<String, BellConfirmationStatus> getActiveBellConfirmations() {
    return Map.fromEntries(
      _bellConfirmationStatus.entries.where((entry) => entry.value.isActive)
    );
  }

  /// Get semua inactive bell confirmations
  Map<String, BellConfirmationStatus> getInactiveBellConfirmations() {
    return Map.fromEntries(
      _bellConfirmationStatus.entries.where((entry) => !entry.value.isActive)
    );
  }

  /// Check apakah ada bell yang aktif ( menggunakan SimpleStatusManager seperti zone)
  bool hasActiveBells() {
    // Gunakan SimpleStatusManager untuk bell accumulation (SAMA seperti zone)
    return _simpleStatusManager.accumulatedBellCount > 0 ||
           _bellConfirmationStatus.values.any((status) => status.isActive);
  }

  /// Update bell confirmation status untuk slave tertentu
  void updateBellConfirmationStatus(String slaveAddress, bool isActive, {String? rawData}) {
    _bellConfirmationStatus[slaveAddress] = BellConfirmationStatus(
      slaveAddress: slaveAddress,
      isActive: isActive,
      timestamp: DateTime.now(),
      rawData: rawData,
    );
    
    notifyListeners();
  }

  /// 🔔 Process bell confirmation dari parser results dengan LED alarm logic
  void processBellConfirmations(Map<String, BellConfirmationStatus> bellConfirmations) {
    bool hasChanges = false;

    // Get current LED alarm status (master status)
    final bool isLEDAlarmOn = getSystemStatus('Alarm');
    

    for (final entry in bellConfirmations.entries) {
      final slaveAddress = entry.key;
      final newStatus = entry.value;

      // 🔔 RESET LOGIC: Check LED alarm status before processing bell confirmation
      if (!isLEDAlarmOn && newStatus.isActive) {
        // LED OFF tapi ada $85 (bell ON) → Jangan update UI bell
        
        continue; // Skip this entry
      }

      // Check if status has changed
      final currentStatus = _bellConfirmationStatus[slaveAddress];
      if (currentStatus == null || currentStatus.isActive != newStatus.isActive) {
        _bellConfirmationStatus[slaveAddress] = newStatus;
        hasChanges = true;
        
      }
    }

    // 🔔 ADDITIONAL RESET LOGIC: If LED OFF, check and reset bell status
    if (!isLEDAlarmOn) {
      _checkAndResetBellStatus();
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  /// 🔥 Force all bells ON for drill mode
  void forceAllBellsOnForDrill() {
    

    bool hasChanges = false;

    // Activate bells for all 63 devices (01-63)
    for (int i = 1; i <= 63; i++) {
      final slaveAddress = i.toString().padLeft(2, '0');
      final currentStatus = _bellConfirmationStatus[slaveAddress];

      // Only update if not already active
      if (currentStatus == null || !currentStatus.isActive) {
        _bellConfirmationStatus[slaveAddress] = BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: true,
          timestamp: DateTime.now(),
          rawData: 'DRILL_MODE_FORCED_ON',
        );
        hasChanges = true;
        
      }
    }

    if (hasChanges) {
      notifyListeners();
      
    }
  }

  /// 🔥 Disable all bells when drill mode ends
  void disableDrillModeBells() {
    

    bool hasChanges = false;

    // Disable bells for all 63 devices (01-63)
    for (int i = 1; i <= 63; i++) {
      final slaveAddress = i.toString().padLeft(2, '0');
      final currentStatus = _bellConfirmationStatus[slaveAddress];

      // Only reset drill-forced bells
      if (currentStatus?.rawData == 'DRILL_MODE_FORCED_ON') {
        _bellConfirmationStatus[slaveAddress] = BellConfirmationStatus(
          slaveAddress: slaveAddress,
          isActive: false, // Turn OFF
          timestamp: DateTime.now(),
          rawData: 'DRILL_MODE_FORCED_OFF',
        );
        hasChanges = true;
        
      }
    }

    if (hasChanges) {
      notifyListeners();
      
    } else {
      
    }
  }

  /// 🔥 Check and update drill mode bell status
  void updateDrillModeBellStatus() {
    try {
      // Safety check before performing drill operations
      if (!_isDrillModeOperationSafe()) {
        
        return;
      }

      if (shouldForceAllBellsOnInDrill) {
        forceAllBellsOnForDrill();
      } else {
        disableDrillModeBells(); // NEW: Clean up drill bells when drill ends
      }
    } catch (e) {
      AppLogger.error('Error updating drill mode bell status', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  /// 🔍 Check if drill mode operations are safe to perform
  bool _isDrillModeOperationSafe() {
    try {
      // Check if FireAlarmData is still mounted
      if (!_mounted) {
        
        return false;
      }

      // Check if LED decoder has valid data
      if (_ledDecoder.currentLEDStatus == null) {
        
        return false;
      }

      // Check if bell confirmation map is accessible
      if (_bellConfirmationStatus.isEmpty) {
        
        return false;
      }

      return true;
    } catch (e) {
      
      return false;
    }
  }

  /// Clear bell confirmation status untuk slave tertentu
  void clearBellConfirmationStatus(String slaveAddress) {
    if (_bellConfirmationStatus.remove(slaveAddress) != null) {
      
      notifyListeners();
    }
  }

  /// Clear semua bell confirmation status
  void clearAllBellConfirmationStatus() {
    if (_bellConfirmationStatus.isNotEmpty) {
      _bellConfirmationStatus.clear();

      notifyListeners();
    }
  }

  /// 🔔 Check and reset bell status based on LED alarm status
  void _checkAndResetBellStatus() {
    // Double-check LED alarm status
    final bool isLEDAlarmOn = getSystemStatus('Alarm');

    if (isLEDAlarmOn) {
      
      return; // LED ON, jangan reset bell status
    }

    // LED OFF - reset all bell containers ke default
    bool hasActiveBells = false;
    for (final entry in _bellConfirmationStatus.entries) {
      if (entry.value.isActive) {
        hasActiveBells = true;
        break;
      }
    }

    if (hasActiveBells) {
      

      // Reset semua bell status ke inactive (OFF)
      for (final slaveAddress in _bellConfirmationStatus.keys) {
        if (_bellConfirmationStatus[slaveAddress]?.isActive == true) {
          _bellConfirmationStatus[slaveAddress] = BellConfirmationStatus(
            slaveAddress: slaveAddress,
            isActive: false, // Force OFF
            timestamp: DateTime.now(),
            rawData: _bellConfirmationStatus[slaveAddress]?.rawData,
          );
        }
      }

      notifyListeners();
      
    } else {
      
    }
  }

  /// 🔔 Periodic check untuk sync bell status dengan LED alarm
  void performPeriodicBellStatusCheck() {
    

    final bool isLEDAlarmOn = getSystemStatus('Alarm');
    

    if (!isLEDAlarmOn) {
      _checkAndResetBellStatus();
    } else {
      
    }
  }

  /// 🔔 FORCE RESET: Aggressive bell status reset when LED OFF
  void forceResetBellStatusWhenLEDOff() {
    final bool isLEDAlarmOn = getSystemStatus('Alarm');
    final bool hasLEDDecoderData = _ledDecoder.currentLEDStatus != null;

    
    
    
    

    // FORCE RESET: If LED is OFF and we have active bells, reset immediately
    if (!isLEDAlarmOn && hasLEDDecoderData) {
      bool hasActiveBells = false;
      List<String> activeBellSlaves = [];

      for (final entry in _bellConfirmationStatus.entries) {
        if (entry.value.isActive) {
          hasActiveBells = true;
          activeBellSlaves.add(entry.key);
        }
      }

      if (hasActiveBells) {
        
        

        // Reset ALL active bells to OFF immediately
        for (final slaveAddress in activeBellSlaves) {
          _bellConfirmationStatus[slaveAddress] = BellConfirmationStatus(
            slaveAddress: slaveAddress,
            isActive: false, // Force OFF
            timestamp: DateTime.now(),
            rawData: 'FORCE_RESET_LED_OFF',
          );
        }

        notifyListeners();
        
      } else {
        
      }

      // 🔄 NEW: Reset zone accumulator when LED turns off
      _resetZoneAccumulator();
    } else {
      if (isLEDAlarmOn) {
        
      } else {
        
      }
    }
  }

  // Enhanced system status detection with zone data awareness - CORRECTED PRIORITY
  String getSystemStatusWithTroubleDetection() {
    // Check if system is resetting
    if (_isResetting) {
      return 'SYSTEM RESETTING';
    }

    // Check for initial loading state first (highest priority)
    if (_isInitiallyLoading) {
      return 'LOADING DATA';
    }

    // 🔥 NEW: Priority 0 - ALARM DRILL (Highest Priority)
    // Check LED drill status from master data first - this overrides all other statuses
    if (getSystemStatus('Drill')) {
      return 'ALARM DRILL'; // Show ALARM DRILL when LED drill is ON
    }

    // Check for no valid zone data first (highest priority)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      return 'NO DATA';
    }

    // CORRECTED: Priority 1 - SYSTEM ALARM (Second Priority now)
    if (getSystemStatus('Alarm') || hasAlarmZones()) {
      return 'SYSTEM ALARM'; // Consistent with main status logic
    }

    // REMOVED: Individual SYSTEM DRILL check - now handled above as ALARM DRILL

    // CORRECTED: Priority 3 - SYSTEM TROUBLE (Third Priority)
    if (getSystemStatus('Trouble')) {
      return 'SYSTEM TROUBLE';
    }

    // CORRECTED: Priority 4 - SYSTEM SILENCED (Fourth Priority)
    if (getSystemStatus('Silenced')) {
      return 'SYSTEM SILENCED';
    }

    // CORRECTED: Priority 5 - SYSTEM DISABLED (Fifth Priority)
    if (getSystemStatus('Disabled')) {
      return 'SYSTEM DISABLED';
    }

    // CORRECTED: Default - SYSTEM NORMAL (Lowest Priority)
    return 'SYSTEM NORMAL';
  }

  // Enhanced system status color detection with zone data awareness - CORRECTED PRIORITY
  Color getSystemStatusColorWithTroubleDetection() {
    // Check if system is resetting
    if (_isResetting) {
      return Colors.white;
    }

    // Check for initial loading state first (highest priority)
    if (_isInitiallyLoading) {
      return Colors.blue;
    }

    // 🔥 NEW: Priority 0 - ALARM DRILL (Highest Priority)
    // Check LED drill status first - same red styling as ALARM
    if (getSystemStatus('Drill')) {
      return Colors.red; // Red for ALARM DRILL status (same as ALARM)
    }

    // CORRECTED: Priority 1 - SYSTEM ALARM (Second Priority now)
    if (getSystemStatus('Alarm') || hasAlarmZones()) {
      return Colors.red; // Red for ALARM status
    }

    // REMOVED: Individual drill color check - now handled above as ALARM DRILL

    // Check for any trouble zones - Priority 5
    if (getSystemStatus('Trouble')) {
      final troubleColor = getActiveColor('Trouble');
      
      return troubleColor; // Orange for ANY trouble
    }

    // Check for no valid zone data - Lowest Priority (only if no system status)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      
      return Colors.grey;
    }
    
    // Check for silenced status
    if (getSystemStatus('Silenced')) {
      return getActiveColor('Silenced'); // Yellow for silenced
    }
    
    // Check for disabled status
    if (getSystemStatus('Disabled')) {
      return getActiveColor('Disabled'); // Grey for disabled
    }
    
    return Colors.green; // Green for normal
  }

  Future<void> _sendWhatsAppMessage() async {
    try {
      // Ensure at least 10 seconds between sends to avoid WhatsApp ban
      if (lastSendTime != null) {
        final diff = DateTime.now().difference(lastSendTime!).inSeconds;
        if (diff < 10) {
          await Future.delayed(Duration(seconds: 10 - diff));
        }
      }

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final formattedTime = dateFormat.format(lastUpdateTime);

      final message =
          '''
*(DDS FIRE ALARM MONITORING SYSTEM)*

*($projectName // $panelType)*
*(${modules.length} MODULES)*

*RECENT STATUS :*
*$recentActivity || $formattedTime*

*SYSTEM STATUS :*
*$_currentStatusText || $formattedTime*
''';

      // Get all user phone numbers from Firebase
      List<String> phoneNumbers = [
        defaultTarget,
      ]; // Always include default admin number

      try {
        final usersSnapshot = await _databaseRef.child('users').get();
        if (usersSnapshot.exists) {
          Map<dynamic, dynamic> users =
              usersSnapshot.value as Map<dynamic, dynamic>;
          for (var userData in users.values) {
            if (userData['phone'] != null && userData['isActive'] == true) {
              String phone = userData['phone'].toString().trim();
              // Convert phone to international format if needed
              if (phone.startsWith('0')) {
                phone = '62${phone.substring(1)}'; // Convert 08xxx to 628xxx
              } else if (phone.startsWith('+62')) {
                phone = phone.substring(1); // Remove + sign
              }
              // Avoid duplicates
              if (!phoneNumbers.contains(phone)) {
                phoneNumbers.add(phone);
              }
            }
          }
        }
      } catch (e) {
        // If error getting users, continue with default target only
        // Error getting user phones: $e
      }

      // Join all phone numbers with comma and set delay of 5 seconds
      String targets = phoneNumbers.join(',');

      final response = await http.post(
        Uri.parse(fonnteApiUrl),
        headers: {
          'Authorization': fonnteToken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'target': targets,
          'message': message,
          'delay': '5', // 5 seconds delay between each message
          'countryCode': '62',
        },
      );

      if (response.statusCode == 200) {
        // Success
        lastSendTime = DateTime.now();
      } else {
        // Failed to send WhatsApp message
      }
    } catch (e) {
      // Error sending WhatsApp message
    }
  }

  Future<void> _sendFCMMessage() async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedTime = dateFormat.format(lastUpdateTime);

    // Initialize notification service if needed
    await _notificationService.initialize();

    // Determine event type from recent activity
    String eventType = 'UNKNOWN';
    if (recentActivity.contains('DRILL')) {
      eventType = 'DRILL';
    } else if (recentActivity.contains('SYSTEM RESET')) {
      eventType = 'SYSTEM RESET';
    } else if (recentActivity.contains('SILENCED')) {
      eventType = 'SILENCE';
    } else if (recentActivity.contains('ACKNOWLEDGE')) {
      eventType = 'ACKNOWLEDGE';
    } else if (recentActivity.contains('ALARM')) {
      eventType = 'ALARM';
    } else if (recentActivity.contains('TROUBLE')) {
      eventType = 'TROUBLE';
    }

    // Send notification using EnhancedNotificationService
    await _notificationService.showNotification(
      title: 'Fire Alarm: $eventType',
      body: 'Status: ${_extractStatusFromActivity(recentActivity)} - By: ${_extractUserFromActivity(recentActivity)}',
      eventType: eventType,
      data: {
        'status': _extractStatusFromActivity(recentActivity),
        'user': _extractUserFromActivity(recentActivity),
        'projectName': projectName,
        'panelType': panelType,
        'timestamp': formattedTime,
      },
    );
  }

  // Helper method to extract status from activity string
  String _extractStatusFromActivity(String activity) {
    try {
      final regex = RegExp(r':\s*(ON|OFF)');
      final match = regex.firstMatch(activity);
      if (match != null) {
        return match.group(1) ?? 'UNKNOWN';
      }
    } catch (e) {
      AppLogger.error('Error extracting status from activity', error: e, tag: 'FIRE_ALARM_DATA');
    }
    return 'UNKNOWN';
  }

  // Helper method to extract user from activity string
  String _extractUserFromActivity(String activity) {
    try {
      final regex = RegExp(r'\(([^)]+)\)$');
      final match = regex.firstMatch(activity);
      if (match != null) {
        return match.group(1) ?? 'Unknown User';
      }
    } catch (e) {
      AppLogger.error('Error extracting user from activity', error: e, tag: 'FIRE_ALARM_DATA');
    }
    return 'Unknown User';
  }

  // Public method to send notification manually
  Future<void> sendNotification() async {
    await _sendWhatsAppMessage();
    await _sendFCMMessage();
  }

  // Public method to manually refresh modules
  void refreshModules() {
    if (numberOfModules > 0) {
      _parseActiveZoneToModules(activeZone);
      notifyListeners();
    }
  }

  // Get zone name by its absolute number (e.g., 1 to 250)
  String getZoneNameByAbsoluteNumber(int zoneNumber) {
    if (modules.isEmpty || zoneNumber <= 0) {
      return 'Unknown Zone';
    }

    // Each module has 5 functional zones + 1 BELL zone.
    // The calculation is based on 5 functional zones per module.
    const int zonesPerModule = 5;

    // Calculate module index (0-based) and zone index within the module (0-based)
    final int moduleIndex = ((zoneNumber - 1) ~/ zonesPerModule);
    final int zoneIndexInModule = (zoneNumber - 1) % zonesPerModule;

    // Ensure the calculated module and zone indices are within bounds
    if (moduleIndex < modules.length) {
      final module = modules[moduleIndex];
      if (module['zones'] is List) {
        final zones = module['zones'] as List<dynamic>;
        if (zoneIndexInModule < zones.length) {
          // The 'zones' list contains 6 items (5 zones + 'BELL'). We only care about the first 5.
          return zones[zoneIndexInModule].toString();
        }
      }
    }

    return 'Zone $zoneNumber'; // Fallback if not found
  }

  // Get zone status by its absolute number (e.g., 1 to 250)
  String? getZoneStatusByAbsoluteNumber(int zoneNumber) {
    if (modules.isEmpty || zoneNumber <= 0) {
      return null;
    }

    // Check if system is in alarm
    if (getSystemStatus('Alarm')) {
      return 'Alarm';
    }

    // Check if system is in trouble
    if (getSystemStatus('Trouble')) {
      return 'Trouble';
    }

    // Check if system is in drill mode
    if (getSystemStatus('Drill')) {
      return 'Drill';
    }

    // Check if system is silenced
    if (getSystemStatus('Silenced')) {
      return 'Silenced';
    }

    // Return normal status if no issues
    return 'Normal';
  }

  // Clear all activity logs from local state and Firebase
  void clearAllActivityLogs() {
    activityLogs.clear();
    notifyListeners();
  }

  /// 🔥 FIXED: Connect LED Decoder to Zone Parser data stream (Path C) - Performance Optimized
  void _connectLEDDecoderToZoneParser() {
    try {
      

      // 🔥 FIXED: Use proper event-driven stream instead of periodic polling
      final zoneParserLEDStream = _createOptimizedZoneParserLEDStream();

      // Connect LED decoder to this stream
      _ledDecoder.connectToZoneParser(zoneParserLEDStream);

      
    } catch (e) {
      
      // Fallback: start regular Firebase monitoring if zone parser connection fails
      _ledDecoder.startMonitoring();
    }
  }

  /// 🔥 FIXED: Create optimized event-driven stream for LED data - Type Safe
  Stream<Map<String, dynamic>> _createOptimizedZoneParserLEDStream() {
    // Use StreamController to emit events only when zone parser actually processes data
    final StreamController<Map<String, dynamic>> ledStreamController = StreamController<Map<String, dynamic>>.broadcast();

    // Listen to zone parser results and emit LED data only when needed
    _subscriptions.add(
      _databaseRef.child('all_slave_data/raw_data').onValue.listen((event) async {
        // 🚀 CRITICAL FIX: Skip Firebase LED processing when in WebSocket mode
        if (!isFirebaseMode) {
          
          return;
        }

        try {
          if (event.snapshot.value != null) {
            

            // Process immediately when new data arrives
            final rawData = event.snapshot.value.toString();
            if (rawData.isNotEmpty) {
              // Parse data and extract LED status
              final enhancedResult = await _processRawDataForLED(rawData);
              if (enhancedResult != null) {
                final ledStatusData = EnhancedZoneParser.extractLEDStatusFromDeviceData(enhancedResult);
                final ledMapData = ledStatusData.toLEDDecoderFormat();

                // Emit to LED decoder
                if (!ledStreamController.isClosed) {
                  ledStreamController.add(ledMapData);
                }
              }
            }
          }
        } catch (e) {
          AppLogger.error('Error in Firebase LED listener', error: e, tag: 'FIRE_ALARM_DATA');
        }
      })
    );

    return ledStreamController.stream;
  }

  /// 🔥 FIXED: Helper method to process raw data for LED extraction
  Future<EnhancedParsingResult?> _processRawDataForLED(String rawData) async {
    try {
      

      // 🔥 NEW: Check for master status data first (4-digit pattern like "4200", "41FF")
      final masterStatusMatch = RegExp(r'^([0-9A-Fa-f]{4})\b').firstMatch(rawData.trim());
      if (masterStatusMatch != null) {
        String masterData = masterStatusMatch.group(1)!;
        

        // Create master status result directly
        return await _createMasterStatusResult(masterData);
      }

      // Use existing zone parser logic for other data types
      final result = await EnhancedZoneParser.parseCompleteDataStream(rawData);

      // 🔥 FIXED: Accept master status data too (cycleType == 'master_status')
      if (result.totalDevices > 0 || result.masterSignal != null || result.cycleType == 'master_status') {
        
        return result;
      } else {
        
        return null;
      }
    } catch (e) {
      
      return null;
    }
  }

  /// 🔥 NEW: Create master status result directly from 4-digit master data
  Future<EnhancedParsingResult?> _createMasterStatusResult(String masterData) async {
    try {
      

      // Use the same logic as enhanced zone parser for master status
      String statusByte = masterData.substring(2);  // "FF", "00", etc.
      String headerIgnored = masterData.substring(0, 2); // For logging only

      int statusValue = int.parse(statusByte, radix: 16);

      

      // Decode 7 LED indicators from status byte (FIXED: Bit 1=ON, Bit 0=OFF)
      Map<String, bool> indicators = {
        'ac_power': (statusValue & 0x40) == 0,       // Bit 6: 0=ON, 1=OFF
        'dc_power': (statusValue & 0x20) == 0,       // Bit 5: 0=ON, 1=OFF
        'alarm_active': (statusValue & 0x10) == 0,   // Bit 4: 0=ON, 1=OFF
        'trouble_active': (statusValue & 0x08) == 0, // Bit 3: 0=ON, 1=OFF
        'drill_active': (statusValue & 0x04) == 0,    // Bit 2: 0=ON, 1=OFF
        'silenced': (statusValue & 0x02) == 0,       // Bit 1: 0=ON, 1=OFF
        'disabled': (statusValue & 0x01) == 0,       // Bit 0: 0=ON, 1=OFF
      };

      

      // Create master signal for LED extraction
      final masterSignal = MasterControlSignal(
        signal: statusByte,
        checksum: 'DIRECT', // Direct parsing, no checksum
        timestamp: DateTime.now(),
        type: ControlSignalType.unknown,
      );

      final result = EnhancedParsingResult(
        cycleType: 'master_status',
        checksum: 'DIRECT',
        status: 'MASTER_STATUS',
        totalDevices: 0,
        connectedDevices: 0,
        disconnectedDevices: 0,
        devices: [],
        masterSignal: masterSignal, // 🔥 KEY: Include master signal for LED extraction
        rawData: {
          'type': 'master_status',
          'raw_data': masterData,           // Full "4200"
          'header': headerIgnored,           // "42" (for reference)
          'status_byte': statusByte,        // "00" only
          'status_value': statusValue,      // 0
          'indicators': indicators,          // 7 LED states
        },
        timestamp: DateTime.now(),
      );

      
      return result;

    } catch (e) {
      
      return null;
    }
  }

  // NOTE: _convertUnifiedResultToEnhancedResult method removed - unused
// LED conversion now handled directly by EnhancedZoneParser.extractLEDStatusFromDeviceData()

  // ============= ZONE ACCUMULATOR INTEGRATION =============

  /// Get zone accumulator for external access
  ZoneAccumulator get zoneAccumulator => _zoneAccumulator;

  /// Get bell accumulator for external access
  BellAccumulator get bellAccumulator => _bellAccumulator;

  /// Check if a zone is accumulated as alarm
  bool isZoneAccumulatedAlarm(int zoneNumber) {
    return _zoneAccumulator.isZoneAccumulatedAlarm(zoneNumber);
  }

  /// Check if a zone is accumulated as trouble
  bool isZoneAccumulatedTrouble(int zoneNumber) {
    return _zoneAccumulator.isZoneAccumulatedTrouble(zoneNumber);
  }

  /// Get accumulated alarm zones count
  int get accumulatedAlarmCount => _zoneAccumulator.accumulatedAlarmCount;

  /// Get accumulated trouble zones count
  int get accumulatedTroubleCount => _zoneAccumulator.accumulatedTroubleCount;

  /// Get current accumulation mode status
  bool get isAccumulationMode => _zoneAccumulator.isAccumulationMode;

  /// 🔔 Get accumulated bell count from SimpleStatusManager (SAME AS ZONE)
  int get accumulatedBellCount => _simpleStatusManager.accumulatedBellCount;

  /// Get current bell accumulation mode status from SimpleStatusManager
  bool get isBellAccumulationMode => _simpleStatusManager.isBellAccumulationMode;

  /// Update zone accumulator with new zone status data
  void _updateZoneAccumulator() {
    try {
      // Get current LED alarm status
      final bool isLEDAlarmOn = getSystemStatus('Alarm');

      

      // 🛡️ ERROR HANDLING: Check if zone status map is valid
      if (_zoneStatus.isEmpty) {
        
        return;
      }

      // Update accumulator with all current zones
      for (final entry in _zoneStatus.entries) {
        try {
          final zoneNumber = entry.key;
          final zoneData = entry.value;

          // Zone data structure validation (already guaranteed by Map<int, Map<String, dynamic>> type)
          // zoneData is guaranteed to be Map<String, dynamic> by type declaration

          // 🛡️ ERROR HANDLING: Validate required fields
          final status = zoneData['status'] as String?;
          final description = zoneData['description'] as String?;

          if (status == null) {

            continue;
          }

          // Create ZoneStatus object for accumulator
          final zoneStatus = ZoneStatus(
            globalZoneNumber: zoneNumber,
            zoneInDevice: zoneData['zoneInDevice'] as int? ?? 0,
            deviceAddress: int.tryParse(zoneData['deviceAddress']?.toString() ?? '0') ?? 0,
            isActive: zoneData['isActive'] as bool? ?? true,
            hasAlarm: (status == 'Alarm' || zoneData['hasAlarm'] == true),
            hasTrouble: (status == 'Trouble' || zoneData['hasTrouble'] == true),
            description: description ?? '',
            lastUpdate: DateTime.tryParse(zoneData['timestamp']?.toString() ?? '') ?? DateTime.now(),
          );

          // Update accumulator with this zone
          _zoneAccumulator.updateZoneStatus(zoneNumber, zoneStatus, isLEDAlarmOn);

        } catch (e) {

          continue;
        }
      }

      // Log accumulator status with enhanced statistics
      _zoneAccumulator.getAccumulatorStatus();
      
      
      
      
      
      

    } catch (e) {
      AppLogger.error('Error updating zone accumulator', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  /// Update bell accumulator (SAME AS ZONE but for bell)
  void _updateBellAccumulator() {
    try {
      // Gunakan LED alarm status yang SAMA seperti zone
      final bool isLEDBellOn = getSystemStatus('Alarm');

      

      // 🛡️ ERROR HANDLING: Check if bell confirmation status map is valid
      if (_bellConfirmationStatus.isEmpty) {
        
        return;
      }

      // Update accumulator with all current bells
      for (final entry in _bellConfirmationStatus.entries) {
        try {
          final slaveAddress = entry.key;
          final bellStatus = entry.value;

          // 🛡️ ERROR HANDLING: Bell status always exists (Map<String, BellConfirmationStatus>)
          final hasBell = bellStatus.isActive;

          // Update accumulator with this bell (SAMA seperti zone)
          _bellAccumulator.updateBellStatus(slaveAddress, hasBell, isLEDBellOn);

        } catch (e) {

          continue;
        }
      }

      // Log accumulator status with enhanced statistics (SAMA seperti zone)
      _bellAccumulator.getAccumulatorStatus();
      
      
      
      
      

    } catch (e) {
      AppLogger.error('Error updating bell accumulator', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  /// Reset zone accumulator (called when LED turns off)
  void _resetZoneAccumulator() {
    
    _zoneAccumulator.reset();

    // 🔔 NEW: Reset bell status juga saat LED OFF
    _resetBellStatus();

    // Also reset accumulated counts in SimpleStatusManager
    _simpleStatusManager.resetAccumulatedCounts();
  }

  /// Reset bell status (called when LED turns off - synchronized with zones)
  void _resetBellStatus() {
    
    _bellManager.resetAllBellStatus();
    notifyListeners();
  }

  /// Get zone accumulator status for debugging
  Map<String, dynamic> getZoneAccumulatorStatus() {
    return _zoneAccumulator.getAccumulatorStatus();
  }

  // Dispose resources
  void disposeResources() {
    try {
      // Cancel all tracked subscriptions
      for (final subscription in _subscriptions) {
        subscription.cancel();
      }
      _subscriptions.clear();

      // Cancel cleanup timer
      _cleanupTimer?.cancel();
      _cleanupTimer = null;

      // 🏷️ Dispose module names subscription
      _moduleNamesSubscription?.cancel();
      _moduleNamesSubscription = null;

      // Dispose LED decoder
      _ledDecoder.dispose();

      // Clear zone status cache to prevent memory leaks
      _clearZoneStatusCache();

      // Clear other cached data
      _lastUnifiedResult = null;
      _lastUnifiedUpdateTime = null;

    } catch (e) {
      AppLogger.error('Error disposing resources', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  // ============= LED STATUS DECODER INTEGRATION =============
  
  /// Get current LED status from decoder
  LEDStatus? get currentLEDStatus => _ledDecoder.currentLEDStatus;
  
  /// Get LED status stream for real-time updates
  Stream<LEDStatus?> get ledStatusStream => _ledDecoder.ledStatusStream;
  
  /// Get raw LED data stream
  Stream<String?> get rawLEDDataStream => _ledDecoder.rawLEDDataStream;
  
  /// Get LED color for specific LED type
  Color? getLEDColorFromDecoder(LEDType ledType) => _ledDecoder.getLEDColor(ledType);
  
  /// Get LED status for specific LED type
  bool? getLEDStatusFromDecoder(LEDType ledType) => _ledDecoder.getLEDStatus(ledType);
  
  /// Get current system context from LED decoder
  SystemContext? get currentSystemContext => _ledDecoder.currentSystemContext;
  
  /// Check if system is in alarm state (from LED decoder)
  bool get isSystemInAlarmFromLED => _ledDecoder.isSystemInAlarm;
  
  /// Check if system is in trouble state (from LED decoder)
  bool get isSystemInTroubleFromLED => _ledDecoder.isSystemInTrouble;

  /// Check if LED decoder has valid data
  bool get hasLEDDecoderData => _ledDecoder.currentLEDStatus != null;

  /// Get LED decoder timestamp for debugging
  DateTime? getLEDDecoderTimestamp() => _ledDecoder.currentLEDStatus?.timestamp;
  
  /// Check if system is silenced (from LED decoder)
  bool get isSystemSilencedFromLED => _ledDecoder.isSystemSilenced;

  // 🚀 CRITICAL FIX: WebSocket Mode Manager Initialization
  Future<void> _initializeWebSocketModeManager() async {
    try {
      

      // 🚀 Initialize the singleton mode manager with this FireAlarmData instance
      await WebSocketModeManager.instance.initializeManager(this);

      
      
      
      

      // 🚀 Listen to mode changes from singleton
      WebSocketModeManager.instance.addListener(_onModeChanged);

    } catch (e, stackTrace) {
      AppLogger.error('Error initializing WebSocket mode', error: e, stackTrace: stackTrace, tag: 'FIRE_ALARM_DATA');

      // Continue without WebSocket mode if initialization fails
    }
  }

  /// Handle mode changes from WebSocket mode manager
  void _onModeChanged() {
    if (_mounted) {
      
      notifyListeners();
    }
  }

  // ============= UNIFIED PARSER INTEGRATION =============

  /// 🔌 Process WebSocket data using Unified Fire Alarm Parser
  /// [forceProcess] allows processing even when not in WebSocket mode (for mode switching)
  Future<void> processWebSocketData(String rawData, {bool forceProcess = false}) async {
    try {
      

      // 🚀 MODE CHECK: Only process WebSocket data when in WebSocket mode OR forced processing
      if (!isWebSocketMode && !forceProcess) {
        
        return;
      }

      // Store pending data for later processing when switching modes
      if (!isWebSocketMode && !forceProcess && _pendingWebSocketData.length < 10) {
        _pendingWebSocketData.add(rawData);
        
        return;
      }

      // 🔔 BELL MANAGER INTEGRATION: Process raw data for $85/$84 confirmation codes
      if (getIt.isRegistered<BellManager>()) {
        try {
          final bellManager = getIt<BellManager>();
          bellManager.processRawData(rawData);

        } catch (e) {
          AppLogger.error('Error processing bell manager data', error: e, tag: 'FIRE_ALARM_DATA');
        }
      }

      // 🔥 NEW: Extract and process master data for LED status first (before zone processing)
      
      await _processWebSocketMasterData(rawData);

      
      
      

      // Use same unified parser for consistency with Firebase
      
      final result = await _unifiedParser.parseData(rawData);

      
      
      if (result.zones.isNotEmpty) {
        // Sample zones could be logged here if needed for debugging
      }

      // Update internal state (same as Firebase processing)
      _lastUnifiedResult = result;
      _lastUnifiedUpdateTime = DateTime.now();
      _hasValidZoneData = true;
      _hasNoParsedPacketData = false;
      _lastValidZoneDataTime = DateTime.now();

      // Update zone status map for UI consumption
      
      _updateZoneStatusFromUnifiedResult(result);

      // Process bell confirmations from WebSocket data
      if (result.bellConfirmations.isNotEmpty) {
        processBellConfirmations(result.bellConfirmations);
        
      }

      // Check and update drill mode bell status
      updateDrillModeBellStatus();

      // Update zone accumulator with LED-based mode switching
      _updateZoneAccumulator();

      // Update bell accumulator with LED-based mode switching (SAME AS ZONE)
      _updateBellAccumulator();

      // Also update SystemStatusData from WebSocket result
      if (result.parsingSource == 'enhanced_zone_parser') {
        

        // Create SystemStatusData directly from WebSocket result
        final systemStatusData = _createSystemStatusFromUnifiedResult(result);

        // Validate and update SystemStatusData
        final isValidStatus = extractor.SystemStatusExtractor.validateSystemStatus(systemStatusData);
        if (isValidStatus) {
          _currentSystemStatus = systemStatusData;
          
          
        }
      }

      // 🚀 UPDATE: Mark WebSocket data as received
      _hasWebSocketData = true;

      // 🚀 FIXED: Single UI notification to prevent race conditions
      if (_mounted) {
        notifyListeners();
        
      }

      // 🔥 NEW: Process LED status from WebSocket data (same as Firebase processing)
      
      await _processLEDStatusFromWebSocket(rawData);

      

    } catch (e) {
      
      AppLogger.error('WebSocket data processing failed', error: e);
    }
  }

  /// 🔥 NEW: Process master data from WebSocket for LED status (SAFE EXTRACTION)
  Future<void> _processWebSocketMasterData(String rawData) async {
    try {
      

      // 🔥 FIXED: Extract actual data from JSON string if needed
      String actualData = rawData;
      

      if (rawData.contains('{') && rawData.contains('"data":') && rawData.contains(' <STX>')) {
        
        try {
          // Parse the JSON properly
          final jsonStart = rawData.indexOf('{');
          final jsonEnd = rawData.lastIndexOf('}') + 1;
          if (jsonStart != -1 && jsonEnd > jsonStart) {
            final jsonStr = rawData.substring(jsonStart, jsonEnd);
            

            final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
            if (jsonData.containsKey('data')) {
              actualData = jsonData['data'].toString();
              
            } else {
              
            }
          } else {
            
          }
        } catch (e) {
          
          

          // 🔥 CRITICAL FIX: Fallback to regex extraction for JSON with control characters
          try {
            
            // More flexible regex to handle control characters
            final regex = RegExp(r'"data":\s*"([^"]*(?:\\.[^"]*)*)"', dotAll: true);
            final match = regex.firstMatch(rawData);
            if (match != null) {
              var extractedData = match.group(1)!;
              

              // Unescape common escape sequences
              extractedData = extractedData.replaceAll(r'\u0002', '');
              extractedData = extractedData.replaceAll(r'\u0003', '');
              extractedData = extractedData.replaceAll(r'\n', '\n');
              extractedData = extractedData.replaceAll(r'\t', '\t');
              extractedData = extractedData.replaceAll(r'\"', '"');
              extractedData = extractedData.replaceAll(r'\\', r'\');

              actualData = extractedData;
              
            } else {

            }
          } catch (e2) {
            AppLogger.error('Error in nested parsing', error: e2, tag: 'FIRE_ALARM_DATA');
          }
        }
      } else {
        
      }

      // Check if data contains master status pattern (4-char at beginning before <STX>)
      if (actualData.contains(' <STX>')) {
        // Extract the part before first <STX>
        final parts = actualData.split(' <STX>');
        if (parts.isNotEmpty && parts[0].trim().isNotEmpty) {
          final masterDataCandidate = parts[0].trim();

          // Check if it's a 4-character master status (like "51DD")
          if (masterDataCandidate.length == 4 && RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(masterDataCandidate)) {
            

            // Use exact same Firebase logic to process master data
            final masterResult = await _createMasterStatusResult(masterDataCandidate);
            if (masterResult != null) {
              

              // Extract LED status from master result and send to LED decoder
              final ledStatusData = EnhancedZoneParser.extractLEDStatusFromDeviceData(masterResult);
              final ledMapData = ledStatusData.toLEDDecoderFormat();

              

              // 🔥 FIXED: Direct LED status update like Firebase (no temporary stream)
              _ledDecoder.processZoneParserLEDData(ledMapData);

              
            } else {
              
            }
          } else {
            
          }
        }
      } else {
        

        // Handle standalone master data (without zone modules)
        final trimmedData = actualData.trim();
        if (trimmedData.length == 4 && RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(trimmedData)) {
          

          // Process standalone master data
          final masterResult = await _createMasterStatusResult(trimmedData);
          if (masterResult != null) {
            final ledStatusData = EnhancedZoneParser.extractLEDStatusFromDeviceData(masterResult);
            final ledMapData = ledStatusData.toLEDDecoderFormat();

            

            // 🔥 FIXED: Direct LED status update like Firebase (no temporary stream)
            _ledDecoder.processZoneParserLEDData(ledMapData);

            
          }
        } else {
          
        }
      }
    } catch (e) {
      AppLogger.error('Error processing WebSocket master data', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  /// 🔥 NEW: Process LED status from WebSocket data (same logic as Firebase LED stream)
  Future<void> _processLEDStatusFromWebSocket(String rawData) async {
    try {
      

      // Parse data and extract LED status using same logic as Firebase
      final enhancedResult = await _processRawDataForLED(rawData);
      if (enhancedResult != null) {
        

        // Extract LED status from parsed result
        final ledStatusData = EnhancedZoneParser.extractLEDStatusFromDeviceData(enhancedResult);
        final ledMapData = ledStatusData.toLEDDecoderFormat();

        

        // 🔥 FIXED: Direct LED status update like Firebase (no temporary stream)
        _ledDecoder.processZoneParserLEDData(ledMapData);

        
      } else {
        
      }
    } catch (e) {
      AppLogger.error('Error processing LED status from WebSocket', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  /// 🎯 Process raw data using Unified Fire Alarm Parser
  Future<void> _processRawDataWithUnifiedParser(String rawData) async {
    try {
      
      

      // Use unified parser with automatic strategy selection
      final result = await _unifiedParser.parseData(rawData);

      // Update internal state
      _lastUnifiedResult = result;
      _lastUnifiedUpdateTime = DateTime.now();
      _hasValidZoneData = true;
      _hasNoParsedPacketData = false;
      _lastValidZoneDataTime = DateTime.now();

      // Update zone status map for UI consumption
      _updateZoneStatusFromUnifiedResult(result);

      // 🔔 NEW: Process bell confirmations dari parsing result
      if (result.bellConfirmations.isNotEmpty) {
        processBellConfirmations(result.bellConfirmations);
        
      }

      // 🔥 NEW: Check and update drill mode bell status
      updateDrillModeBellStatus();

      // 🔄 NEW: Update zone accumulator with LED-based mode switching
      _updateZoneAccumulator();

      // 🔄 NEW: Update bell accumulator with LED-based mode switching (SAME AS ZONE)
      _updateBellAccumulator();

      // 🔥 REMOVED: _updateSystemStatusFromUnifiedResult call (OBSOLETE method)
      // System status now comes from SystemStatusData only

      // 🔥 NEW: Also update SystemStatusData from Unified Parser result
      if (result.parsingSource == 'enhanced_zone_parser') {
        

        // Create SystemStatusData directly from UnifiedParsingResult
        final systemStatusData = _createSystemStatusFromUnifiedResult(result);

        // Validate and update SystemStatusData
        final isValidStatus = extractor.SystemStatusExtractor.validateSystemStatus(systemStatusData);
        if (isValidStatus) {
          _currentSystemStatus = systemStatusData;
          // 🔥 REMOVED: _updateSystemStatusFlags call (OBSOLETE method)

          
          
          
        } else {
          
        }
      }

      
      
      
      
      
      
      
      

      // 🎯 NEW: Update Simple Status Manager with your exact 4 rules + active zones detection
      _updateSimpleStatusFromParsing(
        alarmZones: result.systemStatus.totalAlarmZones,
        troubleZones: result.systemStatus.totalTroubleZones,
        hasFirebaseData: isFirebaseConnected,
        activeZonesCount: result.systemStatus.totalActiveZones,
      );

      // 🎯 CRITICAL: End initial loading state on successful parsing
      if (_isInitiallyLoading && result.zones.isNotEmpty) {
        _isInitiallyLoading = false;
        
      }

      // 🔔 NEW: Force reset bell status based on LED alarm status
      // This handles cases where LED OFF but bell containers still show ON
      forceResetBellStatusWhenLEDOff();

      // Notify listeners for UI update
      if (_mounted) {
        notifyListeners();
      }

    } catch (e) {
      
      // Fallback to enhanced zone parser if unified parser fails
      await _processRawZoneDataWithEnhancedParser(rawData);
    }
  }

  /// Update zone status from unified parsing result
  void _updateZoneStatusFromUnifiedResult(UnifiedParsingResult result) {
    try {
      // 🔔 BELL MANAGER INTEGRATION: Process zone data for bell status
      if (getIt.isRegistered<BellManager>() && result.zones.isNotEmpty) {
        final bellManager = getIt<BellManager>();

        // Convert UnifiedZoneStatus to ZoneStatus for Bell Manager
        final Map<String, ZoneStatus> zonesForBell = {};
        for (final entry in result.zones.entries) {
          final zoneStatus = entry.value;
          final bellZoneStatus = ZoneStatus(
                globalZoneNumber: zoneStatus.zoneNumber,
                zoneInDevice: zoneStatus.zoneInDevice,
                deviceAddress: zoneStatus.deviceNumber,
                isActive: zoneStatus.status != 'Offline' && zoneStatus.status != 'Normal',
                hasAlarm: zoneStatus.status == 'Alarm',
                hasTrouble: zoneStatus.status == 'Trouble',
                hasSupervisory: false,
                description: zoneStatus.description,
                lastUpdate: zoneStatus.timestamp,
                zoneType: ZoneType.unknown,
                metadata: {
                  'deviceAddress': zoneStatus.deviceAddress,
                  'color': zoneStatus.color.toARGB32().toString(),
                  'isOffline': zoneStatus.isOffline,
                  'hasPower': zoneStatus.hasPower,
                  'rawData': zoneStatus.rawData ?? '',
                },
              );
          zonesForBell[entry.key.toString()] = bellZoneStatus;
        }
        bellManager.processZoneData(zonesForBell);

        // Also process raw data for $85/$84 confirmation codes
        if (result.rawData?.isNotEmpty == true) {
          bellManager.processRawData(result.rawData!);
        }
      }

      // 🔥 SMART CACHE MANAGEMENT: Only clear cache if we have actual zone data
      final hasZoneData = result.zones.isNotEmpty;
    final isZoneDataSource = _isZoneDataSource(result.parsingSource);

    

    // 🔥 ENHANCED VALIDATION: Verify zone data integrity
    if (hasZoneData && !_validateZoneDataIntegrity(result)) {
      
      return; // Don't proceed with invalid zone data
    }

    // 🚀 FIXED: Smart cache management - preserve existing data, only update what changed
    if (!hasZoneData) {
      if (isZoneDataSource) {
        
      } else {
        
      }
      return; // Don't proceed if no zone data to update
    }

    if (!isZoneDataSource) {
      
      return; // Don't clear cache for non-zone data
    }

    // 🚀 SMART UPDATE: Don't clear cache! Just update the specific zones that changed
    

    // Update zones only if we have zone data
    for (final entry in result.zones.entries) {
      final zoneNumber = entry.key;
      final zoneStatus = entry.value;

      final statusData = {
        'status': zoneStatus.status,
        'description': zoneStatus.description,
        'color': zoneStatus.color,
        'deviceAddress': zoneStatus.deviceAddress,
        'deviceNumber': zoneStatus.deviceNumber,
        'zoneInDevice': zoneStatus.zoneInDevice,
        'isOffline': zoneStatus.isOffline,
        'hasPower': zoneStatus.hasPower,
        'timestamp': zoneStatus.timestamp.toIso8601String(),
        'rawData': zoneStatus.rawData.toString(),
      };

      // Use cache management
      _updateZoneStatusInCache(zoneNumber, statusData);
    }

    
    

    } catch (e, stackTrace) {
      
      if (stackTrace.toString().isNotEmpty) {
        
      }
      // Continue processing even if bell manager fails
    }
  }

  /// 🔥 ENHANCED: Validate zone data integrity
  bool _validateZoneDataIntegrity(UnifiedParsingResult result) {
    try {
      // Check 1: Minimum zone count validation (FIXED - allow partial updates)
      if (result.zones.isEmpty) {
        
        return false;
      }

      

      // Check 2: Maximum zone count validation
      if (result.zones.length > 315) {
        
        return false;
      }

      // Check 3: Zone number continuity and validity
      final zoneNumbers = result.zones.keys.toList()..sort();
      for (int i = 0; i < zoneNumbers.length; i++) {
        final zoneNumber = zoneNumbers[i];
        if (zoneNumber < 1 || zoneNumber > 315) {
          
          return false;
        }
      }

      // Check 4: Device address consistency
      final deviceAddresses = <String>{};
      for (final zoneStatus in result.zones.values) {
        if (zoneStatus.deviceAddress.isEmpty) {
          
          return false;
        }
        deviceAddresses.add(zoneStatus.deviceAddress);
      }

      // Check 5: Status consistency
      final validStatuses = {'Alarm', 'Trouble', 'Normal', 'Active', 'Offline', 'Supervisory'};
      for (final zoneStatus in result.zones.values) {
        if (!validStatuses.contains(zoneStatus.status)) {
          
          return false;
        }
      }

      // Check 6: Zone-in-device consistency (1-5)
      for (final zoneStatus in result.zones.values) {
        if (zoneStatus.zoneInDevice < 1 || zoneStatus.zoneInDevice > 5) {
          
          return false;
        }
      }

      
      return true;

    } catch (e) {
      
      return false;
    }
  }

  /// Check if parsing source contains actual zone data
  bool _isZoneDataSource(String parsingSource) {
    // Define which sources produce reliable zone data
    const zoneDataSources = {
      'enhanced_zone_parser',
      'zone_data_parser',
      'firebase_4char_format',
      'slave_pooling',
      'complete_data_stream',
    };

    return zoneDataSources.contains(parsingSource);
  }

  // 🔥 REMOVED: _updateSystemStatusFromUnifiedResult (OBSOLETE - no more systemStatus map)
// System status is now determined by:
// 1. Master Status Data (from AABBCC algorithm)
// 2. LED Decoder (derived from master status)
// 3. Simple Status Manager (zone counts for Alarm/Trouble)
// NO MORE UPDATING OBSOLETE systemStatus MAP!

  // ============= ENHANCED ZONE PARSER INTEGRATION (LEGACY) =============

  /// Process raw zone data using Enhanced Zone Parser (fallback)
  Future<void> _processRawZoneDataWithEnhancedParser(String rawData) async {
    try {
      
      

      // Parse raw data using Enhanced Zone Parser (now async for background processing)
      final result = await EnhancedZoneParser.parseCompleteDataStream(rawData);

      // 🔥 NEW: Extract unified system status from parsing result
      final systemStatus = extractor.SystemStatusExtractor.extractFromParsingResult(result);

      // Validate system status consistency
      final isValidStatus = extractor.SystemStatusExtractor.validateSystemStatus(systemStatus);
      if (isValidStatus) {
        _currentSystemStatus = systemStatus;

        
        
        

        // 🔥 REMOVED: _updateSystemStatusFlags call (OBSOLETE method)
        // SystemStatusData already contains all needed flags
      } else {
        
      }

      // Update internal state
      _hasValidZoneData = true;
      _hasNoParsedPacketData = false;
      _lastValidZoneDataTime = DateTime.now();

      // Update zone status map for UI consumption
      _updateZoneStatusFromEnhancedResult(result);

      // 🔄 NEW: Update zone accumulator with LED-based mode switching
      _updateZoneAccumulator();

      // 🔄 NEW: Update bell accumulator with LED-based mode switching (SAME AS ZONE)
      _updateBellAccumulator();

      // FIXED: Use SystemStatusExtractor instead of ineffective _generateSystemStatusFromZones
      final systemStatusData = extractor.SystemStatusExtractor.extractFromParsingResult(result);

      // Validate and update SystemStatusData
      final isSystemStatusValid = extractor.SystemStatusExtractor.validateSystemStatus(systemStatusData);
      if (isSystemStatusValid) {
        _currentSystemStatus = systemStatusData;
        // 🔥 REMOVED: _updateSystemStatusFlags call (OBSOLETE method)

        
        
        
      } else {
        
        // 🔥 REMOVED: _generateSystemStatusFromZones fallback (OBSOLETE method)
        // System will continue with previous valid SystemStatusData
      }

      
      
      
      
      

      // 🎯 NEW: Update Simple Status Manager with your exact 4 rules + active zones detection
      _updateSimpleStatusFromParsing(
        alarmZones: result.totalAlarmZones,
        troubleZones: result.totalTroubleZones,
        hasFirebaseData: isFirebaseConnected,
        activeZonesCount: result.totalActiveZones,
      );

      if (_mounted) {
        notifyListeners();
      }

    } catch (e, stackTrace) {
      AppLogger.error('Error updating zone status from enhanced result', error: e, stackTrace: stackTrace, tag: 'FIRE_ALARM_DATA');
    }
  }

  
  /// Update zone status map from Enhanced Zone Parser result
  void _updateZoneStatusFromEnhancedResult(EnhancedParsingResult result) {
    try {
      

      // 🔔 BELL MANAGER INTEGRATION: Process zone data for bell status
      if (getIt.isRegistered<BellManager>()) {
        final bellManager = getIt<BellManager>();

        // Convert enhanced result to zone map for bell manager
        final Map<String, ZoneStatus> zonesForBell = {};
        for (final device in result.devices) {
          for (final zone in device.zones) {
            final absoluteZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(
              int.parse(device.address.isEmpty ? '1' : device.address),
              zone.zoneNumber
            );

            if (absoluteZoneNumber <= 315) {
              final zoneStatus = ZoneStatus(
                globalZoneNumber: absoluteZoneNumber,
                zoneInDevice: zone.zoneNumber,
                deviceAddress: int.tryParse(device.address) ?? 1,
                isActive: zone.isActive,
                hasAlarm: zone.hasAlarm,
                hasTrouble: zone.hasTrouble,
                hasSupervisory: false, // Enhanced parser may not have this data
                description: zone.description,
                lastUpdate: DateTime.now(),
                zoneType: ZoneType.unknown,
                metadata: {'deviceAddress': device.address},
              );

              zonesForBell[absoluteZoneNumber.toString()] = zoneStatus;
            }
          }
        }

        // Process zones for bell manager
        if (zonesForBell.isNotEmpty) {
          bellManager.processZoneData(zonesForBell);
        }

        // Process raw data for $85/$84 confirmation codes if available
        if (result.rawData.isNotEmpty) {
          // Convert rawData Map to string format for bell manager
          final rawString = result.rawData.entries.map((e) => '${e.key}:${e.value}').join(',');
          bellManager.processRawData(rawString);
        }
      }

      // Clear current zone status
      _zoneStatus.clear();

    // Map devices × zones to absolute zone numbers (1-250)
    for (final device in result.devices) {
      for (final zone in device.zones) {
        // Convert device+zone to absolute zone number
        final absoluteZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(
          int.parse(device.address.isEmpty ? '1' : device.address),
          zone.zoneNumber
        );

        if (absoluteZoneNumber <= 315) { // 63 devices × 5 zones = 315 total zones
          _zoneStatus[absoluteZoneNumber] = {
            'status': _determineZoneStatus(zone),
            'timestamp': DateTime.now().toIso8601String(),
            'description': zone.description,
            'deviceAddress': device.address,
            'isActive': zone.isActive,
            'hasAlarm': zone.hasAlarm,
            'hasTrouble': zone.hasTrouble,
          };
        }
      }
    }

    

    } catch (e, stackTrace) {
      
      if (stackTrace.toString().isNotEmpty) {
        
      }
      // Continue processing even if bell manager fails
    }
  }

  /// Calculate absolute zone number from device address and zone number
  
  /// Determine zone status from ZoneStatus object
  String _determineZoneStatus(dynamic zone) {
    if (zone.hasAlarm) return 'Alarm';
    if (zone.hasTrouble) return 'Trouble';
    if (zone.isActive) return 'Active';
    return 'Normal';
  }

  // 🔥 REMOVED: _generateSystemStatusFromZones method (OBSOLETE - used systemStatus map)
  // System status generation now uses:
  // 1. SystemStatusExtractor from EnhancedParsingResult (Priority 1)
  // 2. Master Status Data via LED decoder (Priority 2)
  // 3. Simple Status Manager for zone counts (Priority 3)
  // No more direct systemStatus map assignments!

  /// Get individual zone status by absolute zone number (1-250) with cache management
  Map<String, dynamic>? getIndividualZoneStatus(int zoneNumber) {
    return getZoneStatusFromCache(zoneNumber);
  }

  /// Check if individual zone data is available
  bool get hasIndividualZoneData => _zoneStatus.isNotEmpty;

  /// Get list of active alarm zones with fallback for WebSocket mode
  List<int> get activeAlarmZones {
    // Primary: Use zone status map if available (Firebase mode)
    if (_zoneStatus.isNotEmpty) {
      return _zoneStatus.entries
          .where((entry) => entry.value['status'] == 'Alarm')
          .map((entry) => entry.key)
          .toList();
    }

    // Fallback: Generate zone list from SimpleStatusManager count (WebSocket mode)
    final alarmCount = _simpleStatusManager.alarmCount;
    if (alarmCount <= 0) return [];

    // Return sequential zone numbers 1..N for display purposes
    return List.generate(alarmCount, (index) => index + 1);
  }

  /// Get list of active trouble zones with fallback for WebSocket mode
  List<int> get activeTroubleZones {
    // Primary: Use zone status map if available (Firebase mode)
    if (_zoneStatus.isNotEmpty) {
      return _zoneStatus.entries
          .where((entry) => entry.value['status'] == 'Trouble')
          .map((entry) => entry.key)
          .toList();
    }

    // Fallback: Generate zone list from SimpleStatusManager count (WebSocket mode)
    final troubleCount = _simpleStatusManager.troubleCount;
    if (troubleCount <= 0) return [];

    // Return sequential zone numbers 100..N+100 (different range to distinguish from alarms)
    return List.generate(troubleCount, (index) => index + 101);
  }

  /// Get list of all active zones
  List<int> get activeZones {
    return _zoneStatus.entries
        .where((entry) => entry.value['isActive'] == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get count of zones by status
  Map<String, int> get zoneStatusCounts {
    final counts = <String, int>{'Normal': 0, 'Alarm': 0, 'Trouble': 0, 'Active': 0};

    for (final zoneData in _zoneStatus.values) {
      final status = zoneData['status'] as String?;
      if (status != null) {
        counts[status] = (counts[status] ?? 0) + 1;
      }
    }

    return counts;
  }
  
  /// Check if system is disabled (from LED decoder)
  bool get isSystemDisabledFromLED => _ledDecoder.isSystemDisabled;
  
  /// Get power status from LED decoder
  PowerStatus get powerStatusFromLED => _ledDecoder.powerStatus;

  /// Check if system is in drill mode (from LED status)
  bool get isDrillModeActive {
    try {
      return getSystemStatus('Drill');
    } catch (e) {
      
      return false;
    }
  }

  /// Check if system should force all bells ON due to drill mode
  bool get shouldForceAllBellsOnInDrill {
    // Force all bells ON when drill is active (independent of alarm LED)
    // Drill mode should work regardless of individual zone alarms
    return isDrillModeActive;
  }

  /// Process manual LED data (for testing)
  LEDStatus? processManualLEDData(String rawData) => _ledDecoder.processManualLEDData(rawData);
  
  /// Enhanced system status detection using LED decoder data
  String getSystemStatusFromLED() {
    if (_ledDecoder.currentLEDStatus == null) {
      return 'NO LED DATA';
    }
    
    switch (_ledDecoder.currentSystemContext) {
      case SystemContext.systemDisabledMaintenance:
        return 'SYSTEM DISABLED - MAINTENANCE';
      case SystemContext.systemSilencedManual:
        return 'SYSTEM SILENCED - MANUAL';
      case SystemContext.alarmWithTroubleCondition:
        return 'ALARM WITH TROUBLE CONDITION';
      case SystemContext.alarmWithDrillActive:
        return 'ALARM WITH DRILL';
      case SystemContext.fullAlarmActive:
        return 'FULL ALARM ACTIVE';
      case SystemContext.troubleConditionOnly:
        return 'TROUBLE CONDITION DETECTED';
      case SystemContext.supervisoryPreAlarm:
        return 'SUPERVISORY PRE-ALARM';
      case SystemContext.systemNormal:
        return 'SYSTEM NORMAL';
      case null:
        return 'NO LED DATA';
    }
  }
  
  /// Get system status color based on LED decoder data
  Color getSystemStatusColorFromLED() {
    if (_ledDecoder.currentLEDStatus == null) {
      return Colors.grey;
    }
    
    switch (_ledDecoder.currentSystemContext) {
      case SystemContext.fullAlarmActive:
      case SystemContext.alarmWithTroubleCondition:
        return Colors.red;
      case SystemContext.alarmWithDrillActive:
        return Colors.orange;
      case SystemContext.troubleConditionOnly:
        return Colors.yellow;
      case SystemContext.systemSilencedManual:
        return Colors.amber;
      case SystemContext.systemDisabledMaintenance:
        return Colors.grey;
      case SystemContext.systemNormal:
        return Colors.green;
      case SystemContext.supervisoryPreAlarm:
        return Colors.yellow;
      case null:
        return Colors.grey;
    }
  }
  
  /// Enhanced LED color getter that uses decoder data when available
  Color getEnhancedLEDColor(String statusName) {
    Color selectedColor;

    // If LED decoder has data, use it
    if (_ledDecoder.currentLEDStatus != null) {
      switch (statusName) {
        case 'AC Power':
          selectedColor = _ledDecoder.getLEDColor(LEDType.acPower) ?? Colors.grey.shade300;
          break;
        case 'DC Power':
          selectedColor = _ledDecoder.getLEDColor(LEDType.dcPower) ?? Colors.grey.shade300;
          break;
        case 'Alarm':
          selectedColor = _ledDecoder.getLEDColor(LEDType.alarm) ?? Colors.grey.shade300;
          break;
        case 'Trouble':
          selectedColor = _ledDecoder.getLEDColor(LEDType.trouble) ?? Colors.grey.shade300;
          break;
        case 'Drill':
          selectedColor = _ledDecoder.getLEDColor(LEDType.drill) ?? Colors.grey.shade300;
          break;
        case 'Silenced':
          selectedColor = _ledDecoder.getLEDColor(LEDType.silenced) ?? Colors.grey.shade300;
          break;
        case 'Disabled':
          selectedColor = _ledDecoder.getLEDColor(LEDType.disabled) ?? Colors.grey.shade300;
          break;
        default:
          selectedColor = Colors.grey.shade300;
      }
    } else {
      // 🔥 FIXED: LED indicators 100% independent - No Simple Status Manager fallback!
      bool statusActive = false;
      statusActive = getSystemStatus(statusName); // Use ONLY master status via getSystemStatus()

      if (statusActive) {
        selectedColor = getActiveColor(statusName);
      } else {
        selectedColor = getInactiveColor(statusName);
      }

      // Enhanced debug logging
      
    }

    // Debug logging for color selection
    

    return selectedColor;
  }
  
  /// Enhanced LED status getter that uses decoder data when available
  bool getEnhancedLEDStatus(String statusName) {
    bool selectedStatus;

    // If LED decoder has data, use it
    if (_ledDecoder.currentLEDStatus != null) {
      switch (statusName) {
        case 'AC Power':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.acPower) ?? false;
          break;
        case 'DC Power':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.dcPower) ?? false;
          break;
        case 'Alarm':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.alarm) ?? false;
          break;
        case 'Trouble':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.trouble) ?? false;
          break;
        case 'Drill':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.drill) ?? false;
          break;
        case 'Silenced':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.silenced) ?? false;
          break;
        case 'Disabled':
          selectedStatus = _ledDecoder.getLEDStatus(LEDType.disabled) ?? false;
          break;
        default:
          selectedStatus = false;
      }
    } else {
      // Use getSystemStatus as final source (LED Decoder/SystemStatusData)
      selectedStatus = getSystemStatus(statusName);
    }

    // Debug logging for status selection
    

    return selectedStatus;
  }

  // ==================== UNIFIED PARSER PUBLIC API ====================

  /// 🎯 Get unified parsing result
  UnifiedParsingResult? get unifiedParsingResult => _lastUnifiedResult;

  /// 🎯 Get unified system status
  UnifiedSystemStatus? get unifiedSystemStatus => _lastUnifiedResult?.systemStatus;

  /// 🎯 Check if unified parser data is fresh (within 30 seconds)
  bool get isUnifiedDataFresh {
    if (_lastUnifiedUpdateTime == null) return false;
    return DateTime.now().difference(_lastUnifiedUpdateTime!).inSeconds < 30;
  }

  /// 🎯 Get unified parser statistics
  Map<String, dynamic> get unifiedStatistics {
    if (_lastUnifiedResult == null) return {};

    final result = _lastUnifiedResult!;
    return {
      'totalZones': result.zones.length,
      'alarmZones': result.alarmZones.length,
      'troubleZones': result.troubleZones.length,
      'offlineZones': result.offlineZones.length,
      'connectedDevices': result.systemStatus.connectedDevices,
      'disconnectedDevices': result.systemStatus.disconnectedDevices,
      'systemContext': result.systemStatus.systemContext,
      'lastUpdate': _lastUnifiedUpdateTime?.toIso8601String(),
      'parsingSource': result.parsingSource,
      'isDataFresh': isUnifiedDataFresh,
    };
  }

  /// 🎯 Get zone color using unified parser (with fallback to legacy)
  Color getUnifiedZoneColor(int zoneNumber) {
    // Try unified parser first
    final unifiedZone = _unifiedParser.getZoneStatus(zoneNumber);
    if (unifiedZone != null && isUnifiedDataFresh) {
      return unifiedZone.color;
    }

    // Fallback to legacy method
    final legacyZone = getIndividualZoneStatus(zoneNumber);
    if (legacyZone != null) {
      final status = legacyZone['status'] as String?;
      switch (status) {
        case 'Alarm': return Colors.red;
        case 'Trouble': return Colors.orange;
        case 'Active': return Colors.blue.shade200;
        case 'Normal': return Colors.white;
        default: return Colors.grey.shade300;
      }
    }

    return Colors.grey; // Default for no data
  }

  /// 🎯 Get system status color using unified parser
  Color getUnifiedSystemStatusColor() {
    return _unifiedParser.getSystemStatusColor();
  }

  /// 🎯 Get alarm zones using unified parser
  List<UnifiedZoneStatus> get unifiedAlarmZones {
    return _unifiedParser.alarmZones;
  }

  /// 🎯 Get trouble zones using unified parser
  List<UnifiedZoneStatus> get unifiedTroubleZones {
    return _unifiedParser.troubleZones;
  }

  /// 🎯 Get offline zones using unified parser
  List<UnifiedZoneStatus> get unifiedOfflineZones {
    return _unifiedParser.offlineZones;
  }

  /// 🎯 Manually trigger unified parsing (for testing)
  Future<void> triggerUnifiedParsing(String rawData) async {
    await _processRawDataWithUnifiedParser(rawData);
  }

  /// 🎯 Clear unified parser cache
  void clearUnifiedCache() {
    _unifiedParser.clearCache();
    _lastUnifiedResult = null;
    _lastUnifiedUpdateTime = null;
    
  }

  /// 🎯 Get unified parsing info for debugging
  String get unifiedParsingInfo {
    if (_lastUnifiedResult == null) return 'No unified parsing data available';

    final result = _lastUnifiedResult!;
    return 'Unified Parser: ${result.zones.length} zones, '
           '${result.systemStatus.systemContext}, '
           'Source: ${result.parsingSource}, '
           'Fresh: ${isUnifiedDataFresh ? 'Yes' : 'No'}';
  }

  // 🔥 REMOVED: _updateSystemStatusFlags method (OBSOLETE - uses systemStatus map)
  // System status flags now come directly from:
  // 1. Master Status Data (Priority 1: AABBCC algorithm)
  // 2. LED Decoder (Priority 2: Derived from master status)
  // 3. Simple Status Manager (Priority 3: Zone counts only)
  // No more systemStatus map fallbacks!

  // 🔥 NEW: Get system status from single source of truth
  bool getSystemStatusFromSingleSource(String statusName) {
    return _currentSystemStatus.systemFlags[statusName] ?? false;
  }

  // 🔥 NEW: Get system status text from single source of truth
  String getSystemStatusTextFromSingleSource() {
    return _currentSystemStatus.getSystemStatusText();
  }

  // 🔥 NEW: Get debug info for current system status
  String getSystemStatusDebugInfo() {
    return extractor.SystemStatusExtractor.getDebugInfo(_currentSystemStatus);
  }

  // 🔥 NEW: Get current system status data
  extractor.SystemStatusData get currentSystemStatus => _currentSystemStatus;

  // 🔥 NEW: Create SystemStatusData directly from UnifiedParsingResult
  extractor.SystemStatusData _createSystemStatusFromUnifiedResult(UnifiedParsingResult unifiedResult) {
    try {
      

      // Count zones by status
      int totalAlarmZones = 0;
      int totalTroubleZones = 0;

      for (final zone in unifiedResult.zones.values) {
        if (zone.status == 'Alarm') {
          totalAlarmZones++;
        } else if (zone.status == 'Trouble') {
          totalTroubleZones++;
        }
      }

      // Extract system flags from master control signal and zone counts
      final systemFlags = <String, bool>{
        'Alarm': totalAlarmZones > 0,
        'Trouble': totalTroubleZones > 0,
      };

      // Extract additional flags from system status
      final systemStatus = unifiedResult.systemStatus;
      systemFlags['Drill'] = systemStatus.isDrill;
      systemFlags['Silenced'] = systemStatus.isSilenced;
      systemFlags['Supervisory'] = systemStatus.hasTrouble; // Use trouble for supervisory in current implementation
      systemFlags['Disabled'] = systemStatus.isDisabled;
      

      // Create empty devices list (not needed for SystemStatusData)
      final devices = <extractor.DeviceStatus>[];

      final systemStatusData = extractor.SystemStatusData(
        hasAlarm: totalAlarmZones > 0,
        hasTrouble: totalTroubleZones > 0,
        hasSupervisory: systemFlags['Supervisory'] ?? false,
        systemFlags: systemFlags,
        devices: devices,
        timestamp: DateTime.now(),
      );

      
      
      

      return systemStatusData;

    } catch (e) {
      
      return extractor.SystemStatusData.empty();
    }
  }

  // ============= MODULE NAMES MANAGEMENT =============

  // Initialize module names Firebase listener
  void _initializeModuleNamesListener() {
    try {
      _moduleNamesRef = _databaseRef.child('moduleNames');

      

      _moduleNamesSubscription = _moduleNamesRef!.onValue.listen((DatabaseEvent event) {
        if (!_mounted) return;

        

        if (event.snapshot.value != null) {
          final data = event.snapshot.value;
          bool hasChanges = false;

          // Handle different data formats
          if (data is Map) {
            // Map format: {"1": "Module 1", "2": "Module 2", ...}
            for (var entry in data.entries) {
              final moduleKey = entry.key.toString();
              final moduleValue = entry.value?.toString() ?? '';

              if (_moduleNames[moduleKey] != moduleValue) {
                _moduleNames[moduleKey] = moduleValue;
                hasChanges = true;
                
              }
            }
          } else if (data is List) {
            // List format: ["Module 1", "Module 2", ...]
            for (int i = 0; i < data.length; i++) {
              if (data[i] != null) {
                final moduleKey = (i + 1).toString();
                final moduleValue = data[i].toString();

                if (_moduleNames[moduleKey] != moduleValue) {
                  _moduleNames[moduleKey] = moduleValue;
                  hasChanges = true;
                  
                }
              }
            }
          }

          // Trigger UI update if there are changes
          if (hasChanges) {
            
            notifyListeners();
          }
        } else {
          
        }
      }, onError: (error) {
        
      });

      
    } catch (e) {
      AppLogger.error('Error initializing module names listener', error: e, tag: 'FIRE_ALARM_DATA');
    }
  }

  // Get module name by module number
  String getModuleNameByNumber(int moduleNumber) {
    // Try both formats for backward compatibility
    final firebaseKey = 'module$moduleNumber';  // Firebase format: "module1", "module2"
    final numberKey = moduleNumber.toString();  // Legacy format: "1", "2"

    // First try Firebase format (current implementation)
    if (_moduleNames.containsKey(firebaseKey)) {
      return _moduleNames[firebaseKey]!;
    }

    // Fallback to legacy format for backward compatibility
    if (_moduleNames.containsKey(numberKey)) {
      return _moduleNames[numberKey]!;
    }

    // Final fallback to default
    return 'Module $moduleNumber';
  }

  // Get all module names
  Map<String, String> get moduleNames => Map.unmodifiable(_moduleNames);

  // Save module name to Firebase
  Future<void> saveModuleName(int moduleNumber, String moduleName) async {
    if (!_mounted) return;

    final firebaseKey = 'module$moduleNumber';  // Firebase format: "module1", "module2"
    final previousName = _moduleNames[firebaseKey] ?? '';

    try {
      

      // Update local cache immediately for better UX
      _moduleNames[firebaseKey] = moduleName;
      notifyListeners();

      // Save to Firebase with consistent format
      await _moduleNamesRef!.child(firebaseKey).set(moduleName);

      
    } catch (e) {
      

      // Revert local change on error
      _moduleNames[firebaseKey] = previousName;
      notifyListeners();

      rethrow;
    }
  }

  // Check if module names are loaded
  bool get hasModuleNames => _moduleNames.isNotEmpty;

  // 🚀 NEW: Mode Switching Methods for Firebase/WebSocket Integration

  /// Toggle between Firebase and WebSocket modes
  Future<bool> toggleConnectionMode() async {
    try {
      

      final result = await WebSocketModeManager.instance.toggleMode();

      // Notify listeners about mode change
      notifyListeners();

      
      return result;
    } catch (e) {
      
      return false;
    }
  }

  /// Force switch to WebSocket mode
  Future<bool> switchToWebSocketMode() async {
    if (isWebSocketMode) {
      
      return true;
    }

    return await toggleConnectionMode();
  }

  /// Force switch to Firebase mode
  Future<bool> switchToFirebaseMode() async {
    if (isFirebaseMode) {
      
      return true;
    }

    return await toggleConnectionMode();
  }

  /// Save current projectInfo data to cache
  Future<void> _saveProjectInfoToCache() async {
    try {
      await ProjectInfoCacheService.saveProjectInfoData(
        numberOfModules: numberOfModules,
        numberOfZones: numberOfZones,
      );
    } catch (e) {
      AppLogger.error(
        'Error saving projectInfo to cache',
        tag: 'FIRE_ALARM_DATA',
        error: e,
      );
    }
  }

  /// Test Firebase connectivity
  Future<bool> testFirebaseConnectivity() async {
    try {
      AppLogger.info('Testing Firebase connectivity...', tag: 'FIRE_ALARM_DATA');

      // Test basic database connection
      final testRef = _databaseRef.child('.info/connected');
      final connectionTest = await testRef.get();

      if (connectionTest.exists) {
        AppLogger.info('Firebase basic connection successful', tag: 'FIRE_ALARM_DATA');
      } else {
        AppLogger.warning('Firebase basic connection failed', tag: 'FIRE_ALARM_DATA');
        return false;
      }

      // Test projectInfo access
      final projectTest = await _databaseRef.child('projectInfo').get();

      if (projectTest.exists) {
        AppLogger.info('Firebase projectInfo access successful', tag: 'FIRE_ALARM_DATA');

        // Log available projectInfo fields
        final data = projectTest.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final availableFields = data.keys.join(', ');
          AppLogger.info('Available projectInfo fields: $availableFields', tag: 'FIRE_ALARM_DATA');
        }

        return true;
      } else {
        AppLogger.warning('Firebase projectInfo not found or accessible', tag: 'FIRE_ALARM_DATA');
        return false;
      }
    } catch (e) {
      AppLogger.error(
        'Firebase connectivity test failed',
        tag: 'FIRE_ALARM_DATA',
        error: e,
      );
      return false;
    }
  }

  /// Get Firebase connection status info
  Future<Map<String, dynamic>> getFirebaseConnectionInfo() async {
    try {
      final isConnected = await testFirebaseConnectivity();
      final config = _getFirebaseConfig();

      return {
        'isConnected': isConnected,
        'databaseUrl': config['databaseUrl'],
        'projectId': config['projectId'],
        'isFirebaseMode': isFirebaseMode,
        'isWebSocketMode': isWebSocketMode,
        'numberOfModules': numberOfModules,
        'numberOfZones': numberOfZones,
        'cacheInfo': await ProjectInfoCacheService.getCacheInfo(),
      };
    } catch (e) {
      AppLogger.error(
        'Error getting Firebase connection info',
        tag: 'FIRE_ALARM_DATA',
        error: e,
      );
      return {
        'isConnected': false,
        'error': e.toString(),
      };
    }
  }

  /// Get Firebase configuration (debug info)
  Map<String, String> _getFirebaseConfig() {
    try {
      return {
        'databaseUrl': 'https://testing1do-default-rtdb.asia-southeast1.firebasedatabase.app/',
        'projectId': 'testing1do', // From google-services.json
      };
    } catch (e) {
      return {
        'error': e.toString(),
      };
    }
  }
}

/// 🔔 Bell Accumulator - Sama persis seperti ZoneAccumulator tapi untuk bell
class BellAccumulator {
  // 🛡️ MEMORY PROTECTION: Maximum bells (63 devices)
  static const int maxBells = 63;

  // Set for O(1) operations and memory efficiency
  final Set<String> _accumulatedBellSlaves = <String>{};

  // LED-based accumulation mode control
  bool _isAccumulationMode = false;
  DateTime? _lastBellLEDStatusChange;

  // 📊 PERFORMANCE MONITORING: Track performance metrics
  int _totalUpdates = 0;
  int _totalProcessingTimeMs = 0;
  DateTime? _lastUpdateTime;
  int _maxUpdateTimeMs = 0;
  int _minUpdateTimeMs = 0x7FFFFFFF; // Max int value

  /// Update bell status dengan deteksi LED bell ON/OFF (SAMA seperti zone)
  void updateBellStatus(String slaveAddress, bool hasBell, bool isLEDBellOn) {
    // 📊 PERFORMANCE MONITORING: Start timing
    final stopwatch = Stopwatch()..start();

    // 🔔 DETEKSI PERUBAHAN LED STATUS (SAMA seperti zone)
    if (_isAccumulationMode != isLEDBellOn) {
      if (!isLEDBellOn) {
        // LED mati - switch ke real-time mode dan reset (SAMA seperti zone)
        reset();
      }
      _isAccumulationMode = isLEDBellOn;
      _lastBellLEDStatusChange = DateTime.now();
    }

    // Akumulasi bell saat LED ON (SAMA seperti zone)
    if (_isAccumulationMode && hasBell) {
      // 🛡️ MEMORY PROTECTION: Check accumulator size before adding
      if (_accumulatedBellSlaves.length >= maxBells) {
        
      } else {
        _accumulatedBellSlaves.add(slaveAddress);
      }
    }

    // 📊 PERFORMANCE MONITORING: Record performance metrics
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    _totalUpdates++;
    _totalProcessingTimeMs += elapsedMs;
    _lastUpdateTime = DateTime.now();

    if (elapsedMs > _maxUpdateTimeMs) {
      _maxUpdateTimeMs = elapsedMs;
    }
    if (elapsedMs < _minUpdateTimeMs) {
      _minUpdateTimeMs = elapsedMs;
    }

    // Log performance warnings if needed
    if (elapsedMs > 5) { // Warn if > 5ms
      
    }
  }

  /// Check if a bell is accumulated
  bool isBellAccumulated(String slaveAddress) {
    return _accumulatedBellSlaves.contains(slaveAddress);
  }

  /// Get current accumulation mode status
  bool get isAccumulationMode => _isAccumulationMode;

  /// Get time since last LED status change
  Duration? get timeSinceLastLEDChange {
    if (_lastBellLEDStatusChange == null) return null;
    return DateTime.now().difference(_lastBellLEDStatusChange!);
  }

  /// Get accumulated bell slaves (read-only copy)
  Set<String> get accumulatedBellSlaves => Set.unmodifiable(_accumulatedBellSlaves);

  /// Get accumulated bell count
  int get accumulatedBellCount => _accumulatedBellSlaves.length;

  /// Reset semua bell status (SAMA seperti zone.reset())
  void reset() {
    
    _accumulatedBellSlaves.clear();
    _isAccumulationMode = false;
    _lastBellLEDStatusChange = null;

    // 📊 PERFORMANCE MONITORING: Reset performance metrics
    _totalUpdates = 0;
    _totalProcessingTimeMs = 0;
    _lastUpdateTime = null;
    _maxUpdateTimeMs = 0;
    _minUpdateTimeMs = 0x7FFFFFFF;

    
  }

  /// Get detailed accumulator status for debugging
  Map<String, dynamic> getAccumulatorStatus() {
    final avgProcessingTimeMs = _totalUpdates > 0 ? (_totalProcessingTimeMs / _totalUpdates).round() : 0;

    return {
      'isAccumulationMode': _isAccumulationMode,
      'lastBellLEDStatusChange': _lastBellLEDStatusChange?.toIso8601String(),
      'timeSinceLastLEDChange': timeSinceLastLEDChange?.inMilliseconds,
      'accumulatedBellCount': accumulatedBellCount,
      'accumulatedBellSlaves': accumulatedBellSlaves.toList(),
      // 📊 PERFORMANCE MONITORING: Add performance metrics
      'performance': {
        'totalUpdates': _totalUpdates,
        'totalProcessingTimeMs': _totalProcessingTimeMs,
        'averageProcessingTimeMs': avgProcessingTimeMs,
        'maxUpdateTimeMs': _maxUpdateTimeMs,
        'minUpdateTimeMs': _minUpdateTimeMs == 0x7FFFFFFF ? 0 : _minUpdateTimeMs,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
        'memoryUsage': {
          'accumulatedBellSlaves': _accumulatedBellSlaves.length,
          'totalMemoryBytes': _accumulatedBellSlaves.length * 20 + 4000, // Estimated
        },
      },
    };
  }
}

/// Zone accumulator for tracking zones that ever alarmed during LED ON periods
class ZoneAccumulator {
  // 🛡️ MEMORY PROTECTION: Maximum zones (63 devices × 5 zones)
  static const int maxZones = 315;
  static const int maxAccumulatedZones = 315; // Same as max zones for safety

  // Sets for O(1) operations and memory efficiency
  final Set<int> _accumulatedAlarmZones = <int>{};
  final Set<int> _accumulatedTroubleZones = <int>{};

  // LED-based accumulation mode control
  bool _isAccumulationMode = false;
  DateTime? _lastLEDStatusChange;

  // 📊 PERFORMANCE MONITORING: Track performance metrics
  int _totalUpdates = 0;
  int _totalProcessingTimeMs = 0;
  DateTime? _lastUpdateTime;
  int _maxUpdateTimeMs = 0;
  int _minUpdateTimeMs = 0x7FFFFFFF; // Max int value

  /// Add or update zone status in accumulation
  void updateZoneStatus(int zoneNumber, ZoneStatus status, bool isLEDAlarmOn) {
    // 📊 PERFORMANCE MONITORING: Start timing
    final stopwatch = Stopwatch()..start();

    // 🛡️ VALIDATION: Check zone number range (1-315 for 63 devices × 5 zones)
    if (zoneNumber < 1 || zoneNumber > 315) {
      
      return;
    }

    // Check if LED alarm status changed
    if (_isAccumulationMode != isLEDAlarmOn) {
      if (!isLEDAlarmOn) {
        // LED turned off - switch to real-time mode
        reset();
      }
      _isAccumulationMode = isLEDAlarmOn;
      _lastLEDStatusChange = DateTime.now();
    }

    // Only accumulate when LED alarm is ON (accumulation mode)
    if (_isAccumulationMode) {
      // 🛡️ MEMORY PROTECTION: Check accumulator size before adding
      if (status.hasAlarm) {
        if (_accumulatedAlarmZones.length >= maxAccumulatedZones) {
          
        } else {
          _accumulatedAlarmZones.add(zoneNumber);
        }
      }
      if (status.hasTrouble) {
        if (_accumulatedTroubleZones.length >= maxAccumulatedZones) {
          
        } else {
          _accumulatedTroubleZones.add(zoneNumber);
        }
      }
    }

    // 📊 PERFORMANCE MONITORING: Record performance metrics
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;

    _totalUpdates++;
    _totalProcessingTimeMs += elapsedMs;
    _lastUpdateTime = DateTime.now();

    if (elapsedMs > _maxUpdateTimeMs) {
      _maxUpdateTimeMs = elapsedMs;
    }
    if (elapsedMs < _minUpdateTimeMs) {
      _minUpdateTimeMs = elapsedMs;
    }

    // Log performance warnings if needed
    if (elapsedMs > 5) { // Warn if > 5ms
      
    }
  }

  /// Check if a zone is accumulated as alarm
  bool isZoneAccumulatedAlarm(int zoneNumber) {
    // 🛡️ VALIDATION: Check zone number range
    if (zoneNumber < 1 || zoneNumber > 315) {
      
      return false;
    }
    return _accumulatedAlarmZones.contains(zoneNumber);
  }

  /// Check if a zone is accumulated as trouble
  bool isZoneAccumulatedTrouble(int zoneNumber) {
    // 🛡️ VALIDATION: Check zone number range
    if (zoneNumber < 1 || zoneNumber > 315) {
      
      return false;
    }
    return _accumulatedTroubleZones.contains(zoneNumber);
  }

  /// Get current accumulation mode status
  bool get isAccumulationMode => _isAccumulationMode;

  /// Get time since last LED status change
  Duration? get timeSinceLastLEDChange {
    if (_lastLEDStatusChange == null) return null;
    return DateTime.now().difference(_lastLEDStatusChange!);
  }

  /// Get accumulated alarm zones (read-only copy)
  Set<int> get accumulatedAlarmZones => Set.unmodifiable(_accumulatedAlarmZones);

  /// Get accumulated trouble zones (read-only copy)
  Set<int> get accumulatedTroubleZones => Set.unmodifiable(_accumulatedTroubleZones);

  /// Get accumulated alarm count
  int get accumulatedAlarmCount => _accumulatedAlarmZones.length;

  /// Get accumulated trouble count
  int get accumulatedTroubleCount => _accumulatedTroubleZones.length;

  /// Reset accumulator (when LED turns off)
  void reset() {
    _accumulatedAlarmZones.clear();
    _accumulatedTroubleZones.clear();
    _isAccumulationMode = false;
    _lastLEDStatusChange = null;

    // 📊 PERFORMANCE MONITORING: Reset performance metrics
    _totalUpdates = 0;
    _totalProcessingTimeMs = 0;
    _lastUpdateTime = null;
    _maxUpdateTimeMs = 0;
    _minUpdateTimeMs = 0x7FFFFFFF;

    
  }

  /// Get detailed accumulator status for debugging
  Map<String, dynamic> getAccumulatorStatus() {
    final avgProcessingTimeMs = _totalUpdates > 0 ? (_totalProcessingTimeMs / _totalUpdates).round() : 0;

    return {
      'isAccumulationMode': _isAccumulationMode,
      'lastLEDStatusChange': _lastLEDStatusChange?.toIso8601String(),
      'timeSinceLastLEDChange': timeSinceLastLEDChange?.inMilliseconds,
      'accumulatedAlarmCount': accumulatedAlarmCount,
      'accumulatedTroubleCount': accumulatedTroubleCount,
      'accumulatedAlarmZones': accumulatedAlarmZones.toList(),
      'accumulatedTroubleZones': accumulatedTroubleZones.toList(),
      // 📊 PERFORMANCE MONITORING: Add performance metrics
      'performance': {
        'totalUpdates': _totalUpdates,
        'totalProcessingTimeMs': _totalProcessingTimeMs,
        'averageProcessingTimeMs': avgProcessingTimeMs,
        'maxUpdateTimeMs': _maxUpdateTimeMs,
        'minUpdateTimeMs': _minUpdateTimeMs == 0x7FFFFFFF ? 0 : _minUpdateTimeMs,
        'lastUpdateTime': _lastUpdateTime?.toIso8601String(),
        'memoryUsage': {
          'accumulatedAlarmZones': _accumulatedAlarmZones.length,
          'accumulatedTroubleZones': _accumulatedTroubleZones.length,
          'totalMemoryBytes': (_accumulatedAlarmZones.length + _accumulatedTroubleZones.length) * 4 + 8000, // Estimated
        },
      },
    };
  }
}
