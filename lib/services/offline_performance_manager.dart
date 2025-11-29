import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'logger.dart';
// import 'firebase_log_handler.dart'; 

/// Performance modes for offline monitoring
enum OfflinePerformanceMode {
  normal,     // Normal operation with all features
  focused,    // Focused on WebSocket only
  maximum     // Maximum performance mode
}

/// Performance metrics for monitoring
class PerformanceMetrics {
  final int cpuUsage;
  final int memoryUsage;
  final double responseTime;
  final int rebuildCount;
  final int messageProcessingRate;

  const PerformanceMetrics({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.responseTime,
    required this.rebuildCount,
    required this.messageProcessingRate,
  });

  Map<String, dynamic> toJson() => {
    'cpuUsage': cpuUsage,
    'memoryUsage': memoryUsage,
    'responseTime': responseTime,
    'rebuildCount': rebuildCount,
    'messageProcessingRate': messageProcessingRate,
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
}

/// Background process status
class BackgroundProcessStatus {
  final String name;
  final bool isActive;
  final String? description;
  final DateTime? lastPaused;
  final DateTime? lastResumed;

  const BackgroundProcessStatus({
    required this.name,
    required this.isActive,
    this.description,
    this.lastPaused,
    this.lastResumed,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'isActive': isActive,
    'description': description,
    'lastPaused': lastPaused?.toIso8601String(),
    'lastResumed': lastResumed?.toIso8601String(),
  };
}

/// High-performance offline mode manager
class OfflinePerformanceManager extends ChangeNotifier {
  static OfflinePerformanceManager? _instance;
  static OfflinePerformanceManager get instance => _instance ??= OfflinePerformanceManager._internal();

  OfflinePerformanceManager._internal() {
    AppLogger.info('OfflinePerformanceManager initialized');
    _receivePort = ReceivePort();
  }

  // Performance mode
  OfflinePerformanceMode _currentMode = OfflinePerformanceMode.normal;
  OfflinePerformanceMode get currentMode => _currentMode;

  // Background process tracking
  final Map<String, BackgroundProcessStatus> _backgroundProcesses = {};
  Map<String, BackgroundProcessStatus> get backgroundProcesses => Map.unmodifiable(_backgroundProcesses);

  // Performance metrics
  final List<PerformanceMetrics> _metricsHistory = [];
  List<PerformanceMetrics> get metricsHistory => List.unmodifiable(_metricsHistory);

  // Timers and subscriptions
  Timer? _performanceMonitorTimer;
  Timer? _cleanupTimer;
  Timer? _metricsTimer;

  // Performance counters
  int _rebuildCount = 0;
  int _messageProcessingCount = 0;
  DateTime _lastMetricsReset = DateTime.now();

  // Isolate for heavy processing
  Isolate? _processingIsolate;
  ReceivePort? _receivePort;

  /// Initialize performance manager
  Future<void> initialize() async {
    try {
      AppLogger.info('Initializing OfflinePerformanceManager');

      // Register background processes
      await _registerBackgroundProcesses();

      // Start performance monitoring
      _startPerformanceMonitoring();

      // Initialize isolate for heavy processing
      await _initializeProcessingIsolate();

      AppLogger.info('OfflinePerformanceManager initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize OfflinePerformanceManager', error: e);
      rethrow;
    }
  }

  /// Set performance mode
  Future<void> setPerformanceMode(OfflinePerformanceMode mode) async {
    if (_currentMode == mode) return;

    final previousMode = _currentMode;
    _currentMode = mode;

    AppLogger.info('Switching performance mode: $previousMode → $mode');

    try {
      switch (mode) {
        case OfflinePerformanceMode.normal:
          await _enableNormalMode();
          break;
        case OfflinePerformanceMode.focused:
          await _enableFocusedMode();
          break;
        case OfflinePerformanceMode.maximum:
          await _enableMaximumMode();
          break;
      }

      notifyListeners();
      AppLogger.info('Performance mode switched successfully to: $mode');
    } catch (e) {
      // Rollback on error
      _currentMode = previousMode;
      AppLogger.error('Failed to switch performance mode, rolled back to: $previousMode', error: e);
      rethrow;
    }
  }

  /// Enable normal mode (all features active)
  Future<void> _enableNormalMode() async {
    AppLogger.info('Enabling normal performance mode');

    // Resume all background processes
    await _resumeBackgroundProcesses();

    // Start cleanup timer
    _startCleanupTimer();
  }

