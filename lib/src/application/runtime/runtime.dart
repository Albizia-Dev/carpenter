import 'package:flutter/widgets.dart';

/// Core non-visual capability exposed by Carpenter application hosts.
final class CarpenterCoreRuntime {
  const CarpenterCoreRuntime({required this.platform, this.locale});

  final TargetPlatform platform;
  final Locale? locale;
}

/// Immutable typed capability registry for application-level Carpenter features.
final class CarpenterRuntime {
  const CarpenterRuntime([Map<Type, Object> values = const {}]) : _values = values;

  final Map<Type, Object> _values;

  T read<T extends Object>() {
    final value = _values[T];
    if (value == null) throw StateError('CarpenterRuntime: capability $T is not registered.');
    return value as T;
  }

  T? maybeRead<T extends Object>() => _values[T] as T?;
  bool contains(Type type) => _values.containsKey(type);
  Set<Type> get types => Set<Type>.unmodifiable(_values.keys);

  CarpenterRuntime extend<T extends Object>(T value) => CarpenterRuntime({..._values, T: value});
  CarpenterRuntime extendByType(Type type, Object value) => CarpenterRuntime({..._values, type: value});
}

final class CarpenterRuntimeScope extends InheritedWidget {
  const CarpenterRuntimeScope({super.key, required this.runtime, required super.child});

  final CarpenterRuntime runtime;

  static CarpenterRuntime of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CarpenterRuntimeScope>();
    assert(scope != null, 'No CarpenterRuntimeScope found in context.');
    return scope!.runtime;
  }

  @override
  bool updateShouldNotify(CarpenterRuntimeScope oldWidget) => runtime != oldWidget.runtime;
}

extension CarpenterRuntimeBuildContext on BuildContext {
  CarpenterRuntime get runtime => CarpenterRuntimeScope.of(this);
}

extension CarpenterCoreRuntimeAccess on CarpenterRuntime {
  CarpenterCoreRuntime get core => read<CarpenterCoreRuntime>();
}
