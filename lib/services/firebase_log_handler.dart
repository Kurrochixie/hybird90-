import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';

class FirebaseLogHandler extends ChangeNotifier {
  final DatabaseReference _databaseRef;
  StreamSubscription<DatabaseEvent>? _statusSubscription;
  StreamSubscription<DatabaseEvent>? _connectionSubscription;
  StreamSubscription<DatabaseEvent>? _troubleSubscription;
  StreamSubscription<DatabaseEvent>? _fireSubscription;

  List<Map<String, dynamic>> _statusLogs = [];
  List<Map<String, dynamic>> _connectionLogs = [];
  List<Map<String, dynamic>> _troubleLogs = [];
  List<Map<String, dynamic>> _fireLogs = [];

  bool _isLoading = false;
  bool _isLoadingMoreTrouble = false;
  bool _hasMoreTroubleLogs = true;
  String? _errorMessage;

  FirebaseLogHandler() : _databaseRef = FirebaseDatabase.instance.ref() {
    _initializeLogListeners();
  }

  // Getters
  List<Map<String, dynamic>> get statusLogs => _statusLogs;
  List<Map<String, dynamic>> get connectionLogs => _connectionLogs;
  List<Map<String, dynamic>> get troubleLogs => _troubleLogs;
  List<Map<String, dynamic>> get fireLogs => _fireLogs;
  bool get isLoading => _isLoading;
  bool get isLoadingMoreTrouble => _isLoadingMoreTrouble;
  bool get hasMoreTroubleLogs => _hasMoreTroubleLogs;
  String? get errorMessage => _errorMessage;

  void _initializeLogListeners() {
    _isLoading = true;
    notifyListeners();

    // Initialize listeners for all 4 log types
    _initializeStatusLogs();
    _initializeConnectionLogs();
    _initializeTroubleLogs();
    _initializeFireLogs();
  }

