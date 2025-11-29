import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

// Hive models for local storage
part 'daily_backup_service.g.dart';

@HiveType(typeId: 0)
class BackupLogEntry extends HiveObject {
  @HiveField(0)
  String? id;

  @HiveField(1)
  DateTime? timestamp;

  @HiveField(2)
  String? logType; // 'trouble', 'status', 'fire', 'connection'

  @HiveField(3)
  String? date;

  @HiveField(4)
  String? time;

  @HiveField(5)
  String? address;

  @HiveField(6)
  String? zoneName;

  @HiveField(7)
  String? status;

  @HiveField(8)
  String? information;

  @HiveField(9)
  String? user;
}

@HiveType(typeId: 1)
class BackupMetadata extends HiveObject {
  @HiveField(0)
  String? date;

  @HiveField(1)
  int? troubleLogsCount;

  @HiveField(2)
  int? statusLogsCount;

  @HiveField(3)
  int? fireLogsCount;

  @HiveField(4)
  int? connectionLogsCount;

  @HiveField(5)
  DateTime? lastBackupTime;

  @HiveField(6)
  bool? isCompressed;
}

class DailyBackupService {
  static const Duration _backupInterval = Duration(hours: 24);
  static const Duration _retentionPeriod = Duration(days: 60); // 2 months

  static Timer? _backupTimer;
  static const String _backupBasePath = 'daily_backups';
  static const String _archiveBasePath = 'archived_backups';

  static late Box<BackupLogEntry> _troubleBox;
  static late Box<BackupLogEntry> _statusBox;
  static late Box<BackupLogEntry> _fireBox;
  static late Box<BackupLogEntry> _connectionBox;
  static late Box<BackupMetadata> _metadataBox;

  static bool _isInitialized = false;

