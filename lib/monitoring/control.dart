import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:provider/provider.dart';
import '../core/fire_alarm_data.dart';
import '../services/local_audio_manager.dart';
import '../services/enhanced_notification_service.dart';
// REMOVED: Unused imports - background_notification_service, button_action_service
// import '../services/background_notification_service.dart' as bg_notification;
// import '../services/button_action_service.dart';
import '../services/bell_manager.dart';
import '../di/service_locator.dart';
import '../widgets/unified_status_bar.dart';

class ControlPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final String? username;
  const ControlPage({super.key, this.scaffoldKey, this.username});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // State untuk tracking button yang sedang ditekan
  final bool _isAcknowledgeActive = false;

  // State untuk outline flashing saat drill

  // Local Audio Manager untuk independen audio control
  final LocalAudioManager _audioManager = LocalAudioManager();
  
  // Enhanced Notification Service
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();
  
  // Track previous button status to detect changes
  // bool _previousDrillStatus = false;
  // bool _previousAlarmStatus = false;
  // bool _previousTroubleStatus = false;
  // bool _previousSilencedStatus = false;

  // Stream subscription untuk audio status updates
  StreamSubscription<Map<String, bool>>? _audioStatusSubscription;

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

  // OLD _handleSystemReset method removed - replaced with No Authority dialog

  // OLD _handleDrill and _handleAcknowledge methods removed - replaced with No Authority dialog

  // 🔥 NEW: Show "You have No Authority" dialog for 2 seconds
  void _showNoAuthorityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block,
                  color: Colors.white,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  'You have No Authority',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // Auto-close after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  // Handler untuk System Reset - Disabled with No Authority Dialog
  void _handleSystemReset() async {
    
    _showNoAuthorityDialog();
  }

  // Handler untuk Silence - Disabled with No Authority Dialog
  void _handleSilence() async {
    
    _showNoAuthorityDialog();
  }

  // Handler untuk Drill - Disabled with No Authority Dialog
  void _handleDrill() async {
    
    _showNoAuthorityDialog();
  }

  // Handler untuk Acknowledge - Disabled with No Authority Dialog
  void _handleAcknowledge() async {
    
    _showNoAuthorityDialog();
  }

  // Handler untuk Mute Notification (Local)
  void _handleMuteNotification() async {
    await _audioManager.toggleNotificationMute();
    await _notificationService.updateNotificationMuteStatus(_audioManager.isNotificationMuted);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notifications ${_audioManager.isNotificationMuted ? 'muted' : 'unmuted'} (Local)',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _audioManager.isNotificationMuted ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handler untuk Mute Sound (Local)
  void _handleMuteSound() async {
    await _audioManager.toggleSoundMute();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sound ${_audioManager.isSoundMuted ? 'muted' : 'unmuted'} (Local)',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: _audioManager.isSoundMuted ? Colors.orange : Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Handler untuk Mute Bell (Enhanced with Bell Manager)
  void _handleMuteBell() async {
    try {
      // Get Bell Manager from dependency injection
      final bellManager = getIt<BellManager>();

      // Toggle system-wide bell mute
      final success = await bellManager.toggleSystemMute();

      if (mounted && success) {
        final isMuted = bellManager.isSystemMuted;

        // Also update local audio manager for consistency
        await _audioManager.toggleBellMute();

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🔔 System bells ${isMuted ? 'muted' : 'unmuted'}',
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: isMuted ? Colors.orange : Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Details',
                textColor: Colors.white,
                onPressed: () {
                  _showBellDetails(bellManager);
                },
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '❌ Failed to toggle bell mute',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local audio manager only
      await _audioManager.toggleBellMute();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Bell ${_audioManager.isBellMuted ? 'muted' : 'unmuted'} (Local)',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: _audioManager.isBellMuted ? Colors.orange : Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // Show bell details dialog
  void _showBellDetails(BellManager bellManager) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.notifications, color: Colors.red),
            SizedBox(width: 8),
            Text('Bell System Status'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Status: ${bellManager.isSystemMuted ? "MUTED" : "ACTIVE"}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: bellManager.isSystemMuted ? Colors.orange : Colors.green,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Active Bells: ${bellManager.currentStatus.activeBells}/${bellManager.currentStatus.totalDevices}',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Last Activity: ${_formatTime(bellManager.currentStatus.lastBellActivity)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return '${difference.inHours} hours ago';
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize audio manager and notification service
    _initializeServices();
    
    // Listen to FireAlarmData changes to handle button status
    final fireAlarmData = context.read<FireAlarmData>();
    fireAlarmData.addListener(_onSystemStatusChanged);
    
    // Set initial button status
    // _previousDrillStatus = fireAlarmData.getSystemStatus('Drill');
    // _previousAlarmStatus = fireAlarmData.getSystemStatus('Alarm');
    // _previousTroubleStatus = fireAlarmData.getSystemStatus('Trouble');
    // _previousSilencedStatus = fireAlarmData.getSystemStatus('Silenced');
    
    // Listen to audio status updates
    _audioStatusSubscription = _audioManager.audioStatusStream.listen((audioStatus) {
      if (mounted) {
        setState(() {
          // Update UI based on audio status if needed
        });
      }
    });
  }

  // Initialize services
  Future<void> _initializeServices() async {
    try {
      await _audioManager.initialize();
      await _notificationService.initialize();
      print('Audio and notification services initialized successfully');
    } catch (e) {
      // Service initialization failed - will use defaults
      print('Warning: Failed to initialize audio/notification services: $e');
      print('Will continue with default settings');
    }
  }

  // Listener for system status changes to sync with audio
  void _onSystemStatusChanged() {
    final fireAlarmData = context.read<FireAlarmData>();
    
    final currentDrillStatus = fireAlarmData.getSystemStatus('Drill');
    final currentAlarmStatus = fireAlarmData.getSystemStatus('Alarm');
    final currentTroubleStatus = fireAlarmData.getSystemStatus('Trouble');
    final currentSilencedStatus = fireAlarmData.getSystemStatus('Silenced');

    // Update audio manager with new button statuses
    _audioManager.updateAudioStatusFromButtons(
      isDrillActive: currentDrillStatus,
      isAlarmActive: currentAlarmStatus,
      isTroubleActive: currentTroubleStatus,
      isSilencedActive: currentSilencedStatus,
    );

    // Update previous status trackers
    // _previousDrillStatus = currentDrillStatus;
    // _previousAlarmStatus = currentAlarmStatus;
    // _previousTroubleStatus = currentTroubleStatus;
    // _previousSilencedStatus = currentSilencedStatus;
  }

  @override
  void dispose() {
    // Cancel subscriptions
    _audioStatusSubscription?.cancel();
    
    // Remove listener
    final fireAlarmData = context.read<FireAlarmData>();
    fireAlarmData.removeListener(_onSystemStatusChanged);
    
    // Dispose services
    _audioManager.dispose();
    _notificationService.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Hitung ukuran font dasar berdasarkan layar
    final baseFontSize = _calculateFontSize(context);
    // Removed unused variable 'isDesktop'
    // final isDesktop = _isDesktop(context);

    // Menggunakan data dari FireAlarmData melalui Provider
    final fireAlarmData = context.watch<FireAlarmData>();

    // Sync button states with Firebase data
    final isDrillActive = fireAlarmData.getSystemStatus('Drill');
    final isSilenceActive = fireAlarmData.getSystemStatus('Silenced');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Unified Status Bar - Synchronized across all pages
              FullStatusBar(scaffoldKey: widget.scaffoldKey),

              // Control Buttons
              Container(
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                color: Colors.white,
                child: Column(
                  children: [
                    // Mute Buttons Section (Local Control)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Mute Notification Button
                              Expanded(
                                child: _buildMuteButton(
                                  context,
                                  'MUTE NOTIF',
                                  'Notifications',
                                  _audioManager.isNotificationMuted,
                                  _handleMuteNotification,
                                  Colors.red,
                                  Icons.notifications_off,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Mute Sound Button
                              Expanded(
                                child: _buildMuteButton(
                                  context,
                                  'MUTE SOUND',
                                  'Sound Notifications',
                                  _audioManager.isSoundMuted,
                                  _handleMuteSound,
                                  Colors.red,
                                  Icons.volume_off,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Enhanced Mute Bell Button
                              Expanded(
                                child: _buildMuteButton(
                                  context,
                                  'MUTE BELL',
                                  _audioManager.isBellMuted ? 'Bells Muted' : 'Tap to Mute',
                                  _audioManager.isBellMuted,
                                  _handleMuteBell,
                                  _audioManager.isBellMuted ? Colors.orange : Colors.red,
                                  _audioManager.isBellMuted ? Icons.notifications_off : Icons.notifications,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // System Reset Button - Special handling for green color during reset
                    _buildSystemResetButton(context),
                    const SizedBox(height: 10),
                    // Drill Button - Red when active
                    _buildControlButton(
                      context,
                      'DRILL',
                      'DRILL',
                      isDrillActive ? Colors.red : Colors.blue,
                      isDrillActive,
                      _handleDrill,
                    ),

                    const SizedBox(height: 10),
                    // Acknowledge Button - Orange when active
                    _buildControlButton(
                      context,
                      'ACKNOWLEDGE',
                      'ACK',
                      _isAcknowledgeActive ? Colors.orange : Colors.grey,
                      _isAcknowledgeActive,
                      _handleAcknowledge,
                    ),
                    const SizedBox(height: 10),
                    // Silence Button - Yellow when active
                    _buildControlButton(
                      context,
                      'SILENCE',
                      'SILENCE',
                      isSilenceActive ? Colors.yellow[700]! : Colors.grey,
                      isSilenceActive,
                      _handleSilence,
                    ),
                  ],
                ),
              ),

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

  // Widget untuk System Reset button dengan logika khusus
  Widget _buildSystemResetButton(BuildContext context) {
    final baseFontSize = _calculateFontSize(context);
    final fireAlarmData = context.watch<FireAlarmData>();
    final isResetting = fireAlarmData.isResetting;
    final buttonColor = isResetting ? Colors.green : Colors.red;
    final alpha15 = 0.15;
    final alpha40 = 0.4;

    return SizedBox(
      height: 120, // fixed height for all buttons
      width: double.infinity,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isResetting
              ? buttonColor.withValues(alpha: alpha15)
              : Colors.white,
          border: Border.all(
            color: isResetting ? buttonColor : Colors.grey[400]!,
            width: isResetting ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isResetting
              ? [
                  BoxShadow(
                    color: buttonColor.withValues(alpha: alpha40),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),

        child: InkWell(
          onTap: _handleSystemReset,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'SYSTEM RESET',
                style: TextStyle(
                  fontSize: baseFontSize * 1.8,
                  fontWeight: FontWeight.bold,
                  color: isResetting ? buttonColor : Colors.black87,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isResetting ? 'RESETTING...' : 'SYSTEM RESET',
                style: TextStyle(
                  fontSize: baseFontSize * 0.9,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              if (isResetting)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '● RESETTING',
                    style: TextStyle(
                      fontSize: baseFontSize * 0.8,
                      fontWeight: FontWeight.bold,
                      color: buttonColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget untuk control button
  Widget _buildControlButton(
    BuildContext context,
    String label,
    String subtitle,
    Color color,
    bool isActive,
    VoidCallback onPressed,
  ) {
    final baseFontSize = _calculateFontSize(context);
    final alpha15 = 0.15;
    final alpha40 = 0.4;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 100, maxHeight: 140),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: alpha15) : Colors.white,
          border: Border.all(
            color: isActive ? color : Colors.grey[400]!,
            width: isActive ? 2.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: alpha40),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 0,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),

        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: baseFontSize * 1.8,
                  fontWeight: FontWeight.bold,
                  color: isActive ? color : Colors.black87,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: baseFontSize * 0.9,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              if (isActive && label != 'SYSTEM RESET')
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '● ACTIVE',
                    style: TextStyle(
                      fontSize: baseFontSize * 0.8,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: 1,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  // Widget untuk mute button (local control) - dengan icon
  Widget _buildMuteButton(
    BuildContext context,
    String label,
    String subtitle,
    bool isActive,
    VoidCallback onPressed,
    Color color,
    IconData icon,
  ) {
    final baseFontSize = _calculateFontSize(context);
    final alpha15 = 0.15;
    final alpha40 = 0.4;

    return Container(
      constraints: const BoxConstraints(minHeight: 60, maxHeight: 70),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withValues(alpha: alpha15) : Colors.white,
          border: Border.all(
            color: isActive ? color : Colors.grey[400]!,
            width: isActive ? 2.0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: alpha40),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    spreadRadius: 0,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),

        child: InkWell(
          onTap: onPressed,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? color : Colors.grey[600],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: baseFontSize * 0.6,
                  color: isActive ? color : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
