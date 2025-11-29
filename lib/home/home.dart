import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../core/fire_alarm_data.dart';
import '../constants/app_constants.dart';
import '../services/logger.dart';
import '../services/websocket_mode_manager.dart';
import '../widgets/websocket_toggle_button.dart';
import '../widgets/esp32_ip_dialog.dart';


class HomePage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const HomePage({super.key, this.scaffoldKey});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin<HomePage> {
  List<String> _availableDates = [];
  String _selectedDate = '';
  String _selectedTab = 'recent'; // Default to recent status tab
  late TabController _tabController;
  late ScrollController _scrollController;

  // 🚀 NEW: WebSocket Mode Manager (using singleton)
  late WebSocketModeManager _webSocketModeManager;
  
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    _scrollController = ScrollController();

    // 🚀 NEW: Initialize WebSocket Mode Manager (singleton)
    _webSocketModeManager = WebSocketModeManager.instance;

    // Optimized: Reduced delay and immediate initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Minimal delay to ensure FireAlarmData is ready
      Future.delayed(AppConstants.shortDelay, () {
        if (mounted) {
          _initializeDates();
          // Listen for changes in activity logs
          context.read<FireAlarmData>().addListener(_onActivityLogsChanged);

          // NEW: Initialize WebSocket manager with FireAlarmData
          _initializeWebSocketManager();
        }
      });
    });
  }
  
  // NEW: Initialize WebSocket Manager
  Future<void> _initializeWebSocketManager() async {
    try {
      final fireAlarmData = context.read<FireAlarmData>();

      // Force reset to Firebase mode untuk troubleshooting
      await _webSocketModeManager.forceResetToFirebaseMode();
      await _webSocketModeManager.initializeManager(fireAlarmData);

      // Listen to WebSocket status changes
      _webSocketModeManager.addListener(_onWebSocketStatusChanged);

      AppLogger.info('WebSocket manager initialized in home page', tag: 'HOME_WS');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error initializing WebSocket manager',
        tag: 'HOME_WS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  // NEW: Handle WebSocket status changes
  void _onWebSocketStatusChanged() {
    if (mounted) {
      setState(() {
        // UI will update automatically through AnimatedBuilder
      });
    }
  }

  // Listener for activity logs changes - Optimized
  void _onActivityLogsChanged() {
    if (mounted) {
      // Debounce rapid changes to avoid excessive re-initialization
      Future.delayed(AppConstants.debounceDelay, () {
        if (mounted) {
          _initializeDates();
        }
      });
    }
  }
  
  @override
  void dispose() {
    // Remove listener when widget is disposed
    if (mounted) {
      try {
        context.read<FireAlarmData>().removeListener(_onActivityLogsChanged);
      } catch (e) {
        // Context might not be available during disposal
        AppLogger.error('Error removing listener', error: e);
      }
    }

    // NEW: Dispose WebSocket manager
    try {
      _webSocketModeManager.removeListener(_onWebSocketStatusChanged);
      _webSocketModeManager.dispose();
    } catch (e) {
      AppLogger.error('Error disposing WebSocket manager', error: e);
    }

    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _initializeDates() {
    final fireAlarmData = context.read<FireAlarmData>();
    final logs = fireAlarmData.activityLogs;

    // Optimized: Skip processing if logs are empty
    if (logs.isEmpty) {
      if (mounted) {
        setState(() {
          _availableDates = [];
          _selectedDate = '';
        });
      }
      return;
    }

    // Optimized: Use Set comprehension for faster processing
    final Set<String> uniqueDates = logs
        .where((log) => (log['date'] as String?)?.isNotEmpty == true)
        .map((log) => log['date'] as String)
        .toSet();

    // Sort dates (newest first)
    final sortedDates = uniqueDates.toList()
      ..sort((a, b) => _compareDates(b, a));

    // Set selected date to today if available, otherwise to newest
    final today = DateFormat('dd/MM/yyyy').format(DateTime.now());
    final selectedDate = sortedDates.contains(today) ? today : (sortedDates.isNotEmpty ? sortedDates.first : '');

    if (mounted) {
      setState(() {
        _availableDates = sortedDates;
        _selectedDate = selectedDate;
      });

      // Update tab controller
      _tabController.dispose();
      _tabController = TabController(length: _availableDates.length, vsync: this);

      // Find index of selected date and animate
      final selectedIndex = _availableDates.indexOf(_selectedDate);
      if (selectedIndex >= 0) {
        _tabController.animateTo(selectedIndex);
      }

      // Auto-scroll to selected date after a short delay
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToSelectedDate();
      });
    }

    // Minimal debug logging
    AppLogger.info('Dates updated: ${_availableDates.length} dates, selected: $_selectedDate', tag: 'DATES');
  }

  
  // NEW: Build enhanced header with WebSocket components
  Widget _buildEnhancedHeader(bool isFirebaseConnected) {
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
              : FireAlarmData.logoWidth;
          final responsiveLogoHeight = isSmallScreen
              ? 30.0
              : isMediumScreen
              ? 35.0
              : FireAlarmData.logoHeight;

          // Responsive connection status text
          final showFullConnectionText = screenWidth > 320;

          return Stack(
            children: [
              // Logo in the center-left with responsive sizing
              Positioned(
                left: FireAlarmData.logoLeftPadding, // Space for hamburger menu
                top: 0,
                bottom: 0,
                child: Center(
                  child: Image.asset(
                    FireAlarmData.logoAssetPath,
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
                          child: Icon(
                            Icons.warning,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Hamburger menu on the left (PRESERVED)
              Positioned(
                left: FireAlarmData.hamburgerLeftPadding,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: FireAlarmData.hamburgerIconColor,
                      size: FireAlarmData.hamburgerIconSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Use scaffoldKey if provided, otherwise try to find Scaffold
                      final scaffoldKey = widget.scaffoldKey;
                      if (scaffoldKey != null && scaffoldKey.currentState != null) {
                        scaffoldKey.currentState!.openDrawer();
                      } else {
                        // Fallback: try to find Scaffold in context
                        if (context.mounted) {
                          Scaffold.of(context).openDrawer();
                        }
                      }
                    },
                  ),
                ),
              ),

              // NEW: WebSocket Toggle Button in CENTER
              Positioned(
                left: 0, right: 0, top: 0, bottom: 0,
                child: Center(
                  child: WebSocketToggleButton(
                    manager: _webSocketModeManager,
                    padding: EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
              ),

              // Connection Status on the right (DYNAMIC based on mode) - Safe area
              Positioned(
                right: 20, // Safe area margin from right edge
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _webSocketModeManager,
                    builder: (context, child) {
                      String statusText;
                      Color statusColor;

                      if (_webSocketModeManager.isConnecting) {
                        statusText = 'CONNECTING...';
                        statusColor = Colors.orange;
                      } else if (_webSocketModeManager.isWebSocketMode) {
                        statusText = 'LOCAL MODE';
                        statusColor = _webSocketModeManager.isConnected
                            ? Colors.green
                            : Colors.grey;
                      } else {
                        // Firebase mode
                        statusText = isFirebaseConnected ? 'ONLINE MODE' : 'DISCONNECTED';
                        statusColor = isFirebaseConnected
                            ? FireAlarmData.connectionActiveColor
                            : FireAlarmData.connectionInactiveColor;
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isSmallScreen ? 6 : 8,
                            height: isSmallScreen ? 6 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          if (showFullConnectionText) ...[
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontSize: isSmallScreen ? 8 : 10,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ),
              ),

  
              ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hitung tinggi untuk Recent Status container berdasarkan ukuran layar
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Subtract approximate bottom navigation bar height (56) and safe area
    final availableHeight =
        screenHeight - 56 - bottomPadding - 100; // Extra buffer

    double recentStatusHeight;
    if (screenWidth <= AppConstants.smallScreenBreakpoint) {
      recentStatusHeight = availableHeight * 0.3; // Reduced from 0.35
    } else if (screenWidth <= AppConstants.mediumScreenBreakpoint) {
      recentStatusHeight = AppConstants.recentStatusHeightSmall;
    } else if (screenWidth <= AppConstants.largeScreenBreakpoint) {
      recentStatusHeight = 300.0; // Reduced from 350
    } else {
      recentStatusHeight = 350.0; // Reduced from 400
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
              // Unified Status Bar - Custom layout for home page with WebSocket support
              Consumer<FireAlarmData>(
                builder: (context, fireAlarmData, child) {
                  return Column(
                    children: [
                      // NEW: Enhanced Header with WebSocket components
                      _buildEnhancedHeader(
                        fireAlarmData.isFirebaseConnected,
                      ),

                      // Custom Project Information Section with Panel Image
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(top: 5, bottom: 15),
                        color: Colors.white,
                        child: Column(
                          children: [
                            // NEW: ESP32 IP Display (tappable for configuration)
                            QuickIPSelector(
                              manager: _webSocketModeManager,
                              currentIP: _webSocketModeManager.esp32IP,
                              onIPSelected: (ip) {
                                AppLogger.info('ESP32 IP selected via quick selector: $ip', tag: 'HOME_WS');
                              },
                            ),

                            const SizedBox(height: 8),

                            // Project Name
                            Text(
                              fireAlarmData.projectName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 28,
                                letterSpacing: 1.5,
                              ),
                            ),
                            
                            // Panel Image
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Image.asset(
                                  'assets/data/images/PANEL.png',
                                  width: 180,
                                  height: 200,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 180,
                                      height: 200,
                                      decoration: BoxDecoration(
                                        color: Colors.red[400],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.warning_amber_rounded,
                                              size: 60,
                                              color: Colors.white,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'FIRE PANEL',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // Panel Type
                            Text(
                              fireAlarmData.panelType,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.5,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Module and Zone Count
                            Text(
                              (!fireAlarmData.isFirebaseConnected ||
                                      fireAlarmData.numberOfModules == 0 ||
                                      fireAlarmData.numberOfZones == 0)
                                  ? 'XX MODULES • XX ZONES'
                                  : '${fireAlarmData.numberOfModules} MODULES • ${fireAlarmData.numberOfZones} ZONES',
                              style: const TextStyle(
                                fontSize: 20,
                                color: Colors.black87,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // System Status Section
                      _buildSystemStatusSection(context, fireAlarmData),

                      // Status Indicators Section  
                      _buildStatusIndicatorsSection(context, fireAlarmData),
                    ],
                  );
                },
              ),

              // Additional spacing after status bar
              const SizedBox(height: 10),

              // Tab Container for RECENT STATUS and FIRE ALARM
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 15, bottom: 8),
                child: Column(
                  children: [
                    // Tab Headers
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          // RECENT STATUS Tab
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
                                      ? const Color.fromARGB(255, 19, 137, 47).withAlpha(38)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: _selectedTab == 'recent'
                                      ? Border.all(
                                          color: const Color.fromARGB(255, 10, 103, 39),
                                          width: 1.5)
                                      : null,
                                ),
                                child: Text(
                                  'RECENT STATUS',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _selectedTab == 'recent'
                                        ? const Color.fromARGB(255, 10, 103, 39)
                                        : Colors.grey[600],
                                    fontWeight: _selectedTab == 'recent'
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // FIRE ALARM Tab
                          Expanded(
                            child: Consumer<FireAlarmData>(
                              builder: (context, fireAlarmData, child) {
                                bool hasActiveAlarm = fireAlarmData.hasAlarmZones();
                                bool isFireAlarmTab = _selectedTab == 'fire_alarm';

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedTab = 'fire_alarm';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isFireAlarmTab
                                          ? (hasActiveAlarm
                                              ? Colors.red.withAlpha(38)
                                              : Colors.grey.withAlpha(38))
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isFireAlarmTab
                                          ? Border.all(
                                              color: hasActiveAlarm ? Colors.red : Colors.grey,
                                              width: 1.5)
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'FIRE ALARM',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: isFireAlarmTab
                                                ? (hasActiveAlarm ? Colors.red : Colors.black)
                                                : (hasActiveAlarm ? Colors.red : Colors.grey[600]),
                                            fontWeight: isFireAlarmTab
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 15,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                        if (hasActiveAlarm && !isFireAlarmTab) ...[
                                          const SizedBox(width: 4),
                                          Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tab Content
                    _selectedTab == 'recent' && _availableDates.isNotEmpty
                        ? _buildDateTabs()
                        : const SizedBox.shrink(),
                  ],
                ),
              ),


              // Dynamic Container berdasarkan tab yang dipilih
              Consumer<FireAlarmData>(
                builder: (context, fireAlarmData, child) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Container(
                        height: recentStatusHeight,
                        margin: const EdgeInsets.fromLTRB(15, 0, 15, 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _selectedTab == 'fire_alarm'
                              ? (fireAlarmData.hasAlarmZones() ? Colors.red[50] : Colors.grey[50])
                              : Colors.grey[50],
                          border: Border.all(
                            color: _selectedTab == 'fire_alarm'
                                ? (fireAlarmData.hasAlarmZones() ? Colors.red[300]! : Colors.grey[300]!)
                                : Colors.grey[300]!
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _selectedTab == 'recent'
                            ? (fireAlarmData.activityLogs.isNotEmpty && _selectedDate.isNotEmpty
                                ? _buildDateActivityLogs(fireAlarmData.activityLogs, _selectedDate)
                                : Center(
                                    child: Text(
                                      'No recent activity',
                                      style: TextStyle(
                                        fontSize: _calculateActivityLogFontSize(context) + 2,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ))
                            : _buildFireAlarmContainer(fireAlarmData),
                      );
                    },
                  );
                },
              ),

              // Footer info (optional)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '© 2025 DDS Fire Alarm System',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ),

              // Bottom spacing
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Build date tabs with carousel-style horizontal scroll
  Widget _buildDateTabs() {
    // Sort dates from oldest to newest for horizontal scroll
    List<String> sortedDates = List<String>.from(_availableDates);
    sortedDates.sort((a, b) => _compareDates(a, b));

    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive item width based on screen size
    double itemWidth;

    if (screenWidth <= 360) {
      itemWidth = 90.0; // Very small screens
    } else if (screenWidth <= 412) {
      itemWidth = 100.0; // Small phones
    } else {
      itemWidth = 110.0; // Default size
    }

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        controller: _scrollController,
        itemCount: sortedDates.length,
        itemBuilder: (context, index) {
          String date = sortedDates[index];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
              // Animate to this item
              _scrollToSelectedDate();
            },
            child: Container(
              width: itemWidth,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: _selectedDate == date
                    ? const Color.fromARGB(255, 19, 137, 47).withAlpha(38)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: _selectedDate == date
                    ? Border.all(
                        color: const Color.fromARGB(255, 10, 103, 39),
                        width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  date, // Display full date format (dd/MM/yyyy)
                  style: TextStyle(
                    fontSize: _calculateDateTabFontSize(context), // Responsive font size for foldables
                    fontWeight:
                        _selectedDate == date ? FontWeight.w700 : FontWeight.w500,
                    color: _selectedDate == date
                        ? const Color.fromARGB(255, 10, 103, 39)
                        : Colors.grey[700],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Build activity logs for selected date
  Widget _buildDateActivityLogs(List<Map<String, dynamic>> logs, String selectedDate) {
    // Filter logs for selected date
    List<Map<String, dynamic>> dateLogs = logs
        .where((log) => log['date'] == selectedDate)
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (dateLogs.isEmpty) {
          return Center(
            child: Text(
              'No activity for this date',
              style: TextStyle(
                fontSize: _calculateActivityLogFontSize(context),
                color: Colors.grey,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: dateLogs.length,
          itemBuilder: (context, index) {
            final log = dateLogs[index];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey[50]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      log['activity'] ?? '',
                      style: TextStyle(
                        fontSize: _calculateActivityLogFontSize(context),
                        color: Colors.black87,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ),
              );
          },
        );
      },
    );
  }


  // Method to scroll to the selected date (for horizontal carousel)
  void _scrollToSelectedDate() {
    if (_availableDates.isEmpty || !_scrollController.hasClients) return;
    
    // Sort dates from oldest to newest for consistent indexing
    List<String> sortedDates = List<String>.from(_availableDates);
    sortedDates.sort((a, b) => _compareDates(a, b));
    
    int selectedIndex = sortedDates.indexOf(_selectedDate);
    if (selectedIndex < 0) return;
    
    // Calculate responsive item width
    final screenWidth = MediaQuery.of(context).size.width;
    double itemWidth;
    if (screenWidth <= 360) {
      itemWidth = 90.0;
    } else if (screenWidth <= 412) {
      itemWidth = 100.0;
    } else {
      itemWidth = 110.0;
    }
    
    // Calculate scroll position (each item width + margin)
    double itemTotalWidth = itemWidth + 8; // itemWidth + horizontal margin (4+4)
    double targetScrollPosition = selectedIndex * itemTotalWidth;
    
    // Animate to the selected position
    _scrollController.animateTo(
      targetScrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // Helper method to compare dates in dd/MM/yyyy format
  int _compareDates(String date1, String date2) {
    try {
      List<String> parts1 = date1.split('/');
      List<String> parts2 = date2.split('/');
      
      if (parts1.length != 3 || parts2.length != 3) return 0;
      
      DateTime dt1 = DateTime(
        int.parse(parts1[2]), // year
        int.parse(parts1[1]), // month
        int.parse(parts1[0]), // day
      );
      
      DateTime dt2 = DateTime(
        int.parse(parts2[2]), // year
        int.parse(parts2[1]), // month
        int.parse(parts2[0]), // day
      );
      
      return dt1.compareTo(dt2);
    } catch (e) {
      return 0;
    }
  }

  // Build System Status Section
  Widget _buildSystemStatusSection(BuildContext context, FireAlarmData fireAlarmData) {
    // Determine status using enhanced detection
    String statusText;
    Color statusColor;
    Color textColor;

    if (fireAlarmData.isResetting) {
      statusText = 'SYSTEM RESETTING';
      statusColor = Colors.white;
      textColor = Colors.black;
    } else {
      // 🎯 Use Simple Status Manager with your exact 4 rules
      statusText = fireAlarmData.getSimpleSystemStatusWithDetection();
      statusColor = fireAlarmData.getSimpleSystemStatusColorWithDetection();
      
      // 🎯 Consistent status colors - Alarm=Red, Trouble=Orange, Normal=Blue, No Data=Grey
      if (statusText == 'SYSTEM TROUBLE') {
        statusColor = Colors.orange;
        textColor = Colors.white;
      } else if (statusText == 'ALARM') {
        statusColor = Colors.red;
        textColor = Colors.white;
      } else if (statusText == 'SYSTEM NORMAL') {
        statusColor = Colors.green;
        textColor = Colors.white;
      } else if (statusText == 'NO DATA') {
        statusColor = Colors.grey;
        textColor = Colors.white;
      } else {
        textColor = Colors.white;
      }
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 5),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: statusColor.withAlpha(77),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            statusText,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }

  // Build Status Indicators Section
  Widget _buildStatusIndicatorsSection(BuildContext context, FireAlarmData fireAlarmData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatusIndicator('AC POWER', 'AC Power', fireAlarmData),
                _buildStatusIndicator('DC POWER', 'DC Power', fireAlarmData),
                _buildStatusIndicator('ALARM', 'Alarm', fireAlarmData),
                _buildStatusIndicator('TROUBLE', 'Trouble', fireAlarmData),
                _buildStatusIndicator('DRILL', 'Drill', fireAlarmData),
                _buildStatusIndicator('SILENCED', 'Silenced', fireAlarmData),
                _buildStatusIndicator('DISABLED', 'Disabled', fireAlarmData),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Calculate responsive font size based on screen diagonal
  double _calculateResponsiveFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = _calculateDiagonal(size.width, size.height);
    final baseSize = diagonal / 100;
    return baseSize.clamp(8.0, 15.0);
  }

  // Calculate screen diagonal
  double _calculateDiagonal(double width, double height) {
    return math.sqrt(width * width + height * height);
  }

  // Calculate responsive font size for activity log - optimized for foldable devices
  double _calculateActivityLogFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Handle foldable devices with specific breakpoints
    if (screenWidth <= 320) {
      // Very small/folded screens
      return 7.0;
    } else if (screenWidth <= 360) {
      // Small phones and folded foldables
      return 8.0;
    } else if (screenWidth <= 412) {
      // Regular phones
      return 9.0;
    } else if (screenWidth <= 480) {
      // Large phones / small tablets
      return 10.0;
    } else if (screenWidth <= AppConstants.mediumScreenBreakpoint) {
      // Tablets and unfolded foldables (compact mode)
      return 11.0;
    } else if (screenWidth <= 768) {
      // Tablets
      return 12.0;
    } else if (screenWidth <= 1024) {
      // Large tablets
      return 13.0;
    } else {
      // Desktop and large screens
      return 14.0;
    }
  }

  // Calculate responsive font size for date tabs - optimized for foldable devices
  double _calculateDateTabFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth <= 320) {
      return 9.0;
    } else if (screenWidth <= 360) {
      return 10.0;
    } else if (screenWidth <= 412) {
      return 11.0;
    } else if (screenWidth <= AppConstants.mediumScreenBreakpoint) {
      return 12.0;
    } else {
      return 13.0;
    }
  }

  // Build Individual Status Indicator
  Widget _buildStatusIndicator(
    String label,
    String statusKey,
    FireAlarmData fireAlarmData,
  ) {
    bool isActive = fireAlarmData.getSystemStatus(statusKey);

    // 🔥 FIXED: LED indicators 100% independent from zone data
    // Use ONLY master status via getSystemStatus() - No Simple Status Manager override!

    final activeColor = fireAlarmData.getActiveColor(statusKey);
    final inactiveColor = fireAlarmData.getInactiveColor(statusKey);
    final baseFontSize = _calculateResponsiveFontSize(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: baseFontSize * 0.9,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        SizedBox(height: baseFontSize * 0.4),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(102),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
        
              ],
    );
  }

  // Build Fire Alarm Container untuk menampilkan zona yang sedang alarm
  Widget _buildFireAlarmContainer(FireAlarmData fireAlarmData) {
    // Get alarm zones from FireAlarmData
    final alarmZones = fireAlarmData.getActiveAlarmZones();

    if (alarmZones.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Colors.grey[500],
            ),
            const SizedBox(height: 12),
            Text(
              'NO FIRE ALARM',
              style: TextStyle(
                fontSize: _calculateActivityLogFontSize(context) + 4,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All zones are normal',
              style: TextStyle(
                fontSize: _calculateActivityLogFontSize(context),
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header dengan alarm count
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.red[300]!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning,
                color: Colors.red[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${alarmZones.length} ZONE${alarmZones.length > 1 ? 'S' : ''} IN ALARM',
                style: TextStyle(
                  fontSize: _calculateActivityLogFontSize(context) + 2,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // List of alarm zones
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: alarmZones.length,
            itemBuilder: (context, index) {
              final zone = alarmZones[index];
              final zoneNumber = zone['zoneNumber'] as int? ?? 0;
              final areaName = zone['area'] as String? ?? 'Unknown Area';
              final timestamp = zone['timestamp'] as String? ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.red[200]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withAlpha(25),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Zone indicator
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withAlpha(100),
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Zone info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ZONE ${zoneNumber.toString().padLeft(2, '0')} - $areaName',
                            style: TextStyle(
                              fontSize: _calculateActivityLogFontSize(context) + 1,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                          if (timestamp.isNotEmpty)
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: _calculateActivityLogFontSize(context) - 1,
                                color: Colors.red[600],
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Alarm icon
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.red[600],
                      size: 20,
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

}
