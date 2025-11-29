import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../core/fire_alarm_data.dart';
import '../widgets/unified_status_bar.dart';
import '../models/zone_status.dart';

class MonitoringPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const MonitoringPage({super.key, this.scaffoldKey});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // Zone status list (placeholder untuk compatibility)
  final List<ZoneStatus> _currentZoneStatus = [];

  @override
  void initState() {
    super.initState();
      }

  @override
  void dispose() {
    super.dispose();
  }


  // Get zone color based on individual zone status first, then system status as fallback
  Color _getZoneColorFromSystem(int zoneNumber) {
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

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

    // FALLBACK: Use system status if no individual zone data available
    if (fireAlarmData.getSystemStatus('Alarm')) {
      return Colors.red;
    }

    // REMOVED: System-wide trouble fallback to prevent zone contamination
    // Individual zone status should always take priority over system status
    // This prevents ALL zones from turning orange when any zone has trouble

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

  // Fungsi untuk memisahkan teks menjadi dua baris (kata pertama dan sisanya)
  String _splitTextIntoTwoLines(String text) {
    final words = text.split(' ');
    if (words.length <= 1) return text;

    // Ambil kata pertama
    final firstWord = words[0];

    // Gabungkan kata-kata sisanya
    final remainingWords = words.sublist(1).join(' ');

    return '$firstWord\n$remainingWords';
  }

  // Fungsi untuk menghitung ukuran font berdasarkan rasio layar
  double _calculateFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );

    // Rasio berdasarkan diagonal layar
    final baseSize = diagonal / 100;

    // Batasi ukuran font antara 8.0 dan 15.0
    return baseSize.clamp(8.0, 15.0);
  }

  // Fungsi untuk menentukan apakah perangkat adalah desktop
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }


  // Get module border color based on alarm status (any zone alarm or bell trouble)
  Color _getModuleBorderColor(int moduleNumber) {
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

    // 🔔 NEW: Bell accumulation override pattern (SAMA seperti zones)
    bool hasActiveBell = false;
    if (fireAlarmData.isAccumulationMode) {
      // In accumulation mode, check if this module has accumulated bells
      final slaveAddress = moduleNumber.toString().padLeft(2, '0');
      hasActiveBell = fireAlarmData.bellAccumulator.isBellAccumulated(slaveAddress);
      
    } else {
      // In real-time mode, check individual bell status
      final slaveAddress = moduleNumber.toString().padLeft(2, '0');
      final bellStatus = fireAlarmData.getBellConfirmationStatus(slaveAddress);
      hasActiveBell = bellStatus?.isActive == true;
      
    }

    // Check if any zone in this module has alarm
    bool hasZoneAlarm = _checkModuleHasAlarm(moduleNumber);

    // Return red border if either active bell or zone alarm exists
    if (hasActiveBell || hasZoneAlarm) {
      return Colors.red; // Border merah jika ada active bell atau alarm zona
    }
    return Colors.grey[300]!; // Border abu-abu default
  }

  // Check if any zone in the module has alarm
  bool _checkModuleHasAlarm(int moduleNumber) {
    if (_currentZoneStatus.isEmpty) {
      return false;
    }

    try {
      // System has 5 zones per module, but monitoring shows 6 zones (5 zones + BELL)
      // We need to check zones 0-4 for this module
      for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
        int globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(moduleNumber, zoneIndex + 1);

        try {
          final zoneStatus = _currentZoneStatus.firstWhere((zone) => zone.zoneNumber == globalZoneNumber);
          if (zoneStatus.hasAlarm) {
            
            return true;
          }
        } catch (e) {
          // Zone not found, continue checking other zones
          continue;
        }
      }
      return false;
    } catch (e) {
      
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung ukuran font dasar berdasarkan layar
    final baseFontSize = _calculateFontSize(context);
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // Unified Status Bar - Synchronized across all pages with height constraint
              Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.35, // Max 35% of screen height
                ),
                child: FullStatusBar(scaffoldKey: widget.scaffoldKey),
              ),

              // Spacing after status bar
              SizedBox(height: isDesktop ? 15 : 20),

              // Container untuk Zona dengan Scroll Terpisah
              Builder(
              builder: (context) {
                final fireAlarmData = context.watch<FireAlarmData>();
                final numModules = fireAlarmData.numberOfModules;
                final screenHeight = MediaQuery.of(context).size.height;
                final isDesktop = _isDesktop(context);

                // Calculate dynamic height based on number of modules
                const double moduleHeight = 140.0; // Estimated height per module including margins/padding
                final totalModuleHeight = numModules * moduleHeight;
                final maxHeight = screenHeight * 0.60; // 60% of screen height max (reduced for better breathing room)
                final containerHeight = math.min(totalModuleHeight + 40, maxHeight); // + padding

                return Container(
                  height: containerHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Area scrollable untuk modul
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: fireAlarmData.modules.map((module) {
                              final moduleNumber = int.tryParse(module['number'].toString()) ?? 1;
                              final moduleBorderColor = _getModuleBorderColor(moduleNumber);
                              final hasAlarmCondition = moduleBorderColor == Colors.red;

                              return Container(
                                margin: EdgeInsets.fromLTRB(
                                  4,
                                  isDesktop ? 4 : 4,
                                  4,
                                  isDesktop ? 8 : 12,
                                ),
                                padding: EdgeInsets.all(isDesktop ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: moduleBorderColor,
                                    width: hasAlarmCondition ? 3.0 : 1.0, // Thick red border when alarm is active
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                    // Add red shadow when there's alarm condition (bell trouble or zone alarm)
                                    if (hasAlarmCondition)
                                      BoxShadow(
                                        color: Colors.red.withAlpha(77),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Header Modul dengan garis dan nomor
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(
                                        bottom: isDesktop ? 6 : 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '#${module['number']}',
                                              style: TextStyle(
                                                fontSize: baseFontSize * 1.4,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Grid 2x3 untuk zona
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: isDesktop
                                                ? 6.0
                                                : 8.0,
                                            mainAxisSpacing: isDesktop
                                                ? 6.0
                                                : 8.0,
                                            childAspectRatio: isDesktop
                                                ? 5.0
                                                : 2.4,
                                          ),
                                      itemCount: 6, // 6 zona per modul
                                      itemBuilder: (context, zoneIndex) {
                                        final zoneName =
                                            module['zones'][zoneIndex];
                                        final isBellZone = zoneName == 'BELL';

                                        // Calculate global zone number for system data
                                        // Note: System uses 5 zones per module, but monitoring shows 6 zones per module
                                        // Zone 6 in each module is BELL, so we map zones 0-4 to system zones
                                        final moduleNumber = int.tryParse(module['number'].toString()) ?? 1;
                                        int globalZoneNumber;
                                        if (zoneIndex < 5) {
                                          // FIXED: Use consistent formula with ZoneStatusUtils
                                          // zoneIndex is 0-based, so we add 1 to make it 1-based like zoneInDevice
                                          globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(moduleNumber, zoneIndex + 1);
                                        } else {
                                          // Zone 5 is BELL, use the first zone of this module as reference
                                          globalZoneNumber = ZoneStatusUtils.calculateGlobalZoneNumber(moduleNumber, 1);
                                        }

                                        // Get zone colors from system data
                                        final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);
                                        final slaveAddress = moduleNumber.toString().padLeft(2, '0');
                                        final bellStatus = fireAlarmData.getBellConfirmationStatus(slaveAddress);

                                        final zoneColor = isBellZone
                                            ? (fireAlarmData.shouldForceAllBellsOnInDrill || bellStatus?.isActive == true)
                                                ? Colors.red  // Red background when bell is active ($85) OR drill mode
                                                : Colors.grey[300]  // Gray background when bell is inactive ($84)
                                            : _getZoneColorFromSystem(globalZoneNumber);
                                        final borderColor = isBellZone
                                            ? _getModuleBorderColor(moduleNumber)
                                            : _getZoneBorderColor(globalZoneNumber);
                                        final textColor = isBellZone
                                            ? (fireAlarmData.shouldForceAllBellsOnInDrill || bellStatus?.isActive == true)
                                                ? Colors.white  // White text when red background (drill or active)
                                                : Colors.black87  // Black text when gray background
                                            : _getZoneTextColor(globalZoneNumber);

                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            // Format teks untuk zona non-bell dengan zone number
                                            String formattedText;
                                            if (isBellZone) {
                                              formattedText = zoneName;
                                            } else {
                                              // Add zone number to display
                                              final zoneNumberText = '$globalZoneNumber';
                                              final zoneNameText = _splitTextIntoTwoLines(zoneName);

                                              // Combine zone number and zone name
                                              if (zoneNameText.contains('\n')) {
                                                // Zone name has 2 lines, put zone number on top
                                                formattedText = '$zoneNumberText\n$zoneNameText';
                                              } else {
                                                // Zone name has 1 line, put zone number and name together
                                                formattedText = '$zoneNumberText\n$zoneNameText';
                                              }
                                            }

                                            // Tentukan apakah teks memiliki 2 baris atau lebih
                                            final hasTwoLines = formattedText
                                                .contains('\n');

                                            // Hitung ukuran font berdasarkan baseFontSize dan jumlah baris
                                            double fontSize = baseFontSize;
                                            if (hasTwoLines) {
                                              fontSize = baseFontSize * 0.8; // Smaller font for multiple lines
                                            }

                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: isDesktop ? 6 : 8,
                                                horizontal: isDesktop ? 3 : 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: zoneColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: borderColor,
                                                  width: 1.0,
                                                ),
                                                // Add shadow for active zones (alarm/trouble) and bell confirmation (including drill mode)
                                                boxShadow: (zoneColor != null && (zoneColor == Colors.red || zoneColor == Colors.yellow)) ||
                                                           (isBellZone && (bellStatus?.isActive == true || fireAlarmData.shouldForceAllBellsOnInDrill))
                                                    ? [
                                                        BoxShadow(
                                                          color: isBellZone && (bellStatus?.isActive == true || fireAlarmData.shouldForceAllBellsOnInDrill)
                                                                ? Colors.red.withValues(alpha: 0.4)
                                                                : zoneColor?.withValues(alpha: 0.3) ?? Colors.grey.withValues(alpha: 0.3),
                                                          spreadRadius: 1,
                                                          blurRadius: 2,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Center(
                                                child: isBellZone
                                                    ? Icon(
                                                        Icons.notifications,
                                                        size:
                                                            baseFontSize *
                                                            (isDesktop
                                                                ? 1.8
                                                                : 2.0),
                                                        color: (bellStatus?.isActive == true || fireAlarmData.shouldForceAllBellsOnInDrill)
                                                            ? Colors.white  // White icon when red background (drill or active)
                                                            : Colors.black87,  // Black icon when gray background
                                                      )
                                                    : Text(
                                                        formattedText,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: fontSize,
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 3,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tambahan spacing untuk memastikan scroll berfungsi
            const SizedBox(height: 10),

            // Footer info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '© 2025 DDS Fire Alarm System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFontSize * 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
  }

}