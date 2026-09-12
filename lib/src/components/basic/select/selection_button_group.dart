import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../button/toggle_button.dart';

/// Descriptor for one choice in a controlled [CarpenterSelectionButtonGroup].
@immutable
final class CarpenterSelectionButtonOption<T> {
  /// Creates a choice with an application-owned [value], visible label, and
  /// optional icon.
  const CarpenterSelectionButtonOption({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Value delivered when this option is selected; keep option values
  /// distinct.
  final T value;

  /// Visible text naming the control or choice; keep it meaningful without
  /// relying on an icon.
  final String label;

  /// Optional icon shown on this option's toggle button.
  final CarpenterIconSource? icon;

  /// Whether this option can be selected. The whole group is also disabled
  /// when its callback is null.
  final bool enabled;

  /// Accessible name supplied to assistive technology. When omitted, the
  /// visible label is used.
  final String? semanticLabel;
}

/// Controlled single-choice group for switching one local content scope.
final class CarpenterSelectionButtonGroup<T> extends StatefulWidget {
  /// Creates a connected single-choice button group. Asserts that [options]
  /// is not empty; the caller owns the selected value.
  const CarpenterSelectionButtonGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.size = ControlSize.medium,
    this.colorRole = ActionColorRole.primary,
    this.semanticLabel = 'Выбор представления',
    this.fillAvailableWidth = false,
  }) : assert(options.length > 0);

  /// Choices in presentation and keyboard order. Keep values stable and
  /// distinct across rebuilds.
  final List<CarpenterSelectionButtonOption<T>> options;

  /// Current selected option value; the group compares option values using
  /// equality.
  final T value;

  /// Receives the value of an activated enabled option. Update [value] to
  /// commit the choice; null disables the group.
  final ValueChanged<T>? onChanged;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final ActionColorRole colorRole;

  /// Accessible name for the whole choice group; defaults to "View
  /// selection".
  final String semanticLabel;

  /// Whether the connected choices should divide a bounded available width.
  ///
  /// This is useful for compact scope switchers whose choices must remain
  /// simultaneously reachable instead of overflowing off-screen. In an
  /// unbounded horizontal context the group keeps its intrinsic width. Bounded
  /// groups wrap into joined rows when labels would otherwise be truncated;
  /// keyboard traversal keeps the original option order.
  final bool fillAvailableWidth;

  @override
  State<CarpenterSelectionButtonGroup<T>> createState() =>
      _CarpenterSelectionButtonGroupState<T>();
}

final class _CarpenterSelectionButtonGroupState<T>
    extends State<CarpenterSelectionButtonGroup<T>> {
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _createFocusNodes();
  }

  @override
  void didUpdateWidget(CarpenterSelectionButtonGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options.length != widget.options.length) {
      _disposeFocusNodes();
      _createFocusNodes();
    }
  }

  void _createFocusNodes() {
    _focusNodes = List.generate(
      widget.options.length,
      (index) => FocusNode(
        debugLabel: 'Selection button ${widget.options[index].label}',
      ),
    );
  }

  void _disposeFocusNodes() {
    for (final node in _focusNodes) {
      node.dispose();
    }
  }

  @override
  void dispose() {
    _disposeFocusNodes();
    super.dispose();
  }

  void _move(int index, int delta) {
    final callback = widget.onChanged;
    if (callback == null) return;
    for (
      var target = index + delta;
      target >= 0 && target < widget.options.length;
      target += delta
    ) {
      if (widget.options[target].enabled) {
        callback(widget.options[target].value);
        _focusNodes[target].requestFocus();
        return;
      }
    }
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _move(index, -1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _move(index, 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.home) {
      final target = widget.options.indexWhere((option) => option.enabled);
      if (target >= 0) {
        widget.onChanged?.call(widget.options[target].value);
        _focusNodes[target].requestFocus();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      final target = widget.options.lastIndexWhere((option) => option.enabled);
      if (target >= 0) {
        widget.onChanged?.call(widget.options[target].value);
        _focusNodes[target].requestFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      final index = _focusNodes.indexWhere((node) => node.hasFocus);
      return index < 0 ? KeyEventResult.ignored : _handleKey(index, event);
    },
    child: Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final distribute =
              widget.fillAvailableWidth && constraints.hasBoundedWidth;
          Widget option(int index, {required bool first, required bool last}) =>
              CarpenterToggleButton(
                label: widget.options[index].label,
                semanticLabel: widget.options[index].semanticLabel,
                checked: widget.options[index].value == widget.value,
                icon: widget.options[index].icon,
                size: widget.size,
                colorRole: widget.colorRole,
                shape: CarpenterShape(
                  start: first ? ShapeRole.rounded : ShapeRole.none,
                  end: last ? ShapeRole.rounded : ShapeRole.none,
                ),
                focusNode: _focusNodes[index],
                onChanged:
                    widget.onChanged == null || !widget.options[index].enabled
                    ? null
                    : (_) => widget.onChanged!(widget.options[index].value),
              );

          final rows = <List<int>>[[]];
          var widest = 0.0;
          final theme = CarpenterTheme.of(context);
          for (var index = 0; index < widget.options.length; index++) {
            if (distribute) {
              final item = widget.options[index];
              final painter = TextPainter(
                text: TextSpan(
                  text: item.label,
                  style: theme.typography.action(
                    context,
                    widget.size,
                    TypographyEmphasis.medium,
                  ),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final width =
                  painter.width.ceilToDouble() +
                  context.units(
                        theme.spacing.actionHorizontalPadding(widget.size),
                      ) *
                      2 +
                  context.units(theme.shapes.actionBorderWidth) * 2 +
                  context.units(theme.focus.gap) * 2 +
                  (item.icon == null
                      ? 0
                      : MediaQuery.textScalerOf(context).scale(
                              context.units(
                                theme.sizes.actionIcon(widget.size),
                              ),
                            ) +
                            context.units(
                              theme.spacing.actionGap(widget.size),
                            ));
              painter.dispose();
              final nextWidest = math.max(widest, width);
              if (rows.last.isNotEmpty &&
                  nextWidest * (rows.last.length + 1) > constraints.maxWidth) {
                rows.add([]);
                widest = width;
              } else {
                widest = nextWidest;
              }
            }
            rows.last.add(index);
          }
          Widget row(List<int> indices) => Row(
            mainAxisSize: distribute ? MainAxisSize.max : MainAxisSize.min,
            children: [
              for (final index in indices)
                if (distribute)
                  Expanded(
                    child: option(
                      index,
                      first: index == indices.first,
                      last: index == indices.last,
                    ),
                  )
                else
                  option(
                    index,
                    first: index == indices.first,
                    last: index == indices.last,
                  ),
            ],
          );
          if (rows.length == 1) return row(rows.single);
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0)
                  SizedBox(height: context.units(theme.spacing.small) / 2),
                row(rows[index]),
              ],
            ],
          );
        },
      ),
    ),
  );
}
