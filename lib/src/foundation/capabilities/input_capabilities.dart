import 'package:flutter/foundation.dart';

@immutable
final class CarpenterInputCapabilities {
  const CarpenterInputCapabilities({
    required this.precisePointer,
    required this.hover,
    required this.touch,
    required this.hardwareKeyboard,
  });

  static const hybrid = CarpenterInputCapabilities(
    precisePointer: true,
    hover: true,
    touch: true,
    hardwareKeyboard: true,
  );

  static const pointerOriented = CarpenterInputCapabilities(
    precisePointer: true,
    hover: true,
    touch: false,
    hardwareKeyboard: true,
  );

  static const touchOriented = CarpenterInputCapabilities(
    precisePointer: false,
    hover: false,
    touch: true,
    hardwareKeyboard: false,
  );

  final bool precisePointer;
  final bool hover;
  final bool touch;
  final bool hardwareKeyboard;
}
