# System Event Streams

This document explains the Stream-based event system for monitoring reboot and HTTP service readiness in the PiHole Control application.

## Overview

The `SystemEventService` provides two broadcast streams:
- **Reboot Stream**: Emits events during system reboot lifecycle
- **Service Stream**: Emits events about HTTP service availability

## Components

### 1. SystemEventService (`lib/pihole/system_events.dart`)

Main service class that manages event streams.

```dart
final eventService = SystemEventService();

// Listen to reboot events
eventService.rebootStream.listen((event) {
  print('Reboot state: ${event.state}');
});

// Listen to service readiness events
eventService.serviceStream.listen((event) {
  print('Service state: ${event.state}');
});
```

### 2. Event States

**RebootState enum:**
- `idle` - No reboot in progress
- `started` - Reboot command initiated
- `pending` - System is actively rebooting
- `complete` - Reboot finished successfully
- `failed` - Reboot failed or timed out

**ServiceState enum:**
- `unknown` - Service state not yet determined
- `checking` - Actively polling service health
- `ready` - Service is responding
- `unavailable` - Service not responding

### 3. Event Models

**RebootEvent:**
```dart
class RebootEvent {
  final RebootState state;
  final String? message;
  final DateTime timestamp;
}
```

**ServiceReadinessEvent:**
```dart
class ServiceReadinessEvent {
  final ServiceState state;
  final String? message;
  final DateTime timestamp;
}
```

## Integration

### In PiHoleClient

The `PiHoleClient` optionally accepts a `SystemEventService` instance:

```dart
final eventService = SystemEventService();

final client = PiHoleClient(
  hostname: 'pihole.local',
  sysAdminAccount: 'admin',
  appPassword: 'password',
  sysPassword: 'syspass',
  systemEventService: eventService,
);

// Reboot with automatic monitoring
await client.rebootSystem();
```

When `systemEventService` is provided, `rebootSystem()` will:
1. Emit `RebootState.started`
2. Execute the SSH reboot command
3. Emit `RebootState.pending`
4. Poll the service health endpoint every 5 seconds
5. Emit `ServiceState.checking` during polling
6. Emit `RebootState.complete` + `ServiceState.ready` when service responds
7. Emit `RebootState.failed` if timeout occurs (3 minutes)

### In UI (main.dart)

The `_MasterDetailPageState` subscribes to events in `initState()`:

```dart
void _setupEventListeners() {
  _rebootSubscription = DataService.systemEvents.rebootStream.listen((event) {
    switch (event.state) {
      case RebootState.started:
        // Show "Starting reboot..." SnackBar
        break;
      case RebootState.pending:
        // Show "Rebooting..." SnackBar
        break;
      case RebootState.complete:
        // Show success SnackBar
        // Trigger UI refresh
        setState(() { _refreshKey++; });
        break;
      case RebootState.failed:
        // Show error SnackBar
        break;
    }
  });
}
```

The `CategoryListView` listens for `RebootState.pending` to show an overlay:

```dart
class _CategoryListViewState extends State<CategoryListView> {
  bool _isRebooting = false;

  void _setupRebootListener() {
    _rebootSubscription = DataService.systemEvents.rebootStream.listen((event) {
      setState(() {
        _isRebooting = event.state == RebootState.pending;
      });
    });
  }

  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main content
        YourContent(),
        
        // Overlay when rebooting
        if (_isRebooting)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  Text('System is rebooting...'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
```

## UI Behavior

When user clicks "Reboot System":

1. **Immediate**: SnackBar shows "Starting system reboot..." (orange)
2. **After command**: SnackBar shows "System is rebooting..." (orange)
3. **Overlay appears**: Dark semi-transparent overlay with spinner and "System is rebooting..." text
4. **Polling begins**: SnackBar shows "Waiting for service to come back online..." (blue)
5. **Success**: 
   - Overlay disappears
   - SnackBar shows "Reboot completed successfully" (green)
   - UI refreshes automatically
6. **Failure** (if timeout):
   - Overlay disappears
   - SnackBar shows "Service did not respond within timeout" (red)

## Health Check

The service health check pings the `/api/version` endpoint:

```dart
Future<bool> checkHealth() async {
  try {
    final res = await _http.get(
      Uri.parse('http://$hostname/api/version'),
    ).timeout(const Duration(seconds: 5));
    
    return res.statusCode == 200 || res.statusCode == 401;
  } catch (e) {
    return false;
  }
}
```

A 401 response means the service is up but requires authentication, which counts as "ready".

## Configuration

Polling and timeout parameters can be adjusted when calling `monitorServiceAfterReboot()`:

```dart
await eventService.monitorServiceAfterReboot(
  healthCheck: client.checkHealth,
  pollInterval: Duration(seconds: 10),  // Poll every 10 seconds
  timeout: Duration(minutes: 5),        // Timeout after 5 minutes
);
```

## Cleanup

Always dispose of the event service when done:

```dart
@override
void dispose() {
  _rebootSubscription?.cancel();
  _serviceSubscription?.cancel();
  DataService.systemEvents.dispose(); // If managed by DataService
  super.dispose();
}
```

## Testing

To test the event system without actual reboots:

```dart
// Emit test events
DataService.systemEvents.emitRebootEvent(
  RebootState.pending,
  message: 'Testing reboot UI',
);

// Wait 5 seconds
await Future.delayed(Duration(seconds: 5));

// Complete the test
DataService.systemEvents.emitRebootEvent(
  RebootState.complete,
  message: 'Test complete',
);
```
