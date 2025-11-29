import 'package:get_it/get_it.dart';
import '../services/websocket_service.dart';
import '../services/fire_alarm_websocket_manager.dart';
import '../services/led_status_decoder.dart';
import '../services/enhanced_zone_parser.dart';
import '../services/simple_status_manager.dart';
import '../services/enhanced_notification_service.dart';
import '../services/firebase_log_handler.dart';
import '../services/websocket_mode_manager.dart';
import '../services/bell_manager.dart';
import '../services/logger.dart';
import '../core/fire_alarm_data.dart';

/// Global service locator for dependency injection
/// Helps manage service dependencies and improves testability
final GetIt getIt = GetIt.instance;

/// Initialize all services and dependencies
Future<void> setupDependencies() async {
  try {
    AppLogger.info('🔧 Initializing dependency injection', tag: 'DI_SETUP');

    // ============= SINGLETON SERVICES =============

    // Core logging service
    getIt.registerSingleton<AppLogger>(AppLogger());

    // WebSocket services
    getIt.registerSingleton<WebSocketService>(WebSocketService());

    // System management services
    getIt.registerSingleton<LEDStatusDecoder>(LEDStatusDecoder());
    getIt.registerSingleton<SimpleStatusManager>(SimpleStatusManager());
    getIt.registerSingleton<WebSocketModeManager>(WebSocketModeManager.instance);

    // Parsing services
    getIt.registerSingleton<EnhancedZoneParser>(EnhancedZoneParser());

    // Notification services
    getIt.registerSingleton<EnhancedNotificationService>(EnhancedNotificationService());

    // Bell management service
    getIt.registerSingleton<BellManager>(BellManager());

    // ============= FACTORY SERVICES =============

    // Firebase log handler (creates fresh instance each time)
    getIt.registerFactory<FirebaseLogHandler>(() => FirebaseLogHandler());

    // ============= MAIN APPLICATION SERVICES =============

    // FireAlarmData as the main state manager
    getIt.registerFactory<FireAlarmData>(() => FireAlarmData());

    // FireAlarmWebSocketManager requires FireAlarmData, so register it after FireAlarmData
    getIt.registerLazySingleton<FireAlarmWebSocketManager>(() {
      return FireAlarmWebSocketManager(getIt<FireAlarmData>());
    });

    AppLogger.info('✅ Dependency injection setup completed', tag: 'DI_SETUP');

    // Count registered services
    final registeredCount = getIt.allReadySync().toString().split(',').length;
    AppLogger.info('📊 Registered approximately $registeredCount services', tag: 'DI_SETUP');

  } catch (e, stackTrace) {
    AppLogger.error('❌ Failed to setup dependencies', tag: 'DI_SETUP', error: e, stackTrace: stackTrace);
    rethrow;
  }
}

/// Reset all dependencies (useful for testing or hot restart)
Future<void> resetDependencies() async {
  try {
    AppLogger.info('🔄 Resetting dependency injection', tag: 'DI_SETUP');

    // Dispose services that need cleanup
    if (getIt.isRegistered<WebSocketService>()) {
      getIt<WebSocketService>().dispose();
    }
    if (getIt.isRegistered<FireAlarmWebSocketManager>()) {
      getIt<FireAlarmWebSocketManager>().dispose();
    }
    if (getIt.isRegistered<LEDStatusDecoder>()) {
      getIt<LEDStatusDecoder>().dispose();
    }

    // Reset GetIt
    await getIt.reset();

    AppLogger.info('✅ Dependency injection reset completed', tag: 'DI_SETUP');
  } catch (e) {
    AppLogger.error('❌ Error resetting dependencies', tag: 'DI_SETUP', error: e);
  }
}

/// Get service by type with proper error handling
T getService<T extends Object>() {
  if (!getIt.isRegistered<T>()) {
    throw Exception('Service ${T.toString()} is not registered in DI container');
  }
  return getIt<T>();
}

/// Check if service is registered
bool isServiceRegistered<T extends Object>() {
  return getIt.isRegistered<T>();
}

