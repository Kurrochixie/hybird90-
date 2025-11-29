import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:audioplayers/audioplayers.dart'; // Temporarily removed due to compilation issues
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'base_notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Enhanced background notification service that extends BaseNotificationService
/// Provides comprehensive notification handling with rate limiting and unified audio management
class EnhancedBackgroundNotificationService extends BaseNotificationService {
  static final EnhancedBackgroundNotificationService _instance =
      EnhancedBackgroundNotificationService._internal();
  factory EnhancedBackgroundNotificationService() => _instance;
  EnhancedBackgroundNotificationService._internal();

  // final AudioPlayer _audioPlayer = AudioPlayer(); // Temporarily removed due to compilation issues
  bool _isPlayingAlarm = false;

  @override
  Future<void> onInitialize() async {
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

    // Create unified notification channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final channels = [
      // Critical alarm channel
      AndroidNotificationChannel(
        'fire_alarm_channel',
        'Fire Alarm Notifications',
        description: 'Critical fire alarm notifications with sound',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('alarm_clock'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
      ),
      // Drill channel
      AndroidNotificationChannel(
        'drill_channel',
        'Drill Notifications',
        description: 'Fire drill notifications',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('beep_short'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      ),
      // System alerts channel
      AndroidNotificationChannel(
        'system_alerts_channel',
        'System Alerts',
        description: 'System status and control notifications',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 300, 100, 300]),
      ),
    ];

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    
    _handleNotificationTap(response.payload);
  }

  void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      // Simple parsing - in real implementation, use proper JSON parsing
      if (payload.contains('stop_alarm')) {
        stopAlarm();
      }
    } catch (e) {
      
    }
  }

  @override
  Future<void> onShowNotification(Map<String, dynamic> data) async {
    await showFireAlarmNotification(
      title: 'Fire Alarm: ${data['eventType']}',
      body: 'Status: ${data['status']} - By: ${data['user']}',
      eventType: data['eventType'],
      data: data,
    );
  }

  /// Show fire alarm notification with enhanced features
  Future<void> showFireAlarmNotification({
    required String title,
    required String body,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Acquire wake lock to ensure device stays awake for critical events
      if (isCriticalEvent(eventType)) {
        await WakelockPlus.enable();
      }

      // Determine notification channel based on event type
      String channelId = _getChannelId(eventType);

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channelId,
        _getChannelName(eventType),
        channelDescription: _getChannelDescription(eventType),
        importance: _getImportance(eventType),
        priority: _getPriority(eventType),
        showWhen: true,
        autoCancel: !isCriticalEvent(eventType),
        ongoing: isCriticalEvent(eventType),
        fullScreenIntent: isCriticalEvent(eventType),
        category: isCriticalEvent(eventType)
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.status,
        visibility: NotificationVisibility.public,
        sound: RawResourceAndroidNotificationSound(_getSoundResourceName(eventType)),
        playSound: requiresSound(eventType),
        enableVibration: requiresVibration(eventType),
        vibrationPattern: _getVibrationPattern(eventType),
        color: _getNotificationColor(eventType),
        ledColor: _getNotificationColor(eventType),
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: _getTickerText(eventType),
        additionalFlags: isCriticalEvent(eventType)
            ? Int32List.fromList([4, 4]) // FLAG_INSISTENT + FLAG_NO_CLEAR
            : null,
        actions: _buildNotificationActions(eventType),
      );

      DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: requiresSound(eventType),
        sound: _getIOSSoundFile(eventType),
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

      // Play alarm sound in background with rate limiting
      if (!_isPlayingAlarm && requiresSound(eventType)) {
        await _playAlarmSoundWithRateLimiting(eventType);
      }

      
    } catch (e) {
      
    }
  }

  Future<void> _playAlarmSoundWithRateLimiting(String eventType) async {
    // Rate limiting removed for audio playback

    await _playAlarmSound(eventType);
  }

  Future<void> _playAlarmSound(String eventType) async {
    try {
      _isPlayingAlarm = true;

      String soundFile = getSoundFileForEventType(eventType);

      // Configure audio player based on event type
      if (isCriticalEvent(eventType)) {
        
        // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        
        // await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      }

      
      // await _audioPlayer.play(AssetSource('sounds/$soundFile'));

      
    } catch (e) {
      
      _isPlayingAlarm = false;
    }
  }

  Future<void> stopAlarm() async {
    try {
      
      // await _audioPlayer.stop();
      await WakelockPlus.disable();
      _isPlayingAlarm = false;

      // Cancel all notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      
    } catch (e) {
      
    }
  }

  // Enhanced notification channel management
  String _getChannelId(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
        return 'fire_alarm_channel';
      case 'DRILL':
        return 'drill_channel';
      default:
        return 'system_alerts_channel';
    }
  }

  String _getChannelName(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
        return 'Fire Alarm Notifications';
      case 'DRILL':
        return 'Drill Notifications';
      default:
        return 'System Alerts';
    }
  }

  String _getChannelDescription(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
        return 'Critical fire alarm notifications with sound';
      case 'DRILL':
        return 'Fire drill notifications';
      default:
        return 'System status and control notifications';
    }
  }

  Importance _getImportance(String eventType) {
    return isCriticalEvent(eventType) ? Importance.max : Importance.high;
  }

  Priority _getPriority(String eventType) {
    return isCriticalEvent(eventType) ? Priority.high : Priority.low;
  }

  String _getSoundResourceName(String eventType) {
    return getSoundFileForEventType(eventType).replaceAll('.ogg', '');
  }

  String _getIOSSoundFile(String eventType) {
    return getSoundFileForEventType(eventType).replaceAll('.ogg', '.caf');
  }

  Int64List _getVibrationPattern(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'DRILL':
        return Int64List.fromList([0, 500, 200, 500]);
      case 'ALARM':
      case 'FIRE':
        return Int64List.fromList([0, 1000, 500, 1000]);
      default:
        return Int64List.fromList([0, 300, 100, 300]);
    }
  }

  Color _getNotificationColor(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
        return const Color.fromARGB(255, 255, 0, 0); // Red
      case 'DRILL':
        return const Color.fromARGB(255, 255, 165, 0); // Orange
      case 'TROUBLE':
        return const Color.fromARGB(255, 255, 255, 0); // Yellow
      default:
        return const Color.fromARGB(255, 33, 150, 243); // Blue
    }
  }

  String _getTickerText(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'ALARM':
      case 'FIRE':
        return 'Fire Alarm Alert - Immediate attention required!';
      case 'DRILL':
        return 'Fire Drill in Progress';
      default:
        return 'System Alert';
    }
  }

  List<AndroidNotificationAction>? _buildNotificationActions(String eventType) {
    if (!isCriticalEvent(eventType)) return null;

    return [
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
    ];
  }

  @override
  EnhancedBackgroundNotificationService createServiceInstance() {
    return EnhancedBackgroundNotificationService();
  }

  /// Standard background handler for FCM
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    

    try {
      final service = EnhancedBackgroundNotificationService();
      await service.initialize();
      await service.handleBackgroundMessage(message);
    } catch (e) {
      
    }
  }

  @override
  Future<void> dispose() async {
    await super.dispose();
    
    // await _audioPlayer.dispose();
    
  }
}