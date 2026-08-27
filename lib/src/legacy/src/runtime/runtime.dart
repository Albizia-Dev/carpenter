import 'package:carpenter/src/legacy/src/root/system.dart';
import 'package:flutter/widgets.dart';

/// Core capability Carpenter-приложения.
class CarpenterCoreRuntime {
  /// Создает core runtime capability.
  const CarpenterCoreRuntime({
    required this.carpenter,
    required this.platform,
    this.locale,
  });

  /// Visual runtime.
  final Carpenter carpenter;

  /// Target platform приложения.
  final TargetPlatform platform;

  /// Локаль приложения.
  final Locale? locale;
}

/// Typed runtime registry Carpenter.
///
/// Runtime хранит capabilities приложения: router, hotkeys, auth, overlay,
/// DI-контейнеры и любые пользовательские приколдесы. Доступ идет по типу,
/// поэтому shell-и и модули зависят от контрактов, а не от concrete classes.
class CarpenterRuntime {
  /// Создает runtime registry.
  const CarpenterRuntime([Map<Type, Object> values = const {}])
    : _values = values;

  final Map<Type, Object> _values;

  /// Возвращает capability типа [T] или бросает понятную ошибку.
  T read<T extends Object>() {
    final value = _values[T];
    if (value == null) {
      throw StateError('CarpenterRuntime: capability $T не найден.');
    }
    return value as T;
  }

  /// Возвращает capability типа [T], если он зарегистрирован.
  T? maybeRead<T extends Object>() => _values[T] as T?;

  /// Проверяет, есть ли capability с типом [type].
  bool contains(Type type) => _values.containsKey(type);

  /// Добавляет или заменяет capability.
  CarpenterRuntime extend<T extends Object>(T value) {
    return CarpenterRuntime({..._values, T: value});
  }

  /// Добавляет или заменяет capability с runtime-типом [type].
  CarpenterRuntime extendByType(Type type, Object value) {
    return CarpenterRuntime({..._values, type: value});
  }

  /// Все зарегистрированные типы. Нужно для validation/debug.
  Set<Type> get types => Set<Type>.unmodifiable(_values.keys);
}

/// Inherited scope для typed runtime registry.
class CarpenterRuntimeScope extends InheritedWidget {
  /// Создает runtime scope.
  const CarpenterRuntimeScope({
    super.key,
    required this.runtime,
    required super.child,
  });

  /// Текущий runtime registry.
  final CarpenterRuntime runtime;

  /// Возвращает runtime из widget tree.
  static CarpenterRuntime of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<CarpenterRuntimeScope>();
    assert(scope != null, 'No CarpenterRuntimeScope found in context.');
    return scope!.runtime;
  }

  @override
  bool updateShouldNotify(CarpenterRuntimeScope oldWidget) {
    return runtime != oldWidget.runtime;
  }
}

/// Доступ к Carpenter runtime registry из Flutter context.
extension CarpenterRuntimeBuildContext on BuildContext {
  /// Typed runtime registry приложения.
  CarpenterRuntime get runtime => CarpenterRuntimeScope.of(this);
}

/// Typed access к core capability.
extension CarpenterCoreRuntimeAccess on CarpenterRuntime {
  /// Core runtime приложения.
  CarpenterCoreRuntime get core => read<CarpenterCoreRuntime>();
}
