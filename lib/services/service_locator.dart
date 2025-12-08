import 'package:get_it/get_it.dart';
import 'settings_service.dart';
import 'system_events.dart';
import 'data_services.dart';
import '../pihole/pihole_client.dart';
import '../pihole/pihole_service.dart';

/// Global service locator instance
final getIt = GetIt.instance;

/// Setup all dependencies for dependency injection
/// Call this once at app startup before runApp()
void setupServiceLocator() {
  // Register services as singletons (single instance throughout app lifecycle)
  
  // Core services
  getIt.registerSingleton<SystemEventService>(SystemEventService());
  getIt.registerSingleton<SettingsService>(SettingsService());
  
  // API client - depends on settings and event services
  getIt.registerSingleton<PiHoleClient>(
    PiHoleClient(
      settingsService: getIt<SettingsService>(),
      systemEventService: getIt<SystemEventService>(),
    ),
  );
  
  // Service layer - depends on client
  getIt.registerSingleton<PiHoleService>(
    PiHoleService(getIt<PiHoleClient>()),
  );
  
  // Data service - high-level business logic layer
  getIt.registerSingleton<DataService>(
    DataService(
      piHoleService: getIt<PiHoleService>(),
      settingsService: getIt<SettingsService>(),
      systemEventService: getIt<SystemEventService>(),
    ),
  );
}

/// Cleanup and reset all registered services
/// Useful for testing or app restart scenarios
Future<void> resetServiceLocator() async {
  await getIt.reset();
}
