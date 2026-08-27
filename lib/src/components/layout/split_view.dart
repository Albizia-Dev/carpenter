import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

enum CarpenterSplitOrientation { horizontal, vertical }

final class CarpenterSplitView extends StatelessWidget {
  const CarpenterSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    required this.position,
    required this.onPositionChanged,
    this.orientation = CarpenterSplitOrientation.horizontal,
    this.minimumPosition = 0.2,
    this.maximumPosition = 0.8,
    this.dividerSemanticLabel = 'Resize regions',
  }) : assert(position >= 0 && position <= 1),
       assert(minimumPosition >= 0 && minimumPosition <= 1),
       assert(maximumPosition >= 0 && maximumPosition <= 1),
       assert(minimumPosition <= maximumPosition);

  final Widget primary;
  final Widget secondary;
  final double position;
  final ValueChanged<double>? onPositionChanged;
  final CarpenterSplitOrientation orientation;
  final double minimumPosition;
  final double maximumPosition;
  final String dividerSemanticLabel;

  void _change(double delta) => onPositionChanged?.call(
    (position + delta).clamp(minimumPosition, maximumPosition),
  );

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final dividerExtent = context.units(theme.sizes.layoutSplitDivider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = orientation == CarpenterSplitOrientation.horizontal;
        final available = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        assert(
          available.isFinite,
          'CarpenterSplitView requires a bounded main axis.',
        );
        final effectiveDividerExtent = available < dividerExtent
            ? available
            : dividerExtent;
        final contentExtent = available > effectiveDividerExtent
            ? available - effectiveDividerExtent
            : 0.0;
        final primaryExtent = contentExtent * position;
        final primaryRegion = SizedBox(
          width: horizontal ? primaryExtent : null,
          height: horizontal ? null : primaryExtent,
          child: primary,
        );
        final divider = _SplitDivider(
          orientation: orientation,
          extent: effectiveDividerExtent,
          semanticLabel: dividerSemanticLabel,
          value: position,
          enabled: onPositionChanged != null,
          onDelta: (delta) {
            if (contentExtent == 0) return;
            final logicalDelta =
                horizontal && Directionality.of(context) == TextDirection.rtl
                ? -delta
                : delta;
            onPositionChanged?.call(
              (position + logicalDelta / contentExtent).clamp(
                minimumPosition,
                maximumPosition,
              ),
            );
          },
          onDecrease: () => _change(-0.05),
          onIncrease: () => _change(0.05),
        );
        if (horizontal) {
          return Row(
            children: [
              primaryRegion,
              divider,
              Expanded(child: secondary),
            ],
          );
        }
        return Column(
          children: [
            primaryRegion,
            divider,
            Expanded(child: secondary),
          ],
        );
      },
    );
  }
}

final class _SplitDivider extends StatefulWidget {
  const _SplitDivider({
    required this.orientation,
    required this.extent,
    required this.semanticLabel,
    required this.value,
    required this.enabled,
    required this.onDelta,
    required this.onDecrease,
    required this.onIncrease,
  });

  final CarpenterSplitOrientation orientation;
  final double extent;
  final String semanticLabel;
  final double value;
  final bool enabled;
  final ValueChanged<double> onDelta;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  State<_SplitDivider> createState() => _SplitDividerState();
}

final class _SplitDividerState extends State<_SplitDivider> {
  bool _focused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final horizontal =
        widget.orientation == CarpenterSplitOrientation.horizontal;
    final decrementKey = horizontal
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowUp;
    final incrementKey = horizontal
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowDown;
    final divider = Container(
      width: horizontal ? widget.extent : double.infinity,
      height: horizontal ? double.infinity : widget.extent,
      color: _focused ? theme.focus.color : theme.overlay.border,
    );
    return Semantics(
      slider: true,
      enabled: widget.enabled,
      label: widget.semanticLabel,
      value: '${(widget.value * 100).round()}%',
      decreasedValue: '${((widget.value - 0.05).clamp(0, 1) * 100).round()}%',
      increasedValue: '${((widget.value + 0.05).clamp(0, 1) * 100).round()}%',
      onDecrease: widget.enabled ? widget.onDecrease : null,
      onIncrease: widget.enabled ? widget.onIncrease : null,
      child: FocusableActionDetector(
        enabled: widget.enabled,
        focusNode: _focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        shortcuts: {
          SingleActivator(decrementKey): const _DecreaseSplitIntent(),
          SingleActivator(incrementKey): const _IncreaseSplitIntent(),
        },
        actions: {
          _DecreaseSplitIntent: CallbackAction<_DecreaseSplitIntent>(
            onInvoke: (_) {
              widget.onDecrease();
              return null;
            },
          ),
          _IncreaseSplitIntent: CallbackAction<_IncreaseSplitIntent>(
            onInvoke: (_) {
              widget.onIncrease();
              return null;
            },
          ),
        },
        child: MouseRegion(
          cursor: widget.enabled
              ? horizontal
                    ? SystemMouseCursors.resizeColumn
                    : SystemMouseCursors.resizeRow
              : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled ? _focusNode.requestFocus : null,
            onHorizontalDragUpdate: widget.enabled && horizontal
                ? (details) => widget.onDelta(details.delta.dx)
                : null,
            onVerticalDragUpdate: widget.enabled && !horizontal
                ? (details) => widget.onDelta(details.delta.dy)
                : null,
            child: divider,
          ),
        ),
      ),
    );
  }
}

final class _DecreaseSplitIntent extends Intent {
  const _DecreaseSplitIntent();
}

final class _IncreaseSplitIntent extends Intent {
  const _IncreaseSplitIntent();
}
