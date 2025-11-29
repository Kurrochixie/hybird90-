import 'dart:async';
import 'dart:collection';

class MemoryManager {
  static const String _tag = 'MEMORY_MANAGER';
  static const Duration _defaultCleanupInterval = Duration(minutes: 5);
  static const int _defaultMaxCacheSize = 1000;
  static const int _defaultMaxMemoryUsage = 100 * 1024 * 1024; // 100MB

  static Timer? _cleanupTimer;
  static final Map<String, LruCache> _caches = {};
  static final List<WeakReference> _trackedObjects = [];
  static int _currentMemoryUsage = 0;
  static bool _isInitialized = false;

  /// Initialize memory manager with automatic cleanup
  ///
  /// [cleanupInterval] - Interval for automatic cleanup (default: 5 minutes)
  /// [maxMemoryUsage] - Maximum memory usage before forced cleanup (default: 100MB)
  static void initialize({
    Duration? cleanupInterval,
    int? maxMemoryUsage,
  }) {
    if (_isInitialized) {
      
      return;
    }

    _cleanupTimer = Timer.periodic(
      cleanupInterval ?? _defaultCleanupInterval,
      (_) => performCleanup(),
    );

    _isInitialized = true;
    
  }

  /// Create or get a named LRU cache
  ///
  /// [name] - Cache name for identification
  /// [maxSize] - Maximum number of items in cache
  /// [maxAge] - Maximum age for cache items
  ///
  /// Returns LRU cache instance
  static LruCache<T> getCache<T>(String name, {int? maxSize, Duration? maxAge}) {
    if (_caches.containsKey(name)) {
      return _caches[name]! as LruCache<T>;
    }

    final cache = LruCache<T>(
      maxSize: maxSize ?? _defaultMaxCacheSize,
      maxAge: maxAge,
      onEvict: (key, value) {
        _currentMemoryUsage -= _estimateObjectSize(value);
        
      },
    );

    _caches[name] = cache;
    
    return cache;
  }

  /// Track an object for automatic cleanup
  ///
  /// [object] - Object to track
  ///
  /// Returns weak reference to tracked object
  static WeakReference<T> trackObject<T>(T object) {
    final weakRef = WeakReference<T>(object);
    _trackedObjects.add(weakRef);
    return weakRef;
  }

  /// Add memory usage for tracking
  ///
  /// [bytes] - Number of bytes added
  static void addMemoryUsage(int bytes) {
    _currentMemoryUsage += bytes;
    

    // Trigger cleanup if memory usage exceeds threshold
    if (_currentMemoryUsage > _defaultMaxMemoryUsage) {
      
      performCleanup();
    }
  }

  /// Remove memory usage for tracking
  ///
  /// [bytes] - Number of bytes removed
  static void removeMemoryUsage(int bytes) {
    _currentMemoryUsage = _currentMemoryUsage - bytes < 0 ? 0 : _currentMemoryUsage - bytes;
    
  }

  /// Perform manual cleanup of caches and tracked objects
  ///
  /// [force] - Force cleanup even if not needed
  ///
  /// Returns cleanup statistics
  static CleanupStats performCleanup({bool force = false}) {
    final startTime = DateTime.now();
    final stats = CleanupStats();

    try {
      

      // Cleanup caches
      for (final entry in _caches.entries) {
        final cacheName = entry.key;
        final cache = entry.value;

        final beforeSize = cache.size;
        cache.cleanup();
        final afterSize = cache.size;

        final cleanedItems = beforeSize - afterSize;
        stats.cachesCleaned++;
        stats.itemsRemoved += cleanedItems;

        if (cleanedItems > 0) {
          
        }
      }

      // Cleanup weak references
      final initialTrackedCount = _trackedObjects.length;
      _trackedObjects.removeWhere((ref) => ref.target == null);
      final finalTrackedCount = _trackedObjects.length;
      final garbageCollected = initialTrackedCount - finalTrackedCount;

      stats.objectsGarbageCollected = garbageCollected;

      if (garbageCollected > 0) {
        
      }

      // Force garbage collection if needed
      if (force || _currentMemoryUsage > _defaultMaxMemoryUsage) {
        // Note: Dart doesn't have explicit garbage collection trigger
        // But we can suggest it by creating and discarding objects
        _suggestGarbageCollection();
        stats.forcedGarbageCollection = true;
      }

      final endTime = DateTime.now();
      stats.duration = endTime.difference(startTime);
      stats.memoryUsageBefore = _currentMemoryUsage;

      // Estimate memory usage after cleanup
      _currentMemoryUsage = _estimateCurrentMemoryUsage();
      stats.memoryUsageAfter = _currentMemoryUsage;

      
      
      
      
      

    } catch (e) {
      // Memory cleanup operation failed
      print('Warning: Memory cleanup operation failed: $e');
      // Continue with current memory state
    }

    return stats;
  }

