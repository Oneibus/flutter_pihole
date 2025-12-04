import 'package:flutter/material.dart';
import 'common_dialog.dart';

class DynamicItemEditDialog {
  static Future<void> show(BuildContext context, IconData icon, String title, Widget dialogContent,
        Function()? onSave, 
        Function()? onCancel) {

    return DialogBuilder()
        .setTitle(title)
        .setTitleIcon(icon)
        .setSpacable(true)
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
  final TextStyle _scaleDropTextStyle = const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w400);
  final Color _cursorColor = Colors.green[800]!;
  final Color _bkgndCursorColor = Colors.grey;
  final BoxDecoration _boxDecoration = BoxDecoration(
    border: Border.all(color: Colors.green[800]!, width: 1, strokeAlign: BorderSide.strokeAlignCenter),
    borderRadius: BorderRadius.circular(8),
  );
  final OutlineInputBorder _dropDownBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: Colors.green[800]!, width: 1),
  );

  return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // First row: Name and Comment inputs
              Row(
                /// mainAxisSize: MainAxisSize.min,
                  children: [
                  // Name Input
                  Expanded(
                    flex: 3,
                    child: Container(alignment: Alignment.centerLeft,
                      width: 220, height: 32,
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
                  ),
                  const SizedBox(width: 8),
                  // Comment Input
                  Expanded(
                    flex: 3,
                    child: Container(alignment: Alignment.centerLeft,
                      width: 140, height: 32,
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
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Second row: Status Dropdown
              ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 160,
                  maxHeight: 32,
                  minHeight: 32,
                ),
                child: Transform.scale(
                  scale: 0.80,
                  alignment: Alignment.centerLeft,
                  child: DropdownMenu<String>(
                    width: 140,
                    menuHeight: 200,
                    alignmentOffset: const Offset(0, 4),
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 'enabled', label: 'enabled'),
                      DropdownMenuEntry(value: 'disabled', label: 'disabled'),
                    ],
                    menuStyle: const MenuStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      // contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                      border: _dropDownBorder,
                      enabledBorder: _dropDownBorder,
                      focusedBorder: _dropDownBorder,
                    ),
                    trailingIcon: const Icon(Icons.arrow_drop_down, size: 16),
                    selectedTrailingIcon: const Icon(Icons.arrow_drop_up, size: 16),
                    textStyle: _scaleDropTextStyle,
                    initialSelection: status,
                    onSelected: (String? value) {
                      onStatusChanged(value);
                    },
                  ),
                ),
              ),
            ],
          );
}
