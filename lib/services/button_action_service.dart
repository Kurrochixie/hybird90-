import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/fire_alarm_data.dart';
import '../di/service_locator.dart';
import 'bell_manager.dart';
import 'auth_service.dart';

/// Service terpusat untuk mengelola aksi button pada Control Page dan Full Monitoring Page
/// Mengirim data ke Firebase path: system_status/user_input/data
class ButtonActionService {
  static final ButtonActionService _instance = ButtonActionService._internal();
  factory ButtonActionService() => _instance;
  ButtonActionService._internal();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();

  // Button action codes
  static const String drillCode = 'd';
  static const String systemResetCode = 'r';
  static const String acknowledgeCode = 'a';
  static const String silenceCode = 's';

  // Track last sent data to prevent duplicates
  String? _lastSentData;
  DateTime? _lastSentTime;

  /// Mengirim data button action dengan mode-aware routing
  /// Firebase mode: Kirim ke Firebase, WebSocket mode: Kirim ke ESP32
  /// Data hanya dikirim 1x untuk mencegah pengiriman berulang
  Future<bool> sendButtonAction(String actionCode, {required BuildContext context}) async {
    try {
      final fireAlarmData = context.read<FireAlarmData>();

      // 🚀 MODE-AWARE ROUTING
      if (fireAlarmData.isWebSocketMode) {
        // WebSocket Mode: Kirim langsung ke ESP32
        return await _sendToESP32(actionCode, context, fireAlarmData);
      } else {
        // Firebase Mode: Kirim ke Firebase (existing logic)
        return await _sendToFirebase(actionCode, context, fireAlarmData);
      }
    } catch (e) {
      
      if (context.mounted) {
        _showErrorNotification(context, 'Failed to send command');
      }
      return false;
    }
  }

  /// Kirim command ke Firebase (existing logic)
  Future<bool> _sendToFirebase(String actionCode, BuildContext context, dynamic fireAlarmData) async {
    try {
      // Cek koneksi Firebase
      if (!fireAlarmData.isFirebaseConnected) {
        if (context.mounted) {
          _showDisconnectedNotification(context);
        }
        return false;
      }

      // Cegah pengiriman data yang sama dalam waktu 1 detik
      if (_lastSentData == actionCode && _lastSentTime != null) {
        final timeDiff = DateTime.now().difference(_lastSentTime!);
        if (timeDiff.inMilliseconds < 1000) {
          
          return false;
        }
      }

      // Kirim data ke Firebase
      final userInputRef = _databaseRef.child('system_status/user_input/data/');

      await userInputRef.set({
        'DATA_UNTUK_SISTEM': actionCode,
        'timestamp': ServerValue.timestamp,
        'user': await _authService.getCurrentUsername() ?? 'Unknown',
        'action': _getActionName(actionCode),
      });

      // Update tracking
      _lastSentData = actionCode;
      _lastSentTime = DateTime.now();

      
      return true;
    } catch (e) {
      
      if (context.mounted) {
        _showErrorNotification(context, 'Failed to send command');
      }
      return false;
    }
  }

  /// Kirim command ke ESP32 via WebSocket
  Future<bool> _sendToESP32(String actionCode, BuildContext context, dynamic fireAlarmData) async {
    try {
      

      // Cek koneksi WebSocket
      final modeManager = fireAlarmData.modeManager;
      if (!modeManager.isWebSocketMode || !modeManager.isConnected) {
        if (context.mounted) {
          _showESPDisconnectedNotification(context);
        }
        return false;
      }

      // Cegah pengiriman data yang sama dalam waktu 1 detik
      if (_lastSentData == actionCode && _lastSentTime != null) {
        final timeDiff = DateTime.now().difference(_lastSentTime!);
        if (timeDiff.inMilliseconds < 1000) {
          
          return false;
        }
      }

      // Kirim command via WebSocket manager
      final webSocketManager = modeManager.webSocketManager;
      if (webSocketManager == null) {
        
        return false;
      }

      final commandData = {
        'command': actionCode,
        'type': 'control_command',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'user': await _authService.getCurrentUsername() ?? 'Unknown',
        'action': _getActionName(actionCode),
      };

      final success = await webSocketManager.sendToESP32(commandData);

      if (success) {
        // 🔔 BELL MANAGER INTEGRATION: Process bell-related commands
        if (context.mounted) {
          await _processBellCommand(actionCode, context);
        }

        // Update tracking
        _lastSentData = actionCode;
        _lastSentTime = DateTime.now();

        
        return true;
      } else {
        
        if (context.mounted) {
          _showErrorNotification(context, 'Failed to send command to ESP32');
        }
        return false;
      }
    } catch (e) {
      
      if (context.mounted) {
        _showErrorNotification(context, 'Failed to send command to ESP32');
      }
      return false;
    }
  }

