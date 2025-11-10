import 'package:flutter/material.dart';

/// A callback function type for handling item updates
typedef ItemUpdateCallback = Future<void> Function(String category, String name, Map<String, Object?> props);

/// A reusable dialog for editing item properties
class EditItemDialog extends StatefulWidget {
  final String category;
  final String initialName;
  final String? initialComment;
  final String? initialStatus;
  final ItemUpdateCallback onUpdate;

  const EditItemDialog({
    super.key,
    required this.category,
    required this.initialName,
    required this.initialComment,
    this.initialStatus,
    required this.onUpdate,
  });

  /// Static method to show the dialog
  static Future<void> show({
    required BuildContext context,
    required String category,
    required String initialName,
    required String? initialComment,
    String? initialStatus,
    required ItemUpdateCallback onUpdate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => EditItemDialog(
        category: category,
        initialName: initialName,
        initialComment: initialComment,
        initialStatus: initialStatus,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _commentController = TextEditingController(text: widget.initialComment);
    _status = widget.initialStatus ?? 'enabled';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      await widget.onUpdate(
        widget.category,
        widget.initialName,
        {
          'name': _nameController.text,
          'comment': _commentController.text == "" ? null : _commentController.text,
          'enabled': _status == 'enabled' ? true : false,
        },
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Handle error - could show a snackbar or error dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: Colors.grey[50],
      titlePadding: const EdgeInsets.all(4.0),
      title: Text(widget.category),
      titleTextStyle: TextStyle(
        color: Colors.green[800],
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Adjust radius as needed
      ),

      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              // Name and Status Row
              Row(
                children: [
                  // Name Input
                  Container(
                    width: 120,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green[800]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: EditableText(
                      controller: _nameController,
                      focusNode: FocusNode(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: Colors.green[800]!,
                      backgroundCursorColor: Colors.grey,
                      onChanged: (value) {
                        // Optional: Add real-time validation here
                      },
                    ),
                  ),

                  const SizedBox(width: 16),
                  // Comment Input
                  Container(
                    width: 120,
                    height: 32,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green[800]!),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: EditableText(
                      controller: _commentController,
                      focusNode: FocusNode(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      cursorColor: Colors.green[800]!,
                      backgroundCursorColor: Colors.grey,
                      onChanged: (value) {
                        // Optional: Add real-time validation here
                      },
                    ),
                  ),

                  const SizedBox(width: 16),
                  // Status Dropdown
                  Container(
                    width: 132,
                    height: 32,
                    padding: EdgeInsets.zero,
                    child: DropdownMenu<String>(
                      width: 124,
                      dropdownMenuEntries: const [
                        DropdownMenuEntry(value: 'enabled', label: 'enabled'),
                        DropdownMenuEntry(value: 'disabled', label: 'disabled'),
                      ],
                      menuStyle: const MenuStyle(
                        padding: WidgetStatePropertyAll(EdgeInsets.zero),
                      ),
                      inputDecorationTheme: const InputDecorationTheme(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                      ),
                      textStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      initialSelection: _status,
                      onSelected: (String? value) {
                        if (value != null) {
                          setState(() {
                            _status = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              // Action Buttons Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _handleSave,
                    child: const Text('Save'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}