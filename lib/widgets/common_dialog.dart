import 'package:flutter/material.dart';

/// A reusable base dialog widget with common styling and structure
/// Uses composition to allow custom content insertion
class BuildableCommonDialog extends StatelessWidget {
  final String title;
  final Widget? subtitle;
  final double maxHeight;
  final double maxWidth;
  final Widget content;
  final List<Widget>? actions;
  final bool isLoading;
  final Color? titleBackgroundColor;
  final Color? backgroundColor;
  final IconData? titleIcon;
  final bool spaceContent;

  const BuildableCommonDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    this.maxHeight = 480,
    this.maxWidth = 400,
    this.actions,
    this.isLoading = false,
    this.titleBackgroundColor,
    this.backgroundColor,
    this.titleIcon, 
    this.spaceContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleBgColor = titleBackgroundColor ?? Colors.green[700];
    final effectiveBgColor = backgroundColor ?? Colors.grey[50];

    return Dialog(
      backgroundColor: effectiveBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Container(
        width: maxWidth,
        constraints: BoxConstraints(
          maxHeight: maxHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: effectiveTitleBgColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),

              child: Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, color: Colors.white),
                    const SizedBox(width: 10),
                  ],

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          DefaultTextStyle(
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                            child: subtitle!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content area
            content,

            // // Spacer to push actions to bottom
            if (spaceContent) 
               const Spacer(),

            // Actions area (if provided)
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions!,
                ),
              ),

            // Loading indicator overlay
            if (isLoading)
              Container(
                padding: const EdgeInsets.all(8.0),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Builder pattern helper for creating dialogs with common structure
class DialogBuilder {
  String? title;
  Widget? subtitle;
  Widget? content;
  List<Widget>? actions;
  bool isLoading = false;
  double? width = 300;
  double? height = 300;
  double? minWidth;
  double? minHeight;
  double? maxWidth = 400;
  double? maxHeight = 400;
  Color? titleBackgroundColor;
  Color? backgroundColor;
  IconData? titleIcon;
  bool isSpaceable = false;

  DialogBuilder setTitle(String title) {
    this.title = title;
    return this;
  }

  DialogBuilder setSubtitle(Widget subtitle) {
    this.subtitle = subtitle;
    return this;
  }

  DialogBuilder setContent(Widget content) {
    this.content = content;
    return this;
  }

  DialogBuilder setActions(List<Widget> actions) {
    this.actions = actions;
    return this;
  }

  DialogBuilder setLoading(bool loading) {
    this.isLoading = loading;
    return this;
  }

  DialogBuilder setWidth(double width) {
    this.width = width;
    return this;
  }

  DialogBuilder setHeight(double height) {
    this.height = height;
    return this;
  }

  DialogBuilder setMinWidth(double minWidth) {
    this.minWidth = minWidth;
    return this;
  }

  DialogBuilder setMinHeight(double minHeight) {
    this.minHeight = minHeight;
    return this;
  }
  
  DialogBuilder setMaxWidth(double maxWidth) {
    this.maxWidth = maxWidth;
    return this;
  }

  DialogBuilder setMaxHeight(double maxHeight) {
    this.maxHeight = maxHeight;
    return this;
  }

  DialogBuilder setTitleBackgroundColor(Color color) {
    this.titleBackgroundColor = color;
    return this;
  }

  DialogBuilder setBackgroundColor(Color color) {
    this.backgroundColor = color;
    return this;
  }

  DialogBuilder setTitleIcon(IconData icon) {
    this.titleIcon = icon;
    return this;
  }

  DialogBuilder setSpacable(bool isSpaceable) {
    this.isSpaceable = isSpaceable;
    return this;
  }

  Widget build() {
    return BuildableCommonDialog(
      title: title ?? 'Dialog',
      subtitle: subtitle,
      content: content ?? const SizedBox.shrink(),
      actions: actions,
      isLoading: isLoading,
      maxWidth: width ?? maxWidth ?? 400,
      maxHeight: maxHeight ?? 400,
      titleBackgroundColor: titleBackgroundColor,
      backgroundColor: backgroundColor,
      titleIcon: titleIcon,
      spaceContent: isSpaceable,
    );
  }

  Future<T?> show<T>(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (context) => build(),
    );
  }
}
