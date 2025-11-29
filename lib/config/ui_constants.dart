// 🎨 UI CONSTANTS - Centralized UI Configuration
//
// Berisi semua konstanta untuk UI, layout, padding, spacing, dan styling
// Menggantikan magic numbers yang tersebar di seluruh codebase
//
// Author: Claude Code Assistant
// Version: 1.0.0

import 'package:flutter/material.dart';

class UIConstants {
  // ==================== LAYOUT & SPACING ====================

  /// Small spacing for tight elements
  static const double spacingXS = 4.0;

  /// Small spacing
  static const double spacingS = 8.0;

  /// Medium spacing
  static const double spacingM = 16.0;

  /// Large spacing
  static const double spacingL = 24.0;

  /// Extra large spacing
  static const double spacingXL = 32.0;

  /// Horizontal gap between zone groups (5-zone groups)
  static const double zoneGroupHorizontalGap = 16.0;

  // ==================== NAVIGATION & APP BAR ====================

  /// Bottom navigation bar height
  static const double bottomNavHeight = 56.0;

  /// App bar height
  static const double appBarHeight = 56.0;

  /// Safe area bottom buffer
  static const double safeAreaBottomBuffer = 100.0;

  // ==================== CARD & CONTAINER DIMENSIONS ====================

  /// Card border radius
  static const double cardBorderRadius = 8.0;

  /// Card elevation
  static const double cardElevation = 2.0;

  /// Dialog border radius
  static const double dialogBorderRadius = 12.0;

  /// Button border radius
  static const double buttonBorderRadius = 6.0;

  // ==================== FONT SIZES ====================

  /// Extra small font size
  static const double fontSizeXS = 10.0;

  /// Small font size
  static const double fontSizeS = 12.0;

  /// Medium font size
  static const double fontSizeM = 14.0;

  /// Large font size
  static const double fontSizeL = 16.0;

  /// Extra large font size
  static const double fontSizeXL = 18.0;

  /// Extra extra large font size
  static const double fontSizeXXL = 20.0;

  /// Title font size
  static const double fontSizeTitle = 24.0;

  // ==================== TABLE CONSTANTS ====================

  /// Table header font size
  static const double tableHeaderFontSize = 12.0;

  /// Table data font size
  static const double tableDataFontSize = 11.0;

  /// Table padding
  static const double tablePadding = 8.0;

  /// Table minimum column widths
  static const double tableMinColumnWidth = 60.0;

  /// Table minimum zone column width
  static const double tableMinZoneWidth = 100.0;

  // ==================== HOME PAGE SPECIFIC ====================

  /// Home page refresh button size
  static const double homeRefreshButtonSize = 40.0;

  /// Home page recent status height percentage (large screens)
  static const double homeRecentStatusHeightRatio = 0.3;

  /// Home page recent status height (medium screens)
  static const double homeRecentStatusHeightMedium = 250.0;

  /// Home page recent status height (small screens)
  static const double homeRecentStatusHeightSmall = 300.0;

  /// Home page recent status height (extra small screens)
  static const double homeRecentStatusHeightExtraSmall = 350.0;

  /// Home page content top padding
  static const double homeContentTopPadding = 5.0;

  /// Home page content bottom padding
  static const double homeContentBottomPadding = 15.0;

  // ==================== MONITORING PAGE CONSTANTS ====================

  /// Monitoring zone card width
  static const double monitoringZoneCardWidth = 60.0;

  /// Monitoring zone card height
  static const double monitoringZoneCardHeight = 40.0;

  /// Monitoring zone font size
  static const double monitoringZoneFontSize = 10.0;

  /// Monitoring zone border radius
  static const double monitoringZoneBorderRadius = 4.0;

  // ==================== TAB MONITORING CONSTANTS ====================

  /// Tab monitoring device container width
  static const double tabMonitoringDeviceWidth = 280.0;

  /// Tab monitoring device container height
  static const double tabMonitoringDeviceHeight = 320.0;

  /// Tab monitoring zone grid cross axis count
  static const int tabMonitoringZoneGridCrossAxisCount = 5;

  /// Tab monitoring zone grid child aspect ratio
  static const double tabMonitoringZoneGridChildAspectRatio = 1.2;

  // ==================== ZONE MONITORING PAGE CONSTANTS ====================

  /// Zone monitoring grid cross axis count
  static const int zoneMonitoringGridCrossAxisCount = 5;

  /// Zone monitoring grid child aspect ratio
  static const double zoneMonitoringGridChildAspectRatio = 1.0;

  // ==================== FULL MONITORING PAGE CONSTANTS ====================

  /// Full monitoring grid cross axis count
  static const int fullMonitoringGridCrossAxisCount = 8;

  /// Full monitoring grid child aspect ratio
  static const double fullMonitoringGridChildAspectRatio = 1.0;

  /// Full monitoring large horizontal gap
  static const double fullMonitoringLargeHorizontalGap = 16.0;

  // ==================== CONTROL PAGE CONSTANTS ====================

  /// Control button height
  static const double controlButtonHeight = 50.0;

  /// Control section spacing
  static const double controlSectionSpacing = 20.0;

  // ==================== HISTORY PAGE CONSTANTS ====================

  /// History table height ratio
  static const double historyTableHeightRatio = 0.8;

  /// History tab bar height
  static const double historyTabBarHeight = 50.0;

  /// History content padding
  static const double historyContentPadding = 16.0;

  // ==================== ANIMATION DURATIONS ====================

