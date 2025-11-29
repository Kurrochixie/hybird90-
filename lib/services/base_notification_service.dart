import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Base class for all notification services with common functionality
/// Provides data validation and standardized notification handling
abstract class BaseNotificationService {
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await onInitialize();
      _isInitialized = true;
      
    } catch (e) {
      
      rethrow;
    }
  }

  /// Override this method for service-specific initialization
  Future<void> onInitialize();

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Validate notification data before processing
  bool validateNotificationData(Map<String, dynamic> data) {
    final eventType = data['eventType'] as String?;
    final status = data['status'] as String?;
    final user = data['user'] as String?;

    if (eventType == null || eventType.isEmpty) {
      
      return false;
    }

    if (status == null || status.isEmpty) {
      
      return false;
    }

    if (user == null || user.isEmpty) {
      
      return false;
    }

    return true;
  }

  /// Create standardized notification data
  Map<String, dynamic> createNotificationData({
    required String eventType,
    required String status,
    required String user,
    String? projectName,
    String? panelType,
    Map<String, dynamic>? additionalData,
  }) {
    final data = <String, dynamic>{
      'eventType': eventType.toUpperCase(),
      'status': status.toUpperCase(),
      'user': user,
      'projectName': projectName ?? 'Unknown Project',
      'panelType': panelType ?? 'Unknown Panel',
      'timestamp': DateTime.now().toIso8601String(),
      'notificationId': _generateNotificationId(eventType, status),
    };

    if (additionalData != null) {
      data.addAll(additionalData);
    }

    return data;
  }

  /// Handle notification with rate limiting and validation
  Future<bool> handleNotification({
    required String eventType,
    required String status,
    required String user,
    String? projectName,
    String? panelType,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Create notification data
    final data = createNotificationData(
      eventType: eventType,
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
      additionalData: additionalData,
    );

    // Validate data
    if (!validateNotificationData(data)) {
      return false;
    }

    // Rate limiting removed for simplicity
    

    try {
      // Delegate to implementation
      await onShowNotification(data);
      
      return true;
    } catch (e) {
      
      return false;
    }
  }

  /// Override this method to implement notification display
  Future<void> onShowNotification(Map<String, dynamic> data);

  /// Handle background FCM message
  Future<void> handleBackgroundMessage(RemoteMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }

    

    try {
      final data = message.data;

      if (data.isEmpty) {
        
        return;
      }

      final eventType = data['eventType'] ?? 'UNKNOWN';
      final status = data['status'] ?? '';
      final user = data['user'] ?? 'System';

      // Rate limiting removed for background messages
      

      await handleNotification(
        eventType: eventType,
        status: status,
        user: user,
        projectName: data['projectName'],
        panelType: data['panelType'],
        additionalData: data,
      );
    } catch (e) {
      
    }
  }

  /// Handle foreground FCM message
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    if (!_isInitialized) {
      await initialize();
    }

    

    try {
      final data = message.data;

      if (data.isEmpty) {
        
        return;
      }

      final eventType = data['eventType'] ?? 'UNKNOWN';
      final status = data['status'] ?? '';
      final user = data['user'] ?? 'System';

      await handleNotification(
        eventType: eventType,
        status: status,
        user: user,
        projectName: data['projectName'],
        panelType: data['panelType'],
        additionalData: data,
      );
    } catch (e) {
      
    }
  }

  /// Generate unique notification ID
  String _generateNotificationId(String eventType, String status) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${eventType}_${status}_$timestamp';
  }

  /// Get sound file for event type
  String getSoundFileForEventType(String eventType) {
    switch (eventType.toUpperCase()) {
      case 'DRILL':
        return 'beep_short.ogg';
      case 'ALARM':
      case 'FIRE':
        return 'alarm_clock.ogg';
      case 'TROUBLE':
        return 'warning_tone.ogg';
      case 'SYSTEM RESET':
        return 'success_tone.ogg';
      case 'SILENCE':
      case 'ACKNOWLEDGE':
        return 'beep_confirm.ogg';
      default:
        return 'default_notification.ogg';
    }
  }

  /// Check if event type requires critical handling
  bool isCriticalEvent(String eventType) {
    const criticalEvents = ['ALARM', 'FIRE', 'TROUBLE'];
    return criticalEvents.contains(eventType.toUpperCase());
  }

  /// Check if event type requires sound
  bool requiresSound(String eventType) {
    // All events except silence require sound
    return eventType.toUpperCase() != 'SILENCE';
  }

  /// Check if event type requires vibration
  bool requiresVibration(String eventType) {
    const vibrationEvents = ['ALARM', 'FIRE', 'TROUBLE', 'DRILL'];
    return vibrationEvents.contains(eventType.toUpperCase());
  }

  /// Dispose resources
  @mustCallSuper
  Future<void> dispose() async {
    _isInitialized = false;
    
  }

  
  /// Create standard notification channel configuration
  Map<String, dynamic> createNotificationChannelConfig({
    required String id,
    required String name,
    required String description,
    required bool isCritical,
  }) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'importance': isCritical ? 'max' : 'high',
      'enableVibration': true,
      'playSound': true,
      'sound': getSoundFileForEventType(id),
    };
  }

  /// Override this method to return the appropriate service instance
  BaseNotificationService createServiceInstance() {
    throw UnimplementedError('Subclasses must implement createServiceInstance()');
  }
}