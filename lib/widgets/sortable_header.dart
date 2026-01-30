import 'package:flutter/material.dart';

enum SortOrder {
  none,
  ascending,
  descending,
}

/// A clickable header cell that shows a dropdown menu for sorting and filtering
class SortableHeaderCell extends StatelessWidget {
  final String label;
  final SortOrder sortOrder;
  final String? filterText;
  final VoidCallback onSort;
  final VoidCallback? onSortDirect; // For clicking the sort icon directly
  final ValueChanged<String> onFilterChanged;
  final bool isExpanded;
  final int? flex;
  final double? width;

  const SortableHeaderCell({
    super.key,
    required this.label,
    this.sortOrder = SortOrder.none,
    this.filterText,
    required this.onSort,
    this.onSortDirect,
    required this.onFilterChanged,
    this.isExpanded = false,
    this.flex,
    this.width,
  });

  Widget _buildHeaderContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label text - clickable to show full menu
          Flexible(
            child: InkWell(
              onTap: () => _showHeaderMenu(context),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Sort indicator - clickable to toggle sort
          if (sortOrder != SortOrder.none)
            InkWell(
              onTap: _toggleSortDirect,
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Icon(
                  sortOrder == SortOrder.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          // Filter indicator - clickable to open filter dialog
          if (filterText != null && filterText!.isNotEmpty)
            InkWell(
              onTap: () => _showFilterDialog(context),
              child: const Padding(
                padding: EdgeInsets.all(2.0),
                child: Icon(
                  Icons.filter_alt,
                  size: 14,
                  color: Colors.amber,
                ),
              ),
            ),
          // Dropdown icon - clickable to show full menu
          InkWell(
            onTap: () => _showHeaderMenu(context),
            child: const Padding(
              padding: EdgeInsets.all(2.0),
              child: Icon(
                Icons.arrow_drop_down,
                size: 18,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSortDirect() {
    // Directly toggle between ascending and descending
    if (onSortDirect != null) {
      onSortDirect!();
    } else {
      onSort(); // Fallback to regular sort if direct callback not provided
    }
  }

  void _showHeaderMenu(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height,
      ),
      elevation: 8.0,
      useRootNavigator: false,
      constraints: const BoxConstraints(
        minWidth: 180,
        maxWidth: 240,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      // Remove animation completely
      popUpAnimationStyle: AnimationStyle.noAnimation,
      items: [
        // Sort section
        const PopupMenuItem<String>(
          enabled: false,
          height: 24,
          child: Text(
            'Sort',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_asc',
          height: 32,
          child: Row(
            children: [
              Icon(
                Icons.arrow_upward,
                size: 14,
                color: sortOrder == SortOrder.ascending
                    ? Colors.green[700]
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              const Text('Ascending', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_desc',
          height: 32,
          child: Row(
            children: [
              Icon(
                Icons.arrow_downward,
                size: 14,
                color: sortOrder == SortOrder.descending
                    ? Colors.green[700]
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              const Text('Descending', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'sort_none',
          height: 32,
          child: Row(
            children: [
              Icon(
                Icons.clear,
                size: 14,
                color: sortOrder == SortOrder.none
                    ? Colors.green[700]
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              const Text('No Sort', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        const PopupMenuDivider(),
        // Filter section
        const PopupMenuItem<String>(
          enabled: false,
          height: 24,
          child: Text(
            'Filter',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: Colors.black54,
            ),
          ),
        ),
        PopupMenuItem<String>(
          value: 'filter',
          height: 32,
          child: const Row(
            children: [
              Icon(Icons.filter_alt, size: 14, color: Colors.blue),
              SizedBox(width: 6),
              Text('Set Filter...', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
        if (filterText != null && filterText!.isNotEmpty)
          PopupMenuItem<String>(
            value: 'clear_filter',
            height: 32,
            child: const Row(
              children: [
                Icon(Icons.clear, size: 14, color: Colors.red),
                SizedBox(width: 6),
                Text('Clear Filter', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
      ],
    ).then((value) {
      if (value == null) return;

      switch (value) {
        case 'sort_asc':
        case 'sort_desc':
        case 'sort_none':
          onSort();
          break;
        case 'filter':
          _showFilterDialog(context);
          break;
        case 'clear_filter':
          onFilterChanged('');
          break;
      }
    });
  }

  void _showFilterDialog(BuildContext context) {
    final controller = TextEditingController(text: filterText ?? '');
    showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        title: Container(
          decoration: BoxDecoration(
            color: Colors.green[800]!,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24), bottom: Radius.circular(0))
          ),
          padding: const EdgeInsets.all(12),
          child: Text(
            'Filter by $label',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
        contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        actionsPadding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Filter prefix',
            labelStyle: const TextStyle(fontSize: 12),
            hintText: 'Enter text to filter...',
            hintStyle: const TextStyle(fontSize: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            isDense: true,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, size: 18),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () {
                controller.clear();
              },
            ),
          ),
          onSubmitted: (value) {
            onFilterChanged(value);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              onFilterChanged(controller.text);
              Navigator.of(context).pop();
            },
            icon: Icon(Icons.check, size: 12),
            label: Text('Apply', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(width: 2),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            label: const Text('Cancel', style: TextStyle(fontSize: 12)),
            icon: const Icon(Icons.cancel, size: 12),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isExpanded) {
      return Expanded(
        flex: flex ?? 1,
        child: _buildHeaderContent(context),
      );
    } else if (width != null) {
      return SizedBox(
        width: width,
        child: _buildHeaderContent(context),
      );
    } else {
      return _buildHeaderContent(context);
    }
  }
}
