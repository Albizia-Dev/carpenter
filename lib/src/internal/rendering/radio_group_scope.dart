import 'package:flutter/widgets.dart';

final class CarpenterRadioGroupScope<T> extends InheritedWidget {
  const CarpenterRadioGroupScope({
    super.key,
    required this.value,
    required this.onChanged,
    required this.register,
    required this.unregister,
    required this.move,
    required super.child,
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final void Function(T value, FocusNode focusNode) register;
  final void Function(T value, FocusNode focusNode) unregister;
  final void Function(T value, bool forward) move;

  static CarpenterRadioGroupScope<T>? maybeOf<T>(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarpenterRadioGroupScope<T>>();

  @override
  bool updateShouldNotify(CarpenterRadioGroupScope<T> oldWidget) =>
      value != oldWidget.value || onChanged != oldWidget.onChanged;
}
