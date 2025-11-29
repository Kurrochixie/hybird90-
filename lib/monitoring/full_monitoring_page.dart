import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../core/fire_alarm_data.dart';
import '../services/local_audio_manager.dart';
import '../services/enhanced_notification_service.dart';
import '../services/background_notification_service.dart' as bg_notification;
import '../services/button_action_service.dart';

class FullMonitoringPage extends StatefulWidget {
  const FullMonitoringPage({super.key});

  @override
  State<FullMonitoringPage> createState() => _FullMonitoringPageState();
}

class _FullMonitoringPageState extends State<FullMonitoringPage> with WidgetsBindingObserver {
  // ==================== KONFIGURASI UKURAN ====================
  // Button Configuration
  static const double _buttonContainerHeightMultiplier = 0.08;  // 8% of screen width
  static const double _buttonHeightMultiplier = 0.07;           // 7% of screen width
  static const double _buttonFontMultiplier = 0.025;            // 2.5% of screen width
  
  // Button Size Limits
  static const double _minButtonHeight = 35.0;
  static const double _maxButtonHeight = 60.0;
  static const double _minButtonFont = 8.0;
  static const double _maxButtonFont = 14.0;
  // ============================================================

  // State untuk tracking button yang sedang ditekan
  bool _isAcknowledgeActive = false;

  // State untuk zona yang dipilih
  int? _selectedZoneNumber;

  // State untuk visibility kontrol container
  bool _showProjectContainer = true;
  bool _showZonesContainer = true;
  bool _showButtonsContainer = true;
  bool _showLedStatusContainer = true;
  bool _showZoneNameContainer = true;

  // Local Audio Manager untuk independen audio control
  final LocalAudioManager _audioManager = LocalAudioManager();
  
  // Enhanced Notification Service
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  // Stream subscription untuk audio status updates
  StreamSubscription<Map<String, bool>>? _audioStatusSubscription;

  // Flag untuk mencegah multiple dispose calls
  bool _isDisposed = false;

  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Force landscape mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    // Hide status bar for full screen experience
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    
    // Initialize services
    _initializeServices();
    
    // Listen to FireAlarmData changes
    final fireAlarmData = context.read<FireAlarmData>();
    fireAlarmData.addListener(_onSystemStatusChanged);
    
