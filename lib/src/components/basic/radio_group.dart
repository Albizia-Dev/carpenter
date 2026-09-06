import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../internal/rendering/radio_group_scope.dart';
import 'radio.dart';

/// Controlled group of mutually exclusive radio choices with shared selection
/// and keyboard navigation.
///
/// Children must have unique values. Supply [onChanged] and rebuild with the
/// chosen [value]; null disables the entire group. Horizontal groups wrap
/// rather than requiring a fixed-width row.
final class CarpenterRadioGroup<T> extends StatefulWidget {
  /// Creates a radio group whose [children] all use the same value type.
  /// [value] may be null to represent no selection.
  const CarpenterRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.orientation = Axis.vertical,
  });

  /// Currently selected child value, or null when no choice is selected.
  final T? value;

  /// Receives a chosen value from pointer or keyboard interaction. Null
  /// disables all choices; the group does not store the new selection.
  final ValueChanged<T>? onChanged;

  /// Radio choices in display and keyboard traversal order. Their values must
  /// be unique.
  final List<CarpenterRadio<T>> children;

  /// Vertical stacked presentation or horizontal wrapping presentation;
  /// defaults to vertical.
  final Axis orientation;

  @override
  State<CarpenterRadioGroup<T>> createState() => _CarpenterRadioGroupState<T>();
}

final class _CarpenterRadioGroupState<T> extends State<CarpenterRadioGroup<T>> {
  final Map<T, FocusNode> _focusNodes = {};

  void _register(T value, FocusNode focusNode) {
    _focusNodes[value] = focusNode;
  }

  void _unregister(T value, FocusNode focusNode) {
    if (identical(_focusNodes[value], focusNode)) _focusNodes.remove(value);
  }

  void _move(T value, bool forward) {
    if (widget.onChanged == null || widget.children.length < 2) return;
    final values = widget.children.map((radio) => radio.value).toList();
    final currentIndex = values.indexOf(value);
    if (currentIndex < 0) return;
    final delta = forward ? 1 : -1;
    final nextIndex = (currentIndex + delta) % values.length;
    final nextValue = values[nextIndex];
    widget.onChanged!(nextValue);
    _focusNodes[nextValue]?.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.children.map((radio) => radio.value).toSet().length ==
          widget.children.length,
      'Radio values must be unique within a CarpenterRadioGroup.',
    );
    final gap = context.units(
      CarpenterTheme.of(context).spacing.selectionGroupGap,
    );
    final verticalChildren = <Widget>[
      for (var index = 0; index < widget.children.length; index++) ...[
        if (index > 0)
          SizedBox(
            width: widget.orientation == Axis.horizontal ? gap : null,
            height: widget.orientation == Axis.vertical ? gap : null,
          ),
        widget.children[index],
      ],
    ];
    return RadioGroup<T>(
      groupValue: widget.value,
      onChanged: (next) {
        if (next != null) widget.onChanged?.call(next);
      },
      child: CarpenterRadioGroupScope<T>(
        value: widget.value,
        onChanged: widget.onChanged,
        register: _register,
        unregister: _unregister,
        move: _move,
        child: widget.orientation == Axis.horizontal
            ? Wrap(spacing: gap, runSpacing: gap, children: widget.children)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: verticalChildren,
              ),
      ),
    );
  }
}
