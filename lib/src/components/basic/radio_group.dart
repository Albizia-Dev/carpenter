import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../internal/rendering/radio_group_scope.dart';
import 'radio.dart';

final class CarpenterRadioGroup<T> extends StatefulWidget {
  const CarpenterRadioGroup({
    super.key,
    required this.value,
    required this.onChanged,
    required this.children,
    this.orientation = Axis.vertical,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final List<CarpenterRadio<T>> children;
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
