import 'package:flutter/material.dart';

/// Animation constants for blinking and glow effects
class AnimationConstants {
  // Private constructor to prevent instantiation
  AnimationConstants._();

  /// Blinking animation timing
  static const Duration blinkingInterval = Duration(milliseconds: 750);
  static const Duration transitionDuration = Duration(milliseconds: 150);

  /// Blinking animation curves
  static const Curve blinkingCurve = Curves.easeInOut;

  /// Opacity values for blinking effect
  static const double maxOpacity = 1.0;
  static const double minOpacity = 0.3;

  /// Glow effect parameters
  static const double minGlowIntensity = 0.3;
  static const double maxGlowIntensity = 1.0;
  static const double glowAlpha = 0.4; // 40% opacity for glow shadows

  /// Glow shadow parameters
  static const double innerGlowSpreadRadius = 1.0;
  static const double innerGlowBlurRadius = 4.0;
  static const double innerGlowOffsetY = 1.0;

  static const double outerGlowSpreadRadius = 2.0;
  static const double outerGlowBlurRadius = 8.0;
  static const double outerGlowOffsetY = 2.0;

  /// Performance and accessibility settings
  static const double maxGlowSpreadRadiusVariation = 3.0;
  static const double maxGlowBlurRadiusVariation = 6.0;
  static const double outerGlowIntensityMultiplier = 0.6;

  /// Color definitions for different states
  static Color getAlarmGlowColor(Color baseColor) {
    return Color.fromARGB(
      (255 * glowAlpha).round(),
      (baseColor.r * 255.0).round(),
      (baseColor.g * 255.0).round(),
      (baseColor.b * 255.0).round(),
    );
  }

  static Color getTroubleGlowColor(Color baseColor) {
    return Color.fromARGB(
      (255 * glowAlpha).round(),
      (baseColor.r * 255.0).round(),
      (baseColor.g * 255.0).round(),
      (baseColor.b * 255.0).round(),
    );
  }
}