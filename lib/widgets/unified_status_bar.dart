import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import '../core/fire_alarm_data.dart';

/// Unified Status Bar Widget - Centralized status bar management
/// Ensures consistent design, data, and behavior across all pages
class UnifiedStatusBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showProjectInfo;
  final bool showStatusIndicators;
  final bool showSystemStatus;
  final bool useCompactMode;
  final double? customHeight;
  final EdgeInsets? customPadding;

  const UnifiedStatusBar({
    super.key,
    this.scaffoldKey,
    this.showProjectInfo = true,
    this.showStatusIndicators = true,
    this.showSystemStatus = true,
    this.useCompactMode = false,
    this.customHeight,
    this.customPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<FireAlarmData>(
      builder: (context, fireAlarmData, child) {
        return SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Complete header with hamburger, logo, and connection status
              FireAlarmData.getCompleteHeader(
                isConnected: fireAlarmData.isFirebaseConnected,
                scaffoldKey: scaffoldKey,
              ),

              // Project Information Section
              if (showProjectInfo) _buildProjectInfo(context, fireAlarmData),

              // System Status Section
              if (showSystemStatus) _buildSystemStatus(context, fireAlarmData),

              // Status Indicators Section
              if (showStatusIndicators) _buildStatusIndicators(context, fireAlarmData),
            ],
          ),
        );
      },
    );
  }

  /// Build Project Information Section
  Widget _buildProjectInfo(BuildContext context, FireAlarmData fireAlarmData) {
    final fontSize = _calculateResponsiveFontSize(context);
    final padding = customPadding ?? const EdgeInsets.only(top: 5, bottom: 8);

    return Container(
      width: double.infinity,
      padding: padding,
      color: Colors.white,
      child: Column(
        children: [
          // Project Name
          Text(
            fireAlarmData.projectName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w600,
              fontSize: fontSize * 1.8,
              letterSpacing: 1.5,
            ),
          ),
          
          // Panel Type
          Text(
            fireAlarmData.panelType,
            style: TextStyle(
              fontSize: fontSize * 1.6,
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
            style: TextStyle(
              fontSize: fontSize * 1.4,
              color: Colors.black87,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// Build System Status Section
  Widget _buildSystemStatus(BuildContext context, FireAlarmData fireAlarmData) {
    final fontSize = _calculateResponsiveFontSize(context);
    
    // Determine status using enhanced detection
    String statusText;
    Color statusColor;
    Color textColor;

    if (fireAlarmData.isResetting) {
      statusText = 'SYSTEM RESETTING';
      statusColor = Colors.white;
      textColor = Colors.black;
    } else {
      // 🎯 NEW: Use Simple Status Manager with your exact 4 rules
      statusText = fireAlarmData.getSimpleSystemStatusWithDetection();
      statusColor = fireAlarmData.getSimpleSystemStatusColorWithDetection();

      // 🎯 Consistent status colors - Alarm=Red, ALARM DRILL=Red, Trouble=Orange, Normal=Green, No Data=Grey
      if (statusText == 'SYSTEM TROUBLE') {
        statusColor = Colors.orange;
        textColor = Colors.white;
      } else if (statusText == 'ALARM DRILL') {
        statusColor = Colors.red;  // Same as ALARM
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
      padding: const EdgeInsets.only(bottom: 3),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 15),
        padding: EdgeInsets.symmetric(
          vertical: useCompactMode ? 8 : 12,
        ),
        constraints: BoxConstraints(
          minHeight: customHeight ?? 60,
        ),
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
              fontSize: fontSize * (useCompactMode ? 1.8 : 2.0),
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 3,
            ),
          ),
        ),
      ),
    );
  }

  /// Build Status Indicators Section
  Widget _buildStatusIndicators(BuildContext context, FireAlarmData fireAlarmData) {
    final fontSize = _calculateResponsiveFontSize(context);

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
                _buildStatusIndicator('AC POiWER', 'AC Power', fontSize, fireAlarmData),
                _buildStatusIndicator('DC POWER', 'DC Power', fontSize, fireAlarmData),
                _buildStatusIndicator('ALARM', 'Alarm', fontSize, fireAlarmData),
                _buildStatusIndicator('TROUBLE', 'Trouble', fontSize, fireAlarmData),
                _buildStatusIndicator('DRILL', 'Drill', fontSize, fireAlarmData),
                _buildStatusIndicator('SILENCED', 'Silenced', fontSize, fireAlarmData),
                _buildStatusIndicator('DISABLED', 'Disabled', fontSize, fireAlarmData),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build Individual Status Indicator
  Widget _buildStatusIndicator(
    String label,
    String statusKey,
    double baseFontSize,
    FireAlarmData fireAlarmData,
  ) {
    // 🎯 UNIFIED: Use consistent getSystemStatus method for ALL indicators
    // This ensures all 7 indicators use the same data source (Path C → LED Decoder/SystemStatusData)
    bool isActive = fireAlarmData.getSystemStatus(statusKey);

      // 🔥 FIXED: LED indicators now 100% independent from zone data
    // All 7 indicators use ONLY master status data (Path C → LED Decoder)
    // No more Simple Status Manager override for Alarm/Trouble LEDs!

    

    final activeColor = fireAlarmData.getActiveColor(statusKey);
    final inactiveColor = fireAlarmData.getInactiveColor(statusKey);

    
    final indicatorSize = useCompactMode ? 18.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: baseFontSize * (useCompactMode ? 0.8 : 0.9),
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
        SizedBox(height: useCompactMode ? 4 : 6),
        Container(
          width: indicatorSize,
          height: indicatorSize,
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
        
        // Status text indicator removed for cleaner, more professional appearance
        // LED circle indicator alone provides clear visual feedback
        // without text duplication for better UI aesthetics
      ],
    );
  }

  /// Calculate responsive font size based on screen dimensions
  double _calculateResponsiveFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = _calculateDiagonal(size.width, size.height);
    final baseSize = diagonal / 100;
    return baseSize.clamp(8.0, 15.0);
  }

  /// Calculate screen diagonal
  double _calculateDiagonal(double width, double height) {
    return math.sqrt(width * width + height * height);
  }
}

/// Extension for double power calculation
extension DoubleExtension on double {
  double pow(int exponent) {
    if (exponent == 0) return 1.0;
    if (exponent < 0) return 1.0 / pow(-exponent);
    
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}

/// Compact Status Bar for space-constrained areas
class CompactStatusBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool showProjectName;

  const CompactStatusBar({
    super.key,
    this.scaffoldKey,
    this.showProjectName = true,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedStatusBar(
      scaffoldKey: scaffoldKey,
      useCompactMode: true,
      showProjectInfo: showProjectName,
      showStatusIndicators: true,
      showSystemStatus: true,
      customHeight: 50.0,
    );
  }
}

/// Full Status Bar for detailed pages
class FullStatusBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const FullStatusBar({
    super.key,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedStatusBar(
      scaffoldKey: scaffoldKey,
      useCompactMode: false,
      showProjectInfo: true,
      showStatusIndicators: true,
      showSystemStatus: true,
    );
  }
}

/// Minimal Status Bar for pages with limited space
class MinimalStatusBar extends StatelessWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const MinimalStatusBar({
    super.key,
    this.scaffoldKey,
  });

  @override
  Widget build(BuildContext context) {
    return UnifiedStatusBar(
      scaffoldKey: scaffoldKey,
      useCompactMode: true,
      showProjectInfo: false,
      showStatusIndicators: false,
      showSystemStatus: true,
      customHeight: 45.0,
    );
  }
}
