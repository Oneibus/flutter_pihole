import 'package:flutter/material.dart';

/// A collapsible side panel that can slide in and out with smooth animations.
///
/// Features:
/// - Smooth slide-in/out animations
/// - Manual toggle via tap on handle
/// - Drag gesture support for opening/closing
/// - Visible handle when collapsed for easy access
class CollapsiblePanel extends StatefulWidget {
  /// The content to display in the panel when expanded
  final Widget child;

  /// Width of the panel when fully expanded
  final double expandedWidth;

  /// Width of the visible handle when collapsed
  final double collapsedWidth;

  /// Duration of the collapse/expand animation
  final Duration animationDuration;

  /// Callback when panel state changes
  final ValueChanged<bool>? onExpandedChanged;

  /// Initial expanded state
  final bool initiallyExpanded;

  const CollapsiblePanel({
    super.key,
    required this.child,
    this.expandedWidth = 100,
    this.collapsedWidth = 8,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onExpandedChanged,
    this.initiallyExpanded = true,
  });

  @override
  State<CollapsiblePanel> createState() => CollapsiblePanelState();
}

class CollapsiblePanelState extends State<CollapsiblePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _widthAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;

    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
      value: _isExpanded ? 1.0 : 0.0,
    );

    _widthAnimation = Tween<double>(
      begin: widget.collapsedWidth,
      end: widget.expandedWidth,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Programmatically expand the panel
  void expand() {
    if (!_isExpanded) {
      setState(() {
        _isExpanded = true;
      });
      _controller.forward();
      widget.onExpandedChanged?.call(true);
    }
  }

  /// Programmatically collapse the panel
  void collapse() {
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
      });
      _controller.reverse();
      widget.onExpandedChanged?.call(false);
    }
  }

  /// Toggle between expanded and collapsed states
  void toggle() {
    if (_isExpanded) {
      collapse();
    } else {
      expand();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _widthAnimation,
      builder: (context, child) {
        final currentWidth = _widthAnimation.value;
        final isNearlyCollapsed = currentWidth < widget.expandedWidth * 0.3;

        return Container(
          width: currentWidth,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          clipBehavior: Clip.none,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main content (only visible when expanded enough)
              if (!isNearlyCollapsed)
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: widget.child,
                  ),
                ),

              // Handle bar on the right edge
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: MouseRegion(
                  onEnter: (_) {
                    // Auto-expand when hovering over handle while collapsed
                    if (!_isExpanded) {
                      expand();
                    }
                  },
                  child: GestureDetector(
                    onTap: toggle,
                    onHorizontalDragUpdate: (details) {
                      // Update animation based on drag
                      final delta = details.primaryDelta ?? 0;
                      final change = delta /
                          (widget.expandedWidth - widget.collapsedWidth);
                      _controller.value =
                          (_controller.value + change).clamp(0.0, 1.0);
                    },
                    onHorizontalDragEnd: (details) {
                      // Snap to nearest state based on velocity and position
                      if (_controller.value > 0.5 ||
                          (details.primaryVelocity ?? 0) > 500) {
                        expand();
                      } else {
                        collapse();
                      }
                    },
                    child: Container(
                      width: 16,
                      color: Colors.transparent,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: isNearlyCollapsed ? widget.collapsedWidth : 4,
                          decoration: BoxDecoration(
                            color: _isExpanded
                                ? Colors.grey[400]
                                : Colors.green[400],
                            borderRadius: BorderRadius.circular(1),
                          ),
                          child: isNearlyCollapsed
                              ? Align(
                                  child: Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    blendMode: BlendMode.srcOver,
                                    color: Colors.green[800],
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
