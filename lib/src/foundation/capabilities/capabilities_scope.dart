import 'package:flutter/widgets.dart';

import 'input_capabilities.dart';

final class CarpenterCapabilityScope extends InheritedWidget {
  const CarpenterCapabilityScope({
    super.key,
    required this.capabilities,
    required super.child,
  });

  final CarpenterInputCapabilities capabilities;

  static CarpenterInputCapabilities of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CarpenterCapabilityScope>()
          ?.capabilities ??
      CarpenterInputCapabilities.hybrid;

  @override
  bool updateShouldNotify(CarpenterCapabilityScope oldWidget) =>
      capabilities != oldWidget.capabilities;
}
