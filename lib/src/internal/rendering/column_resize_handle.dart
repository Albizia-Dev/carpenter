import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

/// Shared pointer resize behaviour for tabular collection columns.
final class ColumnResizeHandle extends StatefulWidget {
  const ColumnResizeHandle({
    super.key,
    required this.width,
    required this.currentWidth,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.onChanged,
  });

  final double width;
  final double currentWidth;
  final double minimumWidth;
  final double maximumWidth;
  final ValueChanged<double> onChanged;

  @override
  State<ColumnResizeHandle> createState() => _ColumnResizeHandleState();
}

final class _ColumnResizeHandleState extends State<ColumnResizeHandle> {
  late double _dragWidth;
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final active = _hovered || _dragging;
    final strokeWidth = active
        ? context.units(theme.focus.width)
        : context.units(theme.shapes.tableBorderWidth);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragWidth = widget.currentWidth;
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (details) {
          final logicalDelta = Directionality.of(context) == TextDirection.rtl
              ? -details.delta.dx
              : details.delta.dx;
          _dragWidth = (_dragWidth + logicalDelta).clamp(
            widget.minimumWidth,
            widget.maximumWidth,
          );
          widget.onChanged(_dragWidth);
        },
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.width,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: strokeWidth,
              height: double.infinity,
              child: ColoredBox(
                color: active ? theme.focus.color : theme.overlay.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
