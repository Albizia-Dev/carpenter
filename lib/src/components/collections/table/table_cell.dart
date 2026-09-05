import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';
import '../../../internal/rendering/interactive_region.dart';
import '../table_metrics.dart';
import 'table_column.dart';

/// Shared cell chrome for table-shaped collections.
///
/// Width, two-axis alignment and optional content padding live here so regular
/// tables and tree tables do not reimplement cell placement independently.
/// [padded] is explicit so legacy tree-table geometry can migrate separately.
final class CarpenterTableCellChrome extends StatelessWidget {
  const CarpenterTableCellChrome({
    super.key,
    required this.width,
    required this.alignment,
    required this.verticalAlignment,
    required this.child,
    this.padded = true,
  });

  final double width;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final metrics = CarpenterTableMetrics.resolve(context);
    Widget content = Align(
      alignment: carpenterTableCellAlignment(alignment, verticalAlignment),
      child: child,
    );
    if (padded) {
      content = Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: metrics.verticalPadding,
        ),
        child: content,
      );
    }
    return SizedBox(width: width, child: content);
  }
}

/// Shared header chrome with optional activation feedback and column resizing.
final class CarpenterTableHeaderCellChrome extends StatelessWidget {
  const CarpenterTableHeaderCellChrome({
    super.key,
    required this.id,
    required this.width,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.alignment,
    required this.verticalAlignment,
    required this.resizable,
    required this.onWidthChanged,
    required this.child,
    this.onActivate,
    this.padded = true,
    this.hoverFeedback = false,
    this.resizeHandleKey,
  });

  final String id;
  final double width;
  final double minimumWidth;
  final double maximumWidth;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final bool resizable;
  final ValueChanged<double> onWidthChanged;
  final Widget child;
  final VoidCallback? onActivate;
  final bool padded;
  final bool hoverFeedback;
  final Key? resizeHandleKey;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    Widget content = Align(
      alignment: carpenterTableCellAlignment(alignment, verticalAlignment),
      child: child,
    );
    if (padded) {
      content = Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: metrics.horizontalPadding,
          vertical: metrics.verticalPadding,
        ),
        child: content,
      );
    }
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveRegion(
            onActivate: onActivate,
            builder: (context, states, showFocusHighlight) => DecoratedBox(
              decoration: BoxDecoration(
                color: hoverFeedback && states.contains(WidgetState.hovered)
                    ? theme.overlay.hovered
                    : theme.surface.subtle,
                border: showFocusHighlight
                    ? Border.all(
                        color: theme.focus.color,
                        width: context.units(theme.focus.width),
                      )
                    : null,
              ),
              child: content,
            ),
          ),
          if (resizable)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CarpenterTableResizeHandle(
                key: resizeHandleKey,
                width: metrics.resizeHandleWidth,
                currentWidth: width,
                minimumWidth: minimumWidth,
                maximumWidth: maximumWidth,
                onChanged: onWidthChanged,
              ),
            ),
        ],
      ),
    );
  }
}

/// Shared pointer resize affordance for regular and tree table headers.
final class CarpenterTableResizeHandle extends StatefulWidget {
  const CarpenterTableResizeHandle({
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
  State<CarpenterTableResizeHandle> createState() =>
      _CarpenterTableResizeHandleState();
}

final class _CarpenterTableResizeHandleState
    extends State<CarpenterTableResizeHandle> {
  late double _dragWidth;
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final active = _hovered || _dragging;
    final strokeWidth = active
        ? context.units(theme.focus.width)
        : metrics.borderWidth;
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
