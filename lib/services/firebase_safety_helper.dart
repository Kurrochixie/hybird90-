import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';

/// Universal Firebase safety helper to prevent null safety errors
class FirebaseSafetyHelper {
  static const String _tag = 'FIREBASE_SAFETY';

  /// Safe way to get a Map from Firebase DataSnapshot with proper null checking
  static Map<String, dynamic>? getMapFromSnapshot(DataSnapshot snapshot) {
    final snapshotValue = snapshot.value;

    if (snapshotValue == null) {
      
      return null;
    }

    if (snapshotValue is! Map) {
      
      return null;
    }

    try {
      return Map<String, dynamic>.from(snapshotValue);
    } catch (e) {
      
      return null;
    }
  }

  /// Safe way to listen to Firebase value changes
  static StreamSubscription listenToValue(
    DatabaseReference reference, {
    required void Function(Map<String, dynamic>?) onData,
    String? tag = 'FIREBASE_LISTENER',
  }) {
    return reference.onValue.listen((event) {
      try {
        final data = getMapFromSnapshot(event.snapshot);
        if (data != null) {
          onData(data);
        }
      } catch (e, stackTrace) {
        
        
      }
    });
  }

  /// Safe way to write to Firebase with proper error handling
  static Future<void> safeSet(
    DatabaseReference reference,
    dynamic value, {
    String? tag = 'FIREBASE_WRITE',
  }) async {
    try {
      await reference.set(value);
      
    } catch (e, stackTrace) {
      
      
    }
  }

  /// Safe way to update specific fields in Firebase
  static Future<void> safeUpdate(
    DatabaseReference reference,
    Map<String, dynamic> updates, {
    String? tag = 'FIREBASE_UPDATE',
  }) async {
    try {
      await reference.update(updates);
      
    } catch (e, stackTrace) {
      
      
    }
  }

  /// Safe way to get a List from Firebase
  static List<T>? getListFromSnapshot<T>(DataSnapshot snapshot) {
    final snapshotValue = snapshot.value;

    if (snapshotValue == null) {
      
      return null;
    }

    if (snapshotValue is! List) {
      
      return null;
    }

    try {
      return List<T>.from(snapshotValue);
    } catch (e) {
      
      return null;
    }
  }

  /// Safe way to check if a key exists in Firebase
  static Future<bool> keyExists(
    DatabaseReference reference,
    String key, {
    String? tag = 'FIREBASE_KEY_EXISTS',
  }) async {
    try {
      final snapshot = await reference.child(key).get();
      return snapshot.exists;
    } catch (e) {
      
      return false;
    }
  }

  /// Validate Firebase data structure
  static bool validateFirebaseDataStructure(dynamic data) {
    if (data == null) return false;

    // Basic validation for common Firebase data structures
    if (data is Map) {
      final map = data;
      // Check for non-string keys that might cause issues
      for (final entry in map.entries) {
        if (entry.value == null) {
          
          return false;
        }
      }
    }

    return true;
  }
}