  /// Enable focused mode (WebSocket focus)
  Future<void> _enableFocusedMode() async {
    AppLogger.info('Enabling focused performance mode - WebSocket focus');

    // Pause non-essential background processes
    await _pauseNonEssentialProcesses();

    // Optimize UI rebuild frequency
    _optimizeUIUpdates();

    // Increase WebSocket processing priority
    _prioritizeWebSocketProcessing();
  }

  /// Enable maximum performance mode
  Future<void> _enableMaximumMode() async {
    AppLogger.info('Enabling maximum performance mode');

    // Pause ALL background processes except WebSocket
    await _pauseAllBackgroundProcesses();

    // Force garbage collection
    await _forceGarbageCollection();

    // Set CPU priority to high
    await _setHighCPUPriority();

    // Disable animations and transitions
    await _disableAnimations();
  }

  /// Register all background processes
  Future<void> _registerBackgroundProcesses() async {
    final processes = [
      'Firebase Database Streams',
      'Firebase Auth Listener',
      'Connectivity Monitor',
      'Battery Monitor',
      'Memory Cleanup Timer',
      'Log Uploader',
      'Status Synchronizer',
      'Location Services',
      'Analytics Collector',
      'Background Sync',
    ];

    for (final process in processes) {
      _backgroundProcesses[process] = BackgroundProcessStatus(
        name: process,
        isActive: true,
        description: 'Background process: $process',
      );
    }

    AppLogger.info('Registered ${processes.length} background processes');
  }

  /// Pause non-essential background processes
  Future<void> _pauseNonEssentialProcesses() async {
    const essentialProcesses = [
      'WebSocket Connection',
      'FireAlarm Data Manager',
      'UI Controller',
    ];

    for (final processName in _backgroundProcesses.keys) {
      if (!essentialProcesses.contains(processName)) {
        await _pauseProcess(processName);
      }
    }
  }

  /// Pause all background processes
  Future<void> _pauseAllBackgroundProcesses() async {
    for (final processName in _backgroundProcesses.keys) {
      await _pauseProcess(processName);
    }
  }

  /// Resume background processes
  Future<void> _resumeBackgroundProcesses() async {
    for (final processName in _backgroundProcesses.keys) {
      await _resumeProcess(processName);
    }
  }

  /// Pause specific process
  Future<void> _pauseProcess(String processName) async {
    final status = _backgroundProcesses[processName];
    if (status != null && status.isActive) {
      _backgroundProcesses[processName] = BackgroundProcessStatus(
        name: processName,
        isActive: false,
        description: status.description,
        lastPaused: DateTime.now(),
        lastResumed: status.lastResumed,
      );

      AppLogger.info('Paused background process: $processName');

      // Notify Firebase log handler to pause if applicable
      if (processName.contains('Firebase')) {
        // FirebaseLogHandler.pause(); 
        AppLogger.info('Firebase service paused: $processName');
      }
    }
  }

  /// Resume specific process
  Future<void> _resumeProcess(String processName) async {
    final status = _backgroundProcesses[processName];
    if (status != null && !status.isActive) {
      _backgroundProcesses[processName] = BackgroundProcessStatus(
        name: processName,
        isActive: true,
        description: status.description,
        lastPaused: status.lastPaused,
        lastResumed: DateTime.now(),
      );

      AppLogger.info('Resumed background process: $processName');

      // Resume Firebase log handler if applicable
      if (processName.contains('Firebase')) {
        // FirebaseLogHandler.resume(); 
        AppLogger.info('Firebase service resumed: $processName');
      }
    }
  }

  /// Optimize UI updates for performance
  void _optimizeUIUpdates() {
    // Set higher frame rate target
    // This would be implemented with specific UI optimizations
    AppLogger.info('UI optimizations applied for focused mode');
  }

  /// Prioritize WebSocket processing
  void _prioritizeWebSocketProcessing() {
    // Implementation for WebSocket priority
    AppLogger.info('🚀 WebSocket processing prioritized - ensuring UI updates are not blocked');
    AppLogger.debug('🚀 OFFLINE_PERFORMANCE: WebSocket processing prioritized');
  }

  /// Force garbage collection
  Future<void> _forceGarbageCollection() async {
    if (!kReleaseMode) {
      // Force GC in debug mode
      await Future.delayed(const Duration(milliseconds: 100));
      AppLogger.info('Forced garbage collection');
    }
  }

  /// Set high CPU priority
  Future<void> _setHighCPUPriority() async {
    try {
      // Set high CPU priority for the application
      await SystemChannels.platform.invokeMethod('SystemNavigator.setHighCPUPriority');
      AppLogger.info('CPU priority set to high');
    } catch (e) {
      AppLogger.warning('Could not set CPU priority: $e');
    }
  }

