import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import 'settings_service.dart';
import 'system_events.dart';
import '../pihole/api_models.dart';
import '../pihole/pihole_service.dart';
import '../widgets/system_dialog.dart';

/// Data service layer that provides business logic and coordinates between UI and services
/// This is now a non-static class that uses GetIt for dependency injection
class DataService {
  final PiHoleService _piHoleService;
  final SettingsService _settingsService;
  final SystemEventService _systemEventService;

  DataService({
    required PiHoleService piHoleService,
    required SettingsService settingsService,
    required SystemEventService systemEventService,
  })  : _piHoleService = piHoleService,
        _settingsService = settingsService,
        _systemEventService = systemEventService;

  // Convenience getters for accessing injected services
  SystemEventService get systemEvents => _systemEventService;
  SettingsService get settingsService => _settingsService;

  Future<String> get hostName => _settingsService.getHostname();
  Future<String> get appPassword => _settingsService.getAppPassword();
  Future<String> get sysAccount => _settingsService.getSysAccount();
  Future<String> get sysPassword => _settingsService.getSysPassword();

  // Initialize and cache the DNS blocking status on app startup
  Future<void> initializeBlockingStatus() async {
    try {
      // Query the blocking status to initialize/cache it
      if (await _piHoleService.isConfigured()) {
        await _piHoleService.isBlockingEnabled();
      }
    } catch (e) {
      debugPrint('Error initializing blocking status: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    await _piHoleService.logout();
  }

  Future<List<dynamic>> fetchItems(String category) {
    return _piHoleService.listForCategory(category);
  }

  Future<bool> updateItem(String category, String itemName, {Map<String, Object?>? props}) {
    return _piHoleService.updateCategoryItem(category, itemName, props: props);
  }

  Future<bool> deleteItem(String category, String itemName, {Map<String, Object?>? props}) {
    return _piHoleService.deleteCategoryItem(category, itemName, props: props);
  }

  Widget buildSystemDialog({required BuildContext context}) {
    return SystemDialog(
      onFlushNetworkCache: _piHoleService.flushNetworkCache,
      onRestartDNS: _piHoleService.restartDNS,
      onRebootSystem: _piHoleService.rebootSystem,
      onEnableBlocking: ({int? duration}) => _piHoleService.enableBlocking(),
      onDisableBlocking: ({int? duration}) => _piHoleService.disableBlocking(duration: duration),
      onGetBlockingStatus: _piHoleService.isBlockingEnabled,
      onApplicationSettings: _piHoleService.resetService,
    );
  }

  Future<List<GroupInfo>> getGroupsForClient(int clientId) {
    return _piHoleService.getGroupsForClient(clientId);
  }

  Future<bool> updateClientGroups(int clientId, List<int> groupIds) {
    return _piHoleService.updateClientGroups(clientId, groupIds);
  }

  Future<List<Group>> getGroups() {
    return _piHoleService.getGroups();
  }

  Future<bool> createDomainFilter({
    required String type,
    required String kind,
    required String domain,
    String? comment,
    List<int>? groups,
    bool enabled = true,
  }) {
    return _piHoleService.createDomainFilter(
      type: type,
      kind: kind,
      domain: domain,
      comment: comment,
      groups: groups,
      enabled: enabled,
    );
  }
}

/// Convenience function to get DataService from GetIt
DataService get dataService => GetIt.instance<DataService>();
