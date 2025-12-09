import 'dart:async';

import 'settings_service.dart';

/// Enum representing the system reboot state
enum RebootState {
  idle,
  started,
  pending,
  complete,
  failed,
}

/// Enum representing HTTP service readiness state
enum ServiceState {
  unknown,
  checking,
  ready,
  unavailable,
}

/// Event model for reboot status changes
class RebootEvent {
  final RebootState state;
  final String? message;
  final DateTime timestamp;

  RebootEvent({
    required this.state,
    this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'RebootEvent(state: $state, message: $message, time: $timestamp)';
}

/// Event model for service readiness status changes
class ServiceReadinessEvent {
  final ServiceState state;
  final String? host;
  final String? message;
  final DateTime timestamp;

  ServiceReadinessEvent({
    required this.state,
    this.host,
    this.message,
  }) : timestamp = DateTime.now();

  @override
  String toString() => 'ServiceReadinessEvent(state: $state, message: $message, host: $host, time: $timestamp)';
}

/// Service class that manages system event streams
class SystemEventService {
  final SettingsService _settingsService = SettingsService();

  // Private stream controllers
  final _rebootController = StreamController<RebootEvent>.broadcast();
  final _serviceController = StreamController<ServiceReadinessEvent>.broadcast();

  // Public stream accessors
  Stream<RebootEvent> get rebootStream => _rebootController.stream;
  Stream<ServiceReadinessEvent> get serviceStream => _serviceController.stream;

  // Current state tracking
  RebootState _currentRebootState = RebootState.idle;
  ServiceState _currentServiceState = ServiceState.unknown;

  RebootState get currentRebootState => _currentRebootState;
  ServiceState get currentServiceState => _currentServiceState;

  /// Emit a reboot event
  void emitRebootEvent(RebootState state, {String? message}) {
    _currentRebootState = state;
    final event = RebootEvent(state: state, message: message);
    _rebootController.add(event);
  }

  /// Emit a service readiness event
  void emitServiceEvent(ServiceState state, {String? message}) async {
    _currentServiceState = state;
    String? host = await _settingsService.getHostname();
    final event = ServiceReadinessEvent(state: state, host: host, message: message);
    _serviceController.add(event);
  }

  /// Start monitoring service readiness after a reboot
  /// Polls the service until it becomes available or timeout occurs
  Future<void> monitorServiceAfterReboot({
    required Future<bool> Function() healthCheck,
    Duration pollInterval = const Duration(seconds: 5),
    Duration timeout = const Duration(minutes: 5),
  }) async {
    emitServiceEvent(ServiceState.checking, message: 'Waiting for service to come back online...');

    final startTime = DateTime.now();
    
    while (DateTime.now().difference(startTime) < timeout) {
      await Future.delayed(pollInterval);
      
      try {
        final isHealthy = await healthCheck();
        if (isHealthy) {
          emitServiceEvent(ServiceState.ready, message: 'Service is ready');
          emitRebootEvent(RebootState.complete, message: 'Reboot completed successfully');
          return;
        }
      } catch (e) {
        // Service not ready yet, continue polling
        print('Service health check failed: $e');
      }
    }

    // Timeout reached
    emitServiceEvent(ServiceState.unavailable, message: 'Service did not respond within timeout');
    emitRebootEvent(RebootState.failed, message: 'Service did not come back online');
  }

  /// Helper method to execute a reboot with full event lifecycle
  Future<bool> executeRebootWithMonitoring({
    required Future<bool> Function() rebootCommand,
    required Future<bool> Function() healthCheck,
  }) async {
    try {
      // Emit reboot started event
      emitRebootEvent(RebootState.started, message: 'Initiating system reboot...');
      
      // Execute the reboot command
      final success = await rebootCommand();
      
      if (!success) {
        emitRebootEvent(RebootState.failed, message: 'Failed to execute reboot command');
        return false;
      }

      // Emit reboot pending event
      emitRebootEvent(RebootState.pending, message: 'System is rebooting...');
      
      // Start monitoring for service to come back online
      // This runs in the background
      monitorServiceAfterReboot(healthCheck: healthCheck);
      
      return true;
    } catch (e) {
      emitRebootEvent(RebootState.failed, message: 'Reboot error: $e');
      return false;
    }
  }

  /// Clean up resources
  void dispose() {
    _rebootController.close();
    _serviceController.close();
  }
}
