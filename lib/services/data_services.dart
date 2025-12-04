import 'dart:async';
import 'package:flutter/material.dart';

import 'settings_service.dart';
import 'system_events.dart';
import '../pihole/api_models.dart';
import '../pihole/pihole_client.dart';
import '../pihole/pihole_service.dart';
import '../widgets/system_dialog.dart';

class DataService {
  // System event and settings service instances
  static final SystemEventService systemEvents = SystemEventService();
  static final SettingsService settingsService = SettingsService();

  Future<String> get hostName => settingsService.getHostname();
  Future<String> get appPassword => settingsService.getAppPassword();
  Future<String> get sysAccount => settingsService.getSysAccount();
  Future<String> get sysPassword => settingsService.getSysPassword();

  static final _service = PiHoleService(
    PiHoleClient(
      settingsService: SettingsService(),
      systemEventService: systemEvents,
    ),
  );


  // Initialize and cache the DNS blocking status on app startup
  static Future<void> initializeBlockingStatus() async {
    try {
      // Query the blocking status to initialize/cache it
      if (await _service.isConfigured()) {
        await _service.isBlockingEnabled();
      }
    } catch (e) {
      debugPrint('Error initializing blocking status: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    await _service.logout();
  }

  static Future<List<dynamic>> fetchItems(String category) {
    return _service.listForCategory(category);
  }

  static Future<bool> updateItem(String category, String itemName,{Map<String, Object?>? props}) {
    return _service.updateCategoryItem(category, itemName, props: props);
  }

  static Widget buildSystemDialog({required BuildContext context}) {
    return SystemDialog(
      onFlushNetworkCache: _service.flushNetworkCache,
      onRestartDNS: _service.restartDNS,
      onRebootSystem: _service.rebootSystem,
      onEnableBlocking: ({int? duration}) => _service.enableBlocking(),
      onDisableBlocking: ({int? duration}) => _service.disableBlocking(duration: duration),
      onGetBlockingStatus: _service.isBlockingEnabled,
      onApplicationSettings: _service.resetService,
    );
  }

  static Future<List<GroupInfo>> getGroupsForClient(int clientId) {
    return _service.getGroupsForClient(clientId);
  }

  static Future<bool> updateClientGroups(int clientId, List<int> groupIds) {
    return _service.updateClientGroups(clientId, groupIds);
  }
}