  /// Get current memory usage statistics
  ///
  /// Returns memory usage report
  static MemoryUsageReport getMemoryUsage() {
    final cacheStats = <String, CacheStats>{};

    for (final entry in _caches.entries) {
      final cache = entry.value;
      cacheStats[entry.key] = CacheStats(
        size: cache.size,
        maxSize: cache.maxSize,
        hitCount: cache.hitCount,
        missCount: cache.missCount,
        evictionCount: cache.evictionCount,
      );
    }

    return MemoryUsageReport(
      currentMemoryUsage: _currentMemoryUsage,
      maxMemoryUsage: _defaultMaxMemoryUsage,
      trackedObjects: _trackedObjects.length,
      activeCaches: _caches.length,
      cacheStats: cacheStats,
      timestamp: DateTime.now(),
    );
  }

  /// Clear specific cache
  ///
  /// [name] - Cache name to clear
  static void clearCache(String name) {
    if (_caches.containsKey(name)) {
      final cache = _caches[name]!;
      final size = cache.size;
      cache.clear();
      
    }
  }

  /// Clear all caches
  static void clearAllCaches() {
    int totalItems = 0;
    for (final cache in _caches.values) {
      totalItems += cache.size;
      cache.clear();
    }
    
  }

  /// Dispose memory manager and cleanup resources
  static void dispose() {
    if (!_isInitialized) {
      return;
    }

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    // Clear all caches
    clearAllCaches();
    _caches.clear();

    // Clear tracked objects
    _trackedObjects.clear();

    _currentMemoryUsage = 0;
    _isInitialized = false;

    
  }

  /// Estimate object size in bytes (rough approximation)
  static int _estimateObjectSize(dynamic object) {
    if (object == null) return 0;
    if (object is String) return object.length * 2; // UTF-16
    if (object is List) return object.length * 8; // Approximate
    if (object is Map) return object.length * 16; // Approximate
    return 64; // Default approximation
  }

  /// Estimate current memory usage based on caches and tracked objects
  static int _estimateCurrentMemoryUsage() {
    int totalUsage = 0;

    // Estimate cache usage
    for (final cache in _caches.values) {
      totalUsage += cache.size * 64; // Rough estimate
    }

    // Add tracked objects estimate
    totalUsage += _trackedObjects.length * 32;

    return totalUsage;
  }

  /// Suggest garbage collection to Dart VM
  static void _suggestGarbageCollection() {
    // Create and discard temporary objects to suggest GC
    final temp = List.generate(1000, (i) => i.toString());
    temp.clear();
  }
}

/// LRU (Least Recently Used) Cache implementation
class LruCache<T> {
  final int maxSize;
  final Duration? maxAge;
  final LinkedHashMap<String, _CacheEntry<T>> _storage;
  final Function(String, T)? onEvict;

  int _hitCount = 0;
  int _missCount = 0;
  int _evictionCount = 0;

  LruCache({
    required this.maxSize,
    this.maxAge,
    this.onEvict,
  }) : _storage = LinkedHashMap<String, _CacheEntry<T>>();

  /// Get value from cache
  T? get(String key) {
    final entry = _storage.remove(key);
    if (entry != null) {
      // Check if entry has expired
      if (maxAge != null && DateTime.now().difference(entry.timestamp) > maxAge!) {
        _evictionCount++;
        onEvict?.call(key, entry.value);
        return null;
      }

      // Move to end (most recently used)
      _storage[key] = entry;
      _hitCount++;
      return entry.value;
    }

    _missCount++;
    return null;
  }

  /// Put value in cache
  void put(String key, T value) {
    final existingEntry = _storage.remove(key);
    if (existingEntry != null) {
      onEvict?.call(key, existingEntry.value);
    }

    // Remove oldest if cache is full
    while (_storage.length >= maxSize) {
      final oldestKey = _storage.keys.first;
      final oldestEntry = _storage.remove(oldestKey)!;
      _evictionCount++;
      onEvict?.call(oldestKey, oldestEntry.value);
    }

    _storage[key] = _CacheEntry(value, DateTime.now());
  }