  /// Handler untuk System Reset
  Future<bool> handleSystemReset({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      context,
      'SYSTEM RESET',
      'Are you sure you want to reset the entire fire alarm system?',
      'RESET',
    );

    if (!confirmed) return false;

    // Send to Firebase
    // ignore: use_build_context_synchronously
    final success = await sendButtonAction(systemResetCode, context: context);
    
    if (success && context.mounted) {
      // Update local state - ONLY LOG THE RESET, DON'TE CHANGE STATUSES
      final String? currentUser = await _authService.getCurrentUsername();

      fireAlarmData.isResetting = true;
      
      // ONLY update activity log - DON'TE RESET SYSTEM STATUSES
      // Let system naturally update the system status based on actual hardware conditions
      fireAlarmData.updateRecentActivity('SYSTEM RESET', user: currentUser ?? 'Unknown');
      
      // Send notification for the reset action
      fireAlarmData.sendNotification();

      // Clear Firebase data to ensure clean state and wait for latest system data
      await _clearFirebaseDataForReset();
      
      // Clear resetting flag after delay to allow UI updates
      Future.delayed(const Duration(seconds: 3), () {
        if (fireAlarmData.isResetting) {
          fireAlarmData.isResetting = false;
          
        }
      });
    }

    return success;
  }

  /// Clear Firebase data paths to ensure clean state after reset (Path C Only)
  Future<void> _clearFirebaseDataForReset() async {
    try {
      

      // 🔥 KEEP: User input path (needed for button actions)
      await _databaseRef.child('system_status/user_input/data').remove();
      

      // 🔥 KEEP: Recent activity (needed for system logs)
      await _databaseRef.child('recentActivity').remove();
      

      // 🔥 REMOVED: system_status/data, system_status/parsed_packet (Path A & B - OBSOLETE)
      // Data now comes from Path C (all_slave_data/raw_data) only

      // 🔥 REMOVED: systemStatus path (OBSOLETE)
      // System status flows from Path C → Zone Parser → LED Decoder → UI

      // 🔥 REMOVED: zoneStatus, moduleBellTrouble (legacy paths)
      // Zone data now comes from Path C parsing

      

    } catch (e) {
      
      // Continue even if clearing fails - the reset should still work
    }
  }

  /// Handler untuk Drill (toggle)
  Future<bool> handleDrill({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      context,
      'DRILL MODE',
      'Are you sure you want to activate drill mode?',
      'ACTIVATE',
    );

    if (!confirmed) return false;

    // Send to Firebase
    // ignore: use_build_context_synchronously
    final success = await sendButtonAction(drillCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      final currentStatus = fireAlarmData.getSystemStatus('Drill');
      final newStatus = !currentStatus;

      // 🔥 REMOVED: updateSystemStatus call (OBSOLETE method)
      // Drill status is now managed through Simple Status Manager and Firebase response
      fireAlarmData.updateRecentActivity('DRILL : ${newStatus ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Handler untuk Acknowledge (toggle)
  Future<bool> handleAcknowledge({required BuildContext context, bool? currentState}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Send to Firebase
    final success = await sendButtonAction(acknowledgeCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      // Determine new state
      bool newState;
      if (currentState != null) {
        newState = !currentState;
      } else {
        // Fallback: check from FireAlarmData
        newState = !fireAlarmData.getSystemStatus('Silenced'); // Using Silenced as fallback
      }

      fireAlarmData.updateRecentActivity('ACKNOWLEDGE : ${newState ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Handler untuk Silence (toggle)
  Future<bool> handleSilence({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Send to Firebase
    final success = await sendButtonAction(silenceCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      final currentStatus = fireAlarmData.getSystemStatus('Silenced');
      final newStatus = !currentStatus;

      // 🔥 REMOVED: updateSystemStatus call (OBSOLETE method)
      // Silenced status is now managed through Simple Status Manager and Firebase response
      fireAlarmData.updateRecentActivity('SILENCED : ${newStatus ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Mendapatkan nama action dari code
  String _getActionName(String actionCode) {
    switch (actionCode) {
      case drillCode:
        return 'DRILL';
      case systemResetCode:
        return 'SYSTEM_RESET';
      case acknowledgeCode:
        return 'ACKNOWLEDGE';
      case silenceCode:
        return 'SILENCE';
      default:
        return 'UNKNOWN';
    }
  }

  /// Menampilkan dialog konfirmasi
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String action,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Menampilkan notifikasi disconnected
  void _showDisconnectedNotification(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not connected',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Menampilkan notifikasi ESP32 disconnected
  void _showESPDisconnectedNotification(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ESP32 not connected - Check WebSocket connection',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Menampilkan notifikasi error
  void _showErrorNotification(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show success notification
  void _showSuccessNotification(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// 🔔 Process bell-related commands with Bell Manager integration
  Future<void> _processBellCommand(String actionCode, BuildContext context) async {
    try {
      // Check if BellManager is available
      if (!getIt.isRegistered<BellManager>()) {
        
        return;
      }

      final bellManager = getIt<BellManager>();

      switch (actionCode) {
        case silenceCode:
          // Handle silence command - toggle system mute
          
          await bellManager.toggleSystemMute();

          if (context.mounted) {
            final isMuted = bellManager.isSystemMuted;
            _showSuccessNotification(
              context,
              isMuted ? '🔇 System bell muted' : '🔔 System bell unmuted'
            );
          }
          break;

        case systemResetCode:
          // Handle system reset - reset bell manager state
          
          // Bell manager will automatically reset its state through normal processing
          break;

        case acknowledgeCode:
        case drillCode:
          // These commands don't directly affect bell state
          
          break;

        default:
          
      }
    } catch (e) {
      
    }
  }

  /// Reset tracking data (untuk testing purposes)
  void resetTracking() {
    _lastSentData = null;
    _lastSentTime = null;
  }
}
