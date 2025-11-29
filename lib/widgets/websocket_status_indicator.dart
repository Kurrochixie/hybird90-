import 'package:flutter/material.dart';
import '../services/websocket_mode_manager.dart';

/// WebSocket Status Indicator dengan lingkaran warna dan status text
/// Positioned di sebelah kanan header saat WebSocket mode aktif
class WebSocketStatusIndicator extends StatelessWidget {
  final WebSocketModeManager manager;
  final bool showText;
  final bool showTooltip;
  final EdgeInsets? padding;
  final double? circleSize;

  const WebSocketStatusIndicator({
    super.key,
    required this.manager,
    this.showText = true,
    this.showTooltip = true,
    this.padding,
    this.circleSize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        // Only show when in WebSocket mode
        if (!manager.isWebSocketMode) {
          return const SizedBox.shrink();
        }

        final isConnected = manager.isConnected;
        final isConnecting = manager.isConnecting;
        final statusColor = _getStatusColor(isConnected, isConnecting);
        final statusText = _getStatusText(isConnected, isConnecting);

        final widget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Status circle with animation
            _buildStatusCircle(statusColor, isConnecting),

            if (showText) ...[
              const SizedBox(width: 6),
              // Status text
              _buildStatusText(statusText, statusColor),
            ],
          ],
        );

        // Add tooltip if enabled
        if (showTooltip) {
          return Tooltip(
            message: _getTooltipText(isConnected, isConnecting),
            child: widget,
          );
        }

        return widget;
      },
    );
  }

  Widget _buildStatusCircle(Color color, bool isConnecting) {
    final size = circleSize ?? 10.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isConnecting
          ? _buildPulsingIndicator(color)
          : null,
    );
  }

  Widget _buildPulsingIndicator(Color color) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusText(String text, Color color) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: color,
        fontSize: 10,
      ),
    );
  }

  Color _getStatusColor(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return Colors.orange;
    } else if (isConnected) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusText(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return 'ESP32 Connecting...';
    } else if (isConnected) {
      return 'ESP32 Connected';
    } else {
      return 'ESP32 Disconnected';
    }
  }

  String _getTooltipText(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return 'Connecting to ESP32 WebSocket...';
    } else if (isConnected) {
      return 'ESP32 WebSocket connected successfully';
    } else {
      return 'ESP32 WebSocket disconnected. Tap toggle to reconnect.';
    }
  }
}

/// Compact version of status indicator for tight spaces
class CompactWebSocketStatusIndicator extends StatelessWidget {
  final WebSocketModeManager manager;
  final double size;
  final bool showPulseWhenConnecting;

  const CompactWebSocketStatusIndicator({
    super.key,
    required this.manager,
    this.size = 8.0,
    this.showPulseWhenConnecting = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        // Only show when in WebSocket mode
        if (!manager.isWebSocketMode) {
          return const SizedBox.shrink();
        }

        final isConnected = manager.isConnected;
        final isConnecting = manager.isConnecting;
        final statusColor = _getStatusColor(isConnected, isConnecting);

        return Tooltip(
          message: _getTooltipText(isConnected, isConnecting),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha:0.3),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: isConnecting && showPulseWhenConnecting
                ? _buildPulsingDot()
                : null,
          ),
        );
      },
    );
  }

  Widget _buildPulsingDot() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.2, end: 0.8),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Center(
          child: Container(
            width: size * 0.5,
            height: size * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: value),
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return Colors.orange;
    } else if (isConnected) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getTooltipText(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return 'Connecting to ESP32...';
    } else if (isConnected) {
      return 'ESP32 Connected';
    } else {
      return 'ESP32 Disconnected';
    }
  }
}

/// Enhanced status indicator with detailed information
class DetailedWebSocketStatusIndicator extends StatelessWidget {
  final WebSocketModeManager manager;
  final VoidCallback? onTap;

  const DetailedWebSocketStatusIndicator({
    super.key,
    required this.manager,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        // Only show when in WebSocket mode
        if (!manager.isWebSocketMode) {
          return const SizedBox.shrink();
        }

        final isConnected = manager.isConnected;
        final isConnecting = manager.isConnecting;
        final statusColor = _getStatusColor(isConnected, isConnecting);
        final statusText = _getStatusText(isConnected, isConnecting);

        return GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusColor.withValues(alpha:0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha:0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status circle
                _buildStatusCircle(statusColor, isConnecting),

                const SizedBox(width: 8),

                // Status text and details
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        fontSize: 12,
                      ),
                    ),
                    if (manager.esp32IP.isNotEmpty)
                      Text(
                        'IP: ${manager.esp32IP}',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),

                // Arrow icon
                if (onTap != null)
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: statusColor,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusCircle(Color color, bool isConnecting) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isConnecting
          ? _buildPulsingIndicator(color)
          : null,
    );
  }

  Widget _buildPulsingIndicator(Color color) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 1000),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return Colors.orange;
    } else if (isConnected) {
      return Colors.green;
    } else {
      return Colors.grey;
    }
  }

  String _getStatusText(bool isConnected, bool isConnecting) {
    if (isConnecting) {
      return 'ESP32 Connecting';
    } else if (isConnected) {
      return 'ESP32 Connected';
    } else {
      return 'ESP32 Offline';
    }
  }
}