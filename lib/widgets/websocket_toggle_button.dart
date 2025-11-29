import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/websocket_mode_manager.dart';

/// WebSocket Toggle Button untuk switching antara Firebase (Online) dan ESP32 (Offline)
/// Center-positioned di header home page
class WebSocketToggleButton extends StatelessWidget {
  final WebSocketModeManager manager;
  final VoidCallback? onTap;
  final bool showLabel;
  final double? width;
  final EdgeInsets? padding;

  const WebSocketToggleButton({
    super.key,
    required this.manager,
    this.onTap,
    this.showLabel = true,
    this.width,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        final isWebSocketMode = manager.isWebSocketMode;
        final isConnecting = manager.isConnecting;

        return GestureDetector(
          onTap: onTap ?? () async {
            // Haptic feedback
            try {
              // ignore: deprecated_member_use
              HapticFeedback.lightImpact();
            } catch (e) {
              // Ignore haptic feedback errors
            }

            // Toggle mode
            final success = await manager.toggleMode();

            if (success) {
              if (context.mounted) {
                _showModeChangedSnackbar(context, isWebSocketMode);
              }
            } else {
              if (context.mounted) {
                _showErrorSnackbar(context, manager.lastError);
              }
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: width,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isConnecting
                  ? Colors.orange
                  : (isWebSocketMode ? Colors.grey.shade600 : Colors.green),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isConnecting
                    ? Colors.orange.shade700
                    : (isWebSocketMode ? Colors.grey.shade700 : Colors.green.shade700),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (isConnecting
                      ? Colors.orange
                      : (isWebSocketMode ? Colors.grey : Colors.green))
                      .withValues(alpha:0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConnecting) ...[
                  // Loading indicator
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else ...[
                  // Mode icon
                  Icon(
                    isWebSocketMode
                        ? Icons.cloud_off // Offline/ESP32
                        : Icons.cloud_done, // Online/Firebase
                    size: 16,
                    color: Colors.white,
                  ),
                ],

                if (showLabel) ...[
                  const SizedBox(width: 6),
                  Text(
                    isConnecting
                        ? 'Connecting...'
                        : (isWebSocketMode ? 'Offline' : 'Online'),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show mode changed snackbar
  void _showModeChangedSnackbar(BuildContext context, bool wasWebSocketMode) {
    final newModeText = !wasWebSocketMode ? 'ESP32 (Offline)' : 'Firebase (Online)';
    final icon = !wasWebSocketMode ? Icons.wifi_off : Icons.cloud_done;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Switched to $newModeText mode'),
          ],
        ),
        backgroundColor: !wasWebSocketMode ? Colors.grey.shade600 : Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(BuildContext context, String? error) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                error ?? 'Connection failed',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () async {
            final success = await manager.toggleMode();
            if (success) {
              if (context.mounted) {
                _showModeChangedSnackbar(context, !manager.isWebSocketMode);
              }
            }
          },
        ),
      ),
    );
  }
}

/// Compact version of WebSocket toggle for smaller spaces
class CompactWebSocketToggle extends StatelessWidget {
  final WebSocketModeManager manager;
  final VoidCallback? onTap;

  const CompactWebSocketToggle({
    super.key,
    required this.manager,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        final isWebSocketMode = manager.isWebSocketMode;
        final isConnecting = manager.isConnecting;

        return GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isConnecting
                  ? Colors.orange
                  : (isWebSocketMode ? Colors.grey.shade600 : Colors.green),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnecting
                    ? Colors.orange.shade700
                    : (isWebSocketMode ? Colors.grey.shade700 : Colors.green.shade700),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isConnecting) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ] else ...[
                  Icon(
                    isWebSocketMode ? Icons.cloud_off : Icons.cloud_done,
                    size: 14,
                    color: Colors.white,
                  ),
                ],
                const SizedBox(width: 4),
                Text(
                  isConnecting ? '...' : (isWebSocketMode ? 'Off' : 'On'),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Status-only version without toggle functionality
class WebSocketStatusButton extends StatelessWidget {
  final WebSocketModeManager manager;

  const WebSocketStatusButton({
    super.key,
    required this.manager,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: manager,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: manager.getStatusColor().withValues(alpha:0.5),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Status indicator circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: manager.getStatusColor(),
                  boxShadow: [
                    BoxShadow(
                      color: manager.getStatusColor().withValues(alpha:0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Status text
              Text(
                manager.getStatusText(),
                style: TextStyle(
                  color: manager.getStatusColor(),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}