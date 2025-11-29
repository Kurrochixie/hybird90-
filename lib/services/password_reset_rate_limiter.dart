import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Password Reset Rate Limiter Service
/// Mencegah abuse password reset requests dengan rate limiting
class PasswordResetRateLimiter {
  static const String _rateLimitKey = 'password_reset_rate_limit';
  static const String _countKeySuffix = '_count';
  static const String _timestampKeySuffix = '_timestamp';

  // Konfigurasi rate limiting
  static const int _maxRequests = 3; // Maksimal 3 requests
  static const Duration _timeWindow = Duration(hours: 1); // Per 1 jam
  static const Duration _blockDuration = Duration(hours: 1); // Block selama 1 jam

  /// Cek apakah user bisa request password reset
  /// Returns true jika bisa, false jika rate limited
  static Future<bool> canResetPassword(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_$normalizedEmail';

      // Cek apakah user sedang di-block
      final blockUntil = prefs.getString('${rateLimitKey}_blocked_until');
      if (blockUntil != null) {
        final blockUntilTime = DateTime.parse(blockUntil);
        if (DateTime.now().isBefore(blockUntilTime)) {
          
          return false;
        } else {
          // Block sudah kadaluarsa, hapus data
          await _clearRateLimitData(prefs, rateLimitKey);
        }
      }

      // Ambil data request sebelumnya
      final requestCount = prefs.getInt('$rateLimitKey$_countKeySuffix') ?? 0;
      final lastRequestTimestamp = prefs.getString('$rateLimitKey$_timestampKeySuffix');

      if (lastRequestTimestamp == null) {
        // First request
        
        return true;
      }

      final lastRequestTime = DateTime.parse(lastRequestTimestamp);
      final now = DateTime.now();

      // Jika time window sudah kadaluarsa, reset counter
      if (now.difference(lastRequestTime) > _timeWindow) {
        
        return true;
      }

      // Cek apakah masih dalam limit
      if (requestCount < _maxRequests) {
        
        return true;
      }

      // User melebihi limit, block untuk _blockDuration
      final newBlockUntil = now.add(_blockDuration);
      await prefs.setString('${rateLimitKey}_blocked_until', newBlockUntil.toIso8601String());
      
      return false;

    } catch (e) {
      
      // Jika terjadi error, allow request untuk tidak block user yang valid
      return true;
    }
  }

  /// Catat request password reset yang berhasil
  static Future<void> recordSuccessfulRequest(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_$normalizedEmail';
      final now = DateTime.now();

      // Ambil data existing
      final requestCount = prefs.getInt('$rateLimitKey$_countKeySuffix') ?? 0;
      final lastRequestTimestamp = prefs.getString('$rateLimitKey$_timestampKeySuffix');

      // Cek apakah time window sudah kadaluarsa
      if (lastRequestTimestamp != null) {
        final lastRequestTime = DateTime.parse(lastRequestTimestamp);
        if (now.difference(lastRequestTime) > _timeWindow) {
          // Reset counter jika time window kadaluarsa
          await prefs.setInt('$rateLimitKey$_countKeySuffix', 1);
          await prefs.setString('$rateLimitKey$_timestampKeySuffix', now.toIso8601String());
          
        } else {
          // Increment counter
          await prefs.setInt('$rateLimitKey$_countKeySuffix', requestCount + 1);
          await prefs.setString('$rateLimitKey$_timestampKeySuffix', now.toIso8601String());
          
        }
      } else {
        // First request
        await prefs.setInt('$rateLimitKey$_countKeySuffix', 1);
        await prefs.setString('$rateLimitKey$_timestampKeySuffix', now.toIso8601String());
        
      }

    } catch (e) {
      
    }
  }

  /// Catat failed request (untuk monitoring)
  static Future<void> recordFailedRequest(String email, String error) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_failed_$normalizedEmail';
      final now = DateTime.now();

      // Simpan failed request data untuk monitoring
      final failedRequests = prefs.getStringList('${rateLimitKey}_list') ?? [];
      failedRequests.add('${now.toIso8601String()}:$error');

      // Keep only last 10 failed requests
      if (failedRequests.length > 10) {
        failedRequests.removeRange(0, failedRequests.length - 10);
      }

      await prefs.setStringList('${rateLimitKey}_list', failedRequests);
      

    } catch (e) {
      
    }
  }

  /// Dapatkan waktu sampai user bisa request lagi
  static Future<Duration?> getTimeUntilNextRequest(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_$normalizedEmail';

      // Cek block time
      final blockUntil = prefs.getString('${rateLimitKey}_blocked_until');
      if (blockUntil != null) {
        final blockUntilTime = DateTime.parse(blockUntil);
        if (DateTime.now().isBefore(blockUntilTime)) {
          return blockUntilTime.difference(DateTime.now());
        }
      }

      // Cek rate limit window
      final lastRequestTimestamp = prefs.getString('$rateLimitKey$_timestampKeySuffix');
      if (lastRequestTimestamp != null) {
        final lastRequestTime = DateTime.parse(lastRequestTimestamp);
        final requestCount = prefs.getInt('$rateLimitKey$_countKeySuffix') ?? 0;

        if (requestCount >= _maxRequests) {
          final windowEnd = lastRequestTime.add(_timeWindow);
          if (DateTime.now().isBefore(windowEnd)) {
            return windowEnd.difference(DateTime.now());
          }
        }
      }

      return null;

    } catch (e) {
      
      return null;
    }
  }

  /// Dapatkan statistik rate limit untuk email tertentu
  static Future<Map<String, dynamic>> getRateLimitStats(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_$normalizedEmail';

      final requestCount = prefs.getInt('$rateLimitKey$_countKeySuffix') ?? 0;
      final lastRequestTimestamp = prefs.getString('$rateLimitKey$_timestampKeySuffix');
      final blockUntil = prefs.getString('${rateLimitKey}_blocked_until');

      final failedRequests = prefs.getStringList('${rateLimitKey}_failed_${normalizedEmail}_list') ?? [];

      return {
        'email': normalizedEmail,
        'requestCount': requestCount,
        'maxRequests': _maxRequests,
        'lastRequest': lastRequestTimestamp,
        'blockedUntil': blockUntil,
        'isBlocked': blockUntil != null && DateTime.now().isBefore(DateTime.parse(blockUntil)),
        'failedRequestsCount': failedRequests.length,
        'timeWindow': _timeWindow.inHours,
        'remainingRequests': _maxRequests - requestCount,
      };

    } catch (e) {
      
      return {};
    }
  }

  /// Clear semua rate limit data untuk testing purposes
  static Future<void> clearAllRateLimitData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_rateLimitKey)) {
          await prefs.remove(key);
        }
      }

      

    } catch (e) {
      
    }
  }

  /// Clear rate limit data untuk email tertentu
  static Future<void> clearRateLimitData(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final normalizedEmail = email.toLowerCase().trim();
      final rateLimitKey = '${_rateLimitKey}_$normalizedEmail';
      await _clearRateLimitData(prefs, rateLimitKey);
      

    } catch (e) {
      
    }
  }

  /// Helper method untuk clear rate limit data
  static Future<void> _clearRateLimitData(SharedPreferences prefs, String rateLimitKey) async {
    await prefs.remove(rateLimitKey);
    await prefs.remove('$rateLimitKey$_countKeySuffix');
    await prefs.remove('$rateLimitKey$_timestampKeySuffix');
    await prefs.remove('${rateLimitKey}_blocked_until');
    await prefs.remove('${rateLimitKey}_failed_${rateLimitKey}_list');
  }

  /// Debug method untuk print semua rate limit data
  static Future<void> debugPrintRateLimits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final rateLimitKeys = keys.where((key) => key.startsWith(_rateLimitKey));

      
      for (final key in rateLimitKeys) {
        final value = prefs.get(key);
        
      }

    } catch (e) {
      
    }
  }
}