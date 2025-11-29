import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/fire_alarm_data.dart';
import '../utils/tablet_responsive_helper.dart';

class ZoneMonitoringPage extends StatefulWidget {
  const ZoneMonitoringPage({super.key});

  @override
  State<ZoneMonitoringPage> createState() => _ZoneMonitoringPageState();
}

class _ZoneMonitoringPageState extends State<ZoneMonitoringPage> with AutomaticKeepAliveClientMixin {
  // State untuk zona yang dipilih
  int? _selectedZoneNumber;

  // State untuk visibility container
  final bool _showZoneNameContainer = true;

  // FireAlarmData instance for live updates
  late final FireAlarmData _fireAlarmData;

  @override
  void initState() {
    super.initState();
    // Initialize FireAlarmData
    _fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

    // Add FireAlarmData listener for live updates
    _fireAlarmData.addListener(_onSystemStatusChanged);
  }


  @override
  void dispose() {
    // Cleanup FireAlarmData listeners
    _fireAlarmData.removeListener(_onSystemStatusChanged);

    // Cleanup Firebase listeners if needed
    super.dispose();
  }


  // FireAlarmData listener callback for live updates
  void _onSystemStatusChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when system status changes
        
      });
    }
  }

  // Save module name using FireAlarmData
  Future<void> _saveModuleName(int moduleNumber, String moduleName) async {
    try {
      final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

      // Use FireAlarmData to save module name
      await fireAlarmData.saveModuleName(moduleNumber, moduleName);

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module $moduleNumber name updated'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update module name'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // Show dialog to edit module name
  Future<void> _showEditModuleDialog(int moduleNumber) async {
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);
    final TextEditingController dialogController = TextEditingController(
      text: fireAlarmData.getModuleNameByNumber(moduleNumber)
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Module $moduleNumber Name'),
          content: TextField(
            controller: dialogController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Module Name',
              hintText: 'Enter module name...',
            ),
            onSubmitted: (value) {
              Navigator.of(context).pop();
              _saveModuleName(moduleNumber, value);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveModuleName(moduleNumber, dialogController.text);
              },
            ),
          ],
        );
      },
    );
  }

  // Get zone color based on individual zone status first, then system status as fallback
  Color _getZoneColorFromSystem(int zoneNumber, FireAlarmData fireAlarmData) {
    // Check if there's no data or disconnected
    if (!fireAlarmData.hasValidZoneData || fireAlarmData.isInitiallyLoading) {
      return Colors.grey;  // Grey for disconnect/no data
    }

    // 🔄 NEW: Check accumulated zone status FIRST (highest priority in accumulation mode)
    if (fireAlarmData.isAccumulationMode) {
      // In accumulation mode, accumulated status overrides real-time status
      if (fireAlarmData.isZoneAccumulatedAlarm(zoneNumber)) {
        
        return Colors.red;
      }
      if (fireAlarmData.isZoneAccumulatedTrouble(zoneNumber)) {
        
        return Colors.orange;
      }
      
    }

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

    // LEGACY: Check old individual zone status method (for backward compatibility)
    final legacyZoneStatus = fireAlarmData.getZoneStatusByAbsoluteNumber(zoneNumber);
    if (legacyZoneStatus?.toLowerCase().contains('alarm') == true ||
        legacyZoneStatus?.toLowerCase().contains('fire') == true) {
      return Colors.red;
    }

    if (legacyZoneStatus?.toLowerCase().contains('trouble') == true ||
        legacyZoneStatus?.toLowerCase().contains('fault') == true) {
      return Colors.orange;
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

  // Build project name widget with multi-line support
  Widget _buildProjectNameWidget(String projectName, Color textColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxLines = screenWidth < 400 ? 2 : 3;

    return Text(
      projectName,
      style: TextStyle(
        color: textColor,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      textAlign: TextAlign.center,
      maxLines: maxLines,
      overflow: TextOverflow.visible,
      softWrap: true,
    );
  }

  // Build selected zone info container with back button
  Widget _buildSelectedZoneInfoContainer(FireAlarmData fireAlarmData) {
    Color containerColor;
    Color borderColor;
    Color textColor;

    if (_selectedZoneNumber == null) {
      containerColor = Colors.white;  // Changed to white
      borderColor = Colors.grey.shade300;
      textColor = Colors.black87;
    } else {
      // Get zone color based on system status
      containerColor = _getZoneColorFromSystem(_selectedZoneNumber!, fireAlarmData);

      // Set border and text color based on container color
      if (containerColor == Colors.red) {
        borderColor = Colors.red.shade300;
        textColor = Colors.white;
      } else if (containerColor == Colors.orange) {
        borderColor = Colors.orange.shade300;
        textColor = Colors.white;
      } else if (containerColor == Colors.yellow.shade700) {
        borderColor = Colors.yellow.shade600;
        textColor = Colors.black;
      } else if (containerColor == Colors.grey) {
        borderColor = Colors.grey.shade400;
        textColor = Colors.black;
      } else {
        borderColor = Colors.grey.shade300;
        textColor = Colors.black87;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: textColor,
                size: 20,
              ),
            ),
          ),

          // Spacer
          const SizedBox(width: 8),

          // Project and Zone Info - Centered
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Project Name
                _buildProjectNameWidget(fireAlarmData.projectName, textColor),

                // Zone Info
                if (_selectedZoneNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${_selectedZoneNumber.toString().padLeft(3, '0')} - ${fireAlarmData.getZoneNameByAbsoluteNumber(_selectedZoneNumber!)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // 🔄 NEW: Accumulation Status Indicator
                  if (fireAlarmData.isAccumulationMode &&
                      (fireAlarmData.isZoneAccumulatedAlarm(_selectedZoneNumber!) ||
                       fireAlarmData.isZoneAccumulatedTrouble(_selectedZoneNumber!))) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: fireAlarmData.isZoneAccumulatedAlarm(_selectedZoneNumber!)
                            ? Colors.red.withValues(alpha: 0.3)
                            : Colors.orange.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: fireAlarmData.isZoneAccumulatedAlarm(_selectedZoneNumber!)
                              ? Colors.red
                              : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        fireAlarmData.isZoneAccumulatedAlarm(_selectedZoneNumber!)
                            ? 'ACCUMULATED ALARM'
                            : 'ACCUMULATED TROUBLE',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${fireAlarmData.numberOfModules} Modules | ${fireAlarmData.numberOfZones} Zones',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Connection Status Indicator
          _buildConnectionStatusIndicator(fireAlarmData.isFirebaseConnected, textColor),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusIndicator(bool isConnected, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected ? 'CONNECTED' : 'DISCONNECTED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: TabletResponsiveHelper.getOptimalPadding(context),
          child: Column(
            children: [

              // Selected Zone Info Container - Wrapped in Consumer for real-time updates
              if (_showZoneNameContainer) ...[
                Consumer<FireAlarmData>(
                  builder: (context, fireAlarmData, child) {
                    return _buildSelectedZoneInfoContainer(fireAlarmData);
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Content
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double screenWidth = constraints.maxWidth;
                    final double screenHeight = constraints.maxHeight;

                    // Responsive breakpoints
                    if (screenWidth < 360) {
                      // Small phones
                      return _buildCompactLayout(screenWidth, screenHeight);
                    } else if (screenWidth < 600) {
                      // Normal phones
                      return _buildPhoneLayout(screenWidth, screenHeight);
                    } else if (screenWidth < 900) {
                      // Tablets
                      return _buildTabletLayout(screenWidth, screenHeight);
                    } else {
                      // Desktop
                      return _buildDesktopLayout(screenWidth, screenHeight);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact layout for small phones (< 360px)
  Widget _buildCompactLayout(double screenWidth, double screenHeight) {
    const double spacing = 4.0;
    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return _buildModuleTable(tableIndex, screenWidth, spacing, compact: true);
        }),
      ),
    );
  }

  // Phone layout (360px - 600px)
  Widget _buildPhoneLayout(double screenWidth, double screenHeight) {
    const double spacing = 8.0;

    // For smaller screens, force single column to prevent overflow
    if (screenWidth < 400) {
      return SingleChildScrollView(
        child: Column(
          children: List.generate(7, (tableIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: _buildModuleTable(tableIndex, screenWidth, spacing),
            );
          }),
        ),
      );
    }

    // For phones, use tablet-aware calculation with phone fallback
    final int numColumns = TabletResponsiveHelper.calculateOptimalColumns(screenWidth);
    

    if (numColumns == 1) {
      // Single column layout
      return SingleChildScrollView(
        child: Column(
          children: List.generate(7, (tableIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: _buildModuleTable(tableIndex, screenWidth - 16, spacing),
            );
          }),
        ),
      );
    }

    // Two column layout

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return Flexible(
            flex: 1,
            child: _buildModuleTable(tableIndex, double.infinity, spacing),
          );
        }),
      ),
    );
  }

  // Tablet layout (600px - 900px)
  Widget _buildTabletLayout(double screenWidth, double screenHeight) {
    // Debug tablet device info
    TabletResponsiveHelper.debugDeviceInfo(context);

    // Use tablet-responsive spacing
    final double spacing = TabletResponsiveHelper.calculateOptimalSpacing(context);

    // Check if in landscape mode (width > height)
    final bool isLandscape = screenWidth > screenHeight;

    // Force 2 columns in landscape mode
    if (isLandscape) {
      final int tablesPerRow = TabletResponsiveHelper.calculateTablesPerRow(screenWidth);
      

      return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return Flexible(
              flex: 1,
              child: _buildModuleTable(tableIndex, double.infinity, spacing),
            );
          }),
        ),
      );
    }

    // Portrait mode - use tablet-aware column calculation
    final int numColumns = TabletResponsiveHelper.calculateOptimalColumns(screenWidth);
    

    if (numColumns == 2) {
      // Two column layout
            return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return Flexible(
              flex: 1,
              child: _buildModuleTable(tableIndex, double.infinity, spacing),
            );
          }),
        ),
      );
    }

    // Three column layout
        return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return Flexible(
            flex: 1,
            child: _buildModuleTable(tableIndex, double.infinity, spacing),
          );
        }),
      ),
    );
  }

  // Desktop layout (> 900px)
  Widget _buildDesktopLayout(double screenWidth, double screenHeight) {
    // Use tablet-responsive spacing (works for desktop too)
    final double spacing = TabletResponsiveHelper.calculateOptimalSpacing(context);

    // Debug device info for desktop
    TabletResponsiveHelper.debugDeviceInfo(context);

    // Check if in landscape mode (width > height)
    final bool isLandscape = screenWidth > screenHeight;

    // Force 2 columns in landscape mode
    if (isLandscape) {
      final int tablesPerRow = TabletResponsiveHelper.calculateTablesPerRow(screenWidth);
      

      return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return Flexible(
              flex: 1,
              child: _buildModuleTable(tableIndex, double.infinity, spacing),
            );
          }),
        ),
      );
    }

    // Portrait mode - use tablet-aware calculation with desktop enhancement
    final int numColumns = TabletResponsiveHelper.calculateOptimalColumns(screenWidth);
    


    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return Flexible(
            flex: 1,
            child: _buildModuleTable(tableIndex, double.infinity, spacing),
          );
        }),
      ),
    );
  }

  // Build individual module table
  Widget _buildModuleTable(int tableIndex, double availableWidth, double spacing, {bool compact = false}) {
    // Use tablet-responsive sizing
    final double fontSize = TabletResponsiveHelper.getOptimalFontSize(context);
    final double rowHeight = TabletResponsiveHelper.getOptimalRowHeight(context);
    final double zoneSize = TabletResponsiveHelper.getOptimalZoneSize(context);

    

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DataTable(
        headingRowHeight: rowHeight,
        dataRowMinHeight: rowHeight,
        dataRowMaxHeight: rowHeight * 1.2, // Allow some flexibility for tablets
        horizontalMargin: compact ? 2.0 : 4.0,
        columnSpacing: 2.0,
        headingTextStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        dataTextStyle: TextStyle(fontSize: fontSize),
        columns: [
          DataColumn(
            label: Text('#', style: TextStyle(fontSize: fontSize)),
          ),
          DataColumn(
            label: Text('AREA', style: TextStyle(fontSize: fontSize)),
          ),
          ...List.generate(5, (i) => DataColumn(
            label: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Text('${i + 1}', style: TextStyle(fontSize: fontSize)),
            ),
            numeric: false,
          )),
          DataColumn(
            label: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Text('B', style: TextStyle(fontSize: fontSize)),
            ),
            numeric: false,
          ),
        ],
        rows: List.generate(10, (rowIndex) {
          final index = tableIndex * 10 + rowIndex;
          final moduleNumber = index + 1;

          // Don't create rows beyond module 63
          if (moduleNumber > 63) {
            return null;
          }

          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#$moduleNumber',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: availableWidth * 0.35,
                  child: GestureDetector(
                    onTap: () => _showEditModuleDialog(moduleNumber),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2.0 : 4.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Consumer<FireAlarmData>(
                        builder: (context, fireAlarmData, child) {
                          return Text(
                            fireAlarmData.getModuleNameByNumber(moduleNumber),
                            style: TextStyle(fontSize: fontSize),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(6, (colIndex) {
                final bool isBellZone = colIndex == 5;

                if (isBellZone) {
                  return DataCell(
                    Center(
                      child: Consumer<FireAlarmData>(
                        builder: (context, fireAlarmData, child) {
                          // Get bell confirmation status untuk module ini
                          final slaveAddress = moduleNumber.toString().padLeft(2, '0');
                          final bellStatus = fireAlarmData.getBellConfirmationStatus(slaveAddress);

                          // Bell container color berdasarkan confirmation status dan drill mode
                          Color bellColor = Colors.grey[300]!; // Default gray
                          Color borderColor = Colors.grey[400]!;
                          Color iconColor = Colors.black54;

                          // 🔥 Check for drill mode first (highest priority)
                          if (fireAlarmData.shouldForceAllBellsOnInDrill) {
                            // DRILL MODE - Force bell ON dengan warna yang sama seperti alarm nyata
                            bellColor = Colors.red;
                            borderColor = Colors.red.shade700;
                            iconColor = Colors.white;
                            
                          } else if (bellStatus != null) {
                            if (bellStatus.isActive) {
                              // Bell ON - merah (alarm aktif)
                              bellColor = Colors.red;
                              borderColor = Colors.red.shade700;
                              iconColor = Colors.white;
                            } else {
                              // Bell OFF - normal
                              bellColor = Colors.grey[300]!;
                              borderColor = Colors.grey[400]!;
                              iconColor = Colors.black54;
                            }
                          }

                          return Container(
                            width: zoneSize,
                            height: zoneSize,
                            decoration: BoxDecoration(
                              color: bellColor,
                              border: Border.all(
                                color: borderColor,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              // Add shadow effect untuk active bells dan drill mode
                              boxShadow: (bellStatus?.isActive == true || fireAlarmData.shouldForceAllBellsOnInDrill) ? [
                                BoxShadow(
                                  color: Colors.red.withAlpha(100),
                                  spreadRadius: 1,
                                  blurRadius: 3,
                                  offset: const Offset(0, 1),
                                ),
                              ] : null,
                            ),
                            child: Icon(
                              Icons.notifications,
                              size: zoneSize * 0.6,
                              color: iconColor,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                }

                final int zoneNumber = index * 5 + colIndex + 1;

                return DataCell(
                  Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedZoneNumber = zoneNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: zoneSize,
                        height: zoneSize,
                        decoration: BoxDecoration(
                          color: _getZoneColorFromSystem(
                            zoneNumber,
                            _fireAlarmData,
                          ),
                          border: Border.all(
                            color: _selectedZoneNumber == zoneNumber
                                ? Colors.blueAccent
                                : _getZoneBorderColor(zoneNumber),
                            width: _selectedZoneNumber == zoneNumber ? 2.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedZoneNumber == zoneNumber
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withAlpha(150),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }).where((row) => row != null).cast<DataRow>().toList(),
      ),
    );
  }
}