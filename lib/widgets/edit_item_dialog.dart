import 'package:flutter/material.dart';
import 'common_dialog.dart';

class DynamicItemEditDialog {
  static Future<void> show(BuildContext context, IconData icon, String title, Widget dialogContent,
        Function()? onSave, 
        Function()? onCancel) {

    return DialogBuilder()
        .setTitle(title)
        .setTitleIcon(icon)
        .setTitleBackgroundColor(Colors.green[800]!)
        .setWidth(440) // Fixed width: 120+120+120 + 8+8 spacing + 32 padding
        .setMaxHeight(200) // Enough height for content + buttons at bottom
        .setContent(
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: dialogContent,
          ),
        )
        .setActions([
          ElevatedButton.icon(
            onPressed: onSave,
            icon: const Icon(Icons.save, size: 14),
            label: Text('Save'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[700],
              foregroundColor: Colors.white,
              // padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: onCancel,
            label: const Text('Cancel'),
            icon: const Icon(Icons.cancel, size: 14),
          ),
        ]).show<bool>(context);
  }
}

Widget editItemDialogContent(
  TextEditingController primaryController,
  TextEditingController secondaryController,
  String status,
  Function(String) onPrimaryChanged,
  Function(String) onSecondaryChanged,
  Function(String?) onStatusChanged) {

  final TextStyle _textStyle = const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w400);
  final Color _cursorColor = Colors.green[800]!;
  final Color _bkgndCursorColor = Colors.grey;
  final BoxDecoration _boxDecoration = BoxDecoration(
    border: Border.all(color: Colors.green[800]!),
    borderRadius: BorderRadius.circular(4),
  );

  return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Input
              Container(alignment: Alignment.centerLeft,
                width: 120, height: 32,
                padding: const EdgeInsets.all(4),
                decoration: _boxDecoration,

                child: EditableText(
                  controller: primaryController,
                  focusNode: FocusNode(),
                  style: _textStyle,
                  cursorColor: _cursorColor,
                  backgroundCursorColor: _bkgndCursorColor,
                  onChanged: (value) {
                      onPrimaryChanged(value);
                  },
                ),
              ),

              const SizedBox(width: 8),
              // Comment Input
              Container(alignment: Alignment.centerLeft,
                width: 120, height: 32,
                padding: const EdgeInsets.all(4),
                decoration: _boxDecoration,

                child: EditableText(
                  controller: secondaryController,
                  focusNode: FocusNode(),
                  style: _textStyle,
                  cursorColor: _cursorColor,
                  backgroundCursorColor: _bkgndCursorColor,
                  onChanged: (value) {
                    onSecondaryChanged(value);
                  },
                ),
              ),

              const SizedBox(width: 8),

              // Status Dropdown
              Container(width: 120, height: 50, 
                padding: EdgeInsets.zero,
                alignment: Alignment.topCenter,
                child: DropdownMenu<String>(
                  width: 120,
                  dropdownMenuEntries: const [
                    DropdownMenuEntry(value: 'enabled', label: 'enabled'),
                    DropdownMenuEntry(value: 'disabled', label: 'disabled'),
                  ],
                  menuStyle: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
                  inputDecorationTheme: const InputDecorationTheme(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  textStyle: _textStyle,
                  initialSelection: status,
                  onSelected: (String? value) {
                    onStatusChanged(value);
                  },
                ),
              ),
            ],
          );
}
