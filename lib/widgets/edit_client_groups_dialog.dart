import 'package:flutter/material.dart';
import '../pihole/api_models.dart';
import 'common_dialog.dart';
  
/// A callback function type for handling client group assignments update
/// Payload sent to API: { "assignments": [{"client_id": 1, "group_id": 2}, ...] }
typedef ClientGroupsUpdateCallback = Future<void> Function(
  int clientId, 
  List<int> groupIds
);

/// A dialog for editing client group assignments with a checkable list
/// Matches FTL API /api/client_groups endpoints
class EditClientGroupsDialog {
  /// Static method to show the dialog using DialogBuilder pattern
  static Future<void> show({
    required BuildContext context,
    required int clientId,
    required String category,
    required String clientName,
    required List<GroupInfo> availableGroups,
    required ClientGroupsUpdateCallback onUpdate,
  }) {
    // Create a mutable copy of the groups list
    List<GroupInfo> groups = availableGroups.map((g) => g).toList();
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          void toggleGroup(int index) {
            setState(() {
              groups[index] = groups[index].copyWith(
                isAssigned: !groups[index].isAssigned,
              );
            });
          }

          Future<void> handleSave() async {
            setState(() {
              isLoading = true;
            });

            try {
              final assignedGroupIds = groups
                  .where((g) => g.isAssigned)
                  .map((g) => g.id)
                  .toList();

              await onUpdate(clientId, assignedGroupIds);

              if (context.mounted) {
                Navigator.of(context).pop();
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating client groups: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return DialogBuilder()
              .setTitle('Manage Group Assignments')
              .setSubtitle(Text('Client: $clientName'))
              .setTitleIcon(Icons.group)
              .setWidth(330)
              .setMaxHeight(360)
              .setContent(
                editClientGroupsDialogContent(
                  groups: groups,
                  onToggleGroup: toggleGroup,
                  isLoading: isLoading,
                ),
              )
              .setActions([
                ElevatedButton.icon(
                  onPressed: isLoading ? null : handleSave,
                  icon: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.save, size: 14),
                  label: Text(isLoading ? 'Saving...' : 'Save'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.cancel, size: 14),
                  label: const Text('Cancel'),
                ),
              ])
              .build();
        },
      ),
    );
  }
}

Widget editClientGroupsDialogContent({
  required List<GroupInfo> groups,
  required Function(int index) onToggleGroup,
  bool isLoading = false,
}) {
  return Expanded(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Groups list
        Expanded(
        child: groups.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(1.0),
                child: Center(
                  child: Text(
                    'No groups available',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 1.0),
                itemCount: groups.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return CheckboxListTile.adaptive(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0.0),
                    // visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                    visualDensity: VisualDensity.compact,
                    checkboxShape: CircleBorder(side: BorderSide(color: Colors.green[700]!, width: 1)),
                    title: Text(
                      group.name,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                      ),
                    ),
                    // subtitle: Text(
                    //   'ID: ${group.id}',
                    //   style: TextStyle(fontSize: 12, color: Colors.grey[600],
                    //   ),
                    // ),
                    value: group.isAssigned,
                    activeColor: Colors.green[700],
                    onChanged: isLoading ? null : (bool? value) {
                      if (value != null) {
                        onToggleGroup(index);
                      }
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                },
              ),
      ),

      // Summary section
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border(
            top: BorderSide(color: Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, size: 4, color: Colors.green[700]),
            const SizedBox(width: 4),
            Text(
              '${groups.where((g) => g.isAssigned).length} of ${groups.length} groups selected',
              style: TextStyle(
                fontSize: 10,
                color: Colors.green[900],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
    ),
  );
}