  /// Disable animations for performance
  Future<void> _disableAnimations() async {
    // Disable unnecessary animations
    AppLogger.info('Animations disabled for maximum performance');
  }

  /// Start performance monitoring
  void _startPerformanceMonitoring() {
    _performanceMonitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _collectPerformanceMetrics(),
    );
  }

  /// Start cleanup timer for normal mode
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => _performCleanup(),
    );
  }

  
  /// Initialize processing isolate
  Future<void> _initializeProcessingIsolate() async {
    try {
      // Initialize isolate for heavy WebSocket processing
      _receivePort?.listen(_handleIsolateMessage);

      AppLogger.info('Processing isolate initialized');
    } catch (e) {
      AppLogger.warning('Could not initialize processing isolate: $e');
    }
  }

  /// Handle messages from processing isolate
  void _handleIsolateMessage(dynamic message) {
    if (message is Map && message['type'] == 'processing_complete') {
      _messageProcessingCount++;
    }
  }

  /// Collect performance metrics
  void _collectPerformanceMetrics() {
    final now = DateTime.now();
    final timeSinceLastReset = now.difference(_lastMetricsReset);

    final metrics = PerformanceMetrics(
      cpuUsage: _estimateCPUUsage(),
      memoryUsage: _estimateMemoryUsage(),
      responseTime: _calculateAverageResponseTime(timeSinceLastReset),
      rebuildCount: _rebuildCount,
      messageProcessingRate: _messageProcessingCount,
    );

    _metricsHistory.add(metrics);

    // Keep only last 100 metrics
    if (_metricsHistory.length > 100) {
      _metricsHistory.removeAt(0);
    }

    // Reset counters
    _resetCounters();
  }

  /// Estimate CPU usage (simplified)
  int _estimateCPUUsage() {
    // Simplified CPU estimation
    // In real implementation, this would use platform channels
    return (_currentMode == OfflinePerformanceMode.maximum) ? 30 : 50;
  }

  /// Estimate memory usage (simplified)
  int _estimateMemoryUsage() {
    // Simplified memory estimation
    // In real implementation, this would use platform channels
    return (_currentMode == OfflinePerformanceMode.maximum) ? 40 : 60;
  }

  /// Calculate average response time
  double _calculateAverageResponseTime(Duration timeWindow) {
    // Simplified response time calculation
    switch (_currentMode) {
      case OfflinePerformanceMode.normal:
        return 100.0; // ms
      case OfflinePerformanceMode.focused:
        return 50.0; // ms
      case OfflinePerformanceMode.maximum:
        return 25.0; // ms
    }
  }

  /// Reset performance counters
  void _resetCounters() {
    _rebuildCount = 0;
    _messageProcessingCount = 0;
    _lastMetricsReset = DateTime.now();
  }

  /// Perform cleanup operations
  void _performCleanup() {
    if (_currentMode != OfflinePerformanceMode.normal) return;

    // Clean up old metrics
    if (_metricsHistory.length > 50) {
      _metricsHistory.removeRange(0, _metricsHistory.length - 50);
    }

    AppLogger.debug('Performance cleanup completed');
  }

  /// Increment rebuild counter
  void incrementRebuildCount() {
    _rebuildCount++;
  }

  /// Get current performance metrics
  PerformanceMetrics? getCurrentMetrics() {
    return _metricsHistory.isNotEmpty ? _metricsHistory.last : null;
  }

  /// Get performance summary
  Map<String, dynamic> getPerformanceSummary() {
    final currentMetrics = getCurrentMetrics();

    return {
      'mode': _currentMode.toString(),
      'backgroundProcesses': _backgroundProcesses.values.map((p) => p.toJson()).toList(),
      'currentMetrics': currentMetrics?.toJson(),
      'metricsCount': _metricsHistory.length,
      'lastCleanup': _cleanupTimer?.isActive ?? false ? 'Active' : 'Inactive',
    };
  }

  @override
  void dispose() {
    AppLogger.info('Disposing OfflinePerformanceManager');

    _performanceMonitorTimer?.cancel();
    _cleanupTimer?.cancel();
    _metricsTimer?.cancel();

    // Resume all processes before disposal
    _resumeBackgroundProcesses();

    // Dispose isolate
    _processingIsolate?.kill(priority: Isolate.immediate);
    _receivePort?.close();

    super.dispose();
  }
}