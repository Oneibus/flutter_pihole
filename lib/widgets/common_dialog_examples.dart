/// Example: Refactoring existing dialogs to use CommonDialog
/// 
/// This shows how to use the common dialog base for your specific dialogs

import 'package:flutter/material.dart';
import 'common_dialog.dart';

// ============================================================================
// Example 1: Simple usage with CommonDialog directly
// ============================================================================

class SimpleExampleDialog extends StatefulWidget {
  final String itemName;
  final VoidCallback onSave;

  const SimpleExampleDialog({
    super.key,
    required this.itemName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required String itemName,
    required VoidCallback onSave,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => SimpleExampleDialog(
        itemName: itemName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<SimpleExampleDialog> createState() => _SimpleExampleDialogState();
}

class _SimpleExampleDialogState extends State<SimpleExampleDialog> {
  bool _isLoading = false;

  void _handleSave() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API call
    widget.onSave();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BuildableCommonDialog(
      title: 'Edit Item',
      subtitle: Text('Item: ${widget.itemName}'),
      titleIcon: Icons.edit,
      isLoading: _isLoading,
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Comment'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ============================================================================
// Example 2: Using DialogBuilder pattern
// ============================================================================

class BuilderExampleDialog {
  static Future<void> show(BuildContext context, String message) {
    return DialogBuilder()
        .setTitle('Confirmation')
        .setTitleIcon(Icons.warning)
        .setTitleBackgroundColor(Colors.orange[700]!)
        .setContent(
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(message),
          ),
        )
        .setActions([
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ])
        .show<bool>(context);
  }
}

// ============================================================================
// Example 3: Refactored EditClientGroupsDialog using CommonDialog
// ============================================================================

/*
class RefactoredClientGroupsDialog extends StatefulWidget {
  final int clientId;
  final String clientName;
  final List<GroupInfo> availableGroups;
  final ClientGroupsUpdateCallback onUpdate;

  const RefactoredClientGroupsDialog({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.availableGroups,
    required this.onUpdate,
  });

  static Future<void> show({
    required BuildContext context,
    required int clientId,
    required String clientName,
    required List<GroupInfo> availableGroups,
    required ClientGroupsUpdateCallback onUpdate,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => RefactoredClientGroupsDialog(
        clientId: clientId,
        clientName: clientName,
        availableGroups: availableGroups,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<RefactoredClientGroupsDialog> createState() => 
      _RefactoredClientGroupsDialogState();
}

class _RefactoredClientGroupsDialogState 
    extends State<RefactoredClientGroupsDialog> {
  late List<GroupInfo> _groups;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _groups = widget.availableGroups.map((g) => g).toList();
  }

  void _toggleGroup(int index) {
    setState(() {
      _groups[index] = _groups[index].copyWith(
        isAssigned: !_groups[index].isAssigned,
      );
    });
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final assignedGroupIds = _groups
          .where((g) => g.isAssigned)
          .map((g) => g.id)
          .toList();

      await widget.onUpdate(widget.clientId, assignedGroupIds);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the groups list content
    final groupsList = _groups.isEmpty
        ? const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: Text('No groups available')),
          )
        : ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: _groups.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final group = _groups[index];
              return CheckboxListTile(
                title: Text(group.name),
                subtitle: Text('ID: ${group.id}'),
                value: group.isAssigned,
                activeColor: Colors.green[700],
                onChanged: _isLoading ? null : (bool? value) {
                  if (value != null) _toggleGroup(index);
                },
              );
            },
          );

    // Build the summary section
    final summary = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.green[700]),
          const SizedBox(width: 8),
          Text(
            '${_groups.where((g) => g.isAssigned).length} of ${_groups.length} groups selected',
            style: TextStyle(fontSize: 12, color: Colors.green[900]),
          ),
        ],
      ),
    );

    // Use CommonDialog with custom content
    return CommonDialog(
      title: 'Manage Group Assignments',
      subtitle: Text('Client: ${widget.clientName}'),
      titleIcon: Icons.group,
      isLoading: _isLoading,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: groupsList),
          summary,
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isLoading ? null : _handleSave,
          icon: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save, size: 18),
          label: Text(_isLoading ? 'Saving...' : 'Save'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
*/

// ============================================================================
// Example 4: Refactored EditItemDialog using CommonDialog
// ============================================================================

/*
class RefactoredEditItemDialog extends StatefulWidget {
  final String category;
  final String initialName;
  final String? initialComment;
  final String? initialStatus;
  final ItemUpdateCallback onUpdate;

  const RefactoredEditItemDialog({
    super.key,
    required this.category,
    required this.initialName,
    required this.initialComment,
    this.initialStatus,
    required this.onUpdate,
  });

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
      builder: (context) => RefactoredEditItemDialog(
        category: category,
        initialName: initialName,
        initialComment: initialComment,
        initialStatus: initialStatus,
        onUpdate: onUpdate,
      ),
    );
  }

  @override
  State<RefactoredEditItemDialog> createState() => 
      _RefactoredEditItemDialogState();
}

class _RefactoredEditItemDialogState extends State<RefactoredEditItemDialog> {
  late TextEditingController _nameController;
  late TextEditingController _commentController;
  late String _status;
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    try {
      await widget.onUpdate(
        widget.category,
        widget.initialName,
        {
          'name': _nameController.text,
          'comment': _commentController.text.isEmpty 
              ? null 
              : _commentController.text,
          'enabled': _status == 'enabled',
        },
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formContent = Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Comment',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 132,
            child: DropdownButtonFormField<String>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'enabled', child: Text('Enabled')),
                DropdownMenuItem(value: 'disabled', child: Text('Disabled')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
          ),
        ],
      ),
    );

    return CommonDialog(
      title: widget.category,
      titleIcon: Icons.edit,
      width: 500,
      maxHeight: 300,
      isLoading: _isLoading,
      content: formContent,
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
*/
