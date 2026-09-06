import 'package:flutter/widgets.dart';

/// Core non-visual capability exposed by Carpenter application hosts.
final class CarpenterCoreRuntime {
  /// Creates core runtime capability for the effective platform and optional locale.
  const CarpenterCoreRuntime({required this.platform, this.locale});

  /// Target platform used for platform-sensitive Carpenter behavior.
  final TargetPlatform platform;

  /// Optional locale propagated as part of the core Carpenter runtime or application
  /// root.
  final Locale? locale;
}

/// Immutable typed capability registry for application-level Carpenter features.
final class CarpenterRuntime {
  /// Creates an immutable runtime from the supplied type-keyed values; the default
  /// runtime is empty.
  const CarpenterRuntime([Map<Type, Object> values = const {}])
    : _values = values;

  final Map<Type, Object> _values;

  /// Reads the capability registered under `T`; throws `StateError` when the type is
  /// absent.
  T read<T extends Object>() {
    final value = _values[T];
    if (value == null)
      throw StateError('CarpenterRuntime: capability $T is not registered.');
    return value as T;
  }

  /// Reads the capability registered under `T`, or returns `null` when the type is
  /// absent.
  T? maybeRead<T extends Object>() => _values[T] as T?;

  /// Reports whether a capability is registered for the exact supplied type key.
  bool contains(Type type) => _values.containsKey(type);

  /// Unmodifiable set of capability types currently registered in this runtime.
  Set<Type> get types => Set<Type>.unmodifiable(_values.keys);

  /// Returns a new runtime with `value` registered under its generic type `T`,
  /// replacing any previous value for that key.
  CarpenterRuntime extend<T extends Object>(T value) =>
      CarpenterRuntime({..._values, T: value});

  /// Returns a new runtime with `value` registered under the explicit `type` key,
  /// replacing any previous value for that key.
  CarpenterRuntime extendByType(Type type, Object value) =>
      CarpenterRuntime({..._values, type: value});
}

/// Inherited boundary that exposes one immutable Carpenter runtime capability registry
/// to descendants.
final class CarpenterRuntimeScope extends InheritedWidget {
  /// Creates an inherited runtime boundary around `child`.
  const CarpenterRuntimeScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  /// Immutable capability registry exposed to descendants of this boundary.
  final CarpenterRuntime runtime;

  /// Returns the runtime from the nearest scope and asserts in debug mode when no scope
  /// exists.
  static CarpenterRuntime of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CarpenterRuntimeScope>();
    assert(scope != null, 'No CarpenterRuntimeScope found in context.');
    return scope!.runtime;
  }

  /// Notifies dependents when the runtime instance changes.
  @override
  bool updateShouldNotify(CarpenterRuntimeScope oldWidget) =>
      runtime != oldWidget.runtime;
}

/// Convenience access from a build context to the nearest Carpenter runtime scope.
extension CarpenterRuntimeBuildContext on BuildContext {
  /// Carpenter runtime inherited from the nearest runtime scope.
  CarpenterRuntime get runtime => CarpenterRuntimeScope.of(this);
}

/// Typed access to the mandatory core capability stored in a Carpenter runtime.
extension CarpenterCoreRuntimeAccess on CarpenterRuntime {
  /// Mandatory core runtime capability containing effective platform and locale.
  CarpenterCoreRuntime get core => read<CarpenterCoreRuntime>();
}
