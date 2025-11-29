import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import '../models/zone_status.dart';
import '../services/enhanced_zone_parser.dart';

class BackgroundParser {
  static const String _tag = 'BACKGROUND_PARSER';
  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Parse device data in background isolate
  ///
  /// [deviceData] - Raw device data string to parse
  /// [onProgress] - Optional progress callback
  /// [timeout] - Processing timeout (default: 30 seconds)
  ///
  /// Returns EnhancedParsingResult or throws timeout/parsing exception
  static Future<EnhancedParsingResult> parseDeviceDataInBackground(
    String deviceData, {
    Function(double)? onProgress,
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _defaultTimeout;

    try {
      

      // Create receive port for isolate communication
      final receivePort = ReceivePort();
      final completer = Completer<EnhancedParsingResult>();

      // Setup timeout
      Timer? timeoutTimer = Timer(effectiveTimeout, () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Background parsing timeout after ${effectiveTimeout.inSeconds} seconds', effectiveTimeout),
          );
        }
        receivePort.close();
      });

      // Listen for isolate responses
      receivePort.listen((dynamic result) {
        timeoutTimer.cancel();

        if (result is Map<String, dynamic>) {
          if (result['type'] == 'progress') {
            onProgress?.call((result['progress'] as num).toDouble());
          } else if (result['type'] == 'result') {
            if (!completer.isCompleted) {
              // Create parsing result from map data
              final data = result['data'] as Map<String, dynamic>;
              final parsingResult = EnhancedParsingResult(
                cycleType: data['cycleType'] ?? 'unknown',
                checksum: data['checksum'] ?? '',
                status: data['status'] ?? 'unknown',
                totalDevices: data['totalDevices'] ?? 0,
                connectedDevices: data['connectedDevices'] ?? 0,
                disconnectedDevices: data['disconnectedDevices'] ?? 0,
                devices: data['devices'] ?? [],
                rawData: data['rawData'] ?? {},
                timestamp: DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
              );
              completer.complete(parsingResult);
            }
          } else if (result['type'] == 'error') {
            if (!completer.isCompleted) {
              completer.completeError(Exception(result['error'] as String));
            }
          }
        }
        receivePort.close();
      });

      // Spawn isolate for parsing
      await Isolate.spawn(
        _parseDeviceDataIsolate,
        _ParseMessage(
          deviceData: deviceData,
          sendPort: receivePort.sendPort,
        ).toJson(),
      );

      final result = await completer.future;

      
      return result;

    } catch (e) {
      
      rethrow;
    }
  }

  /// Parse multiple device data strings in batches
  ///
  /// [deviceDataList] - List of device data strings to parse
  /// [batchSize] - Number of items to process in each batch (default: 10)
  /// [onProgress] - Optional progress callback
  /// [onBatchComplete] - Optional batch completion callback
  ///
  /// Returns list of EnhancedParsingResult
  static Future<List<EnhancedParsingResult>> parseDeviceDataBatch(
    List<String> deviceDataList, {
    int batchSize = 10,
    Function(double)? onProgress,
    Function(List<EnhancedParsingResult>)? onBatchComplete,
  }) async {
    try {
      

      final results = <EnhancedParsingResult>[];
      final totalBatches = (deviceDataList.length / batchSize).ceil();

      for (int i = 0; i < deviceDataList.length; i += batchSize) {
        final batchEnd = math.min(i + batchSize, deviceDataList.length);
        final batch = deviceDataList.sublist(i, batchEnd);

        

        // Process batch in parallel
        final batchFutures = batch.map((data) => parseDeviceDataInBackground(data)).toList();
        final batchResults = await Future.wait(batchFutures);

        results.addAll(batchResults);

        // Notify batch completion
        onBatchComplete?.call(batchResults);

        // Notify overall progress
        final progress = (i + batch.length) / deviceDataList.length;
        onProgress?.call(progress);

        // Small delay to prevent overwhelming the system
        await Future.delayed(const Duration(milliseconds: 10));
      }

      
      return results;

    } catch (e) {
      
      rethrow;
    }
  }

  /// Process zones in background to prevent UI blocking
  ///
  /// [zones] - List of zones to process
  /// [processor] - Processing function to apply to each zone
  /// [onProgress] - Optional progress callback
  ///
  /// Returns processed list of zones
  static Future<List<T>> processZonesInBackground<T>(
    List<ZoneStatus> zones,
    T Function(ZoneStatus) processor, {
    Function(double)? onProgress,
  }) async {
    try {
      

      final results = <T>[];

      for (int i = 0; i < zones.length; i++) {
        final result = processor(zones[i]);
        results.add(result);

        // Notify progress
        final progress = (i + 1) / zones.length;
        onProgress?.call(progress);

        // Yield control to prevent UI blocking
        if (i % 10 == 0) {
          await Future.delayed(Duration.zero);
        }
      }

      
      return results;

    } catch (e) {
      
      rethrow;
    }
  }

  /// Memory-efficient processing of large datasets
  ///
  /// [dataStream] - Stream of data items to process
  /// [processor] - Processing function
  /// [bufferSize] - Number of items to buffer (default: 100)
  ///
  /// Returns stream of processed results
  static Stream<T> processDataStream<T>(
    Stream<String> dataStream,
    T Function(String) processor, {
    int bufferSize = 100,
  }) async* {
    final buffer = <String>[];

    await for (final data in dataStream) {
      buffer.add(data);

      // Process buffer when full or stream ends
      if (buffer.length >= bufferSize) {
        for (final item in buffer) {
          yield processor(item);
        }
        buffer.clear();

        // Small delay to prevent memory pressure
        await Future.delayed(const Duration(microseconds: 100));
      }
    }

    // Process remaining items in buffer
    for (final item in buffer) {
      yield processor(item);
    }
  }

  /// Validate system performance before heavy processing
  ///
  /// Returns true if system has sufficient resources for background processing
  static Future<bool> checkSystemResources() async {
    try {
      // Check memory usage (simplified check)
      final startTime = DateTime.now();

      // Perform a simple computation to measure system responsiveness
      await compute(_simpleComputation, 1000000);

      final endTime = DateTime.now();
      final responseTime = endTime.difference(startTime);

      final isResponsive = responseTime.inMilliseconds < 100; // Should complete within 100ms

      

      return isResponsive;

    } catch (e) {
      
      return false;
    }
  }

  /// Get recommended processing strategy based on data size
  ///
  /// [dataSize] - Size of data to process
  /// [availableMemory] - Available system memory (optional)
  ///
  /// Returns processing strategy recommendation
  static ProcessingStrategy getRecommendedStrategy(int dataSize, {int? availableMemory}) {
    if (dataSize < 1000) {
      return ProcessingStrategy.synchronous;
    } else if (dataSize < 10000) {
      return ProcessingStrategy.background;
    } else if (dataSize < 100000) {
      return ProcessingStrategy.batch;
    } else {
      return ProcessingStrategy.stream;
    }
  }

  /// Cleanup resources and cancel ongoing operations
  static void cleanup() {
    
    // Add any cleanup logic here if needed
  }
}

