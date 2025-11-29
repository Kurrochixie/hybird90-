import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/fire_alarm_data.dart';
import '../unified_fire_alarm_parser.dart';
import '../models/zone_status.dart';

class TabMonitoringPage extends StatefulWidget {
  const TabMonitoringPage({super.key});

  @override
  State<TabMonitoringPage> createState() => _TabMonitoringPageState();
}

class _TabMonitoringPageState extends State<TabMonitoringPage> {
  int _displayModules = 63; // Default display all modules

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Consumer<FireAlarmData>(
          builder: (context, fireAlarmData, child) {
            return Row(
              children: [
                // Module counter controls
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(4),
                    color: Colors.grey.shade50,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Decrease button
                      InkWell(
                        onTap: _decrementModules,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _displayModules > 1 ? Colors.red.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(
                            Icons.remove,
                            size: 16,
                            color: _displayModules > 1 ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Module count
                      Text(
                        '$_displayModules',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Increase button
                      InkWell(
                        onTap: _incrementModules,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _displayModules < 63 ? Colors.green.shade100 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 16,
                            color: _displayModules < 63 ? Colors.green : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                // LED indicators
                LEDCirclesInAppBar(fireAlarmData: fireAlarmData),
                const SizedBox(width: 20),
                // Status and info text in one row
                Expanded(
                  child: Row(
                    children: [
                      // Status text
                      Text(
                        fireAlarmData.getSystemStatusWithTroubleDetection(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: fireAlarmData.getSystemStatusColorWithTroubleDetection(),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Project name
                      Text(
                        fireAlarmData.projectName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Active modules
                      Text(
                        'MODULES: ${fireAlarmData.modules.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Total zones
                      Text(
                        'ZONES: ${fireAlarmData.numberOfZones}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<FireAlarmData>(
              builder: (context, fireAlarmData, child) {
                // Main container (container induk) for all modules
                return Container(
                  width: constraints.maxWidth - 16, // minus padding
                  height: constraints.maxHeight - 16, // minus padding
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.blue.shade300,
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withValues(alpha: 0.1),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildDynamicGrid(constraints, fireAlarmData),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Helper methods untuk responsive design
  int _calculateCrossAxisCount(double screenWidth) {
    // Hitung jumlah kolom berdasarkan lebar layar - lebih agresif untuk menghemat ruang
    if (screenWidth < 600) {
      return 7; // Mobile kecil - tambah kolom
    } else if (screenWidth < 900) {
      return 10; // Mobile besar/tablet kecil - tambah kolom
    } else {
      return 12; // Tablet/desktop - tambah kolom
    }
  }

  
  Widget _buildDynamicGrid(BoxConstraints constraints, FireAlarmData fireAlarmData) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _calculateCrossAxisCount(constraints.maxWidth),
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 1.2, // Fixed aspect ratio untuk ukuran sama
      ),
      itemCount: _displayModules,
      itemBuilder: (context, index) {
        final moduleNumber = index + 1;
        return IndividualModuleContainer(
          moduleNumber: moduleNumber,
          fireAlarmData: fireAlarmData,
        );
      },
    );
  }
}


class LEDCircles extends StatelessWidget {
  const LEDCircles({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FireAlarmData>(
      builder: (context, fireAlarmData, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SYSTEM STATUS MONITORING',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),
              // Status Text with real-time data
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: fireAlarmData.isDrillModeActive
                      ? Colors.blue.shade50
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: fireAlarmData.isDrillModeActive
                        ? Colors.blue.shade300
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  fireAlarmData.getSystemStatusWithTroubleDetection(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: fireAlarmData.getSystemStatusColorWithTroubleDetection(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Compact LED widget for AppBar
class LEDCirclesInAppBar extends StatelessWidget {
  final FireAlarmData fireAlarmData;

  const LEDCirclesInAppBar({super.key, required this.fireAlarmData});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mini LED indicator
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('AC Power'),
              activeColor: Colors.green,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('DC Power'),
              activeColor: Colors.green,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('Alarm'),
              activeColor: Colors.red,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('Trouble'),
              activeColor: Colors.orange,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('Drill'),
              activeColor: Colors.red,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('Silenced'),
              activeColor: Colors.yellow,
              inactiveColor: Colors.grey.shade400,
            ),
            LEDMiniCircle(
              isActive: fireAlarmData.getSystemStatus('Disabled'),
              activeColor: Colors.yellow,
              inactiveColor: Colors.grey.shade400,
            ),
          ],
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

// Mini LED circle for compact display
class LEDMiniCircle extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const LEDMiniCircle({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
        border: Border.all(
          color: Colors.black54,
          width: 0.5,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: 2,
            spreadRadius: 0.5,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 0.5,
            spreadRadius: 0.25,
          ),
        ],
      ),
    );
  }
}

// Slave Container - Container induk untuk module modules
class SlaveContainer extends StatelessWidget {
  final int slaveNumber;
  final FireAlarmData fireAlarmData;
  final double containerWidth;
  final double containerHeight;

  const SlaveContainer({
    super.key,
    required this.slaveNumber,
    required this.fireAlarmData,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final padding = containerWidth * 0.02;
    final fontSize = (containerWidth * 0.06).clamp(8.0, 14.0);
    final moduleContainerHeight = containerHeight * 0.6;
    final moduleContainerWidth = containerWidth * 0.9;
    final moduleSpacing = containerWidth * 0.01;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.blue.shade300,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: Colors.blue.shade50,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Slave Number Header
          Container(
            padding: EdgeInsets.symmetric(vertical: padding),
            decoration: BoxDecoration(
              color: Colors.blue.shade200,
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Text(
              'SLAVE $slaveNumber',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: padding),

          // Module Container - This will contain individual module indicators
          Container(
            width: moduleContainerWidth,
            height: moduleContainerHeight,
            padding: EdgeInsets.all(moduleSpacing),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(6.0),
              color: Colors.white,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Module Number
                Text(
                  '#${slaveNumber.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: fontSize * 0.8,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: moduleSpacing * 2),

                // 6 LEDs: 5 zones + 1 bell for this slave
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // LED indicators for this slave's zones and bell
                    _buildSlaveLED(1, moduleContainerWidth * 0.08), // Zone 1
                    _buildSlaveLED(2, moduleContainerWidth * 0.08), // Zone 2
                    _buildSlaveLED(3, moduleContainerWidth * 0.08), // Zone 3
                    _buildSlaveLED(4, moduleContainerWidth * 0.08), // Zone 4
                    _buildSlaveLED(5, moduleContainerWidth * 0.08), // Zone 5
                    _buildSlaveLED(6, moduleContainerWidth * 0.08), // Bell
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build LED for slave's zones and bell
  Widget _buildSlaveLED(int ledIndex, double size) {
    // Calculate zone number for this slave
    // Slave 1: LED 1-5 = zones 1-5, LED 6 = bell 6
    // Slave 2: LED 1-5 = zones 7-11, LED 6 = bell 12
    // Slave n: LED 1-5 = zones (n-1)*6+1 to (n-1)*6+5, LED 6 = bell (n-1)*6+6
    int zoneNumber;
    Color activeColor;

    if (ledIndex <= 5) {
      // Zone LEDs 1-5
      zoneNumber = (slaveNumber - 1) * 6 + ledIndex;
      activeColor = Colors.red;
    } else {
      // Bell LED 6
      zoneNumber = (slaveNumber - 1) * 6 + 6;
      activeColor = Colors.yellow;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 2.0),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: UnifiedFireAlarmParser.instance.getZoneStatus(zoneNumber)?.status == 'Alarm'
              ? activeColor
              : Colors.grey.shade300,
          boxShadow: UnifiedFireAlarmParser.instance.getZoneStatus(zoneNumber)?.status == 'Alarm'
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.4),
                    blurRadius: size * 0.2,
                    spreadRadius: size * 0.1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: size * 0.05,
                    spreadRadius: size * 0.02,
                  ),
                ],
        ),
      ),
    );
  }
}

// Individual Module Container - Container untuk setiap module yang ada di dalam container induk
class IndividualModuleContainer extends StatelessWidget {
  final int moduleNumber;
  final FireAlarmData fireAlarmData;

  const IndividualModuleContainer({
    super.key,
    required this.moduleNumber,
    required this.fireAlarmData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 8),

        // 6 LEDs: 5 zones + 1 bell - Use Wrap for better space management
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 1.0,
            runSpacing: 1.0,
            children: [
              _buildLED(1, Colors.red), // Zone 1
              _buildLED(2, Colors.red), // Zone 2
              _buildLED(3, Colors.red), // Zone 3
              _buildLED(4, Colors.red), // Zone 4
              _buildLED(5, Colors.red), // Zone 5
              _buildLED(6, Colors.yellow), // Bell
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLED(int ledIndex, Color activeColor) {
    // Calculate zone number for this module
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

    // Determine LED color based on zone status
    Color ledColor;

    if (ledIndex == 6) {
      // Special handling for Bell LED
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

    return Padding(
    padding: const EdgeInsets.only(right: 1.5),
      child: Container(
        width: 18,
        height: 18,
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
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
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
      if (fireAlarmData.isZoneAccumulatedAlarm(zoneNumber)) return Colors.red;
      if (fireAlarmData.isZoneAccumulatedTrouble(zoneNumber)) return Colors.orange;
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

// Responsive Module Indicator widget
class ResponsiveModuleIndicator extends StatelessWidget {
  final int moduleNumber;
  final FireAlarmData fireAlarmData;
  final double containerWidth;
  final double containerHeight;

  const ResponsiveModuleIndicator({
    super.key,
    required this.moduleNumber,
    required this.fireAlarmData,
    required this.containerWidth,
    required this.containerHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive font size based on container size
    final responsiveFontSize = (containerWidth * 0.15).clamp(8.0, 16.0);
    final ledSize = (containerWidth * 0.08).clamp(8.0, 16.0);
    final spacing = (containerWidth * 0.02).clamp(1.0, 3.0);
    final containerPadding = (containerWidth * 0.05).clamp(8.0, 16.0);

    return Container(
      padding: EdgeInsets.all(containerPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Module number with responsive font
          Text(
            '#${moduleNumber.toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: responsiveFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: spacing * 2),
          // 6 LEDs: 5 zones + 1 bell with responsive sizing
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildResponsiveZoneLED(1, ledSize, spacing), // Zone 1
              _buildResponsiveZoneLED(2, ledSize, spacing), // Zone 2
              _buildResponsiveZoneLED(3, ledSize, spacing), // Zone 3
              _buildResponsiveZoneLED(4, ledSize, spacing), // Zone 4
              _buildResponsiveZoneLED(5, ledSize, spacing), // Zone 5
              _buildResponsiveBellLED(ledSize, spacing),      // Bell
            ],
          ),
        ],
      ),
    );
  }

  // Build responsive LED for zones
  Widget _buildResponsiveZoneLED(int zoneInModule, double size, double spacing) {
    final zoneNumber = (moduleNumber - 1) * 6 + zoneInModule;
    return Padding(
      padding: EdgeInsets.only(right: spacing),
      child: ResponsiveStatusCircle(
        size: size,
        isActive: UnifiedFireAlarmParser.instance.getZoneStatus(zoneNumber)?.status == 'Alarm',
        activeColor: Colors.red,
        inactiveColor: Colors.grey.shade300,
      ),
    );
  }

  // Build responsive LED for bell
  Widget _buildResponsiveBellLED(double size, double spacing) {
    final bellZoneNumber = (moduleNumber - 1) * 6 + 6;
    return Padding(
      padding: EdgeInsets.only(right: spacing),
      child: ResponsiveStatusCircle(
        size: size,
        isActive: UnifiedFireAlarmParser.instance.getZoneStatus(bellZoneNumber)?.status == 'Alarm',
        activeColor: Colors.yellow,
        inactiveColor: Colors.grey.shade300,
      ),
    );
  }
}

// Responsive Status Circle widget
class ResponsiveStatusCircle extends StatelessWidget {
  final double size;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const ResponsiveStatusCircle({
    super.key,
    required this.size,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(left: 2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
        border: Border.all(
          color: Colors.black54,
          width: 0.5,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: size * 0.15,
            spreadRadius: size * 0.05,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: size * 0.05,
            spreadRadius: size * 0.02,
          ),
        ],
      ),
    );
  }
}

// Module Indicator widget for each slave module
class ModuleIndicator extends StatelessWidget {
  final int moduleNumber;
  final FireAlarmData fireAlarmData;

  const ModuleIndicator({
    super.key,
    required this.moduleNumber,
    required this.fireAlarmData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4.0),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Module number
          Text(
            '#${moduleNumber.toString().padLeft(2, '0')}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          // 6 LEDs: 5 zones + 1 bell
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Calculate zone numbers for this module
              // Module 1: zones 1-5, bell 6
              // Module 2: zones 7-11, bell 12
              // Module n: zones (n-1)*6+1 to (n-1)*6+5, bell (n-1)*6+6
              _buildZoneLED(1), // Zone 1
              _buildZoneLED(2), // Zone 2
              _buildZoneLED(3), // Zone 3
              _buildZoneLED(4), // Zone 4
              _buildZoneLED(5), // Zone 5
              _buildBellLED(),  // Bell
            ],
          ),
        ],
      ),
    );
  }

  // Build LED for zones
  Widget _buildZoneLED(int zoneInModule) {
    final zoneNumber = (moduleNumber - 1) * 6 + zoneInModule;
    return Padding(
      padding: const EdgeInsets.only(right: 2.0),
      child: StatusCircle(
        isActive: UnifiedFireAlarmParser.instance.getZoneStatus(zoneNumber)?.status == 'Alarm',
        activeColor: Colors.red,
        inactiveColor: Colors.grey.shade300,
      ),
    );
  }

  // Build LED for bell
  Widget _buildBellLED() {
    final bellZoneNumber = (moduleNumber - 1) * 6 + 6; // Bell is always zone 6 in each module
    return Padding(
      padding: const EdgeInsets.only(right: 2.0),
      child: StatusCircle(
        isActive: UnifiedFireAlarmParser.instance.getZoneStatus(bellZoneNumber)?.status == 'Alarm',
        activeColor: Colors.yellow,
        inactiveColor: Colors.grey.shade300,
      ),
    );
  }
}

// Status Circle widget for larger display
class StatusCircle extends StatelessWidget {
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const StatusCircle({
    super.key,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(left: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
            border: Border.all(
              color: Colors.black54,
              width: 0.5,
            ),
            boxShadow: isActive ? [
              BoxShadow(
                color: activeColor.withValues(alpha: 0.4),
                blurRadius: 2,
                spreadRadius: 0.5,
              ),
            ] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 0.5,
                spreadRadius: 0.25,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class LEDCircle extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;

  const LEDCircle({
    super.key,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? activeColor : inactiveColor,
        boxShadow: isActive ? [
          BoxShadow(
            color: activeColor.withValues(alpha: 0.4),
            blurRadius: 3,
            spreadRadius: 0.5,
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 0.5,
            spreadRadius: 0.25,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? activeColor.withValues(alpha: 0.8)
                : inactiveColor.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }
}