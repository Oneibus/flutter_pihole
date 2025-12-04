import 'package:flutter/material.dart';
import 'package:flutter_pihole_client/widgets/app_settings.dart';
import 'enable_disable_blocking_dialog.dart';

/// A callback function type for system operations
typedef SystemOperationCallback = Future<bool> Function();
typedef EnableDisableCallback = Future<bool> Function({int? duration});
typedef GetBlockingStatusCallback = Future<bool> Function();
typedef ApplicationSettingsCallback = Future<void> Function();

/// A dialog for system operations like restart DNS, flush network table, and reboot
class SystemDialog extends StatefulWidget {
  final SystemOperationCallback onRestartDNS;
  final SystemOperationCallback onFlushNetworkCache;
  final SystemOperationCallback onRebootSystem;
  final EnableDisableCallback onEnableBlocking;
  final EnableDisableCallback onDisableBlocking;
  final GetBlockingStatusCallback onGetBlockingStatus;
  final ApplicationSettingsCallback onApplicationSettings;

  const SystemDialog({
    super.key,
    required this.onRestartDNS,
    required this.onFlushNetworkCache,
    required this.onRebootSystem,
    required this.onEnableBlocking,
    required this.onDisableBlocking,
    required this.onGetBlockingStatus,
    required this.onApplicationSettings,
  });

  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required SystemOperationCallback onRestartDNS,
    required SystemOperationCallback onFlushNetworkCache,
    required SystemOperationCallback onRebootSystem,
    required EnableDisableCallback onEnableBlocking,
    required EnableDisableCallback onDisableBlocking,
    required GetBlockingStatusCallback onGetBlockingStatus,
    required ApplicationSettingsCallback onApplicationSettings,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SystemDialog(
        onRestartDNS: onRestartDNS,
        onFlushNetworkCache: onFlushNetworkCache,
        onRebootSystem: onRebootSystem,
        onEnableBlocking: onEnableBlocking,
        onDisableBlocking: onDisableBlocking,
        onGetBlockingStatus: onGetBlockingStatus,
        onApplicationSettings: onApplicationSettings,
      ),
    );
  }

  @override
  State<SystemDialog> createState() => _SystemDialogState();
}

class _SystemDialogState extends State<SystemDialog> {
  bool _isProcessing = false;
  bool _blockingEnabled = true; // Default to enabled

  @override
  void initState() {
    super.initState();
    _loadBlockingStatus();
  }

  Future<void> _handleAppSettings() async {
    /// Show the Settings page
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );

    // When returning, refresh connection/UI in case URL changed
    setState(() {
      final success = widget.onApplicationSettings();
    });
  }

  Future<void> _loadBlockingStatus() async {
    try {
      final status = await widget.onGetBlockingStatus();
      if (mounted) {
        setState(() {
          _blockingEnabled = status;
        });
      }
    } catch (e) {
      // Ignore errors during initial load
    }
  }

  Future<void> _handleToggleBlocking() async {
    // Show the enable/disable dialog
    await EnableDisableBlockingDialog.show(
      context: context,
      isCurrentlyEnabled: _blockingEnabled,
      onSave: (durationSeconds) async {
        if (_blockingEnabled) {
          // Currently enabled, so disable it
          return await widget.onDisableBlocking(duration: durationSeconds);
        } else {
          // Currently disabled, so enable it
          return await widget.onEnableBlocking();
        }
      },
    );

    // Refresh the blocking status after the dialog closes
    await _loadBlockingStatus();
  }

  Future<void> _handleRestartDNS() async {
    setState(() => _isProcessing = true);
    try {
      final success = await widget.onRestartDNS();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'DNS restarted successfully' : 'Failed to restart DNS'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error restarting DNS: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleFlushNetworkCache() async {
    setState(() => _isProcessing = true);
    try {
      final success = await widget.onFlushNetworkCache();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Network table flushed successfully' : 'Failed to flush network table'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error flushing network table: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRebootSystem() async {
    // Show confirmation dialog for reboot
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Reboot'),
        content: const Text('Are you sure you want to reboot the system? This will interrupt all services.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reboot'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          )
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessing = true);
    try {
      final success = await widget.onRebootSystem();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'System rebooting...' : 'Failed to reboot system'),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rebooting system: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: Colors.grey[50],
      titlePadding: const EdgeInsets.all(8.0),

      titleTextStyle: TextStyle(
        color: Colors.blue[800],
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Enable/Disable Blocking Button
              ElevatedButton.icon(
                onPressed: _handleAppSettings,
                icon: const Icon(Icons.settings),
                label: Text('App Settings'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple[500],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),

              // Toggle Enable/Disable Blocking Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleToggleBlocking,
                icon: Icon(_blockingEnabled ? Icons.block : Icons.check_circle),
                label: Text(_blockingEnabled ? 'Disable Blocking' : 'Enable Blocking'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blockingEnabled ? Colors.orange[700] : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              
              // Restart DNS Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleRestartDNS,
                icon: const Icon(Icons.refresh),
                label: const Text('Restart DNS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              
              // Flush Network Table Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleFlushNetworkCache,
                icon: const Icon(Icons.network_check),
                label: const Text('Flush Network'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              
              // Reboot System Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _handleRebootSystem,
                icon: const Icon(Icons.power_settings_new),
                label: const Text('Reboot System'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              
              if (_isProcessing) ...[
                const SizedBox(height: 16),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
