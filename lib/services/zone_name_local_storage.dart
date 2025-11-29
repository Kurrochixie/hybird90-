import 'package:shared_preferences/shared_preferences.dart';
import '../services/logger.dart';

/// Local storage service for zone names using SharedPreferences
class ZoneNameLocalStorage {
  static const String _tag = 'ZONE_NAME_STORAGE';
  static const String _zoneNamesKey = 'zone_names_data';

  /// Save zone names to local storage
  /// Format: "#001#Zone Name, #002#Zone Name, ..."
  static Future<bool> saveZoneNames(String zoneData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.setString(_zoneNamesKey, zoneData);

      AppLogger.info('Zone names saved to local storage', tag: _tag);
      return result;
    } catch (e) {
      AppLogger.error('Error saving zone names to local storage', tag: _tag, error: e);
      return false;
    }
  }

  /// Load zone names from local storage
  static Future<String> loadZoneNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneData = prefs.getString(_zoneNamesKey) ?? '';

      AppLogger.debug('Zone names loaded from local storage: ${zoneData.isNotEmpty ? "found data" : "empty"}', tag: _tag);
      return zoneData;
    } catch (e) {
      AppLogger.error('Error loading zone names from local storage', tag: _tag, error: e);
      return '';
    }
  }

  /// Parse zone data from format: "#001#Zone Name, #002#Zone Name, ..."
  static Map<int, String> parseZoneData(String data) {
    Map<int, String> zones = {};
    if (data.isEmpty) return zones;

    try {
      // Split by comma
      List<String> zoneEntries = data.split(',');

      for (String entry in zoneEntries) {
        entry = entry.trim();
        if (entry.startsWith('#')) {
          final match = RegExp(r'#(\d+)#(.+)').firstMatch(entry);
          if (match != null) {
            final zoneNumber = int.tryParse(match.group(1)!) ?? 0;
            final zoneName = match.group(2)!;
            zones[zoneNumber] = zoneName;
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error parsing zone data', tag: _tag, error: e);
    }

    return zones;
  }

  /// Format zone names to string format: "#001#Zone Name, #002#Zone Name, ..."
  static String formatZoneNames(Map<int, String> zones) {
    List<String> zoneEntries = [];

    // Sort by zone number for consistent output
    final sortedKeys = zones.keys.toList()..sort();

    for (final zoneNumber in sortedKeys) {
      final zoneName = zones[zoneNumber] ?? '';
      if (zoneName.isNotEmpty) {
        zoneEntries.add('#$zoneNumber#$zoneName');
      }
    }

    return zoneEntries.join(', ');
  }

  /// Clear all zone names from local storage
  static Future<bool> clearZoneNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final result = await prefs.remove(_zoneNamesKey);

      AppLogger.info('Zone names cleared from local storage', tag: _tag);
      return result;
    } catch (e) {
      AppLogger.error('Error clearing zone names from local storage', tag: _tag, error: e);
      return false;
    }
  }

  /// Check if zone names exist in local storage
  static Future<bool> hasZoneNames() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final zoneData = prefs.getString(_zoneNamesKey);
      return zoneData != null && zoneData.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking zone names existence', tag: _tag, error: e);
      return false;
    }
  }

  /// Get default zone name for a zone number
  static String getDefaultZoneName(int zoneNumber) {
    return 'Zone $zoneNumber';
  }

  /// Validate zone name
  static String? validateZoneName(String name) {
    if (name.trim().isEmpty) {
      return 'Zone name cannot be empty';
    }

    if (name.trim().length > 50) {
      return 'Zone name cannot exceed 50 characters';
    }

    // Check for invalid characters that might break the format
    if (name.contains('#') || name.contains(',')) {
      return 'Zone name cannot contain # or , characters';
    }

    return null;
  }
}