    // Listen to audio status updates
    _audioStatusSubscription = _audioManager.audioStatusStream.listen((audioStatus) {
      if (mounted) {
        setState(() {
          // Update UI based on audio status if needed
        });
      }
    });

      }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // When app is resumed, ensure landscape mode for full monitoring
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
    if (_isDisposed) return;
    _isDisposed = true;
    
    WidgetsBinding.instance.removeObserver(this);
    
  // Cancel subscriptions
  _audioStatusSubscription?.cancel();

  // Remove listener
  final fireAlarmData = context.read<FireAlarmData>();
  fireAlarmData.removeListener(_onSystemStatusChanged);

  // Dispose services
  _audioManager.dispose();
  _notificationService.dispose();
    
    // Restore user preferred orientations when leaving the page
    _restoreUserPreferredOrientations();
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
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

    // Force a short delay to ensure orientation change takes effect
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        
      }
    });
  }

  
  // Local helper method to get zone name, moved from FireAlarmData to fix resolution issue.
  String _getZoneName(int zoneNumber, FireAlarmData fireAlarmData) {
    if (fireAlarmData.modules.isEmpty || zoneNumber <= 0) {
      return 'Unknown Zone';
    }

    const int zonesPerModule = 5;
    final int moduleIndex = ((zoneNumber - 1) ~/ zonesPerModule);
    final int zoneIndexInModule = (zoneNumber - 1) % zonesPerModule;

    if (moduleIndex < fireAlarmData.modules.length) {
      final module = fireAlarmData.modules[moduleIndex];
      if (module['zones'] is List) {
        final zones = module['zones'] as List<dynamic>;
        if (zoneIndexInModule < zones.length) {
          return zones[zoneIndexInModule].toString();
        }
      }
    }

    return 'Zone $zoneNumber'; // Fallback if not found
  }

  @override
  Widget build(BuildContext context) {
    // Don't force landscape mode in build - let initState handle it
    // Forcing landscape mode here interferes with orientation restoration when exiting
    
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
                            // TOP CONTAINER with Back Button
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(13),
                                    spreadRadius: 1,
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: _getContainerPadding(context),
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    // Back Button (seemless)
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

                                    // Title
                                    Expanded(
                                      child: Text(
                                        'MONITORED AREAS',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Colors.black87,
                                          fontWeight: FontWeight.w600,
                                          fontSize: _calculateResponsiveFontSize(context) * 1.3,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ),

                                    // Spacer untuk balance dengan back button
                                    const SizedBox(width: 55),
                                  ],
                                ),
                              ),
                            ),

                            // Spacing
                            const SizedBox(height: 10),

                            // Header info (Project info - tanpa back button karena sudah di atas)
                            if (_showProjectContainer)
                              Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(
                                  horizontal: _getContainerPadding(context),
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  children: [
                                    // Space instead of back button
                                    const SizedBox(width: 53),
                                    // Project info
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
                                                fireAlarmData.projectName,
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
                                                // 🎯 Use Simple Status Manager with your exact 4 rules
                                                fireAlarmData.getSimpleSystemStatusWithDetection(),
                                                style: TextStyle(
                                                  // 🎯 Consistent status colors - Alarm=Red, Trouble=Orange, Normal=Blue, No Data=Grey
                                                  color: _getConsistentStatusColor(fireAlarmData.getSimpleSystemStatusWithDetection()),
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            children: [
                                              const Text(
                                                'TOTAL ZONES',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Text(
                                                fireAlarmData.numberOfZones.toString(),
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 10),

                            // Status Indicators - LED Status
                            if (_showLedStatusContainer)
                              Consumer<FireAlarmData>(
                                builder: (context, fireAlarmData, child) {
                                  return Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: _getContainerPadding(context),
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        _buildStatusColumn('AC POWER', 'AC Power', fireAlarmData),
                                        _buildStatusColumn('DC POWER', 'DC Power', fireAlarmData),
                                        _buildStatusColumn('ALARM', 'Alarm', fireAlarmData),
                                        _buildStatusColumn('TROUBLE', 'Trouble', fireAlarmData),
                                        _buildStatusColumn('DRILL', 'Drill', fireAlarmData),
                                        _buildStatusColumn('SILENCED', 'Silenced', fireAlarmData),
                                        _buildStatusColumn('DISABLED', 'Disabled', fireAlarmData),
                                      ],
                                    ),
                                  );
                                },
                              ),

                            // Selected Zone Info Container
                            if (_showZoneNameContainer) ...[
                              const SizedBox(height: 10),
                              _buildSelectedZoneInfoContainer(fireAlarmData),
                            ],

                            if (_showLedStatusContainer && _showZonesContainer)
                              const SizedBox(height: 10),

                            // Zones container
                            if (_showZonesContainer)
                              Flexible(
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(_getContainerPadding(context)),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: _buildZonesGrid(fireAlarmData),
                                ),
                              ),
                            if (_showZonesContainer && _showButtonsContainer)
                              const SizedBox(height: 6),

                            // Control Buttons - Horizontal Layout
                            if (_showButtonsContainer)
                              _buildHorizontalControlButtons(fireAlarmData),
                            if (_showButtonsContainer)
                              const SizedBox(height: 10),
                          
                            const SizedBox(height: 10),
                            // Visibility Controls at the bottom
                            _buildVisibilityControls(),
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

  Widget _buildSelectedZoneInfoContainer(FireAlarmData fireAlarmData) {
    String zoneName;
    if (_selectedZoneNumber == null) {
      zoneName = 'Pilih sebuah zona untuk melihat nama';
    } else {
      zoneName = _getZoneName(_selectedZoneNumber!, fireAlarmData);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
         
          const SizedBox(height: 2),
          Text(
            _selectedZoneNumber != null 
              ? 'ZONA ${_selectedZoneNumber.toString().padLeft(3, '0')}'
              : '--',
            style: const TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            zoneName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonesGrid(FireAlarmData fireAlarmData) {
    final int totalZones = fireAlarmData.numberOfZones > 0 ? fireAlarmData.numberOfZones : 250;
    const int crossAxisCount = 10;
    const double crossAxisSpacing = 2.0;
    const double largeHorizontalGap = 16.0; // The gap between 5-zone groups
    const double childAspectRatio = 2.5;

    
    
    

    return LayoutBuilder(builder: (context, constraints) {
      // Calculate item width considering the different spacings
      final double availableWidth = constraints.maxWidth;
      // For a full row, there are 8 small gaps and 1 large gap
      final double totalSpacing = (crossAxisSpacing * 8) + largeHorizontalGap;
      final double itemWidth = (availableWidth - totalSpacing) / crossAxisCount;
      final double itemHeight = itemWidth / childAspectRatio;

      final int numRows = (totalZones / crossAxisCount).ceil();

      // Generate all rows
      List<Widget> rows = List.generate(numRows, (rowIndex) {
        final bool isLastRow = rowIndex == numRows - 1;
        
        int itemsInThisRow = crossAxisCount;
        if (isLastRow && totalZones % crossAxisCount != 0) {
          itemsInThisRow = totalZones % crossAxisCount;
        }
        
        MainAxisAlignment rowAlignment = MainAxisAlignment.start;
        if (isLastRow) {
          if (itemsInThisRow % 2 != 0) {
            rowAlignment = MainAxisAlignment.center;
          }
        } else {
          // Full rows should be aligned to start, the width calculation will fill the space.
          rowAlignment = MainAxisAlignment.start;
        }

        // Generate all items and spacers for the current row
        List<Widget> rowChildren = [];
        for (int itemIndex = 0; itemIndex < itemsInThisRow; itemIndex++) {
          final int zoneIndex = (rowIndex * crossAxisCount) + itemIndex;
          final int zoneNumber = zoneIndex + 1;

          final zoneItemWidget = SizedBox(
            width: itemWidth,
            height: itemHeight,
            child: Container(
              decoration: BoxDecoration(
                color: _getZoneColorFromSystem(zoneNumber),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(
                  color: _selectedZoneNumber == zoneNumber
                      ? Colors.blueAccent
                      : _getZoneBorderColor(zoneNumber),
                  width: _selectedZoneNumber == zoneNumber ? 2.5 : 1.0,
                ),
              ),
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: Text(
                      zoneNumber.toString().padLeft(3, '0'),
                      style: TextStyle(
                        color: _getZoneTextColor(zoneNumber),
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );

          // Add the zone item, wrapped in InkWell
          rowChildren.add(
            InkWell(
              onTap: () {
                setState(() {
                  _selectedZoneNumber = zoneNumber;
                });
              },
              borderRadius: BorderRadius.circular(3),
              child: zoneItemWidget,
            ),
          );

          // Add spacing after the item, if it's not the last one in the row
          if (itemIndex < itemsInThisRow - 1) {
            // Use large gap after the 5th item (index 4)
            if (itemIndex == 4) {
              rowChildren.add(const SizedBox(width: largeHorizontalGap));
            } else {
              rowChildren.add(const SizedBox(width: crossAxisSpacing));
            }
          }
        }

        // The Row widget that holds the zones
        final rowWidget = Row(
          mainAxisAlignment: rowAlignment,
          children: rowChildren,
        );

        // Return a Column with the row and a divider (if not the last row)
        return Column(
          children: [
            rowWidget,
            if (!isLastRow)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4.0), // Add some space around the divider
                child: Divider(color: Colors.grey, thickness: 1),
              ),
          ],
        );
      });

      return Column(children: rows);
    });
  }

  // Get zone color based on individual zone status first, then system status as fallback
  Color _getZoneColorFromSystem(int zoneNumber) {
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

    // NEW: Check individual zone status first (from Enhanced Zone Parser)
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

    // FALLBACK: Use system status if no individual zone data available
    if (fireAlarmData.getSystemStatus('Alarm')) {
      return Colors.red;
    }

    if (fireAlarmData.getSystemStatus('Trouble')) {
      return Colors.orange;
    }

    if (fireAlarmData.getSystemStatus('Drill')) {
      return Colors.red;
    }

    if (fireAlarmData.getSystemStatus('Silenced')) {
      return Colors.yellow.shade700;
    }

    // Default white for normal status
    return Colors.white;
  }

  // Get zone border color
  Color _getZoneBorderColor(int zoneNumber) {
    return Colors.grey.shade300;
  }

  // Get zone text color based on background color for better visibility
  Color _getZoneTextColor(int zoneNumber) {
    Color backgroundColor = _getZoneColorFromSystem(zoneNumber);
    
    // Return black text for light backgrounds, white for dark backgrounds
    if (backgroundColor == Colors.white) {
      return Colors.black; // White background = black text
    } else if (backgroundColor == Colors.yellow) {
      return Colors.black; // Yellow background = black text
    } else {
      return Colors.white; // Red/Grey backgrounds = white text
    }
  }

  // Calculate responsive font size based on screen diagonal
  double _calculateResponsiveFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(size.width * size.width + size.height * size.height);
    final baseSize = diagonal / 100;
    return baseSize.clamp(8.0, 15.0);
  }

  // Metode untuk membangun status column dengan data terpusat
  Widget _buildStatusColumn(String label, String statusKey, FireAlarmData fireAlarmData) {
    // Use enhanced LED methods that integrate with LED decoder
    bool isActive = fireAlarmData.getEnhancedLEDStatus(statusKey);
    final activeColor = fireAlarmData.getEnhancedLEDColor(statusKey);
    final inactiveColor = fireAlarmData.getInactiveColor(statusKey);
    final baseFontSize = _calculateResponsiveFontSize(context);

    // Debug: Log LED status data for troubleshooting
    

    // Additional debug for color source detection
    if (statusKey == 'Alarm') {
      bool hasLEDData = fireAlarmData.hasLEDDecoderData;
      DateTime? ledTimestamp = fireAlarmData.getLEDDecoderTimestamp();
      
      
    }

    // 🎯 Enhanced trouble detection - Use Simple Status Manager with your exact 4 rules
    if (statusKey == 'Trouble') {
      isActive = fireAlarmData.getSimpleHasTroubleZones();
      
    }

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: baseFontSize * 0.8,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
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
        // Add status text indicator when active
        if (statusKey == 'Trouble' && isActive)
          Padding(
            padding: EdgeInsets.only(top: baseFontSize * 0.15),
            child: Text(
              'TROUBLE',
              style: TextStyle(
                fontSize: baseFontSize * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        if (statusKey == 'Alarm' && isActive)
          Padding(
            padding: EdgeInsets.only(top: baseFontSize * 0.15),
            child: Text(
              'ALARM',
              style: TextStyle(
                fontSize: baseFontSize * 0.6,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }

  // Build visibility controls for containers
  Widget _buildVisibilityControls() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _getContainerPadding(context),
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 255, 255, 255),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // Project Container Checkbox
          Row(
            children: [
              Checkbox(
                value: _showProjectContainer,
                onChanged: (bool? value) {
                  setState(() {
                    _showProjectContainer = value ?? true;
                  });
                },
                activeColor: const Color.fromARGB(255, 38, 152, 17),
              ),
              const Text('Project'),
            ],
          ),
          // Zones Container Checkbox
          Row(
            children: [
              Checkbox(
                value: _showZonesContainer,
                onChanged: (bool? value) {
                  setState(() {
                    _showZonesContainer = value ?? true;
                  });
                },
                activeColor: const Color.fromARGB(255, 38, 152, 17),
              ),
              const Text('Zones'),
            ],
          ),
          // Buttons Container Checkbox
          Row(
            children: [
              Checkbox(
                value: _showButtonsContainer,
                onChanged: (bool? value) {
                  setState(() {
                    _showButtonsContainer = value ?? true;
                  });
                },
                activeColor: const Color.fromARGB(255, 38, 152, 17),
              ),
              const Text('Buttons'),
            ],
          ),
          // LED Status Container Checkbox
          Row(
            children: [
              Checkbox(
                value: _showLedStatusContainer,
                onChanged: (bool? value) {
                  setState(() {
                    _showLedStatusContainer = value ?? true;
                  });
                },
                activeColor: const Color.fromARGB(255, 38, 152, 17),
              ),
              const Text('LED Status'),
            ],
          ),
          // Zone Name Container Checkbox
          Row(
            children: [
              Checkbox(
                value: _showZoneNameContainer,
                onChanged: (bool? value) {
                  setState(() {
                    _showZoneNameContainer = value ?? true;
                  });
                },
                activeColor: const Color.fromARGB(255, 38, 152, 17),
              ),
              const Text('Zone Name'),
            ],
          ),
        ],
      ),
    );
  }

  // Build horizontal control buttons
  Widget _buildHorizontalControlButtons(FireAlarmData fireAlarmData) {
    return Container(
      width: double.infinity,
      height: _getButtonContainerHeight(context),
      padding: EdgeInsets.symmetric(
        horizontal: _getContainerPadding(context),
        vertical: 8,
      ),
      child: Row(
        children: [
          // System Reset Button
          Expanded(
            child: _buildControlButton(
              'SYSTEM RESET',
              Colors.red,
              fireAlarmData.isResetting,
              _handleSystemReset,
            ),
          ),
          SizedBox(width: _getButtonSpacing(context)),
          // Drill Button
          Expanded(
            child: _buildControlButton(
              'DRILL',
              fireAlarmData.getSystemStatus('Drill') ? Colors.red : Colors.blue,
              fireAlarmData.getSystemStatus('Drill'),
              _handleDrill,
            ),
          ),
          SizedBox(width: _getButtonSpacing(context)),
          // Acknowledge Button
          Expanded(
            child: _buildControlButton(
              'ACKNOWLEDGE',
              _isAcknowledgeActive ? Colors.orange : Colors.grey,
              _isAcknowledgeActive,
              _handleAcknowledge,
            ),
          ),
          SizedBox(width: _getButtonSpacing(context)),
          // Silence Button
          Expanded(
            child: _buildControlButton(
              'SILENCE',
              fireAlarmData.getSystemStatus('Silenced') ? Colors.yellow[700]! : Colors.grey,
              fireAlarmData.getSystemStatus('Silenced'),
              _handleSilence,
            ),
          ),
        ],
      ),
    );
  }

  // Build individual control button
  Widget _buildControlButton(
    String label,
    Color color,
    bool isActive,
    VoidCallback onPressed,
  ) {
    final buttonHeight = _getButtonHeight(context);
    final buttonFontSize = _getButtonFontSize(context);
    final buttonPadding = _getButtonPadding(context);
    
    return SizedBox(
      height: buttonHeight,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: buttonPadding,
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: 0.15) : Colors.white,
          border: Border.all(
            color: isActive ? color : Colors.grey[400]!,
            width: isActive ? 2.0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 0,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: buttonFontSize,
                    fontWeight: FontWeight.bold,
                    color: isActive ? color : Colors.black87,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isActive)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '● ACTIVE',
                      style: TextStyle(
                        fontSize: buttonFontSize * 0.6,
                        fontWeight: FontWeight.bold,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  // Get responsive padding for main container
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Base padding: 3% of screen width, minimum 13px, maximum 25px
    final horizontalPadding = (screenWidth * 0.03).clamp(13.0, 25.0);
    final verticalPadding = (screenWidth * 0.02).clamp(8.0, 15.0);
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
  }

  // Get responsive padding for individual containers
  double _getContainerPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Container padding: 2% of screen width, minimum 10px, maximum 20px
    return (screenWidth * 0.02).clamp(10.0, 20.0);
  }

  // Get responsive button container height
  double _getButtonContainerHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use configured button container height multiplier with limits
    return (screenWidth * _buttonContainerHeightMultiplier).clamp(_minButtonHeight, _maxButtonHeight);
  }

  // Get responsive button height
  double _getButtonHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use configured button height multiplier with limits
    return (screenWidth * _buttonHeightMultiplier).clamp(_minButtonHeight, _maxButtonHeight);
  }

  // Get responsive button font size
  double _getButtonFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use configured button font multiplier with limits
    return (screenWidth * _buttonFontMultiplier).clamp(_minButtonFont, _maxButtonFont);
  }

  // Get responsive button padding
  EdgeInsets _getButtonPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = (screenWidth * 0.02).clamp(6.0, 12.0);
    final verticalPadding = (screenWidth * 0.015).clamp(4.0, 8.0);
    return EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding);
  }

  // Get responsive button spacing
  double _getButtonSpacing(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Button spacing: 2% of screen width, minimum 6px, maximum 12px
    return (screenWidth * 0.02).clamp(6.0, 12.0);
  }

  // Handler untuk System Reset
  void _handleSystemReset() async {
    // Stop all audio immediately
    _audioManager.stopAllAudioImmediately();
    await bg_notification.BackgroundNotificationService().stopAlarm();
    await _notificationService.clearAllNotifications();

    setState(() {
      _isAcknowledgeActive = false;
    });

    // Use ButtonActionService untuk handle System Reset
    if (mounted) {
      await ButtonActionService().handleSystemReset(context: context);
    }
  }

  // Handler untuk Drill
  void _handleDrill() async {
    // Use ButtonActionService untuk handle Drill
    if (mounted) {
      await ButtonActionService().handleDrill(context: context);
    }
  }

  // Handler untuk Acknowledge
  void _handleAcknowledge() async {
    // Use ButtonActionService untuk handle Acknowledge
    if (mounted) {
      await ButtonActionService().handleAcknowledge(context: context, currentState: _isAcknowledgeActive);
      
      // Update local state
      setState(() {
        _isAcknowledgeActive = !_isAcknowledgeActive;
      });
    }
  }

  // Handler untuk Silence
  void _handleSilence() async {
    // Use ButtonActionService untuk handle Silence
    if (mounted) {
      await ButtonActionService().handleSilence(context: context);
    }
  }

  
  // Initialize services
  Future<void> _initializeServices() async {
    try {
      await _audioManager.initialize();
      await _notificationService.initialize();
      
    } catch (e) {
      
    }
  }

  // Listener for system status changes to sync with audio
  void _onSystemStatusChanged() {
    final fireAlarmData = context.read<FireAlarmData>();
    
    final currentDrillStatus = fireAlarmData.getSystemStatus('Drill');
    final currentAlarmStatus = fireAlarmData.getSystemStatus('Alarm');
    final currentTroubleStatus = fireAlarmData.getSystemStatus('Trouble');
    final currentSilencedStatus = fireAlarmData.getSystemStatus('Silenced');

    // Update audio manager with new button statuses
    _audioManager.updateAudioStatusFromButtons(
      isDrillActive: currentDrillStatus,
      isAlarmActive: currentAlarmStatus,
      isTroubleActive: currentTroubleStatus,
      isSilencedActive: currentSilencedStatus,
    );
  }

  // 🎯 Consistent status color mapping across all pages (Universal Colors)
  Color _getConsistentStatusColor(String statusText) {
    switch (statusText) {
      case 'ALARM':
        return Colors.red;      // 🔴 Red for Alarm
      case 'ALARM DRILL':
        return Colors.red;      // 🔴 Red for ALARM DRILL (same as Alarm)
      case 'SYSTEM TROUBLE':
        return Colors.orange;   // 🟠 Orange for Trouble
      case 'SYSTEM NORMAL':
        return Colors.green;    // 🟢 Green for Normal (FIXED)
      case 'NO DATA':
        return Colors.grey;     // ⚫ Grey for No Data
      default:
        return Colors.green;    // 🟢 Default to Green
    }
  }
}
