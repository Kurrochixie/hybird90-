import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

class OfflineSettings {
  final String ip;
  final int port;
  final String projectName;
  final int moduleCount;
  final DateTime lastSaved;
  final bool isConfigured;

  const OfflineSettings({
    required this.ip,
    required this.port,
    required this.projectName,
    required this.moduleCount,
    required this.lastSaved,
    this.isConfigured = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'ip': ip,
      'port': port,
      'projectName': projectName,
      'moduleCount': moduleCount,
      'lastSaved': lastSaved.toIso8601String(),
      'isConfigured': isConfigured,
    };
  }

  factory OfflineSettings.fromJson(Map<String, dynamic> json) {
    return OfflineSettings(
      ip: json['ip'] ?? '192.168.1.100',
      port: json['port'] ?? 80,
      projectName: json['projectName'] ?? 'Fire Alarm System',
      moduleCount: json['moduleCount'] ?? 1,
      lastSaved: DateTime.parse(json['lastSaved'] ?? DateTime.now().toIso8601String()),
      isConfigured: json['isConfigured'] ?? false,
    );
  }

  OfflineSettings copyWith({
    String? ip,
    int? port,
    String? projectName,
    int? moduleCount,
    DateTime? lastSaved,
    bool? isConfigured,
  }) {
    return OfflineSettings(
      ip: ip ?? this.ip,
      port: port ?? this.port,
      projectName: projectName ?? this.projectName,
      moduleCount: moduleCount ?? this.moduleCount,
      lastSaved: lastSaved ?? this.lastSaved,
      isConfigured: isConfigured ?? this.isConfigured,
    );
  }

  @override
  String toString() {
    return 'OfflineSettings(ip: $ip, port: $port, projectName: $projectName, moduleCount: $moduleCount, isConfigured: $isConfigured)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OfflineSettings &&
        other.ip == ip &&
        other.port == port &&
        other.projectName == projectName &&
        other.moduleCount == moduleCount &&
        other.isConfigured == isConfigured;
  }

  @override
  int get hashCode {
    return ip.hashCode ^
        port.hashCode ^
        projectName.hashCode ^
        moduleCount.hashCode ^
        isConfigured.hashCode;
  }
}

class OfflineSettingsService {
  static const String _keyIp = 'offline_ip';
  static const String _keyPort = 'offline_port';
  static const String _keyProjectName = 'offline_project_name';
  static const String _keyModuleCount = 'offline_module_count';
  static const String _keyLastSaved = 'offline_last_saved';
  static const String _keyIsConfigured = 'offline_configured';
  static const String _keySettingsJson = 'offline_settings_json';

  static OfflineSettings? _cachedSettings;
  static SharedPreferences? _prefs;

