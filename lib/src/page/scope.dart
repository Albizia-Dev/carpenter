import 'package:flutter/widgets.dart';

import '../application/command.dart';
import 'capability.dart';
import 'controller.dart';
import 'descriptor.dart';

final class CarpenterPageScope extends InheritedWidget {
  const CarpenterPageScope({
    super.key,
    required this.descriptor,
    this.controller,
    this.commands = const [],
    this.capabilities = const [],
    required super.child,
  });

  final CarpenterPageDescriptor descriptor;
  final CarpenterPageController? controller;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterPageCapability> capabilities;

  static CarpenterPageScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CarpenterPageScope>();
    assert(scope != null, 'No CarpenterPageScope found in context.');
    return scope!;
  }

  T? capability<T extends CarpenterPageCapability>() {
    for (final capability in capabilities) {
      if (capability is T) return capability;
    }
    return null;
  }

  @override
  bool updateShouldNotify(CarpenterPageScope oldWidget) => descriptor != oldWidget.descriptor || controller != oldWidget.controller || commands != oldWidget.commands || capabilities != oldWidget.capabilities;
}
