import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Just Audio removed - using LocalAudioManager instead to avoid conflicts
import 'local_audio_manager.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  // Using LocalAudioManager instead to avoid AudioPlayer conflicts
  final LocalAudioManager _audioManager = LocalAudioManager();
  bool _isInitialized = false;
  bool _isPlayingAlarm = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
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

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      
    } catch (e) {
      
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'fire_alarm_channel',
      'Fire Alarm Notifications',
      description: 'Critical fire alarm notifications with sound',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_clock'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    final AndroidNotificationChannel drillChannel = AndroidNotificationChannel(
      'drill_channel',
      'Drill Notifications',
      description: 'Fire drill notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep_short'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(drillChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    
    // Handle notification tap if needed
  }

  Future<void> showFireAlarmNotification({
    required String title,
    required String body,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Acquire wake lock to ensure device stays awake
      await WakelockPlus.enable();

      // Determine notification channel based on event type
      String channelId = eventType == 'DRILL' ? 'drill_channel' : 'fire_alarm_channel';

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channelId,
        eventType == 'DRILL' ? 'Drill Notifications' : 'Fire Alarm Notifications',
        channelDescription: eventType == 'DRILL' 
            ? 'Fire drill notifications' 
            : 'Critical fire alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        autoCancel: false,
        ongoing: eventType != 'DRILL', // Keep alarm notifications ongoing
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        sound: RawResourceAndroidNotificationSound(
            eventType == 'DRILL' ? 'beep_short' : 'alarm_clock'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
            eventType == 'DRILL' ? [0, 500, 200, 500] : [0, 1000, 500, 1000]),
        color: const Color.fromARGB(255, 255, 0, 0), // Red color for urgency
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: 'Fire Alarm Alert - Immediate attention required!',
        additionalFlags: eventType != 'DRILL' 
            ? Int32List.fromList([4, 4]) // FLAG_INSISTENT + FLAG_NO_CLEAR for critical alarms
            : null,
        actions: eventType != 'DRILL' ? [
          AndroidNotificationAction(
            'stop_alarm', 
            'Stop Alarm',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze', 
            'Snooze 5min',
            showsUserInterface: true,
          ),
        ] : null,
      );

      DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: eventType == 'DRILL' ? 'beep_short.caf' : 'alarm_clock.caf',
        badgeNumber: 1,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: data?.toString(),
      );

      // Play alarm sound in background
      if (!_isPlayingAlarm) {
        _playAlarmSound(eventType);
      }

      
    } catch (e) {
      
    }
  }

  Future<void> _playAlarmSound(String eventType) async {
    try {
      _isPlayingAlarm = true;

      
      // Audio playback is now handled by LocalAudioManager to avoid conflicts
      // This service only manages notifications

      // 🔧 FIXED: Remove force-reset of trouble status during alarm
      // Let the LocalAudioManager handle priority logic properly
      if (eventType == 'ALARM') {
        

        // Get current status to preserve existing states
        final currentStatus = _audioManager.getCurrentAudioStatus();

        _audioManager.updateAudioStatusFromButtons(
          isDrillActive: false,
          isAlarmActive: true,
          // 🔥 CRITICAL FIX: Preserve current trouble state instead of forcing false
          isTroubleActive: currentStatus['trouble'] ?? false,
          isSilencedActive: currentStatus['silenced'] ?? false,
        );
      }

    } catch (e) {
      
      _isPlayingAlarm = false;
    }
  }

  Future<void> stopAlarm() async {
    try {
      

      // Stop all sounds using LocalAudioManager
      _audioManager.stopAllAudioImmediately();

      await WakelockPlus.disable();
      _isPlayingAlarm = false;

      // Cancel all fire alarm notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      
    } catch (e) {
      
    }
  }

  // Handle notification actions
  Future<void> handleNotificationAction(String action) async {
    switch (action) {
      case 'stop_alarm':
        await stopAlarm();
        break;
      default:
        
    }
  }

  // Background message handler for FCM
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    
    
    try {
      // Initialize background service
      final service = BackgroundNotificationService();
      await service.initialize();
      
      // Extract message data
      final data = message.data;
      final eventType = data['eventType'] ?? 'UNKNOWN';
      final status = data['status'] ?? '';
      final user = data['user'] ?? 'System';
      
      // Show notification with sound
      await service.showFireAlarmNotification(
        title: 'Fire Alarm: $eventType',
        body: 'Status: $status - By: $user',
        eventType: eventType,
        data: data,
      );
      
      
    } catch (e) {
      
    }
  }

  void dispose() {
    // Audio disposal handled by LocalAudioManager singleton
  }
}