  void _initializeStatusLogs() {
    _statusSubscription = _databaseRef
        .child('history/statusLogs')
        .orderByChild('timestamp')
        .limitToLast(100) // Get last 100 entries for performance
        .onValue
        .listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _statusLogs = [];
          for (final entry in data.entries) {
            try {
              final log = _parseStatusLog(entry.key, entry.value);
              if (_isWithinLast7Days(log['timestamp'])) {
                _statusLogs.add(log);
              }
            } catch (e) {
              
            }
          }
          _statusLogs = _statusLogs.reversed.toList();
        } else {
          _statusLogs = [];
        }
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Error loading status logs: $e';
        
      }
      _isLoading = false;
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Connection error: $error';
      _isLoading = false;
      notifyListeners();
    });
  }

  void _initializeConnectionLogs() {
    _connectionSubscription = _databaseRef
        .child('history/connectionLogs')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _connectionLogs = [];
          for (final entry in data.entries) {
            try {
              final log = _parseConnectionLog(entry.key, entry.value);
              if (_isWithinLast7Days(log['timestamp'])) {
                _connectionLogs.add(log);
              }
            } catch (e) {
              
            }
          }
          _connectionLogs = _connectionLogs.reversed.toList();
        } else {
          _connectionLogs = [];
        }
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Error loading connection logs: $e';
        
      }
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Connection error: $error';
      notifyListeners();
    });
  }

  void _initializeTroubleLogs() {
    _troubleSubscription = _databaseRef
        .child('history/troubleLogs')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _troubleLogs = [];
          for (final entry in data.entries) {
            try {
              final log = _parseTroubleLog(entry.key, entry.value);
              if (_isWithinLast7Days(log['timestamp'])) {
                _troubleLogs.add(log);
              }
            } catch (e) {
              
            }
          }
          _troubleLogs = _troubleLogs.reversed.toList();
        } else {
          _troubleLogs = [];
        }
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Error loading trouble logs: $e';
        
      }
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Connection error: $error';
      notifyListeners();
    });
  }

  void _initializeFireLogs() {
    _fireSubscription = _databaseRef
        .child('history/fireLogs')
        .orderByChild('timestamp')
        .limitToLast(100)
        .onValue
        .listen((event) {
      try {
        final data = event.snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          _fireLogs = [];
          for (final entry in data.entries) {
            try {
              final log = _parseFireLog(entry.key, entry.value);
              if (_isWithinLast7Days(log['timestamp'])) {
                _fireLogs.add(log);
              }
            } catch (e) {
              
            }
          }
          _fireLogs = _fireLogs.reversed.toList();
        } else {
          _fireLogs = [];
        }
        _errorMessage = null;
      } catch (e) {
        _errorMessage = 'Error loading fire logs: $e';
        
      }
      notifyListeners();
    }, onError: (error) {
      _errorMessage = 'Connection error: $error';
      notifyListeners();
    });
  }

  // Parse methods for different log types
  Map<String, dynamic> _parseStatusLog(String key, dynamic value) {
    try {
      final log = Map<String, dynamic>.from(value as Map);
      return {
        'id': key,
        'date': log['date'] ?? '',
        'time': log['time'] ?? '',
        'status': log['status'] ?? '',
        'user': log['user'] ?? 'system',
        'timestamp': log['timestamp'] ?? 0,
      };
    } catch (e) {
      
      // Return a default log structure that will be filtered out
      return {
        'id': key,
        'date': '',
        'time': '',
        'status': '',
        'user': 'system',
        'timestamp': null, // This will be filtered out by _isWithinLast7Days
      };
    }
  }

  Map<String, dynamic> _parseConnectionLog(String key, dynamic value) {
    try {
      final log = Map<String, dynamic>.from(value as Map);
      return {
        'id': key,
        'date': log['date'] ?? '',
        'time': log['time'] ?? '',
        'information': log['information'] ?? '',
        'timestamp': log['timestamp'] ?? 0,
      };
    } catch (e) {
      
      return {
        'id': key,
        'date': '',
        'time': '',
        'information': '',
        'timestamp': null,
      };
    }
  }

  Map<String, dynamic> _parseTroubleLog(String key, dynamic value) {
    try {
      final log = Map<String, dynamic>.from(value as Map);
      return {
        'id': key,
        'date': log['date'] ?? '',
        'time': log['time'] ?? '',
        'address': log['address'] ?? '',
        'zoneName': log['zoneName'] ?? '',
        'status': log['status'] ?? '',
        'timestamp': log['timestamp'] ?? 0,
      };
    } catch (e) {
      
      return {
        'id': key,
        'date': '',
        'time': '',
        'address': '',
        'zoneName': '',
        'status': '',
        'timestamp': null,
      };
    }
  }

  Map<String, dynamic> _parseFireLog(String key, dynamic value) {
    try {
      final log = Map<String, dynamic>.from(value as Map);
      return {
        'id': key,
        'date': log['date'] ?? '',
        'time': log['time'] ?? '',
        'address': log['address'] ?? '',
        'zoneName': log['zoneName'] ?? '',
        'status': log['status'] ?? '',
        'timestamp': log['timestamp'] ?? 0,
      };
    } catch (e) {
      
      return {
        'id': key,
        'date': '',
        'time': '',
        'address': '',
        'zoneName': '',
        'status': '',
        'timestamp': null,
      };
    }
  }

  // Check if log is within last 7 days
  bool _isWithinLast7Days(dynamic timestamp) {
    try {
      final now = DateTime.now();
      int ts;

      if (timestamp == null) {
        return false;
      } else if (timestamp is String) {
        // Handle both String and double formats
        final cleanTs = timestamp.replaceAll(RegExp(r'[^\d]'), '');
        if (cleanTs.isEmpty) return false;
        ts = int.parse(cleanTs);
      } else if (timestamp is int) {
        ts = timestamp;
      } else if (timestamp is double) {
        ts = timestamp.toInt();
      } else {
        // Invalid timestamp format, exclude
        
        return false;
      }

      // Validate timestamp range (between 2000 and 2030)
      final year = DateTime.fromMillisecondsSinceEpoch(ts).year;
      if (year < 2000 || year > 2030) {
        
        return false;
      }

      final logDate = DateTime.fromMillisecondsSinceEpoch(ts);
      final difference = now.difference(logDate);
      return difference.inDays <= 7;
    } catch (e) {
      // If timestamp parsing fails, exclude the log
      
      return false;
    }
  }

  // Method to add new logs (called by ESP/Master data capture)
  Future<void> addStatusLog({
    required String status,
    String user = 'system',
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final date = DateFormat('dd/MM/yyyy').format(now);
      final time = DateFormat('HH:mm').format(now);

      final logData = {
        'date': date,
        'time': time,
        'status': status,
        'user': user,
        'timestamp': timestamp,
      };

      await _databaseRef.child('history/statusLogs').push().set(logData);
    } catch (e) {
      
    }
  }

  Future<void> addConnectionLog({
    required String information,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final date = DateFormat('dd/MM/yyyy').format(now);
      final time = DateFormat('HH:mm').format(now);

      final logData = {
        'date': date,
        'time': time,
        'information': information,
        'timestamp': timestamp,
      };

      await _databaseRef.child('history/connectionLogs').push().set(logData);
    } catch (e) {
      
    }
  }

  Future<void> addTroubleLog({
    required String address,
    required String zoneName,
    required String status,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final date = DateFormat('dd/MM/yyyy').format(now);
      final time = DateFormat('HH:mm').format(now);

      final logData = {
        'date': date,
        'time': time,
        'address': address,
        'zoneName': zoneName,
        'status': status,
        'timestamp': timestamp,
      };

      await _databaseRef.child('history/troubleLogs').push().set(logData);
    } catch (e) {
      
    }
  }

  Future<void> addFireLog({
    required String address,
    required String zoneName,
    required String status,
  }) async {
    try {
      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;
      final date = DateFormat('dd/MM/yyyy').format(now);
      final time = DateFormat('HH:mm').format(now);

      final logData = {
        'date': date,
        'time': time,
        'address': address,
        'zoneName': zoneName,
        'status': status,
        'timestamp': timestamp,
      };

      await _databaseRef.child('history/fireLogs').push().set(logData);
    } catch (e) {
      
    }
  }

  // Cleanup old logs (older than 7 days) - can be called periodically
  Future<void> cleanupOldLogs() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch;

      // Cleanup each log type
      await _cleanupLogType('history/statusLogs', cutoffTimestamp);
      await _cleanupLogType('history/connectionLogs', cutoffTimestamp);
      await _cleanupLogType('history/troubleLogs', cutoffTimestamp);
      await _cleanupLogType('history/fireLogs', cutoffTimestamp);
    } catch (e) {
      
    }
  }

  Future<void> _cleanupLogType(String path, int cutoffTimestamp) async {
    final snapshot = await _databaseRef.child(path).orderByChild('timestamp').endAt(cutoffTimestamp).once();
    final data = snapshot.snapshot.value as Map<dynamic, dynamic>?;

    if (data != null) {
      for (final entry in data.entries) {
        await _databaseRef.child('$path/${entry.key}').remove();
      }
    }
  }

  // Refresh all logs manually
  Future<void> refreshLogs() async {
    _errorMessage = null;
    await cleanupOldLogs();
    // The streams will automatically update after cleanup
  }

  /// Refresh trouble logs specifically
  Future<void> refreshTroubleLogs() async {
    _isLoading = true;
    notifyListeners();

    try {
      _initializeTroubleLogs();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to refresh trouble logs: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more trouble logs (pagination)
  Future<void> loadMoreTroubleLogs() async {
    if (_isLoadingMoreTrouble || !_hasMoreTroubleLogs) return;

    _isLoadingMoreTrouble = true;
    notifyListeners();

    try {
      // Get current oldest timestamp
      final oldestTimestamp = _troubleLogs.isNotEmpty
          ? _troubleLogs.first['timestamp'] as String
          : DateTime.now().toIso8601String();

      // Query for more logs
      final snapshot = await _databaseRef
          .child('history/troubleLogs')
          .orderByChild('timestamp')
          .endAt(oldestTimestamp)
          .limitToFirst(50) // Load 50 more
          .get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final newLogs = <Map<String, dynamic>>[];
          data.forEach((key, value) {
            if (value is Map) {
              newLogs.add(Map<String, dynamic>.from(value));
            }
          });

          if (newLogs.length < 50) {
            _hasMoreTroubleLogs = false;
          }

          _troubleLogs.insertAll(0, newLogs);
        }
      } else {
        _hasMoreTroubleLogs = false;
      }

      _isLoadingMoreTrouble = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load more trouble logs: $e';
      _isLoadingMoreTrouble = false;
      notifyListeners();
    }
  }

  /// Simple method to add trouble log (for ZoneStateTracker)
  Future<void> addTroubleLogSimple({
    required String zone,
    required String status,
    required String user,
    String? details,
  }) async {
    try {
      final logEntry = {
        'zone': zone,
        'status': status,
        'user': user,
        'details': details ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _databaseRef
          .child('history/troubleLogs')
          .push()
          .set(logEntry);
    } catch (e) {
      
    }
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _connectionSubscription?.cancel();
    _troubleSubscription?.cancel();
    _fireSubscription?.cancel();
    super.dispose();
  }
}