/// Lazy service registration (registers only when first accessed)
void registerLazyService<T extends Object>(T Function() factoryFunc, {String? instanceName}) {
  if (!getIt.isRegistered<T>(instanceName: instanceName)) {
    getIt.registerLazySingleton<T>(factoryFunc, instanceName: instanceName);
    AppLogger.debug('📝 Lazy registered service: ${T.toString()}', tag: 'DI_SETUP');
  }
}

/// Get all registered services information
Map<String, dynamic> getDependencyInfo() {
  final services = <String, dynamic>{};

  try {
    // Core services
    if (isServiceRegistered<AppLogger>()) services['AppLogger'] = 'Singleton';
    if (isServiceRegistered<WebSocketService>()) services['WebSocketService'] = 'Singleton';
    if (isServiceRegistered<FireAlarmWebSocketManager>()) services['FireAlarmWebSocketManager'] = 'Singleton';

    // Management services
    if (isServiceRegistered<LEDStatusDecoder>()) services['LEDStatusDecoder'] = 'Singleton';
    if (isServiceRegistered<SimpleStatusManager>()) services['SimpleStatusManager'] = 'Singleton';
    if (isServiceRegistered<WebSocketModeManager>()) services['WebSocketModeManager'] = 'Singleton';

    // Parser services
    if (isServiceRegistered<EnhancedZoneParser>()) services['EnhancedZoneParser'] = 'Singleton';

    // Notification services
    if (isServiceRegistered<EnhancedNotificationService>()) services['EnhancedNotificationService'] = 'Singleton';

    // Factory services
    if (isServiceRegistered<FirebaseLogHandler>()) services['FirebaseLogHandler'] = 'Factory';
    if (isServiceRegistered<FireAlarmData>()) services['FireAlarmData'] = 'Factory';

  } catch (e) {
    AppLogger.error('Error getting dependency info', tag: 'DI_SETUP', error: e);
  }

  return {
    'totalServices': services.length,
    'registeredServices': services,
    'lastUpdated': DateTime.now().toIso8601String(),
  };
}

/// Initialize services with health check
Future<bool> initializeServicesWithHealthCheck() async {
  try {
    AppLogger.info('🏥 Initializing services with health check', tag: 'DI_SETUP');

    // Setup dependencies first
    await setupDependencies();

    // Health check for critical services
    final healthResults = <String, bool>{};

    // Check WebSocket service
    try {
      getIt<WebSocketService>();
      healthResults['WebSocketService'] = true;
      AppLogger.debug('✅ WebSocket service healthy', tag: 'DI_HEALTH');
    } catch (e) {
      healthResults['WebSocketService'] = false;
      AppLogger.error('❌ WebSocket service unhealthy', tag: 'DI_HEALTH', error: e);
    }

    // Check LED decoder service
    try {
      getIt<LEDStatusDecoder>();
      healthResults['LEDStatusDecoder'] = true;
      AppLogger.debug('✅ LED decoder service healthy', tag: 'DI_HEALTH');
    } catch (e) {
      healthResults['LEDStatusDecoder'] = false;
      AppLogger.error('❌ LED decoder service unhealthy', tag: 'DI_HEALTH', error: e);
    }

    // Check zone parser service
    try {
      getIt<EnhancedZoneParser>();
      healthResults['EnhancedZoneParser'] = true;
      AppLogger.debug('✅ Zone parser service healthy', tag: 'DI_HEALTH');
    } catch (e) {
      healthResults['EnhancedZoneParser'] = false;
      AppLogger.error('❌ Zone parser service unhealthy', tag: 'DI_HEALTH', error: e);
    }

    // Calculate overall health
    final healthyServices = healthResults.values.where((healthy) => healthy).length;
    final totalServices = healthResults.length;
    final isHealthy = healthyServices == totalServices;

    AppLogger.info('🏥 Health check completed: $healthyServices/$totalServices services healthy', tag: 'DI_HEALTH');

    if (isHealthy) {
      AppLogger.info('✅ All services initialized successfully', tag: 'DI_SETUP');
    } else {
      AppLogger.warning('⚠️ Some services may not be functioning properly', tag: 'DI_SETUP');
    }

    return isHealthy;
  } catch (e, stackTrace) {
    AppLogger.error('❌ Service initialization failed', tag: 'DI_SETUP', error: e, stackTrace: stackTrace);
    return false;
  }
}