import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'common_dialog.dart';

/// A dialog for enabling or disabling DNS blocking
class EnableDisableBlockingDialog {
  /// Shows the enable/disable blocking dialog
  /// 
  /// [context] The build context
  /// [isCurrentlyEnabled] Whether blocking is currently enabled
  /// [onSave] Callback when save is clicked, receives duration in seconds (null for indefinite)
  static Future<void> show({
    required BuildContext context,
    required bool isCurrentlyEnabled,
    required Future<bool> Function(int? durationSeconds) onSave,
  }) async {
    bool useDuration = false;
    final durationController = TextEditingController(text: '5');
    bool isSaving = false;

    return showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return DialogBuilder()
              .setTitle(isCurrentlyEnabled ? 'Disable Blocking' : 'Enable Blocking')
              .setWidth(450)
              .setHeight(isCurrentlyEnabled ? (useDuration ? 340 : 220) : 150)
              .setContent(
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isCurrentlyEnabled) ...[
                            // Only show options when disabling
                            RadioListTile<bool>(
                              title: const Text('Disable indefinitely'),
                              value: false,
                              groupValue: useDuration,
                              onChanged: (value) {
                                setState(() {
                                  useDuration = value ?? false;
                                });
                              },
                            ),
                            RadioListTile<bool>(
                              title: const Text('Disable for a specific time'),
                              value: true,
                              groupValue: useDuration,
                              onChanged: (value) {
                                setState(() {
                                  useDuration = value ?? false;
                                });
                              },
                            ),
                            if (useDuration) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0, right: 16.0),
                                child: Row(
                                  children: [
                                    const Text('Duration (minutes):'),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 80,
                                      child: TextField(
                                        controller: durationController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter.digitsOnly,
                                        ],
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ] else ...[
                            const Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Enable DNS blocking?'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              )
              .setActions([
                ElevatedButton.icon(
                  onPressed: isSaving
                      ? null
                      : () async {
                          setState(() {
                            isSaving = true;
                          });

                          try {
                            int? durationSeconds;
                            if (isCurrentlyEnabled && useDuration) {
                              // Convert minutes to seconds
                              final minutes = int.tryParse(durationController.text);
                              if (minutes == null || minutes <= 0) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a valid duration'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                                setState(() {
                                  isSaving = false;
                                });
                                return;
                              }
                              durationSeconds = minutes * 60;
                            }

                            final success = await onSave(durationSeconds);
                            
                            if (context.mounted) {
                              if (success) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isCurrentlyEnabled
                                          ? (useDuration
                                              ? 'Blocking disabled for ${int.tryParse(durationController.text) ?? 0} minutes'
                                              : 'Blocking disabled')
                                          : 'Blocking enabled',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to ${isCurrentlyEnabled ? "disable" : "enable"} blocking',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            if (context.mounted) {
                              setState(() {
                                isSaving = false;
                              });
                            }
                          }
                        },
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save),
                  label: const Text('Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Cancel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ])
              .build();
        },
      ),
    );
  }
}
