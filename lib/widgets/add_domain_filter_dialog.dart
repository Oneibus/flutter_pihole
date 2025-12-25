import 'package:flutter/material.dart';
import '../pihole/api_models.dart';
import 'common_dialog.dart';

/// Callback type for creating a domain filter
typedef CreateDomainFilterCallback = Future<void> Function({
  required String type,
  required String kind,
  required String domainFilter,
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
    String domainFilter = domain;
    String filterType = 'deny'; // allow or deny
    String filterKind = 'exact'; // exact or regex
    String? comment;
    List<int> selectedGroups = [0]; // Default group
    bool enabled = true;
    bool isLoading = false;
    
    // Create controllers once outside builder
    final domainFilterController = TextEditingController(text: domainFilter);
    final commentController = TextEditingController(text: comment);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {

          Future<void> handleSave() async {
            setState(() {
              isLoading = true;
            });

            try {
              await onCreate(
                type: filterType,
                kind: filterKind,
                domainFilter: domainFilterController.text.isEmpty ? domainFilter : domainFilterController.text,
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
              .setMaxHeight(510)
              .setContent(
                addDomainFilterDialogContent(
                  domainFilter: domainFilter,
                  domainController: domainFilterController,
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
                  onDomainChanged: (String value) {
                    setState(() {
                      domainFilter = value;
                    });
                  },
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
  required String domainFilter,
  required String filterType,
  required String filterKind,
  required TextEditingController commentController,
  required List<Group> availableGroups,
  required List<int> selectedGroups,
  required bool enabled,
  required bool isLoading,
  required TextEditingController domainController,
  required Function(String) onDomainChanged,
  required Function(String) onFilterTypeChanged,
  required Function(String) onFilterKindChanged,
  required Function(bool?) onEnabledChanged,
  required Function(int) onGroupToggled,
}) {

  final TextStyle _textStyle = const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400);
  final TextStyle _scaleDropTextStyle = const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400);
  final Color _cursorColor = Colors.green[800]!;
  final Color _bkgndCursorColor = Colors.grey;
  final BoxDecoration _boxDecoration = BoxDecoration(
    border: Border.all(color: Colors.green[800]!, width: 1, strokeAlign: BorderSide.strokeAlignCenter),
    borderRadius: BorderRadius.circular(8),
  );

  return SingleChildScrollView(
    padding: const EdgeInsets.all(12.0),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                'Domain Filter:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: TextField(
                controller: domainController,
                style: _textStyle,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.green[800]!, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  isDense: true,
                ),
                onChanged: (value) {
                  onDomainChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Filter Type (Allow/Deny)
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                'Filter Type:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Allow', style: TextStyle(fontSize: 12)),
                value: 'allow',
                groupValue: filterType,
                onChanged: isLoading ? null : (value) => onFilterTypeChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Deny', style: TextStyle(fontSize: 12)),
                value: 'deny',
                groupValue: filterType,
                onChanged: isLoading ? null : (value) => onFilterTypeChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 2),

        // Filter Kind (Exact/Regex)
        Row(
          children: [
            const SizedBox(
              width: 100,
              child: Text(
                'Match Type:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Exact', style: TextStyle(fontSize: 12)),
                value: 'exact',
                groupValue: filterKind,
                onChanged: isLoading ? null : (value) => onFilterKindChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
            Expanded(
              child: RadioListTile<String>(
                title: const Text('Regex', style: TextStyle(fontSize: 12)),
                value: 'regex',
                groupValue: filterKind,
                onChanged: isLoading ? null : (value) => onFilterKindChanged(value!),
                dense: true,
                contentPadding: EdgeInsets.zero,
                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Comment field
        const Text(
          'Comment (optional):',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: commentController,
          enabled: !isLoading,
          decoration: InputDecoration(
            hintText: 'Add a note about this filter',
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          style: const TextStyle(fontSize: 12),
        ),

        const SizedBox(height: 4),

        // Enabled checkbox
        CheckboxListTile(
          title: const Text('Enabled', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          checkboxShape: CircleBorder(side: BorderSide(color: Colors.green[700]!, width: 1)),
          value: enabled,
          onChanged: isLoading ? null : onEnabledChanged,
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
          visualDensity: VisualDensity.compact,
        ),

        const SizedBox(height: 4),

        // Group assignment
        const Text(
          'Assign to Groups:',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        
        // Groups list
        Container(
          height: 100,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: availableGroups.isEmpty
              ? const Center(
                  child: Text(
                    'No groups available',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                )
              : ListView.builder(
                  itemCount: availableGroups.length,
                  itemBuilder: (context, index) {
                    final group = availableGroups[index];
                    final isSelected = selectedGroups.contains(group.id);

                    return CheckboxListTile(
                      title: Text(
                        group.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                      checkboxShape: CircleBorder(side: BorderSide(color: Colors.green[700]!, width: 1)),
                      value: isSelected,
                      onChanged: isLoading
                          ? null
                          : (bool? value) {
                              if (value != null) {
                                onGroupToggled(group.id);
                              }
                            },
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 0),
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    );
                  },
                ),
        ),
      ],
    ),
  );
}
