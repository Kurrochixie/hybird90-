import 'package:flutter/material.dart';

/// 📱 Tablet Responsive Helper - Optimized for 10.1" Tablet (1280x800)
/// Provides tablet-specific responsive design calculations and optimizations
class TabletResponsiveHelper {
  // ============= DEVICE DETECTION =============

  /// Check if current device is a tablet
  static bool isTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600;
  }

  /// Check if current device is a large tablet (1280px+ width)
  static bool isLargeTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 1200;
  }

  /// Check if current device is a medium tablet (900-1200px width)
  static bool isMediumTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 900 && screenWidth < 1200;
  }

  /// Check if current device is a small tablet (600-900px width)
  static bool isSmallTablet(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth >= 600 && screenWidth < 900;
  }

  // ============= LAYOUT CALCULATIONS =============

  /// Calculate optimal column count for zone display based on screen width
  static int calculateOptimalColumns(double screenWidth) {
    // Tablet-specific logic for optimal layout
    if (screenWidth >= 1200) return 4;  // Large tablets (1280px+)
    if (screenWidth >= 900) return 3;   // Medium tablets
    if (screenWidth >= 600) return 2;   // Small tablets
    return 1;                           // Phone fallback
  }

  /// Calculate optimal number of module tables per row
  static int calculateTablesPerRow(double screenWidth) {
    if (screenWidth >= 1200) return 2;  // Large tablets: 2 tables per row
    if (screenWidth >= 900) return 2;   // Medium tablets: 2 tables per row
    if (screenWidth >= 600) return 1;   // Small tablets: 1 table per row
    return 1;                           // Phone fallback
  }

  /// Calculate optimal spacing between elements
  static double calculateOptimalSpacing(BuildContext context) {
    if (isLargeTablet(context)) return 16.0;   // More spacing for large tablets
    if (isMediumTablet(context)) return 12.0;   // Medium spacing
    if (isSmallTablet(context)) return 8.0;    // Less spacing for small tablets
    return 6.0;                                 // Phone fallback
  }

  // ============= ZONE SIZING =============

  /// Get optimal zone size based on device type and screen width
  static double getOptimalZoneSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= 1200) return 48.0;  // Large tablets: bigger zones
    if (screenWidth >= 900) return 40.0;   // Medium tablets: medium zones
    if (screenWidth >= 600) return 36.0;   // Small tablets: slightly bigger
    return 28.0;                           // Phone fallback
  }

  /// Get optimal font size based on device type
  static double getOptimalFontSize(BuildContext context) {
    if (isLargeTablet(context)) return 16.0;  // Large tablets: larger font
    if (isMediumTablet(context)) return 15.0;  // Medium tablets: medium-large font
    if (isSmallTablet(context)) return 14.0;  // Small tablets: medium font
    return 13.0;                               // Phone fallback
  }

  /// Get optimal row height for DataTable based on device type
  static double getOptimalRowHeight(BuildContext context) {
    if (isLargeTablet(context)) return 64.0;  // Large tablets: more space
    if (isMediumTablet(context)) return 56.0;  // Medium tablets: medium space
    if (isSmallTablet(context)) return 52.0;  // Small tablets: slightly more space
    return 48.0;                               // Phone fallback
  }

  /// Get optimal DataTable spacing for tablets
  static DataTableSpacing getOptimalDataTableSpacing(BuildContext context) {
    if (isLargeTablet(context)) {
      return DataTableSpacing(
        horizontalMargin: 12.0,
        columnSpacing: 8.0,
      );
    } else if (isMediumTablet(context)) {
      return DataTableSpacing(
        horizontalMargin: 8.0,
        columnSpacing: 6.0,
      );
    } else if (isSmallTablet(context)) {
      return DataTableSpacing(
        horizontalMargin: 6.0,
        columnSpacing: 4.0,
      );
    }

    // Phone fallback
    return DataTableSpacing(
      horizontalMargin: 4.0,
      columnSpacing: 2.0,
    );
  }

  // ============= SAFE AREA HANDLING =============

  /// Get safe adjusted width considering device safe areas
  static double getSafeAdjustedWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;
    final adjustedWidth = mediaQuery.size.width - safePadding.horizontal;

    // Ensure minimum usable width
    return adjustedWidth.clamp(320.0, double.infinity);
  }

  /// Get optimal padding for tablets considering safe areas
  static EdgeInsets getOptimalPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final safePadding = mediaQuery.padding;

    // Use safe area padding for tablets, minimum 8px for phones
    return EdgeInsets.only(
      left: isTablet(context) ? safePadding.left : 8.0,
      right: isTablet(context) ? safePadding.right : 8.0,
      top: isTablet(context) ? safePadding.top : 8.0,
      bottom: isTablet(context) ? safePadding.bottom : 8.0,
    );
  }

  // ============= DEBUGGING HELPERS =============

  /// Print device information for debugging
  static void debugDeviceInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    final devicePixelRatio = mediaQuery.devicePixelRatio;
    final safePadding = mediaQuery.padding;

    
    
    
    
    
    
    
    
    
  }

  /// Get device type as string for debugging
  static String getDeviceTypeString(BuildContext context) {
    if (isLargeTablet(context)) return 'Large Tablet (1200px+)';
    if (isMediumTablet(context)) return 'Medium Tablet (900-1200px)';
    if (isSmallTablet(context)) return 'Small Tablet (600-900px)';
    return 'Phone (<600px)';
  }
}

/// DataTable spacing configuration for different device types
class DataTableSpacing {
  final double horizontalMargin;
  final double columnSpacing;

  const DataTableSpacing({
    required this.horizontalMargin,
    required this.columnSpacing,
  });
}