  /// Check if key exists in cache
  bool containsKey(String key) {
    final entry = _storage[key];
    if (entry == null) return false;

    // Check if entry has expired
    if (maxAge != null && DateTime.now().difference(entry.timestamp) > maxAge!) {
      remove(key);
      return false;
    }

    return true;
  }

  /// Remove key from cache
  T? remove(String key) {
    final entry = _storage.remove(key);
    if (entry != null) {
      _evictionCount++;
      onEvict?.call(key, entry.value);
      return entry.value;
    }
    return null;
  }

  /// Clear all entries from cache
  void clear() {
    for (final entry in _storage.values) {
      onEvict?.call('', entry.value); // Key is not available during clear
    }
    _storage.clear();
  }

  /// Remove expired entries
  void cleanup() {
    if (maxAge == null) return;

    final now = DateTime.now();
    final expiredKeys = <String>[];

    for (final entry in _storage.entries) {
      if (now.difference(entry.value.timestamp) > maxAge!) {
        expiredKeys.add(entry.key);
      }
    }

    for (final key in expiredKeys) {
      remove(key);
    }
  }

  /// Get current cache size
  int get size => _storage.length;

  /// Get hit count
  int get hitCount => _hitCount;

  /// Get miss count
  int get missCount => _missCount;

  /// Get eviction count
  int get evictionCount => _evictionCount;

  /// Get cache hit ratio
  double get hitRatio => _hitCount + _missCount > 0 ? _hitCount / (_hitCount + _missCount) : 0.0;
}

/// Internal cache entry
class _CacheEntry<T> {
  final T value;
  final DateTime timestamp;

  _CacheEntry(this.value, this.timestamp);
}

/// Cleanup statistics
class CleanupStats {
  int cachesCleaned = 0;
  int itemsRemoved = 0;
  int objectsGarbageCollected = 0;
  bool forcedGarbageCollection = false;
  Duration duration = Duration.zero;
  int memoryUsageBefore = 0;
  int memoryUsageAfter = 0;

  @override
  String toString() {
    return 'CleanupStats('
        'cachesCleaned: $cachesCleaned, '
        'itemsRemoved: $itemsRemoved, '
        'objectsGarbageCollected: $objectsGarbageCollected, '
        'forcedGarbageCollection: $forcedGarbageCollection, '
        'duration: ${duration.inMilliseconds}ms, '
        'memoryFreed: ${memoryUsageBefore - memoryUsageAfter} bytes'
        ')';
  }
}

/// Memory usage report
class MemoryUsageReport {
  final int currentMemoryUsage;
  final int maxMemoryUsage;
  final int trackedObjects;
  final int activeCaches;
  final Map<String, CacheStats> cacheStats;
  final DateTime timestamp;

  MemoryUsageReport({
    required this.currentMemoryUsage,
    required this.maxMemoryUsage,
    required this.trackedObjects,
    required this.activeCaches,
    required this.cacheStats,
    required this.timestamp,
  });

  double get memoryUsageRatio => currentMemoryUsage / maxMemoryUsage;

  @override
  String toString() {
    return 'MemoryUsageReport('
        'currentMemoryUsage: $currentMemoryUsage bytes, '
        'maxMemoryUsage: $maxMemoryUsage bytes, '
        'trackedObjects: $trackedObjects, '
        'activeCaches: $activeCaches, '
        'memoryUsageRatio: ${(memoryUsageRatio * 100).toStringAsFixed(1)}%'
        ')';
  }
}

/// Cache statistics
class CacheStats {
  final int size;
  final int maxSize;
  final int hitCount;
  final int missCount;
  final int evictionCount;

  CacheStats({
    required this.size,
    required this.maxSize,
    required this.hitCount,
    required this.missCount,
    required this.evictionCount,
  });

  double get hitRatio => hitCount + missCount > 0 ? hitCount / (hitCount + missCount) : 0.0;

  double get utilizationRatio => size / maxSize;

  @override
  String toString() {
    return 'CacheStats('
        'size: $size/$maxSize, '
        'hitRatio: ${(hitRatio * 100).toStringAsFixed(1)}%, '
        'evictionCount: $evictionCount'
        ')';
  }
}

/// Weak reference for tracking objects
class WeakReference<T> {
  final T? _target;

  WeakReference(T target) : _target = target;

  T? get target => _target;

  bool get isAlive => _target != null;
}