import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger.dart';

/// ProjectInfo Cache Service untuk persistent storage Firebase projectInfo data
/// Menyimpan numberOfModules dan numberOfZones untuk offline/WebSocket mode access
class ProjectInfoCacheService {
  ProjectInfoCacheService._(); // Private constructor

  // SharedPreferences keys
  static const String _numberOfModulesKey = 'project_info_number_of_modules';
  static const String _numberOfZonesKey = 'project_info_number_of_zones';
  static const String _cacheTimestampKey = 'project_info_cache_timestamp';
  static const String _cacheVersionKey = 'project_info_cache_version';

  // Cache configuration
  static const Duration _cacheExpiration = Duration(days: 7);
  static const String _currentCacheVersion = '1.0';

  /// Check if cache is valid (not expired)
  static Future<bool> _isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cachedVersion = prefs.getString(_cacheVersionKey) ?? '';
      final now = DateTime.now().millisecondsSinceEpoch;

      final isNotExpired = (now - timestamp) < _cacheExpiration.inMilliseconds;
      final isVersionMatch = cachedVersion == _currentCacheVersion;

      return isNotExpired && isVersionMatch;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error checking cache validity',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get cached numberOfModules
  static Future<int?> getCachedNumberOfModules() async {
    try {
      final isValid = await _isCacheValid();
      if (!isValid) return null;

      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_numberOfModulesKey);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting cached number of modules',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Get cached numberOfZones
  static Future<int?> getCachedNumberOfZones() async {
    try {
      final isValid = await _isCacheValid();
      if (!isValid) return null;

      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_numberOfZonesKey);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting cached number of zones',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Save projectInfo data to cache
  static Future<bool> saveProjectInfoData({
    int? numberOfModules,
    int? numberOfZones,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Save data
      final futures = <Future<bool>>[];

      if (numberOfModules != null) {
        futures.add(prefs.setInt(_numberOfModulesKey, numberOfModules));
        AppLogger.info('Cached numberOfModules: $numberOfModules', tag: 'PROJECT_CACHE');
      }

      if (numberOfZones != null) {
        futures.add(prefs.setInt(_numberOfZonesKey, numberOfZones));
        AppLogger.info('Cached numberOfZones: $numberOfZones', tag: 'PROJECT_CACHE');
      }

      // Save metadata
      futures.add(prefs.setInt(_cacheTimestampKey, now));
      futures.add(prefs.setString(_cacheVersionKey, _currentCacheVersion));

      final results = await Future.wait(futures);
      final success = results.every((result) => result);

      if (success) {
        AppLogger.info(
          'ProjectInfo data cached successfully',
          tag: 'PROJECT_CACHE',
        );
      } else {
        AppLogger.warning(
          'Some projectInfo data failed to cache',
          tag: 'PROJECT_CACHE',
        );
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error saving projectInfo data to cache',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Clear cache
  static Future<bool> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final futures = <Future<bool>>[];

      futures.add(prefs.remove(_numberOfModulesKey));
      futures.add(prefs.remove(_numberOfZonesKey));
      futures.add(prefs.remove(_cacheTimestampKey));
      futures.add(prefs.remove(_cacheVersionKey));

      final results = await Future.wait(futures);
      final success = results.every((result) => result);

      if (success) {
        AppLogger.info('ProjectInfo cache cleared', tag: 'PROJECT_CACHE');
      } else {
        AppLogger.warning('Some cache keys failed to clear', tag: 'PROJECT_CACHE');
      }

      return success;
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error clearing projectInfo cache',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  /// Get cache information for debugging
  static Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey) ?? 0;
      final cachedVersion = prefs.getString(_cacheVersionKey) ?? '';
      final modules = prefs.getInt(_numberOfModulesKey);
      final zones = prefs.getInt(_numberOfZonesKey);
      final isValid = await _isCacheValid();

      return {
        'isValid': isValid,
        'version': cachedVersion,
        'currentVersion': _currentCacheVersion,
        'timestamp': timestamp,
        'cachedAt': timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestamp).toIso8601String()
          : null,
        'modules': modules,
        'zones': zones,
        'ageHours': timestamp > 0
          ? (DateTime.now().millisecondsSinceEpoch - timestamp) / (1000 * 60 * 60)
          : null,
        'expirationDays': _cacheExpiration.inDays,
      };
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error getting cache info',
        tag: 'PROJECT_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
      return {
        'isValid': false,
        'error': e.toString(),
      };
    }
  }
}