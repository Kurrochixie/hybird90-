import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'password_reset_rate_limiter.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _phoneKey = 'phone';
  static const String _configDoneKey = 'config_done';
  static const String _settingsDoneKey = 'settings_done';
  static const String _sessionTimestampKey = 'session_timestamp';

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  // Simpan session login ke local storage
  Future<void> saveLoginSession({
    required String userId,
    required String email,
    required String username,
    required String phone,
    bool configDone = false,
    bool settingsDone = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_phoneKey, phone);
    await prefs.setBool(_configDoneKey, configDone);
    await prefs.setBool(_settingsDoneKey, settingsDone);
    // SECURITY FIX: Add session timestamp for expiration tracking
    await prefs.setString(_sessionTimestampKey, DateTime.now().toIso8601String());
  }
  
  // Update status config dan settings
  Future<void> updateConfigStatus({
    bool? configDone,
    bool? settingsDone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (configDone != null) {
      await prefs.setBool(_configDoneKey, configDone);
    }
    if (settingsDone != null) {
      await prefs.setBool(_settingsDoneKey, settingsDone);
    }
  }
  
  // Cek apakah user sudah login sebelumnya
  Future<Map<String, dynamic>?> checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    // Validasi dengan Firebase Database - cek apakah user masih ada dan aktif
    try {
      final userSnapshot = await _databaseRef.child('users/${user.uid}').get();

      if (!userSnapshot.exists) {
        // User tidak ditemukan di Firebase, sign out
        await FirebaseAuth.instance.signOut();
        return null;
      }

      final userData = userSnapshot.value as Map<dynamic, dynamic>;

      // Cek apakah akun masih aktif
      if (userData['isActive'] != true) {
        // Akun tidak aktif, sign out
        await FirebaseAuth.instance.signOut();
        await clearSession();
        
        return null;
      }

      // 🔒 NEW: Persistent Login with Security Validation
      // User account is valid and active - allow persistent login
      
      

      // Get user data from Firebase and session storage
      final prefs = await SharedPreferences.getInstance();
      final sessionData = {
        'userId': user.uid,
        'email': user.email ?? '',
        'username': userData['username'] ?? prefs.getString(_usernameKey) ?? '',
        'phone': userData['phone'] ?? prefs.getString(_phoneKey) ?? '',
        'configDone': prefs.getBool(_configDoneKey) ?? false,
        'settingsDone': prefs.getBool(_settingsDoneKey) ?? false,
        'sessionTimestamp': prefs.getString(_sessionTimestampKey),
        'photoUrl': userData['photoUrl'],
        'isActive': userData['isActive'] ?? true,
      };

      // Update local session data with latest Firebase data
      await saveLoginSession(
        userId: sessionData['userId']!,
        email: sessionData['email']!,
        username: sessionData['username']!,
        phone: sessionData['phone']!,
        configDone: sessionData['configDone'],
        settingsDone: sessionData['settingsDone'],
      );

      return sessionData;
    } catch (e) {
      // Jika ada error, sign out
      await FirebaseAuth.instance.signOut();
      return null;
    }
  }
  
  // Hapus session (untuk logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_configDoneKey);
    await prefs.remove(_settingsDoneKey);
    // SECURITY FIX: Also clear session timestamp
    await prefs.remove(_sessionTimestampKey);
  }
  
  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  // Get current username
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get current phone
  Future<String?> getCurrentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  // Get current user photo URL from Firebase Auth
  Future<String?> getCurrentUserPhotoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      // First try to get from Firebase Auth
      if (user.photoURL != null) {
        return user.photoURL;
      }
      
      // If not in Auth, try to get from Realtime Database
      final userSnapshot = await _databaseRef.child('users/${user.uid}').get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        return userData['photoUrl'];
      }
      return null;
    } catch (e) {
      // Failed to get user session
      print('Warning: Failed to get user session: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String username,
    required String phone,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update Firebase Auth
    await user.updateDisplayName(username);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Update Firebase Realtime Database
    await _databaseRef.child('users/${user.uid}').update({
      'username': username,
      'phone': phone,
      'photoUrl': photoUrl,
    });

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_phoneKey, phone);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await clearSession();
  }

  // Save user data to database after registration (SECURE - no password storage)
  Future<void> saveUserDataToDatabase({
    required String uid,
    required String email,
    required String username,
    required String phone,
  }) async {
    await _databaseRef.child('users/$uid').set({
      'email': email,
      'username': username,
      'phone': phone,
      // Password NOT stored - handled securely by Firebase Auth
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'configDone': false,
      'settingsDone': false,
      'fcmToken': '', // Will be updated after login/registration
    });
  }

  // Update FCM token for current user
  Future<void> updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _databaseRef.child('users/${user.uid}/fcmToken').set(token);
        // SECURITY FIX: Mask FCM token in logs to prevent exposure
        if (token.length > 10) {
          String maskedToken = '${token.substring(0, 8)}...${token.substring(token.length - 8)}';
          
        } else {
          
        }
      }
    } catch (e) {
      // Failed to update FCM token
      print('Warning: Failed to update FCM token: $e');
      // Continue without FCM token update
    }
  }

  // ==========================================
  // FORGOT PASSWORD FUNCTIONALITY
  // ==========================================

  /// Kirim password reset email ke user
  /// Menggunakan Firebase Auth built-in password reset functionality
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();

      

      // Cek rate limiting sebelum mengirim
      final canReset = await PasswordResetRateLimiter.canResetPassword(normalizedEmail);
      if (!canReset) {
        final timeUntilNext = await PasswordResetRateLimiter.getTimeUntilNextRequest(normalizedEmail);
        final timeString = timeUntilNext != null
            ? 'Try again in ${timeUntilNext.inMinutes} minutes'
            : 'Too many requests. Please try again later';
        throw Exception(timeString);
      }

      // Kirim password reset email via Firebase Auth
      await FirebaseAuth.instance.sendPasswordResetEmail(email: normalizedEmail);

      // Catat successful request
      await PasswordResetRateLimiter.recordSuccessfulRequest(normalizedEmail);

      // Log ke database untuk monitoring
      await _logPasswordResetRequest(
        email: normalizedEmail,
        uid: 'unknown', // User belum login
        success: true,
        source: 'forgot_password_page',
      );

      

    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email address';
          break;
        case 'invalid-email':
          errorMessage = 'Please enter a valid email address';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled';
          break;
        default:
          errorMessage = 'Failed to send password reset email: ${e.message}';
      }

      // Log failed request
      await _logPasswordResetRequest(
        email: email.trim().toLowerCase(),
        uid: 'unknown',
        success: false,
        error: e.code,
        source: 'forgot_password_page',
      );

      // Catat failed request untuk rate limiting
      await PasswordResetRateLimiter.recordFailedRequest(
        email.trim().toLowerCase(),
        e.code
      );

      
      throw Exception(errorMessage);

    } catch (e) {
      
      throw Exception('An unexpected error occurred. Please try again.');
    }
  }

  /// Log password reset requests ke database untuk monitoring
  Future<void> _logPasswordResetRequest({
    required String email,
    required String uid,
    required bool success,
    String? error,
    String? source,
  }) async {
    try {
      final requestId = _databaseRef.child('passwordResetRequests').push();
      await requestId.set({
        'email': email.toLowerCase(),
        'uid': uid,
        'success': success,
        'error': error,
        'source': source ?? 'unknown',
        'timestamp': DateTime.now().toIso8601String(),
        'userAgent': 'Flutter App',
        // IP address bisa ditambahkan jika needed
      });

      

    } catch (e) {
      // Logging error seharusnya tidak menghentikan flow utama
      
    }
  }

  /// Cek status password reset untuk user tertentu
  Future<Map<String, dynamic>?> getPasswordResetStatus(String email) async {
    try {
      final normalizedEmail = email.toLowerCase().trim();

      // Dapatkan rate limit stats
      final rateLimitStats = await PasswordResetRateLimiter.getRateLimitStats(normalizedEmail);

      // Dapatkan request history dari database
      final snapshot = await _databaseRef
          .child('passwordResetRequests')
          .orderByChild('email')
          .equalTo(normalizedEmail)
          .limitToLast(10)
          .get();

      final requests = <Map<String, dynamic>>[];
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          requests.add(Map<String, dynamic>.from(value));
        });
      }

      return {
        'email': normalizedEmail,
        'rateLimitStats': rateLimitStats,
        'recentRequests': requests,
        'totalRequests': requests.length,
      };

    } catch (e) {
      
      return null;
    }
  }

  /// Update user data setelah password reset berhasil
  Future<void> updatePasswordResetTimestamp(String uid) async {
    try {
      await _databaseRef.child('users/$uid').update({
        'lastPasswordReset': DateTime.now().toIso8601String(),
        'passwordResetCount': ServerValue.increment(1),
      });

      

    } catch (e) {
      
    }
  }

  /// Cek apakah user memerlukan password reset (opsional untuk security)
  Future<bool> shouldForcePasswordReset(String uid) async {
    try {
      final snapshot = await _databaseRef.child('users/$uid').get();
      if (!snapshot.exists) return false;

      final userData = Map<String, dynamic>.from(snapshot.value as Map);
      final lastPasswordReset = userData['lastPasswordReset'] as String?;
      final createdAt = userData['createdAt'] as String?;

      if (lastPasswordReset == null || createdAt == null) {
        return false;
      }

      final lastResetTime = DateTime.parse(lastPasswordReset);
      final createdTime = DateTime.parse(createdAt);

      // Force reset jika password belum pernah direset dan akun lebih dari 90 hari
      if (lastResetTime.isAtSameMomentAs(createdTime)) {
        final ninetyDaysAgo = DateTime.now().subtract(const Duration(days: 90));
        return createdTime.isBefore(ninetyDaysAgo);
      }

      // Force reset jika password reset terakhir lebih dari 180 hari
      final hundredEightyDaysAgo = DateTime.now().subtract(const Duration(days: 180));
      return lastResetTime.isBefore(hundredEightyDaysAgo);

    } catch (e) {
      
      return false;
    }
  }

  // DEPRECATED: Migration function removed for security reasons
  // This function previously handled plain text passwords which is insecure
  // All users should now register through the secure Firebase Auth flow
  // Future<void> migrateUsers() async {
  //   // Function removed - see documentation for secure user migration
  // }
}
