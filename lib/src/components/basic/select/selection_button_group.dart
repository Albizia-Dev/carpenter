import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
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
    this.semanticLabel = 'View selection',
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
  /// unbounded horizontal context the group keeps its intrinsic width.
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
        onKeyEvent: (node, event) => _handleKey(index, event),
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
    var target = index;
    while (true) {
      target = (target + delta).clamp(0, widget.options.length - 1);
      if (target == index) return;
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
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: widget.semanticLabel,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final distribute =
            widget.fillAvailableWidth && constraints.hasBoundedWidth;
        Widget option(int index) => CarpenterToggleButton(
          label: widget.options[index].label,
          semanticLabel: widget.options[index].semanticLabel,
          checked: widget.options[index].value == widget.value,
          icon: widget.options[index].icon,
          size: widget.size,
          colorRole: widget.colorRole,
          shape: CarpenterShape(
            start: index == 0 ? ShapeRole.rounded : ShapeRole.none,
            end: index == widget.options.length - 1
                ? ShapeRole.rounded
                : ShapeRole.none,
          ),
          focusNode: _focusNodes[index],
          onChanged: widget.onChanged == null || !widget.options[index].enabled
              ? null
              : (_) => widget.onChanged!(widget.options[index].value),
        );

        return Row(
          mainAxisSize: distribute ? MainAxisSize.max : MainAxisSize.min,
          children: [
            for (var index = 0; index < widget.options.length; index++)
              if (distribute) Expanded(child: option(index)) else option(index),
          ],
        );
      },
    ),
  );
}