  /// Initialize the service
  static Future<void> initialize() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      AppLogger.info('OfflineSettingsService initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize OfflineSettingsService', error: e);
      rethrow;
    }
  }

  /// Get current offline settings
  static Future<OfflineSettings> getSettings() async {
    try {
      await initialize();

      // Return cached settings if available
      if (_cachedSettings != null) {
        return _cachedSettings!;
      }

      // Try to load from JSON format (newer versions)
      final settingsJson = _prefs!.getString(_keySettingsJson);
      if (settingsJson != null) {
        try {
          final json = jsonDecode(settingsJson) as Map<String, dynamic>;
          _cachedSettings = OfflineSettings.fromJson(json);
          return _cachedSettings!;
        } catch (e) {
          AppLogger.warning('Failed to parse settings JSON, falling back to individual keys', error: e);
        }
      }

      // Fallback to individual keys (legacy format)
      final ip = _prefs!.getString(_keyIp) ?? '192.168.1.100';
      final port = int.tryParse(_prefs!.getString(_keyPort) ?? '80') ?? 80;
      final projectName = _prefs!.getString(_keyProjectName) ?? 'Fire Alarm System';
      final moduleCount = int.tryParse(_prefs!.getString(_keyModuleCount) ?? '1') ?? 1;
      final lastSavedString = _prefs!.getString(_keyLastSaved);
      final lastSaved = lastSavedString != null
          ? DateTime.parse(lastSavedString)
          : DateTime.now();
      final isConfigured = _prefs!.getBool(_keyIsConfigured) ?? false;

      _cachedSettings = OfflineSettings(
        ip: ip,
        port: port,
        projectName: projectName,
        moduleCount: moduleCount,
        lastSaved: lastSaved,
        isConfigured: isConfigured,
      );

      // Migrate to JSON format for future loads
      await saveSettings(_cachedSettings!);

      return _cachedSettings!;

    } catch (e) {
      AppLogger.error('Failed to get offline settings', error: e);

      // Return default settings on error
      _cachedSettings = OfflineSettings(
        ip: '192.168.1.100',
        port: 80,
        projectName: 'Fire Alarm System',
        moduleCount: 1,
        lastSaved: DateTime.now(),
        isConfigured: false,
      );

      return _cachedSettings!;
    }
  }

  /// Save offline settings
  static Future<bool> saveSettings(OfflineSettings settings) async {
    try {
      await initialize();

      // Update cache
      _cachedSettings = settings.copyWith(lastSaved: DateTime.now());

      // Save as JSON (preferred format)
      final settingsJson = jsonEncode(_cachedSettings!.toJson());
      await _prefs!.setString(_keySettingsJson, settingsJson);

      // Also save individual keys for backward compatibility
      await _prefs!.setString(_keyIp, settings.ip);
      await _prefs!.setString(_keyPort, settings.port.toString());
      await _prefs!.setString(_keyProjectName, settings.projectName);
      await _prefs!.setString(_keyModuleCount, settings.moduleCount.toString());
      await _prefs!.setString(_keyLastSaved, _cachedSettings!.lastSaved.toIso8601String());
      await _prefs!.setBool(_keyIsConfigured, settings.isConfigured);

      AppLogger.info('Offline settings saved: ${_cachedSettings!.toString()}');
      return true;

    } catch (e) {
      AppLogger.error('Failed to save offline settings', error: e);
      return false;
    }
  }

  /// Save individual settings
  static Future<bool> saveIndividualSettings({
    String? ip,
    int? port,
    String? projectName,
    int? moduleCount,
    bool? isConfigured,
  }) async {
    try {
      final currentSettings = await getSettings();
      final newSettings = currentSettings.copyWith(
        ip: ip,
        port: port,
        projectName: projectName,
        moduleCount: moduleCount,
        isConfigured: isConfigured ?? (isConfigured ?? currentSettings.isConfigured),
        lastSaved: DateTime.now(),
      );

      return await saveSettings(newSettings);

    } catch (e) {
      AppLogger.error('Failed to save individual offline settings', error: e);
      return false;
    }
  }

  /// Validate settings before saving
  static String? validateSettings({
    String? ip,
    String? port,
    String? projectName,
    String? moduleCount,
  }) {
    // Inline validation methods

    // IP Address validation
    if (ip == null || ip.trim().isEmpty) {
      return 'IP address is required';
    }
    final ipValue = ip.trim();
    final ipv4Regex = RegExp(
      r'^^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    if (!ipv4Regex.hasMatch(ipValue)) {
      return 'Please enter a valid IPv4 address (e.g., 192.168.1.100)';
    }

    // Port validation
    if (port == null || port.trim().isEmpty) {
      return 'Port is required';
    }
    final portValue = port.trim();
    final portNumber = int.tryParse(portValue);
    if (portNumber == null) {
      return 'Port must be a valid number';
    }
    if (portNumber < 1 || portNumber > 65535) {
      return 'Port must be between 1 and 65535';
    }

    // Project name validation
    if (projectName == null || projectName.trim().isEmpty) {
      return 'Project name is required';
    }
    final projectValue = projectName.trim();
    if (projectValue.length < 3) {
      return 'Project name must be at least 3 characters long';
    }
    if (projectValue.length > 50) {
      return 'Project name must be less than 50 characters';
    }

    // Module count validation
    if (moduleCount == null || moduleCount.trim().isEmpty) {
      return 'Number of modules is required';
    }
    final moduleValue = moduleCount.trim();
    final count = int.tryParse(moduleValue);
    if (count == null) {
      return 'Module count must be a valid number';
    }
    if (count < 1) {
      return 'Module count must be at least 1';
    }
    if (count > 255) {
      return 'Module count cannot exceed 255';
    }

    return null; // All validations passed
  }

  /// Check if offline mode is configured
  static Future<bool> isConfigured() async {
    try {
      final settings = await getSettings();
      return settings.isConfigured;
    } catch (e) {
      AppLogger.error('Failed to check if offline is configured', error: e);
      return false;
    }
  }

  /// Clear all offline settings
  static Future<bool> clearSettings() async {
    try {
      await initialize();

      // Clear all keys
      await _prefs!.remove(_keySettingsJson);
      await _prefs!.remove(_keyIp);
      await _prefs!.remove(_keyPort);
      await _prefs!.remove(_keyProjectName);
      await _prefs!.remove(_keyModuleCount);
      await _prefs!.remove(_keyLastSaved);
      await _prefs!.remove(_keyIsConfigured);

      // Clear cache
      _cachedSettings = null;

      AppLogger.info('Offline settings cleared');
      return true;

    } catch (e) {
      AppLogger.error('Failed to clear offline settings', error: e);
      return false;
    }
  }

  /// Export settings to JSON string
  static Future<String?> exportSettings() async {
    try {
      final settings = await getSettings();
      return jsonEncode(settings.toJson());
    } catch (e) {
      AppLogger.error('Failed to export offline settings', error: e);
      return null;
    }
  }

  /// Import settings from JSON string
  static Future<bool> importSettings(String settingsJson) async {
    try {
      final json = jsonDecode(settingsJson) as Map<String, dynamic>;
      final settings = OfflineSettings.fromJson(json);

      return await saveSettings(settings);
    } catch (e) {
      AppLogger.error('Failed to import offline settings', error: e);
      return false;
    }
  }

  /// Get connection string for display
  static Future<String> getConnectionString() async {
    try {
      final settings = await getSettings();
      return '${settings.ip}:${settings.port}';
    } catch (e) {
      AppLogger.error('Failed to get connection string', error: e);
      return 'Unknown';
    }
  }

  /// Test connection settings (basic validation)
  static Future<bool> testConnectionSettings() async {
    try {
      final settings = await getSettings();

      // Basic validation - in real implementation, you might want to
      // attempt actual socket connection here
      if (settings.ip.isEmpty || settings.port <= 0 || settings.port > 65535) {
        return false;
      }

      // Simulate connection test
      await Future.delayed(const Duration(milliseconds: 500));

      return true;
    } catch (e) {
      AppLogger.error('Failed to test connection settings', error: e);
      return false;
    }
  }

  /// Reset to default settings
  static Future<bool> resetToDefaults() async {
    try {
      final defaultSettings = OfflineSettings(
        ip: '192.168.1.100',
        port: 80,
        projectName: 'Fire Alarm System',
        moduleCount: 1,
        lastSaved: DateTime.now(),
        isConfigured: false,
      );

      return await saveSettings(defaultSettings);
    } catch (e) {
      AppLogger.error('Failed to reset offline settings to defaults', error: e);
      return false;
    }
  }

  /// Clear cached settings (force reload from storage)
  static void clearCache() {
    _cachedSettings = null;
  }
}