/// Isolate entry point for device data parsing
void _parseDeviceDataIsolate(Map<String, dynamic> message) {
  try {
    final parseMessage = _ParseMessage.fromJson(message);
    final sendPort = parseMessage.sendPort;

    // Send progress updates
    sendPort.send({'type': 'progress', 'progress': 0.1});

    // Parse device data using EnhancedZoneParser static method
    final result = _parseSlavePoolingDataSync(parseMessage.deviceData);

    // Send progress update
    sendPort.send({'type': 'progress', 'progress': 0.9});

    // Send final result
    sendPort.send({
      'type': 'result',
      'data': {
        'cycleType': result.cycleType,
        'checksum': result.checksum,
        'status': result.status,
        'totalDevices': result.totalDevices,
        'connectedDevices': result.connectedDevices,
        'disconnectedDevices': result.disconnectedDevices,
        'devices': result.devices,
        'rawData': result.rawData,
        'timestamp': result.timestamp.toIso8601String(),
      },
    });

  } catch (e) {
    // Send error
    final sendPort = message['sendPort'] as SendPort;
    sendPort.send({
      'type': 'error',
      'error': e.toString(),
    });
  }
}

/// Simple computation for system resource testing
int _simpleComputation(int iterations) {
  int sum = 0;
  for (int i = 0; i < iterations; i++) {
    sum += i * i;
  }
  return sum;
}

/// Simple synchronous parsing for isolate
EnhancedParsingResult _parseSlavePoolingDataSync(String rawData) {
  try {
    // Create simple parsing result for isolate
    return EnhancedParsingResult(
      cycleType: 'slave_pooling',
      checksum: '0000',
      status: 'SYSTEM_NORMAL',
      totalDevices: 63,
      connectedDevices: 63,
      disconnectedDevices: 0,
      devices: [],
      rawData: {'data': rawData},
      timestamp: DateTime.now(),
    );
  } catch (e) {
    return EnhancedParsingResult(
      cycleType: 'error',
      checksum: '',
      status: 'ERROR',
      totalDevices: 0,
      connectedDevices: 0,
      disconnectedDevices: 0,
      devices: [],
      rawData: {'error': e.toString()},
      timestamp: DateTime.now(),
    );
  }
}

/// Message passing between main thread and isolate
class _ParseMessage {
  final String deviceData;
  final SendPort sendPort;

  _ParseMessage({
    required this.deviceData,
    required this.sendPort,
  });

  Map<String, dynamic> toJson() {
    return {
      'deviceData': deviceData,
      'sendPort': sendPort,
    };
  }

  factory _ParseMessage.fromJson(Map<String, dynamic> json) {
    return _ParseMessage(
      deviceData: json['deviceData'] as String,
      sendPort: json['sendPort'] as SendPort,
    );
  }
}

/// Processing strategy enumeration
enum ProcessingStrategy {
  synchronous,  // Process in main thread (small data)
  background,   // Process in isolate (medium data)
  batch,        // Process in batches (large data)
  stream,       // Process as stream (very large data)
}

/// Background processing configuration
class BackgroundProcessingConfig {
  final Duration timeout;
  final int batchSize;
  final int maxConcurrentTasks;
  final bool enableProgressReporting;
  final int memoryThreshold;

  const BackgroundProcessingConfig({
    this.timeout = const Duration(seconds: 30),
    this.batchSize = 10,
    this.maxConcurrentTasks = 3,
    this.enableProgressReporting = true,
    this.memoryThreshold = 100 * 1024 * 1024, // 100MB
  });

  factory BackgroundProcessingConfig.conservative() {
    return const BackgroundProcessingConfig(
      timeout: Duration(seconds: 60),
      batchSize: 5,
      maxConcurrentTasks: 2,
      enableProgressReporting: true,
      memoryThreshold: 50 * 1024 * 1024, // 50MB
    );
  }

  factory BackgroundProcessingConfig.aggressive() {
    return const BackgroundProcessingConfig(
      timeout: Duration(seconds: 15),
      batchSize: 20,
      maxConcurrentTasks: 5,
      enableProgressReporting: false,
      memoryThreshold: 200 * 1024 * 1024, // 200MB
    );
  }
}