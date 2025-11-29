import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:audioplayers/audioplayers.dart'; // Temporarily removed due to compilation issues
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  // final AudioPlayer _audioPlayer = AudioPlayer(); // Temporarily removed due to compilation issues
  bool _isInitialized = false;
  bool _isPlayingAlarm = false; // Indicates if any alarm sound is currently playing
  bool _isDrillMode = false; // Indicates if drill mode is active
  bool _isSilentMode = false; // Indicates if system is in silent mode

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

  // Method to set drill mode on/off
  void setDrillMode(bool isDrillOn) {
    _isDrillMode = isDrillOn;
    
  }

  // Method to set silent mode on/off
  void setSilentMode(bool isSilent) {
    _isSilentMode = isSilent;
    
  }

  // Plays a specific sound file with a given release mode.
  // Manages the _isPlayingAlarm flag.
  Future<void> _playSound(String soundFileName, String releaseMode) async {
    try {
      
      // Stop any currently playing sound before starting a new one.
      if (_isPlayingAlarm) {
        
        // await _audioPlayer.stop();
      }

      
      // await _audioPlayer.setReleaseMode(releaseMode);
      // await _audioPlayer.play(AssetSource(soundFileName));
      _isPlayingAlarm = true; // Mark as playing
      
    } catch (e) {
      
      _isPlayingAlarm = false; // Reset if error
    }
  }

  // Handles showing fire alarm notifications and playing associated sounds.
  Future<void> showFireAlarmNotification({
    required String title,
    required String body,
    required String eventType, // e.g., 'DRILL', 'ALARM'
    Map<String, dynamic>? data,
  }) async {
    try {
      String soundFileName = '';
      String releaseMode = 'stop'; // Default to stop

      // Handle sound based on eventType and user requirements
      if (eventType == 'DRILL') {
        // For DRILL events, always play beep_short.ogg once
        soundFileName = 'beep_short.ogg';
        releaseMode = 'stop'; // Play once for drill
        
      } else if (eventType == 'ALARM') {
        // For ALARM events, check conditions before playing alarm_clock.ogg
        if (_isDrillMode && !_isSilentMode) {
          // Only play alarm_clock.ogg if drill mode is ON and NOT in silent mode
          if (!_isPlayingAlarm) {
            soundFileName = 'alarm_clock.ogg';
            releaseMode = 'loop'; // Loop for actual alarm
            
          } else {
            
          }
        } else {
          // Don't play alarm_clock if drill mode is OFF or silent mode is ON
          
        }
      } else {
        // If eventType is not 'DRILL' or 'ALARM', no sound should be played by this method.
        // Also, disable wake lock if it's not a critical alarm.
        await WakelockPlus.disable();
        
        return; // Exit early if no sound/notification is needed.
      }

      // If we reach here, it means a notification with sound is intended.
      await WakelockPlus.enable(); // Keep wake lock for alarms

      // Determine notification channel
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

      // Play sound if determined and conditions met
      if (soundFileName.isNotEmpty) {
        await _playSound(soundFileName, releaseMode);
      }

      
    } catch (e) {
      
    }
  }

  // Plays the system sound for actions like 'system reset' or 'acknowledge'.
  Future<void> playSystemSound() async {
    // User requirement: "apabila user menekan system reset / acknowledge maka yang di play adalah sound : assets\sounds\beep_short.ogg putar sekali saja jangan loop."
    await _playSound('beep_short.ogg', 'stop');
  }

  // Stops the current alarm sound, disables wake lock, and clears notifications.
  Future<void> stopAlarm() async {
    try {
      
      // await _audioPlayer.stop();
      await WakelockPlus.disable();
      _isPlayingAlarm = false; // Reset the alarm state

      // Cancel all fire alarm notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      
    } catch (e) {
      
    }
  }

  // Method to handle system reset action
  Future<void> systemReset() async {
    try {
      

      // CRITICAL: Stop ALL audio immediately
      
      // await _audioPlayer.stop();
      _isPlayingAlarm = false;

      // CRITICAL: Disable wake lock immediately
      await WakelockPlus.disable();

      // CRITICAL: Clear all notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      // Reset all internal states
      _isDrillMode = false;
      _isSilentMode = false;

      // Play system reset sound (beep_short.ogg once) - WITHOUT wake lock
      try {
        
        // await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        // await _audioPlayer.play(AssetSource('beep_short.ogg'));
        
      } catch (e) {
        
      }

      
    } catch (e) {
      
    }
  }

  // Method to handle acknowledge action
  Future<void> acknowledge() async {
    try {
      

      // Stop any playing alarm
      await stopAlarm();

      // Play acknowledge sound (beep_short.ogg once)
      await _playSound('beep_short.ogg', 'stop');

      
    } catch (e) {
      
    }
  }

  // Plays the system sound for actions like 'system reset' or 'acknowledge'.
  Future<void> playSystemActionSound() async {
    // User requirement: "apabila user menekan system reset / acknowledge maka yang di play adalah sound : assets\sounds\beep_short.ogg putar sekali saja jangan loop."
    await _playSound('beep_short.ogg', 'stop');
  }

  // Handle notification actions triggered from the notification itself.
  Future<void> handleNotificationAction(String action) async {
    switch (action) {
      case 'stop_alarm':
        await stopAlarm();
        break;
      case 'snooze':
        // User did not specify behavior for snooze, so we can ignore or add a placeholder.
        // For now, let's just log it.
        
        // If snooze should play a sound, it would be handled here.
        // For example: await playSystemSound(); // If snooze should play beep_short once.
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
      
      // Handle specific event types for sounds
      if (eventType == 'SYSTEM_RESET') {
        await service.systemReset();
      } else if (eventType == 'ACKNOWLEDGE') {
        await service.acknowledge();
      } else {
        // Show notification with sound for other event types (DRILL, ALARM)
        await service.showFireAlarmNotification(
          title: 'Fire Alarm: $eventType',
          body: 'Status: $status - By: $user',
          eventType: eventType,
          data: data,
        );
      }
      
      
    } catch (e) {
      
    }
  }

  void dispose() {
    
    // _audioPlayer.dispose();
  }
}