  /// Fast animation duration
  static const Duration animationFast = Duration(milliseconds: 150);

  /// Normal animation duration
  static const Duration animationNormal = Duration(milliseconds: 300);

  /// Slow animation duration
  static const Duration animationSlow = Duration(milliseconds: 500);

  // ==================== DELAY VALUES ====================

  /// Very short delay for UI updates
  static const Duration delayVeryShort = Duration(milliseconds: 50);

  /// Short delay
  static const Duration delayShort = Duration(milliseconds: 100);

  /// Medium delay
  static const Duration delayMedium = Duration(milliseconds: 200);

  /// Long delay
  static const Duration delayLong = Duration(milliseconds: 500);

  // ==================== SCREEN BREAKPOINTS ====================

  /// Small screen breakpoint
  static const double breakpointSmall = 380.0;

  /// Medium screen breakpoint
  static const double breakpointMedium = 500.0;

  /// Large screen breakpoint
  static const double breakpointLarge = 600.0;

  /// Tablet breakpoint
  static const double breakpointTablet = 900.0;

  // ==================== MULTIPLIERS ====================

  /// Table column multiplier for small screens
  static const double tableMultiplierSmall = 0.8;

  /// Table column multiplier for medium screens
  static const double tableMultiplierMedium = 1.0;

  /// Table column multiplier for large screens
  static const double tableMultiplierLarge = 1.2;

  /// Table column multiplier for tablet screens
  static const double tableMultiplierTablet = 1.5;

  /// Table column multiplier for desktop screens
  static const double tableMultiplierDesktop = 1.6;

  // ==================== RESPONSIVE HELPERS ====================

  /// Check if screen width is small
  static bool isSmallScreen(double screenWidth) {
    return screenWidth < breakpointSmall;
  }

  /// Check if screen width is medium
  static bool isMediumScreen(double screenWidth) {
    return screenWidth >= breakpointSmall && screenWidth < breakpointMedium;
  }

  /// Check if screen width is large
  static bool isLargeScreen(double screenWidth) {
    return screenWidth >= breakpointMedium && screenWidth < breakpointLarge;
  }

  /// Check if screen width is tablet
  static bool isTabletScreen(double screenWidth) {
    return screenWidth >= breakpointLarge && screenWidth < breakpointTablet;
  }

  /// Check if screen width is desktop
  static bool isDesktopScreen(double screenWidth) {
    return screenWidth >= breakpointTablet;
  }

  /// Get table multiplier based on screen width
  static double getTableMultiplier(double screenWidth) {
    if (isSmallScreen(screenWidth)) return tableMultiplierSmall;
    if (isMediumScreen(screenWidth)) return tableMultiplierMedium;
    if (isLargeScreen(screenWidth)) return tableMultiplierLarge;
    if (isTabletScreen(screenWidth)) return tableMultiplierTablet;
    return tableMultiplierDesktop;
  }

  // ==================== COLOR CONSTANTS ====================

  /// 🎨 DATE PICKER COLORS - Green Theme (Matching Home Tab)

  /// Primary green color (main brand color)
  static const Color primaryGreen = Color.fromARGB(255, 19, 137, 47);

  /// Dark green for borders and text
  static const Color primaryGreenDark = Color.fromARGB(255, 10, 103, 39);

  /// Light green transparent background for selected state
  static Color get primaryGreenLight => Color.fromARGB(255, 19, 137, 47).withAlpha(38);

  /// Text color for selected date
  static const Color selectedTextColor = Color.fromARGB(255, 10, 103, 39);

  /// Text color for unselected date
  static Color get unselectedTextColor => Colors.grey[700] ?? Colors.grey;

  /// Background color for unselected date
  static const Color unselectedBackgroundColor = Colors.transparent;

  /// Refresh button background color
  static const Color refreshButtonColor = Color.fromARGB(255, 19, 137, 47);

  /// Border width for selected state
  static const double selectedBorderWidth = 1.5;

  /// Primary opacity for disabled elements
  static const double disabledOpacity = 0.5;

  /// Shadow opacity
  static const double shadowOpacity = 0.1;

  /// Border opacity
  static const double borderOpacity = 0.2;

  // ==================== VALIDATION ====================

  /// Validate UI configuration
  static bool validateConfiguration() {
    // Check mathematical consistency
    if (spacingXS >= spacingS || spacingS >= spacingM) {
      
      return false;
    }

    if (fontSizeXS >= fontSizeS || fontSizeS >= fontSizeM) {
      
      return false;
    }

    // Check responsive breakpoints
    if (breakpointSmall >= breakpointMedium ||
        breakpointMedium >= breakpointLarge ||
        breakpointLarge >= breakpointTablet) {
      
      return false;
    }

    
    return true;
  }

  // ==================== DEBUG INFO ====================

  /// Get UI configuration info
  static Map<String, dynamic> getUIInfo() {
    return {
      'spacingValues': {
        'XS': spacingXS,
        'S': spacingS,
        'M': spacingM,
        'L': spacingL,
        'XL': spacingXL,
      },
      'fontSizes': {
        'XS': fontSizeXS,
        'S': fontSizeS,
        'M': fontSizeM,
        'L': fontSizeL,
        'XL': fontSizeXL,
        'XXL': fontSizeXXL,
        'Title': fontSizeTitle,
      },
      'breakpoints': {
        'Small': breakpointSmall,
        'Medium': breakpointMedium,
        'Large': breakpointLarge,
        'Tablet': breakpointTablet,
      },
      'validationPassed': validateConfiguration(),
    };
  }
}