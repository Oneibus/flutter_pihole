import 'package:flutter/material.dart';

/// A callback function type for system operations
typedef SystemOperationCallback = Future<bool> Function();

/// A dialog for system operations like restart DNS, flush network table, and reboot
class SystemDialog extends StatefulWidget {
  final SystemOperationCallback onRestartDNS;
  final SystemOperationCallback onFlushNetworkTable;
  final SystemOperationCallback onRebootSystem;

  const SystemDialog({
    super.key,
    required this.onRestartDNS,
    required this.onFlushNetworkTable,
    required this.onRebootSystem,
  });

  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required SystemOperationCallback onRestartDNS,
    required SystemOperationCallback onFlushNetworkTable,
    required SystemOperationCallback onRebootSystem,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SystemDialog(
        onRestartDNS: onRestartDNS,
        onFlushNetworkTable: onFlushNetworkTable,
        onRebootSystem: onRebootSystem,
      ),
    );
  }

  @override
  State<SystemDialog> createState() => _SystemDialogState();
}

class _SystemDialogState extends State<SystemDialog> {
  bool _isProcessing = false;

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

  Future<void> _handleFlushNetworkTable() async {
    setState(() => _isProcessing = true);
    try {
      final success = await widget.onFlushNetworkTable();
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
                onPressed: _isProcessing ? null : _handleFlushNetworkTable,
                icon: const Icon(Icons.network_check),
                label: const Text('Flush Network Table'),
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
