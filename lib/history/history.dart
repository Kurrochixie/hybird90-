import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../core/fire_alarm_data.dart';
import '../config/ui_constants.dart';


class HistoryPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const HistoryPage({super.key, this.scaffoldKey});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Date picker state management
  List<String> _availableDates = [];
  String _selectedDate = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Initialize date picker after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDates();
      _setupLogListener();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to calculate font size based on screen diagonal
  double calculateFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );
    final baseSize = diagonal / 100;
    return baseSize.clamp(8.0, 15.0);
  }

  // Function to get responsive multiplier
  double getResponsiveMultiplier(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 1.0;
    if (screenWidth <= 600) return 1.3;
    if (screenWidth <= 900) return 1.5;
    return 1.8;
  }

  // Date picker functionality
  void _initializeDates() {
    final fireAlarmData = context.read<FireAlarmData>();
    final logHandler = fireAlarmData.logHandler;

    // Get all log types
    final statusLogs = logHandler.statusLogs;
    final connectionLogs = logHandler.connectionLogs;
    final troubleLogs = logHandler.troubleLogs;
    final fireLogs = logHandler.fireLogs;

    final totalLogs = statusLogs.length + connectionLogs.length + troubleLogs.length + fireLogs.length;
    
    
    
    
    

    // Extract unique dates from ALL log types
    final Set<String> uniqueDates = {};

    // Add dates from each log type
    uniqueDates.addAll(
      statusLogs
          .where((log) => (log['date'] as String?)?.isNotEmpty == true)
          .map((log) => log['date'] as String)
    );

    uniqueDates.addAll(
      connectionLogs
          .where((log) => (log['date'] as String?)?.isNotEmpty == true)
          .map((log) => log['date'] as String)
    );

    uniqueDates.addAll(
      troubleLogs
          .where((log) => (log['date'] as String?)?.isNotEmpty == true)
          .map((log) => log['date'] as String)
    );

    uniqueDates.addAll(
      fireLogs
          .where((log) => (log['date'] as String?)?.isNotEmpty == true)
          .map((log) => log['date'] as String)
    );

    

    // Sort dates (newest first)
    final sortedDates = uniqueDates.toList()
      ..sort((a, b) => _compareDates(b, a));

    setState(() {
      _availableDates = sortedDates;
      _selectedDate = 'ALL'; // Default to "ALL" untuk menampilkan semua log
    });

    
  }

  // 🆕 Refresh trouble logs
  Future<void> _refreshTroubleLogs() async {
    final fireAlarmData = context.read<FireAlarmData>();
    await fireAlarmData.logHandler.refreshTroubleLogs();

    // Reinitialize dates after refresh
    if (mounted) {
      _initializeDates();
    }
  }

  // Add listener to refresh dates when logs update
  void _setupLogListener() {
    final fireAlarmData = context.read<FireAlarmData>();

    // Listen for log changes and refresh dates
    fireAlarmData.logHandler.addListener(() {
      if (mounted) {
        
        _initializeDates();
      }
    });
  }

  // Date comparison logic (from home.dart)
  int _compareDates(String date1, String date2) {
    try {
      final List<String> parts1 = date1.split('/');
      final List<String> parts2 = date2.split('/');

      if (parts1.length != 3 || parts2.length != 3) {
        return 0;
      }

      final DateTime dt1 = DateTime(
        int.parse(parts1[2]), // year
        int.parse(parts1[1]), // month
        int.parse(parts1[0]), // day
      );

      final DateTime dt2 = DateTime(
        int.parse(parts2[2]), // year
        int.parse(parts2[1]), // month
        int.parse(parts2[0]), // day
      );

      return dt1.compareTo(dt2);
    } catch (e) {
      // Date comparison failed - assume dates are equal
      print('Warning: Date comparison failed: $e');
      return 0;
    }
  }

  // Date selection handler
  void _onDateSelected(String date) {
    setState(() {
      _selectedDate = date;
    });
  }

  // Filter logs based on selected date
  List<Map<String, dynamic>> _getFilteredTroubleLogs(List<Map<String, dynamic>> logs) {
    // Filter by status first - only TROUBLE, FIXED, DISCONNECTED
    var filteredLogs = logs.where((log) {
      final status = log['status']?.toString().toUpperCase();
      return ['TROUBLE', 'FIXED', 'DISCONNECTED'].contains(status);
    }).toList();

    if (_selectedDate == 'ALL' || _selectedDate.isEmpty) {
      return filteredLogs; // Return all trouble logs if "ALL" is selected
    }

    return filteredLogs.where((log) => log['date'] == _selectedDate).toList();
  }

  // Filter fire logs based on selected date
  List<Map<String, dynamic>> _getFilteredFireLogs(List<Map<String, dynamic>> logs) {
    // Filter by status first - only ALARM status
    var filteredLogs = logs.where((log) =>
      log['status']?.toString().toUpperCase() == 'ALARM'
    ).toList();

    if (_selectedDate == 'ALL' || _selectedDate.isEmpty) {
      return filteredLogs; // Return all ALARM logs if "ALL" is selected
    }

    return filteredLogs.where((log) => log['date'] == _selectedDate).toList();
  }

  // Build date picker UI for TROUBLE tab
  Widget _buildDatePicker() {
    final fireAlarmData = context.watch<FireAlarmData>();
    final logHandler = fireAlarmData.logHandler;

    // Show loading state
    if (logHandler.isLoading) {
      return Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Consistent margin
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading dates...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_availableDates.isEmpty) {
      return Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Consistent margin
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 18),
                const SizedBox(width: 8),
                Text(
                  'No dates available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    
                    _initializeDates();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), // Reduced margin
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 🔥 NEW: Date tabs first (oldest on left, newest on right)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                // 🔥 REVERSE INDEX: Show newest dates on the right
                final reversedIndex = _availableDates.length - 1 - index;
                final date = _availableDates[reversedIndex];
                final isSelected = _selectedDate == date;

                return GestureDetector(
                  onTap: () => _onDateSelected(date),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? UIConstants.primaryGreenLight
                          : UIConstants.unselectedBackgroundColor,
                      border: Border.all(
                        color: isSelected
                            ? UIConstants.primaryGreenDark
                            : Colors.transparent,
                        width: isSelected
                            ? UIConstants.selectedBorderWidth
                            : 0,
                      ),
                      borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
                    ),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeM,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? UIConstants.selectedTextColor
                            : UIConstants.unselectedTextColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // 🔥 NEW: "ALL" button moved to the right
          GestureDetector(
            onTap: () => _onDateSelected('ALL'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedDate == 'ALL'
                    ? UIConstants.primaryGreenLight
                    : UIConstants.unselectedBackgroundColor,
                border: Border.all(
                  color: _selectedDate == 'ALL'
                      ? UIConstants.primaryGreenDark
                      : Colors.transparent,
                  width: _selectedDate == 'ALL'
                      ? UIConstants.selectedBorderWidth
                      : 0,
                ),
                borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
              ),
              child: Text(
                'ALL',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: _selectedDate == 'ALL'
                      ? UIConstants.selectedTextColor
                      : UIConstants.unselectedTextColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 🔥 NEW: Refresh button moved to the right
          Consumer<FireAlarmData>(
            builder: (context, fireAlarmData, child) {
              return GestureDetector(
                onTap: fireAlarmData.logHandler.isLoadingMoreTrouble
                    ? null
                    : () async {
                        // Prevent multiple taps while loading
                        if (!fireAlarmData.logHandler.isLoadingMoreTrouble) {
                          await _refreshTroubleLogs();
                        }
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: fireAlarmData.logHandler.isLoadingMoreTrouble
                        ? Colors.grey.shade400
                        : UIConstants.refreshButtonColor,
                    borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
                  ),
                  child: fireAlarmData.logHandler.isLoadingMoreTrouble
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Icon(
                          Icons.refresh,
                          size: 16,
                          color: Colors.white,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Build date picker UI for FIRE tab
  Widget _buildFireDatePicker() {
    final fireAlarmData = context.watch<FireAlarmData>();
    final logHandler = fireAlarmData.logHandler;

    // Show loading state
    if (logHandler.isLoading) {
      return Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.red[600]!)),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading dates...',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_availableDates.isEmpty) {
      return Container(
        height: 45,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning, color: Colors.orange[600], size: 18),
                const SizedBox(width: 8),
                Text(
                  'No dates available',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    
                    _initializeDates();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange[600],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      height: 45,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 🔥 NEW: Date tabs first (oldest on left, newest on right)
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableDates.length,
              itemBuilder: (context, index) {
                // 🔥 REVERSE INDEX: Show newest dates on the right
                final reversedIndex = _availableDates.length - 1 - index;
                final date = _availableDates[reversedIndex];
                final isSelected = _selectedDate == date;

                return GestureDetector(
                  onTap: () => _onDateSelected(date),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? UIConstants.primaryGreenLight
                          : UIConstants.unselectedBackgroundColor,
                      border: Border.all(
                        color: isSelected
                            ? UIConstants.primaryGreenDark
                            : Colors.transparent,
                        width: isSelected
                            ? UIConstants.selectedBorderWidth
                            : 0,
                      ),
                      borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
                    ),
                    child: Text(
                      date,
                      style: TextStyle(
                        fontSize: UIConstants.fontSizeM,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? UIConstants.selectedTextColor
                            : UIConstants.unselectedTextColor,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(width: 8),

          // 🔥 NEW: "ALL" button moved to the right
          GestureDetector(
            onTap: () => _onDateSelected('ALL'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedDate == 'ALL'
                    ? UIConstants.primaryGreenLight
                    : UIConstants.unselectedBackgroundColor,
                border: Border.all(
                  color: _selectedDate == 'ALL'
                      ? UIConstants.primaryGreenDark
                      : Colors.transparent,
                  width: _selectedDate == 'ALL'
                      ? UIConstants.selectedBorderWidth
                      : 0,
                ),
                borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
              ),
              child: Text(
                'ALL',
                style: TextStyle(
                  fontSize: UIConstants.fontSizeS,
                  fontWeight: FontWeight.w600,
                  color: _selectedDate == 'ALL'
                      ? UIConstants.selectedTextColor
                      : UIConstants.unselectedTextColor,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // 🔥 NEW: Refresh button moved to the right
          GestureDetector(
            onTap: () async {
              
              await _refreshFireLogs();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: UIConstants.refreshButtonColor,
                borderRadius: BorderRadius.circular(UIConstants.buttonBorderRadius),
              ),
              child: Icon(
                Icons.refresh,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Refresh FIRE logs method
  Future<void> _refreshFireLogs() async {
    try {
      
      final fireAlarmData = context.read<FireAlarmData>();
      await fireAlarmData.logHandler.refreshLogs();
      // Re-initialize dates to get updated fire log dates
      _initializeDates();
    } catch (e) {
      // Fire logs refresh failed - will use existing data
      print('Warning: Failed to refresh fire logs: $e');
      print('Will display existing fire log data');
    }
  }

  // Function to get table header font size
  double getTableHeaderFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 12.0;
    if (screenWidth <= 600) return 14.0;
    if (screenWidth <= 900) return 16.0;
    return 18.0;
  }

  // Function to get table data font size
  double getTableDataFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 11.0;
    if (screenWidth <= 600) return 13.0;
    if (screenWidth <= 900) return 15.0;
    return 17.0;
  }

  // Function to get table padding
  double getTablePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 8.0;
    if (screenWidth <= 600) return 10.0;
    if (screenWidth <= 900) return 12.0;
    return 14.0;
  }

  // Function to get table column width multiplier
  double getTableColumnMultiplier(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // More granular responsive breakpoints for better table scaling
    if (screenWidth <= 360) return 0.8;  // Small phones
    if (screenWidth <= 412) return 0.9;  // Regular phones
    if (screenWidth <= 480) return 1.0;  // Large phones / Small tablets
    if (screenWidth <= 600) return 1.1;  // Small tablets
    if (screenWidth <= 768) return 1.2;  // Regular tablets
    if (screenWidth <= 900) return 1.3;  // Large tablets
    if (screenWidth <= 1200) return 1.4; // Small desktops
    if (screenWidth <= 1600) return 1.5; // Regular desktops
    return 1.6; // Large desktops
  }

  // NEW: Unified optimal column width calculation for all screen sizes
  Map<String, double> getOptimalColumnWidths(BuildContext context, double availableWidth) {
    try {
      // Safety check - if invalid width, return defaults
      if (availableWidth <= 0 || availableWidth.isInfinite) {
        return {
          'date': 150.0,
          'time': 200.0,
          'zone': 200.0,
          'status': 300.0,
        };
      }

      // ALL SCREEN SIZES - Use desktop formula that works!
      final multiplier = getTableColumnMultiplier(context);

      // Ensure multiplier is valid
      if (multiplier <= 0 || multiplier.isInfinite) {
        return {
          'date': 150.0,
          'time': 200.0,
          'zone': 200.0,
          'status': 300.0,
        };
      }

      double dateWidth = 150 * multiplier;
      double timeWidth = 200 * multiplier;
      double zoneWidth = 200 * multiplier;
      double statusWidth = 300 * multiplier;

      return {
        'date': dateWidth,
        'time': timeWidth,
        'zone': zoneWidth,
        'status': statusWidth,
      };
    } catch (e) {
      // Return safe defaults if any calculation fails
      return {
        'date': 150.0,
        'time': 200.0,
        'zone': 200.0,
        'status': 300.0,
      };
    }
  }

  // NEW: 3-column responsive width calculation for STATUS, CONNECTION tabs
  Map<String, double> getOptimal3ColumnWidths(BuildContext context, double availableWidth) {
    try {
      // Safety check - if invalid width, return defaults
      if (availableWidth <= 0 || availableWidth.isInfinite) {
        return {
          'date': 150.0,
          'time': 200.0,
          'status': 350.0, // Wider status column for 3-column layout
        };
      }

      // ALL SCREEN SIZES - Use desktop formula that works!
      final multiplier = getTableColumnMultiplier(context);

      // Ensure multiplier is valid
      if (multiplier <= 0 || multiplier.isInfinite) {
        return {
          'date': 150.0,
          'time': 200.0,
          'status': 350.0,
        };
      }

      double dateWidth = 150 * multiplier;
      double timeWidth = 200 * multiplier;
      // Give remaining width to status column for better content display
      double statusWidth = (availableWidth - dateWidth - timeWidth - 16); // 16px padding

      // Ensure minimum status width
      if (statusWidth < 250 * multiplier) {
        statusWidth = 350 * multiplier;
      }

      return {
        'date': dateWidth,
        'time': timeWidth,
        'status': statusWidth,
      };
    } catch (e) {
      // Return safe defaults if any calculation fails
      return {
        'date': 150.0,
        'time': 200.0,
        'status': 350.0,
      };
    }
  }

  // NEW: 5-column responsive width calculation for FIRE tab
  Map<String, double> getOptimal5ColumnWidths(BuildContext context, double availableWidth) {
    try {
      // Safety check - if invalid width, return defaults
      if (availableWidth <= 0 || availableWidth.isInfinite) {
        return {
          'date': 120.0,
          'time': 150.0,
          'address': 100.0,
          'zone': 180.0,
          'status': 120.0,
        };
      }

      // ALL SCREEN SIZES - Use desktop formula that works!
      final multiplier = getTableColumnMultiplier(context);

      // Ensure multiplier is valid
      if (multiplier <= 0 || multiplier.isInfinite) {
        return {
          'date': 120.0,
          'time': 150.0,
          'address': 100.0,
          'zone': 180.0,
          'status': 120.0,
        };
      }

      double dateWidth = 120 * multiplier;
      double timeWidth = 150 * multiplier;
      double addressWidth = 100 * multiplier;
      double zoneWidth = 180 * multiplier;
      // Give remaining width to status column for better content display
      double statusWidth = (availableWidth - dateWidth - timeWidth - addressWidth - zoneWidth - 20); // 20px padding

      // Ensure minimum status width
      if (statusWidth < 100 * multiplier) {
        statusWidth = 120 * multiplier;
      }

      return {
        'date': dateWidth,
        'time': timeWidth,
        'address': addressWidth,
        'zone': zoneWidth,
        'status': statusWidth,
      };
    } catch (e) {
      // Return safe defaults if any calculation fails
      return {
        'date': 120.0,
        'time': 150.0,
        'address': 100.0,
        'zone': 180.0,
        'status': 120.0,
      };
    }
  }

  // Check if we should use compact layout for mobile (keeping for compatibility)
  bool shouldUseCompactLayout(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth < 500; // Use compact layout for screens smaller than 500px
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize = calculateFontSize(context);
    final fireAlarmData = context.watch<FireAlarmData>();

    // Better height calculation considering actual screen space
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - topPadding - bottomPadding;

    // Calculate reserved space for headers, footers, etc.
    final reservedSpace = 250.0; // Header + status indicators + tabs + footer + margins (reduced)
    final historyHeight = (availableHeight - reservedSpace).clamp(250.0, availableHeight * 0.8);

    
    
    
    

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Complete header with hamburger, logo, and connection status
              Consumer<FireAlarmData>(
                builder: (context, fireAlarmData, child) {
                  return FireAlarmData.getCompleteHeader(
                    isConnected: fireAlarmData.isFirebaseConnected,
                    scaffoldKey: widget.scaffoldKey,
                  );
                },
              ),

              // Hospital Name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 5, bottom: 15),
                color: Colors.white,
                child: Text(
                  fireAlarmData.projectName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: baseFontSize * 1.8,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // System Info
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  children: [
                    Text(
                      fireAlarmData.panelType,
                      style: TextStyle(
                        fontSize: baseFontSize * 1.6,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (!fireAlarmData.isFirebaseConnected || 
                       fireAlarmData.numberOfModules == 0 || 
                       fireAlarmData.numberOfZones == 0)
                          ? 'XX MODULES • XX ZONES'
                          : '${fireAlarmData.numberOfModules} MODULES • ${fireAlarmData.numberOfZones} ZONES',
                      style: TextStyle(
                        fontSize: baseFontSize * 1.4,
                        color: Colors.black87,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Builder(
                      builder: (context) {
                        final fireAlarmData = context.watch<FireAlarmData>();
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
                          textColor = Colors.white;

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
                          }
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withAlpha(38),
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
                                fontSize: baseFontSize * 2.0,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Status Indicators - Reduced padding
              Container(
                padding: const EdgeInsets.fromLTRB(10, 5, 10, 10), // Reduced padding
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(8), // Reduced inner padding
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatusColumn(
                            'AC POWER',
                            'AC Power',
                            baseFontSize,
                          ),
                          buildStatusColumn(
                            'DC POWER',
                            'DC Power',
                            baseFontSize,
                          ),
                          buildStatusColumn('ALARM', 'Alarm', baseFontSize),
                          buildStatusColumn('TROUBLE', 'Trouble', baseFontSize),
                          buildStatusColumn('DRILL', 'Drill', baseFontSize),
                          buildStatusColumn(
                            'SILENCED',
                            'Silenced',
                            baseFontSize,
                          ),
                          buildStatusColumn(
                            'DISABLED',
                            'Disabled',
                            baseFontSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // History Log Title - Reduced padding
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 10, bottom: 5), // Reduced padding
                child: Text(
                  'HISTORY LOG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: baseFontSize * 1.4,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: const [
                    Tab(text: 'STATUS'),
                    Tab(text: 'CONNECTION'),
                    Tab(text: 'TROUBLE'),
                    Tab(text: 'FIRE'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color.fromARGB(255, 18, 148, 42),
                  labelStyle: TextStyle(
                    fontSize: baseFontSize * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: baseFontSize * 1.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

              // History Log Container - Optimized for Better Height Utilization
              Container(
                width: MediaQuery.of(context).size.width,
                height: historyHeight,
                margin: const EdgeInsets.fromLTRB(10, 3, 10, 3),  // Further reduced margins
                padding: const EdgeInsets.all(8), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Consumer<FireAlarmData>(
                  builder: (context, fireAlarmData, child) {
                    final logHandler = fireAlarmData.logHandler;

                    if (logHandler.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (logHandler.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading logs',
                              style: TextStyle(
                                fontSize: baseFontSize * 1.2,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              logHandler.errorMessage!,
                              style: TextStyle(
                                fontSize: baseFontSize * 0.9,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => logHandler.refreshLogs(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 18, 148, 42),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(fontSize: baseFontSize * 1.0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        buildStatusTable(
                          logHandler.statusLogs,
                          historyHeight - 24,
                        ),
                        buildConnectionTable(
                          logHandler.connectionLogs,
                          historyHeight - 24,
                        ),
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              // Date picker for TROUBLE tab
                              _buildDatePicker(),
                              // TROUBLE table with dynamic height
                              Expanded(
                                child: buildTroubleTable(
                                  _getFilteredTroubleLogs(logHandler.troubleLogs),
                                  historyHeight - 53, // 45px for date picker + 8px for margins
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          child: Column(
                            children: [
                              // Date picker for FIRE tab
                              _buildFireDatePicker(),
                              // FIRE table with dynamic height
                              Expanded(
                                child: buildFireTable(
                                  _getFilteredFireLogs(logHandler.fireLogs),
                                  historyHeight - 53, // 45px for date picker + 8px for margins
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Footer - Reduced padding
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5), // Reduced from 10
                child: Text(
                  '© 2025 DDS Fire Alarm System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize * 0.9, // Slightly smaller
                    color: Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 5), // Reduced from 20
            ],
          ),
        ),
      ),
    );
  }

  // Method to build status column
  Widget buildStatusColumn(
    String label,
    String statusKey,
    double baseFontSize,
  ) {
    final fireAlarmData = context.watch<FireAlarmData>();
    // 🔥 FIXED: Use unified LED decoder data source for ALL LED status
    bool isActive = fireAlarmData.getSystemStatus(statusKey);
    final activeColor = fireAlarmData.getActiveColor(statusKey);
    final inactiveColor = fireAlarmData.getInactiveColor(statusKey);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: baseFontSize * 0.9,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
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

  // Method to build status table
  Widget buildStatusTable(List<Map<String, dynamic>> logs, double height) {
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);
    // Note: columnWidths will be calculated dynamically in LayoutBuilder - COPIED FROM TROUBLE

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No status logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status changes will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // COPIED FROM TROUBLE: Optimized responsive layout with unified width system
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          // Safety check for invalid constraints
          if (constraints.maxWidth <= 0 || !constraints.hasBoundedWidth) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate optimal available width (remove minimal padding) - SAME AS TROUBLE
          final availableWidth = constraints.maxWidth - 8; // Minimal 4px padding on each side

          // Use responsive 3-column width calculation
          final scaledWidths = getOptimal3ColumnWidths(context, availableWidth);

          final isCompactScreen = shouldUseCompactLayout(context);
          final tableWidth = scaledWidths['date']! + scaledWidths['time']! + scaledWidths['status']!;

          // Additional safety check for table width
          if (tableWidth <= 0 || tableWidth.isInfinite) {
            return const Center(child: Text('Error calculating table width'));
          }

        return Center(
          child: SingleChildScrollView(
            scrollDirection: isCompactScreen ? Axis.vertical : Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Enhanced Header with background - COPIED FROM TROUBLE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: scaledWidths['date'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['time'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'TIME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['status'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Data Rows with alternating colors - COPIED FROM TROUBLE
                  Expanded(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final displayStatus = '${log['status']} | ${log['user']}';
                        final isEven = index % 2 == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: scaledWidths['date'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['time'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  formatTimeWithSeconds(log['time'] ?? ''),
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['status'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  displayStatus,
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2, // Allow 2 lines for "Status | User" format
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        } catch (e) {
          // Return error UI if LayoutBuilder fails - COPIED FROM TROUBLE
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text('Error loading table'),
                const SizedBox(height: 8),
                Text('Please try refreshing the page', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }
      },
    );
  }

  // Method to build connection table
  Widget buildConnectionTable(List<Map<String, dynamic>> logs, double height) {
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);
    // Note: columnWidths will be calculated dynamically in LayoutBuilder - COPIED FROM TROUBLE

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No connection logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Module connections will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // COPIED FROM TROUBLE: Optimized responsive layout with unified width system
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          // Safety check for invalid constraints
          if (constraints.maxWidth <= 0 || !constraints.hasBoundedWidth) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate optimal available width (remove minimal padding) - SAME AS TROUBLE
          final availableWidth = constraints.maxWidth - 8; // Minimal 4px padding on each side

          // Use responsive 3-column width calculation (information instead of status)
          final baseWidths = getOptimal3ColumnWidths(context, availableWidth);
          final scaledWidths = {
            'date': baseWidths['date']!,
            'time': baseWidths['time']!,
            'information': baseWidths['status']!, // Use status width for information column
          };

          final isCompactScreen = shouldUseCompactLayout(context);
          final tableWidth = scaledWidths['date']! + scaledWidths['time']! + scaledWidths['information']!;

          // Additional safety check for table width
          if (tableWidth <= 0 || tableWidth.isInfinite) {
            return const Center(child: Text('Error calculating table width'));
          }

        return Center(
          child: SingleChildScrollView(
            scrollDirection: isCompactScreen ? Axis.vertical : Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Enhanced Header with background - COPIED FROM TROUBLE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: scaledWidths['date'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['time'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'TIME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['information'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'INFORMATION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Data Rows with alternating colors - COPIED FROM TROUBLE
                  Expanded(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final isEven = index % 2 == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: scaledWidths['date'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['time'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  formatTimeWithSeconds(log['time'] ?? ''),
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['information'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['information'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2, // Allow 2 lines for long connection info
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        } catch (e) {
          // Return error UI if LayoutBuilder fails - COPIED FROM TROUBLE
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text('Error loading table'),
                const SizedBox(height: 8),
                Text('Please try refreshing the page', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }
      },
    );
  }

  // Method to build trouble table
  Widget buildTroubleTable(List<Map<String, dynamic>> logs, double height) {
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);
    // Note: columnWidths will be calculated dynamically in LayoutBuilder

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trouble logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trouble events will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Optimized responsive layout with unified width system
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          // Safety check for invalid constraints
          if (constraints.maxWidth <= 0 || !constraints.hasBoundedWidth) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate optimal available width (remove minimal padding)
          final availableWidth = constraints.maxWidth - 8; // Minimal 4px padding on each side

          // Use the new unified optimal width calculation
          final columnWidths = getOptimalColumnWidths(context, availableWidth);
          final isCompactScreen = shouldUseCompactLayout(context);
          final tableWidth = columnWidths['date']! + columnWidths['time']! + columnWidths['zone']! + columnWidths['status']!;

          // Additional safety check for table width
          if (tableWidth <= 0 || tableWidth.isInfinite) {
            return const Center(child: Text('Error calculating table width'));
          }

        return Center(
          child: SingleChildScrollView(
            scrollDirection: isCompactScreen ? Axis.vertical : Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Enhanced Header with background
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: columnWidths['date'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: columnWidths['time'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'TIME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: columnWidths['zone'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'ZONE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: columnWidths['status'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Data Rows with Infinite Scroll
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification scrollInfo) {
                        if (scrollInfo is ScrollEndNotification) {
                          final fireAlarmData = context.read<FireAlarmData>();
                          final logHandler = fireAlarmData.logHandler;

                          // Load more when user reaches near the end (90% scrolled)
                          if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent * 0.9) {
                            if (logHandler.hasMoreTroubleLogs && !logHandler.isLoadingMoreTrouble) {
                              logHandler.loadMoreTroubleLogs();
                            }
                          }
                        }
                        return false;
                      },
                      child: ListView.builder(
                        itemCount: logs.length + (context.read<FireAlarmData>().logHandler.hasMoreTroubleLogs ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Show loading indicator at the bottom
                          if (index == logs.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final log = logs[index];
                          final isEven = index % 2 == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: columnWidths['date'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: columnWidths['time'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  formatTimeWithSeconds(log['time'] ?? ''),
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: columnWidths['zone'], // MAXIMUM PRIORITY - Calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['zoneName'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: columnWidths['status'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.8),
                                child: Center(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minWidth: isCompactScreen ? 40.0 : (columnWidths['status']! * 0.7).clamp(50.0, 85.0),
                                      maxWidth: isCompactScreen ? 60.0 : (columnWidths['status']! * 0.9).clamp(70.0, 120.0),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(log['status'] ?? ''),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      log['status'] ?? '',
                                      style: TextStyle(
                                        fontSize: (isCompactScreen ? dataFontSize * 0.75 : dataFontSize * 0.85).clamp(8.0, 12.0),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
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
                  // 🆕 Data count indicator
                  if (logs.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border(top: BorderSide(color: Colors.grey[300]!)),
                      ),
                      child: Consumer<FireAlarmData>(
                        builder: (context, fireAlarmData, child) {
                          final logHandler = fireAlarmData.logHandler;
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Showing ${logs.length} entries${logHandler.hasMoreTroubleLogs ? ' (loading more...)' : ''}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (!logHandler.hasMoreTroubleLogs && logs.isNotEmpty)
                                Text(
                                  'All data loaded',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
        } catch (e) {
          // Return error UI if LayoutBuilder fails
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text('Error loading table'),
                const SizedBox(height: 8),
                Text('Please try refreshing the page', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }
      },
    );
  }

  // Method to build fire table
  Widget buildFireTable(List<Map<String, dynamic>> logs, double height) {
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);
    // Note: columnWidths will be calculated dynamically in LayoutBuilder - COPIED FROM TROUBLE

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No fire logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fire alarm events will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // COPIED FROM TROUBLE: Optimized responsive layout with unified width system
    return LayoutBuilder(
      builder: (context, constraints) {
        try {
          // Safety check for invalid constraints
          if (constraints.maxWidth <= 0 || !constraints.hasBoundedWidth) {
            return const Center(child: CircularProgressIndicator());
          }

          // Calculate optimal available width (remove minimal padding) - SAME AS TROUBLE
          final availableWidth = constraints.maxWidth - 8; // Minimal 4px padding on each side

          // Use responsive 5-column width calculation
          final scaledWidths = getOptimal5ColumnWidths(context, availableWidth);

          final isCompactScreen = shouldUseCompactLayout(context);
          final tableWidth = scaledWidths['date']! + scaledWidths['time']! + scaledWidths['address']! + scaledWidths['zone']! + scaledWidths['status']!;

          // Additional safety check for table width
          if (tableWidth <= 0 || tableWidth.isInfinite) {
            return const Center(child: Text('Error calculating table width'));
          }

        return Center(
          child: SingleChildScrollView(
            scrollDirection: isCompactScreen ? Axis.vertical : Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  // Enhanced Header with background - COPIED FROM TROUBLE
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border(
                        bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: scaledWidths['date'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'DATE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['time'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'TIME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['address'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'ADDRESS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['zone'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'ZONE NAME',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: scaledWidths['status'], // Use calculated optimal width
                          padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.2),
                          child: Text(
                            'STATUS',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: headerFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Enhanced Data Rows with alternating colors - COPIED FROM TROUBLE
                  Expanded(
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        final isEven = index % 2 == 0;

                        return Container(
                          decoration: BoxDecoration(
                            color: isEven ? Colors.white : Colors.grey.shade50,
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.shade200,
                                width: 0.5,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: scaledWidths['date'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['time'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  formatTimeWithSeconds(log['time'] ?? ''),
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['address'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['address'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['zone'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 1.1),
                                child: Text(
                                  log['zoneName'] ?? '',
                                  style: TextStyle(
                                    fontSize: isCompactScreen ? dataFontSize * 0.85 : dataFontSize,
                                    color: Colors.black87,
                                    fontWeight: isEven ? FontWeight.normal : FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                width: scaledWidths['status'], // Use calculated optimal width
                                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.8),
                                child: Center(
                                  child: Container(
                                    constraints: BoxConstraints(
                                      minWidth: isCompactScreen ? 40.0 : (scaledWidths['status']! * 0.7).clamp(50.0, 85.0),
                                      maxWidth: isCompactScreen ? 60.0 : (scaledWidths['status']! * 0.9).clamp(70.0, 120.0),
                                    ),
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getFireStatusColor(log['status'] ?? ''),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 2,
                                          offset: Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      log['status'] ?? '',
                                      style: TextStyle(
                                        fontSize: (isCompactScreen ? dataFontSize * 0.75 : dataFontSize * 0.85).clamp(8.0, 12.0),
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        } catch (e) {
          // Return error UI if LayoutBuilder fails - COPIED FROM TROUBLE
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                const SizedBox(height: 16),
                const Text('Error loading table'),
                const SizedBox(height: 8),
                Text('Please try refreshing the page', style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }
      },
    );
  }

  // 🎯 NEW: Get status color for 3-state trouble logging
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TROUBLE':
        return Colors.red.shade600; // Red for trouble
      case 'FIXED':
        return Colors.green.shade600; // Green for resolved
      case 'DISCONNECTED':
        return Colors.orange.shade600; // Orange for disconnected
      default:
        return Colors.grey.shade600; // Grey for unknown
    }
  }

  Color _getFireStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
      case 'ACTIVE':
        return Colors.red.shade600; // Red for active fire alarms
      case 'NORMAL':
      case 'SAFE':
      case 'CLEAR':
        return Colors.green.shade600; // Green for normal/clear status
      case 'SUPERVISORY':
      case 'TEST':
        return Colors.orange.shade600; // Orange for supervisory/test mode
      case 'TROUBLE':
      case 'FAULT':
        return Colors.purple.shade600; // Purple for trouble/fault conditions
      default:
        return Colors.grey.shade600; // Grey for unknown status
    }
  }

  String formatTimeWithSeconds(String time) {
    // Assuming time is in HH:mm format, add ":00" seconds
    if (time.length == 5 && time[2] == ':') {
      return '$time:00';
    }
    return time;
  }
}
