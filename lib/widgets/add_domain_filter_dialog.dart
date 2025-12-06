import 'package:flutter/material.dart';
import '../pihole/api_models.dart';
import 'common_dialog.dart';

/// Callback type for creating a domain filter
typedef CreateDomainFilterCallback = Future<void> Function({
  required String type,
  required String kind,
  required String domain,
  String? comment,
  List<int>? groups,
  bool enabled,
});

/// Dialog for creating domain filters from DNS queries
/// Allows user to select: allow/deny, exact/regex, group assignment
class AddDomainFilterDialog {
  static Future<void> show({
    required BuildContext context,
    required String domain,
    required List<Group> availableGroups,
    required CreateDomainFilterCallback onCreate,
  }) {
    String filterType = 'deny'; // allow or deny
    String filterKind = 'exact'; // exact or regex
    String? comment;
    List<int> selectedGroups = [0]; // Default group
    bool enabled = true;
    bool isLoading = false;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          final commentController = TextEditingController(text: comment);

          Future<void> handleSave() async {
            setState(() {
              isLoading = true;
            });

            try {
              await onCreate(
                type: filterType,
                kind: filterKind,
                domain: domain,
                comment: commentController.text.isEmpty ? null : commentController.text,
                groups: selectedGroups,
                enabled: enabled,
              );

              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Filter created for $domain'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error creating filter: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }

          return DialogBuilder()
              .setTitle('Add Domain Filter')
              .setSubtitle(Text('Domain: $domain'))
              .setTitleIcon(Icons.filter_alt)
              .setWidth(400)
              .setMaxHeight(500)
              .setContent(
                Expanded(
                  child: addDomainFilterDialogContent(
                    domain: domain,
                    filterType: filterType,
                    filterKind: filterKind,
                    commentController: commentController,
                    availableGroups: availableGroups,
                    selectedGroups: selectedGroups,
                    enabled: enabled,
                    isLoading: isLoading,
                    onFilterTypeChanged: (value) {
                      setState(() {
                        filterType = value;
                      });
                    },
                    onFilterKindChanged: (value) {
                      setState(() {
                        filterKind = value;
                      });
                    },
                    onEnabledChanged: (value) {
                      setState(() {
                        enabled = value ?? true;
                      });
                    },
                    onGroupToggled: (groupId) {
                      setState(() {
                        if (selectedGroups.contains(groupId)) {
                          selectedGroups.remove(groupId);
                        } else {
                          selectedGroups.add(groupId);
                        }
                      });
                    },
                  ),
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
                  label: Text(isLoading ? 'Creating...' : 'Create Filter'),
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

Widget addDomainFilterDialogContent({
  required String domain,
  required String filterType,
  required String filterKind,
  required TextEditingController commentController,
  required List<Group> availableGroups,
  required List<int> selectedGroups,
  required bool enabled,
  required bool isLoading,
  required Function(String) onFilterTypeChanged,
  required Function(String) onFilterKindChanged,
  required Function(bool?) onEnabledChanged,
  required Function(int) onGroupToggled,
}) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter Type (Allow/Deny)
        const Text(
          'Filter Type:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Allow', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Permit this domain', style: TextStyle(fontSize: 11)),
                value: 'allow',
                groupValue: filterType,
                onChanged: isLoading ? null : (value) => onFilterTypeChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Deny', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Block this domain', style: TextStyle(fontSize: 11)),
                value: 'deny',
                groupValue: filterType,
                onChanged: isLoading ? null : (value) => onFilterTypeChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),

        const Divider(),

        // Filter Kind (Exact/Regex)
        const Text(
          'Match Type:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Exact', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Exact domain match', style: TextStyle(fontSize: 11)),
                value: 'exact',
                groupValue: filterKind,
                onChanged: isLoading ? null : (value) => onFilterKindChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Regex', style: TextStyle(fontSize: 13)),
                subtitle: const Text('Pattern matching', style: TextStyle(fontSize: 11)),
                value: 'regex',
                groupValue: filterKind,
                onChanged: isLoading ? null : (value) => onFilterKindChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),

        const Divider(),

        // Comment field
        const Text(
          'Comment (optional):',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: commentController,
          enabled: !isLoading,
          decoration: InputDecoration(
            hintText: 'Add a note about this filter',
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(fontSize: 13),
        ),

        const SizedBox(height: 12),

        // Enabled checkbox
        CheckboxListTile(
          title: const Text('Enabled', style: TextStyle(fontSize: 13)),
          value: enabled,
          onChanged: isLoading ? null : onEnabledChanged,
          dense: true,
          contentPadding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        ),

        const Divider(),

        // Group assignment
        const Text(
          'Assign to Groups:',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        // Groups list
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: availableGroups.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      'No groups available',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: availableGroups.length,
                  itemBuilder: (context, index) {
                    final group = availableGroups[index];
                    final isSelected = selectedGroups.contains(group.id);

                    return CheckboxListTile(
                      title: Text(
                        group.name,
                        style: const TextStyle(fontSize: 13),
                      ),
                      subtitle: group.description.isNotEmpty
                          ? Text(
                              group.description,
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            )
                          : null,
                      value: isSelected,
                      onChanged: isLoading
                          ? null
                          : (bool? value) {
                              if (value != null) {
                                onGroupToggled(group.id);
                              }
                            },
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8.0),
                      visualDensity: VisualDensity.compact,
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
