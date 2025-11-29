import 'package:flutter/material.dart';
import '../config/animation_constants.dart';

/// Blinking tab header widget with glow effects for alarm and trouble indicators
class BlinkingTabHeader extends StatefulWidget {
  final Widget child;
  final bool shouldBlink;
  final Color blinkColor;
  final bool enableGlow;

  const BlinkingTabHeader({
    super.key,
    required this.child,
    required this.shouldBlink,
    required this.blinkColor,
    this.enableGlow = true,
  });

  @override
  State<BlinkingTabHeader> createState() => _BlinkingTabHeaderState();
}

class _BlinkingTabHeaderState extends State<BlinkingTabHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _glowAnimation;

  
  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    if (widget.shouldBlink) {
      _startBlinking();
    }
  }

  void _initializeAnimation() {
    _controller = AnimationController(
      duration: AnimationConstants.blinkingInterval,
      vsync: this,
    );

    // Opacity animation for blinking effect
    _opacityAnimation = Tween<double>(
      begin: AnimationConstants.maxOpacity,
      end: AnimationConstants.minOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.blinkingCurve,
    ));

    // Glow intensity animation for shadow effects
    _glowAnimation = Tween<double>(
      begin: AnimationConstants.minGlowIntensity,
      end: AnimationConstants.maxGlowIntensity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: AnimationConstants.blinkingCurve,
    ));
  }

  void _startBlinking() {
    _controller.repeat(reverse: true);
  }

  void _stopBlinking() {
    _controller.stop();
    _controller.reset();
  }

  @override
  void didUpdateWidget(BlinkingTabHeader oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.shouldBlink != widget.shouldBlink) {
      if (widget.shouldBlink) {
        _startBlinking();
      } else {
        _stopBlinking();
      }
    }

    // Update blink color if it changes
    if (oldWidget.blinkColor != widget.blinkColor) {
      // Animation will pick up new color on next build
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BoxShadow> _buildGlowShadows() {
    if (!widget.enableGlow || !widget.shouldBlink) {
      return [];
    }

    final glowIntensity = _glowAnimation.value;
    final glowColor = AnimationConstants.getAlarmGlowColor(widget.blinkColor);

    return [
      // Inner glow
      BoxShadow(
        color: Color.fromARGB(
          (glowColor.a * glowIntensity * 255.0).round(),
          (glowColor.r * 255.0).round(),
          (glowColor.g * 255.0).round(),
          (glowColor.b * 255.0).round(),
        ),
        spreadRadius: AnimationConstants.innerGlowSpreadRadius + (glowIntensity * AnimationConstants.maxGlowSpreadRadiusVariation),
        blurRadius: AnimationConstants.innerGlowBlurRadius + (glowIntensity * AnimationConstants.maxGlowBlurRadiusVariation),
        offset: const Offset(0, AnimationConstants.innerGlowOffsetY),
      ),
      // Outer glow
      BoxShadow(
        color: Color.fromARGB(
          (glowColor.a * glowIntensity * AnimationConstants.outerGlowIntensityMultiplier * 255.0).round(),
          (glowColor.r * 255.0).round(),
          (glowColor.g * 255.0).round(),
          (glowColor.b * 255.0).round(),
        ),
        spreadRadius: AnimationConstants.outerGlowSpreadRadius + (glowIntensity * AnimationConstants.maxGlowSpreadRadiusVariation),
        blurRadius: AnimationConstants.outerGlowBlurRadius + (glowIntensity * AnimationConstants.maxGlowBlurRadiusVariation),
        offset: const Offset(0, AnimationConstants.outerGlowOffsetY),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return AnimatedContainer(
          duration: AnimationConstants.transitionDuration,
          decoration: BoxDecoration(
            boxShadow: _buildGlowShadows(),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Opacity(
            opacity: widget.shouldBlink ? _opacityAnimation.value : AnimationConstants.maxOpacity,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}