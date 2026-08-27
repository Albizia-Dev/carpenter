import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/controller.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Infrastructure available to every block inside a page.
class CarpenterPageScope extends InheritedWidget {
  CarpenterPageScope({
    super.key,
    required this.descriptor,
    this.controller,
    this.commands = const [],
    this.capabilities = const [],
    required super.child,
  }) {
    final types = <Type>{};
    for (final capability in capabilities) {
      if (!types.add(capability.runtimeType)) {
        throw StateError(
          'Page ${descriptor.id.value} has conflicting capability '
          '${capability.runtimeType}.',
        );
      }
    }
  }

  final CarpenterPageDescriptor descriptor;
  final CarpenterPageController? controller;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterPageCapability> capabilities;

  String get restorationNamespace => descriptor.id.restorationNamespace;

  T? maybeCapability<T extends CarpenterPageCapability>() {
    for (final capability in capabilities) {
      if (capability is T) return capability;
    }
    return null;
  }

  T capability<T extends CarpenterPageCapability>() {
    final result = maybeCapability<T>();
    if (result == null) {
      throw StateError(
        'Page ${descriptor.id.value} does not provide capability $T.',
      );
    }
    return result;
  }

  static CarpenterPageScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CarpenterPageScope>();

  static CarpenterPageScope of(BuildContext context) {
    final scope = maybeOf(context);
    assert(scope != null, 'No CarpenterPageScope found in context.');
    return scope!;
  }

  @override
  bool updateShouldNotify(CarpenterPageScope oldWidget) =>
      descriptor != oldWidget.descriptor ||
      controller != oldWidget.controller ||
      !listEquals(commands, oldWidget.commands) ||
      !listEquals(capabilities, oldWidget.capabilities);
}

extension CarpenterPageBuildContext on BuildContext {
  CarpenterPageScope get page => CarpenterPageScope.of(this);
}
