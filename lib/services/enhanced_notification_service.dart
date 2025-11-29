import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'local_audio_manager.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class EnhancedNotificationService {
  static final EnhancedNotificationService _instance = EnhancedNotificationService._internal();
  factory EnhancedNotificationService() => _instance;
  EnhancedNotificationService._internal();

  bool _isInitialized = false;
  bool _isNotificationMuted = false;
  Timer? _debounceTimer;
  String? _lastNotificationId;
  DateTime? _lastNotificationTime;
  
  // Notification queue untuk mencegah stacking
  final List<_NotificationRequest> _notificationQueue = [];
  bool _isProcessingQueue = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load local notification settings
      await _loadLocalSettings();
      
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels
      await _createNotificationChannels();

      _isInitialized = true;
      
    } catch (e) {
      
    }
  }

  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationMuted = prefs.getBool('notification_muted') ?? false;
      
    } catch (e) {
      
    }
  }

  Future<void> _createNotificationChannels() async {
    // Critical Alarm Channel
    final AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'critical_alarm_channel',
      'Critical Fire Alarm',
      description: 'Critical fire alarm notifications with maximum priority',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_clock'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    // Drill Channel
    final AndroidNotificationChannel drillChannel = AndroidNotificationChannel(
      'drill_channel',
      'Fire Drill',
      description: 'Fire drill notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep_short'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    // Status Update Channel (no sound)
    final AndroidNotificationChannel statusChannel = AndroidNotificationChannel(
      'status_update_channel',
      'Status Updates',
      description: 'System status updates (silent)',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    await androidPlugin?.createNotificationChannel(alarmChannel);
    await androidPlugin?.createNotificationChannel(drillChannel);
    await androidPlugin?.createNotificationChannel(statusChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    
    // Handle notification tap if needed
  }

  // Enhanced notification method with debouncing and deduplication
  Future<void> showNotification({
    required String title,
    required String body,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Check if notifications are muted
      if (_isNotificationMuted) {
        
        return;
      }

      // Create notification ID based on event type and data
      final notificationId = _generateNotificationId(eventType, data);
      
      // Debounce rapid notifications (prevent stacking)
      if (_shouldDebounceNotification(notificationId)) {
        
        return;
      }

      // Add to queue for processing
      final request = _NotificationRequest(
        id: notificationId,
        title: title,
        body: body,
        eventType: eventType,
        data: data,
        timestamp: DateTime.now(),
      );

      _notificationQueue.add(request);
      
      // Process queue if not already processing
      if (!_isProcessingQueue) {
        _processNotificationQueue();
      }

    } catch (e) {
      
    }
  }

  String _generateNotificationId(String eventType, Map<String, dynamic>? data) {
    // Generate consistent ID based on event type and key data
    final buffer = StringBuffer();
    buffer.write(eventType);
    
    if (data != null) {
      // Add relevant data to make ID unique but consistent
      if (data.containsKey('status')) buffer.write('_${data['status']}');
      if (data.containsKey('user')) buffer.write('_${data['user']}');
    }
    
    return buffer.toString();
  }

  bool _shouldDebounceNotification(String notificationId) {
    final now = DateTime.now();
    
    // Check if same notification was sent recently
    if (_lastNotificationId == notificationId && _lastNotificationTime != null) {
      final timeDiff = now.difference(_lastNotificationTime!);
      if (timeDiff.inSeconds < 2) { // Debounce within 2 seconds
        return true;
      }
    }
    
    return false;
  }

  Future<void> _processNotificationQueue() async {
    if (_isProcessingQueue || _notificationQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    while (_notificationQueue.isNotEmpty) {
      final request = _notificationQueue.removeAt(0);
      
      try {
        await _showSingleNotification(request);
        
        // Update tracking
        _lastNotificationId = request.id;
        _lastNotificationTime = request.timestamp;
        
        // Small delay between notifications to prevent overwhelming
        await Future.delayed(const Duration(milliseconds: 100));
        
      } catch (e) {
        
      }
    }
    
    _isProcessingQueue = false;
  }

  Future<void> _showSingleNotification(_NotificationRequest request) async {
    try {
      // Determine channel based on event type
      String channelId;
      AndroidNotificationDetails androidDetails;
      
      switch (request.eventType) {
        case 'ALARM':
        case 'TROUBLE':
          channelId = 'critical_alarm_channel';
          androidDetails = _buildCriticalNotificationDetails(channelId, request.eventType);
          break;
        case 'DRILL':
          channelId = 'drill_channel';
          androidDetails = _buildDrillNotificationDetails(channelId);
          break;
        case 'SYSTEM RESET':
        case 'ACKNOWLEDGE':
        case 'SILENCE':
          channelId = 'status_update_channel';
          androidDetails = _buildStatusNotificationDetails(channelId);
          break;
        default:
          channelId = 'status_update_channel';
          androidDetails = _buildInfoNotificationDetails(channelId);
          break;
      }

      DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: (request.eventType == 'ALARM' || request.eventType == 'TROUBLE' || request.eventType == 'DRILL'),
        sound: _getIOSSound(request.eventType),
        badgeNumber: 1,
      );

      NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      // Acquire wake lock ONLY for DRILL events (per user requirement)
      if (request.eventType == 'DRILL') {
        await WakelockPlus.enable();
      } else {
        // Ensure wake lock is disabled for non-drill events
        await WakelockPlus.disable();
      }

      await flutterLocalNotificationsPlugin.show(
        request.timestamp.millisecondsSinceEpoch.remainder(100000),
        request.title,
        request.body,
        platformDetails,
        payload: request.data?.toString(),
      );

      
      
    } catch (e) {
      
    }
  }

  AndroidNotificationDetails _buildCriticalNotificationDetails(String channelId, String eventType) {
    return AndroidNotificationDetails(
      channelId,
      'Critical Fire Alarm',
      channelDescription: 'Critical fire alarm notifications',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      autoCancel: false,
      ongoing: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('alarm_clock'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      color: const Color.fromARGB(255, 255, 0, 0),
      ledColor: const Color.fromARGB(255, 255, 0, 0),
      ledOnMs: 1000,
      ledOffMs: 500,
      ticker: 'Fire Alarm Alert - Immediate attention required!',
      additionalFlags: Int32List.fromList([4, 4]), // FLAG_INSISTENT + FLAG_NO_CLEAR
      actions: [
        AndroidNotificationAction('stop_alarm', 'Stop Alarm', showsUserInterface: true),
        AndroidNotificationAction('snooze', 'Snooze 5min', showsUserInterface: true),
      ],
    );
  }

  AndroidNotificationDetails _buildDrillNotificationDetails(String channelId) {
    return AndroidNotificationDetails(
      channelId,
      'Fire Drill',
      channelDescription: 'Fire drill notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      autoCancel: true,
      ongoing: false,
      visibility: NotificationVisibility.public,
      sound: RawResourceAndroidNotificationSound('beep_short'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      color: Colors.orange,
    );
  }

  AndroidNotificationDetails _buildStatusNotificationDetails(String channelId) {
    return AndroidNotificationDetails(
      channelId,
      'Status Updates',
      channelDescription: 'System status updates',
      importance: Importance.low,
      priority: Priority.defaultPriority,
      showWhen: true,
      autoCancel: true,
      ongoing: false,
      playSound: false,
      enableVibration: false,
      color: Colors.blue,
    );
  }

  AndroidNotificationDetails _buildInfoNotificationDetails(String channelId) {
    return AndroidNotificationDetails(
      channelId,
      'Information',
      channelDescription: 'General information notifications',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      autoCancel: true,
      ongoing: false,
      playSound: false,
      enableVibration: false,
      color: Colors.grey,
    );
  }

  String? _getIOSSound(String eventType) {
    switch (eventType) {
      case 'ALARM':
      case 'TROUBLE':
        return 'alarm_clock.caf';
      case 'DRILL':
        return 'beep_short.caf';
      default:
        return null;
    }
  }

  // Method to clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      await WakelockPlus.disable();
      
    } catch (e) {
      
    }
  }

  // Method to update notification mute status
  Future<void> updateNotificationMuteStatus(bool isMuted) async {
    _isNotificationMuted = isMuted;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_muted', isMuted);
      
    } catch (e) {
      
    }
  }

  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    
    
    try {
      final service = EnhancedNotificationService();
      await service.initialize();
      
      // Initialize LocalAudioManager for background audio
      final audioManager = LocalAudioManager();
      await audioManager.initialize();
      
      final data = message.data;
      final eventType = data['eventType'] ?? 'UNKNOWN';
      final status = data['status'] ?? '';
      final user = data['user'] ?? 'System';
      
      // Handle audio based on event type
      if (eventType == 'DRILL') {
        final isDrillActive = status == 'ON';
        audioManager.updateAudioStatusFromButtons(
          isDrillActive: isDrillActive,
          isAlarmActive: false,
          isTroubleActive: false,
          isSilencedActive: false,
        );
      } else if (eventType == 'ALARM') {
        final isAlarmActive = status == 'ON';
        audioManager.updateAudioStatusFromButtons(
          isDrillActive: false,
          isAlarmActive: isAlarmActive,
          isTroubleActive: false,
          isSilencedActive: false,
        );
      } else if (eventType == 'TROUBLE') {
        final isTroubleActive = status == 'ON';
        audioManager.updateAudioStatusFromButtons(
          isDrillActive: false,
          isAlarmActive: false,
          isTroubleActive: isTroubleActive,
          isSilencedActive: false,
        );
      }
      
      await service.showNotification(
        title: 'Fire Alarm: $eventType',
        body: 'Status: $status - By: $user',
        eventType: eventType,
        data: data,
      );
      
      
      
    } catch (e) {
      
    }
  }

  void dispose() {
    _debounceTimer?.cancel();
    _notificationQueue.clear();
  }
}

// Helper class for notification requests
class _NotificationRequest {
  final String id;
  final String title;
  final String body;
  final String eventType;
  final Map<String, dynamic>? data;
  final DateTime timestamp;

  _NotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.eventType,
    this.data,
    required this.timestamp,
  });
}
