import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FCMService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  static String get _serverKey => dotenv.env['FCM_SERVER_KEY'] ?? ''; // From environment variables
  static const String _functionsUrl = 'https://us-central1-testing1do.cloudfunctions.net';

  static Future<String> _getAccessToken() async {
    // Get server key from environment variables
    final serverKey = _serverKey;
    if (serverKey.isEmpty) {
      throw Exception('FCM server key not configured in environment variables');
    }
    return serverKey;
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _getAccessToken();
    } catch (e) {
      // Failed to get FCM access token
      print('Warning: Failed to get FCM access token: $e');
      return null;
    }
  }

  static Future<bool> sendFCMNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        
        return false;
      }

      final headers = {
        'Authorization': 'key=$accessToken',
        'Content-Type': 'application/json',
      };

      final message = {
        'to': '/topics/status_updates',
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data.map((key, value) => MapEntry(key, value.toString())),
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        
        return true;
      } else {
        
        return false;
      }
    } catch (e) {
      // Failed to send FCM notification
      print('Warning: Failed to send FCM notification: $e');
      return false;
    }
  }

  // Enhanced FCM service for fire alarm events using Firebase Functions via HTTP
  static Future<bool> sendFireAlarmNotification({
    required String eventType,
    required String status,
    required String user,
    String? projectName,
    String? panelType,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        
        
        // Use Firebase Functions callable endpoint
        final response = await http.post(
          Uri.parse('$_functionsUrl/sendFireAlarmNotification'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Flutter-FCM-Service/1.0',
          },
          body: jsonEncode({
            'data': {
              'eventType': eventType,
              'status': status,
              'user': user,
              'projectName': projectName ?? 'Unknown Project',
              'panelType': panelType ?? 'Unknown Panel',
            }
          }),
        ).timeout(const Duration(seconds: 10));

        
        
        if (response.statusCode == 200) {
          try {
            final result = jsonDecode(response.body);
            
            
            if (result['result'] != null && result['result']['success'] == true) {
              
              return true;
            } else {
              
              return false;
            }
          } catch (e) {
            
            
            return false;
          }
        } else if (response.statusCode == 404) {
          
          if (retryCount < maxRetries) {
            retryCount++;
            
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          } else {
            
            return false;
          }
        } else if (response.statusCode == 500) {
          
          if (retryCount < maxRetries) {
            retryCount++;
            
            await Future.delayed(Duration(seconds: 3 * retryCount));
            continue;
          } else {
            
            return false;
          }
        } else {
          
          return false;
        }
      } catch (e) {
        
        if (retryCount < maxRetries && e.toString().contains('TimeoutException')) {
          retryCount++;
          
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        } else if (retryCount < maxRetries && e.toString().contains('SocketException')) {
          retryCount++;
          
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        } else {
          
          return false;
        }
      }
    }
    
    
    return false;
  }

  // Subscribe to fire alarm events topic via HTTP
  static Future<bool> subscribeToFireAlarmEvents(String? fcmToken) async {
    try {
      if (fcmToken == null || fcmToken.isEmpty) {
        
        return false;
      }

      

      final response = await http.post(
        Uri.parse('$_functionsUrl/subscribeToFireAlarmEvents'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'token': fcmToken,
          }
        }),
      );

      
      

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          if (result['result'] != null && result['result']['success'] == true) {
            
            return true;
          } else {
            
            return false;
          }
        } catch (e) {
          
          return false;
        }
      } else {
        
        return false;
      }
    } catch (e) {
      // Failed to send FCM notification
      print('Warning: Failed to send FCM notification: $e');
      return false;
    }
  }

  // Unsubscribe from fire alarm events topic via HTTP
  static Future<bool> unsubscribeFromFireAlarmEvents(String? fcmToken) async {
    try {
      if (fcmToken == null || fcmToken.isEmpty) {
        
        return false;
      }

      

      final response = await http.post(
        Uri.parse('$_functionsUrl/unsubscribeFromFireAlarmEvents'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'token': fcmToken,
          }
        }),
      );

      
      

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          if (result['result'] != null && result['result']['success'] == true) {
            
            return true;
          } else {
            
            return false;
          }
        } catch (e) {
          
          return false;
        }
      } else {
        
        return false;
      }
    } catch (e) {
      // Failed to send FCM notification
      print('Warning: Failed to send FCM notification: $e');
      return false;
    }
  }

  // Helper methods for specific event types
  static Future<bool> sendDrillNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'DRILL',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendSystemResetNotification({
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'SYSTEM RESET',
      status: 'COMPLETED',
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendSilenceNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'SILENCE',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendAcknowledgeNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'ACKNOWLEDGE',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendAlarmNotification({
    required String status,
    String? user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'ALARM',
      status: status,
      user: user ?? 'System',
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendTroubleNotification({
    required String status,
    String? user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'TROUBLE',
      status: status,
      user: user ?? 'System',
      projectName: projectName,
      panelType: panelType,
    );
  }
}
