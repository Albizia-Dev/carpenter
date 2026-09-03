import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../button/toggle_button.dart';

@immutable
final class CarpenterSelectionButtonOption<T> {
  const CarpenterSelectionButtonOption({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.semanticLabel,
  });

  final T value;
  final String label;
  final CarpenterIconSource? icon;
  final bool enabled;
  final String? semanticLabel;
}

/// Controlled single-choice group for switching one local content scope.
final class CarpenterSelectionButtonGroup<T> extends StatefulWidget {
  const CarpenterSelectionButtonGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.size = ControlSize.medium,
    this.colorRole = ActionColorRole.primary,
    this.semanticLabel = 'View selection',
  }) : assert(options.length > 0);

  final List<CarpenterSelectionButtonOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;
  final ControlSize size;
  final ActionColorRole colorRole;
  final String semanticLabel;

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
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < widget.options.length; index++)
          CarpenterToggleButton(
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
            onChanged:
                widget.onChanged == null || !widget.options[index].enabled
                ? null
                : (_) => widget.onChanged!(widget.options[index].value),
          ),
      ],
    ),
  );
}