  /// Initialize backup service
  static Future<void> initialize() async {
    if (_isInitialized) {
      
      return;
    }

    try {
      

      // Initialize Hive
      final appDir = await getApplicationDocumentsDirectory();
      Hive.init(appDir.path);

      // Register adapters
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BackupLogEntryAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(BackupMetadataAdapter());
      }

      // Open Hive boxes
      _troubleBox = await Hive.openBox<BackupLogEntry>('trouble_logs');
      _statusBox = await Hive.openBox<BackupLogEntry>('status_logs');
      _fireBox = await Hive.openBox<BackupLogEntry>('fire_logs');
      _connectionBox = await Hive.openBox<BackupLogEntry>('connection_logs');
      _metadataBox = await Hive.openBox<BackupMetadata>('backup_metadata');

      // Start daily backup timer
      _startDailyBackupTimer();

      _isInitialized = true;
      

      // Perform initial backup if needed
      await _checkAndPerformInitialBackup();

    } catch (e) {
      // Failed to initialize backup service
      print('Error: Failed to initialize daily backup service: $e');
      rethrow;
    }
  }

  /// Start daily backup timer
  static void _startDailyBackupTimer() {
    _backupTimer = Timer.periodic(_backupInterval, (timer) {
      
      _performDailyBackup();
    });
  }

  /// Check and perform initial backup if needed
  static Future<void> _checkAndPerformInitialBackup() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final metadata = _metadataBox.get(today);

    if (metadata == null) {
      
      await _performDailyBackup();
    } else {
      
    }
  }

  /// Perform daily backup
  static Future<void> _performDailyBackup() async {
    if (!_isInitialized) {
      
      return;
    }

    try {
      

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final backupStartTime = DateTime.now();

      // Note: This would need to be called from FirebaseLogHandler
      // For now, we'll implement the structure and methods
      final troubleCount = await _backupLogsFromBox('trouble', _troubleBox);
      final statusCount = await _backupLogsFromBox('status', _statusBox);
      final fireCount = await _backupLogsFromBox('fire', _fireBox);
      final connectionCount = await _backupLogsFromBox('connection', _connectionBox);

      // Update metadata
      final metadata = BackupMetadata()
        ..date = today
        ..troubleLogsCount = troubleCount
        ..statusLogsCount = statusCount
        ..fireLogsCount = fireCount
        ..connectionLogsCount = connectionCount
        ..lastBackupTime = backupStartTime
        ..isCompressed = false;

      await _metadataBox.put(today, metadata);

      // Clean up old backups
      await _cleanupOldBackups();

      final duration = DateTime.now().difference(backupStartTime);
      
      
      
      
      

    } catch (e) {
      
    }
  }

  /// Backup logs from Firebase to local storage
  static Future<int> _backupLogsFromBox(String logType, Box<BackupLogEntry> box) async {
    try {
      // Clear existing entries for today
      await box.clear();

      // Note: In real implementation, this would fetch from Firebase
      // For now, this is a placeholder structure
      

      return box.length;
    } catch (e) {
      // Failed to get backup count
      print('Warning: Failed to get backup count: $e');
      return 0;
    }
  }

  /// Save a single log to backup
  static Future<void> saveLog(String logType, Map<String, dynamic> logData) async {
    if (!_isInitialized) {
      
      return;
    }

    try {
      Box<BackupLogEntry> box;
      switch (logType.toLowerCase()) {
        case 'trouble':
          box = _troubleBox;
          break;
        case 'status':
          box = _statusBox;
          break;
        case 'fire':
          box = _fireBox;
          break;
        case 'connection':
          box = _connectionBox;
          break;
        default:
          throw Exception('Unknown log type: $logType');
      }

      final backupLog = BackupLogEntry()
        ..id = logData['id']?.toString()
        ..timestamp = logData['timestamp'] != null
            ? (logData['timestamp'] is int
                ? DateTime.fromMillisecondsSinceEpoch(logData['timestamp'])
                : DateTime.parse(logData['timestamp']))
            : null
        ..logType = logType
        ..date = logData['date']?.toString()
        ..time = logData['time']?.toString()
        ..address = logData['address']?.toString()
        ..zoneName = logData['zoneName']?.toString()
        ..status = logData['status']?.toString()
        ..information = logData['information']?.toString()
        ..user = logData['user']?.toString();

      await box.add(backupLog);
    } catch (e) {
      // Failed to save log to backup
      print('Warning: Failed to save log to backup: $e');
      // Continue without saving this log
    }
  }

  /// Load logs from local backup
  static Future<List<Map<String, dynamic>>> loadLogsFromBackup(
    String logType,
    String date, {
    bool useFirebaseFallback = true,
  }) async {
    if (!_isInitialized) {
      
      return [];
    }

    try {
      

      // Check local backup first
      Box<BackupLogEntry>? box;
      switch (logType) {
        case 'trouble':
          box = _troubleBox;
          break;
        case 'status':
          box = _statusBox;
          break;
        case 'fire':
          box = _fireBox;
          break;
        case 'connection':
          box = _connectionBox;
          break;
        default:
          throw Exception('Unknown log type: $logType');
      }

      
      // Filter by date
      final logs = box.values.where((log) {
        return log.date == date;
      }).toList();

      if (logs.isNotEmpty) {
        

        // Convert to Map format
        return logs.map((log) => {
          'id': log.id,
          'date': log.date,
          'time': log.time,
          'address': log.address,
          'zoneName': log.zoneName,
          'status': log.status,
          'information': log.information,
          'user': log.user,
          'timestamp': log.timestamp?.millisecondsSinceEpoch,
        }).toList();
      }

      // If no local data and fallback is enabled
      if (useFirebaseFallback && logs.isEmpty) {
        
        return [];
      }

      return [];
    } catch (e) {
      // Failed to load logs from backup
      print('Warning: Failed to load logs from backup: $e');
      return [];
    }
  }

  /// Check if backup exists for a specific date
  static Future<bool> hasBackupForDate(String date) async {
    if (!_isInitialized) return false;

    try {
      final metadata = _metadataBox.get(date);
      return metadata != null;
    } catch (e) {
      // Failed to check backup existence
      print('Warning: Failed to check backup existence for date $date: $e');
      return false;
    }
  }

  /// Get available backup dates
  static Future<List<String>> getAvailableBackupDates() async {
    if (!_isInitialized) return [];

    try {
      final allMetadata = _metadataBox.values.toList();
      final dates = allMetadata
          .where((metadata) => metadata.date != null)
          .map((metadata) => metadata.date!)
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort newest first

      return dates;
    } catch (e) {
      // Failed to get available backup dates
      print('Warning: Failed to get available backup dates: $e');
      return [];
    }
  }

  /// Get storage usage statistics
  static Future<Map<String, dynamic>> getStorageStats() async {
    if (!_isInitialized) return {};

    try {
      final appDir = await getApplicationDocumentsDirectory();

      final backupDir = Directory('${appDir.path}/$_backupBasePath');
      final archiveDir = Directory('${appDir.path}/$_archiveBasePath');

      int backupSize = 0;
      int archiveSize = 0;

      if (await backupDir.exists()) {
        final entities = backupDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            backupSize += await entity.length();
          }
        }
      }

      if (await archiveDir.exists()) {
        final entities = archiveDir.listSync(recursive: true);
        for (final entity in entities) {
          if (entity is File) {
            archiveSize += await entity.length();
          }
        }
      }

      final totalSize = backupSize + archiveSize;
      final availableDates = await getAvailableBackupDates();

      return {
        'backupSize': backupSize,
        'archiveSize': archiveSize,
        'totalSize': totalSize,
        'backupCount': availableDates.length,
        'availableDates': availableDates,
        'lastBackup': availableDates.isNotEmpty ? availableDates.first : null,
      };
    } catch (e) {
      // Failed to get storage usage statistics
      print('Warning: Failed to get storage usage statistics: $e');
      return {};
    }
    }
  }

  /// Clean up old backups (older than retention period)
  static Future<void> _cleanupOldBackups() async {
    try {


      final cutoffDate = DateTime.now().subtract(_retentionPeriod);
      final cutoffDateString = DateFormat('yyyy-MM-dd').format(cutoffDate);

      final allMetadata = _metadataBox.values.toList();

      for (final metadata in allMetadata) {
        if (metadata.date != null && metadata.date!.compareTo(cutoffDateString) < 0) {

          await _metadataBox.delete(metadata.date!);

          // Archive if recent enough (30-60 days)
          final metadataDate = DateFormat('yyyy-MM-dd').parse(metadata.date!);
          final daysOld = DateTime.now().difference(metadataDate).inDays;

          if (daysOld >= 30 && daysOld <= 60) {
            await _archiveBackup(metadata.date!);
          }
        }
      }
    } catch (e) {
      // Failed to cleanup old backups
      print('Warning: Failed to cleanup old backups: $e');
      // Continue without cleanup
    }
  }

  /// Archive backup to compressed format
  static Future<void> _archiveBackup(String date) async {
    try {


      // This would implement compression logic
      // For now, just log the intent

    } catch (e) {

    }
  }

  /// Manual backup trigger
  static Future<void> triggerManualBackup() async {

    await _performDailyBackup();
  }

  /// Dispose backup service
  static Future<void> dispose() async {
    if (!_isInitialized) return;

    try {
      _backupTimer?.cancel();
      _backupTimer = null;

      await _troubleBox.close();
      await _statusBox.close();
      await _fireBox.close();
      await _connectionBox.close();
      await _metadataBox.close();

      _isInitialized = false;

    } catch (e) {

    }
  }
}