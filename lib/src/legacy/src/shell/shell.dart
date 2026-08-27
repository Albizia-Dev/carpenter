import 'package:carpenter/src/legacy/src/runtime/runtime.dart';
import 'package:flutter/widgets.dart';

/// Контекст shell на этапе конфигурации.
class CarpenterShellConfigureContext {
  /// Создает configure context.
  const CarpenterShellConfigureContext({required this.runtime});

  /// Runtime, собранный предыдущими shell-ами.
  final CarpenterRuntime runtime;
}

/// Контекст shell на этапе widget wrapping.
class CarpenterShellBuildContext {
  /// Создает build context shell-а.
  const CarpenterShellBuildContext({
    required this.runtime,
    required this.buildContext,
  });

  /// Runtime после compile phase.
  final CarpenterRuntime runtime;

  /// Flutter context текущей сборки.
  final BuildContext buildContext;
}

/// Middleware-like shell Carpenter.
///
/// Shell может объявить capabilities, которые он предоставляет и требует,
/// расширить typed runtime registry и обернуть дочернее дерево widgets.
abstract interface class CarpenterShell {
  /// Стабильный id shell-а для диагностики.
  String get id;

  /// Capabilities, которые должны существовать до этого shell-а.
  Set<Type> get requires;

  /// Capabilities, которые shell обещает добавить.
  Set<Type> get provides;

  /// Расширяет runtime. Вызывается слева направо по списку shell-ов.
  CarpenterRuntime configure(CarpenterShellConfigureContext context);

  /// Оборачивает widget tree. Визуально shell-и применяются как middleware.
  Widget wrap(CarpenterShellBuildContext context, Widget child);
}

/// Удобная база для shell-ов без обязательного наследования в публичном API.
abstract class CarpenterShellBase implements CarpenterShell {
  /// Создает base shell.
  const CarpenterShellBase();

  @override
  Set<Type> get requires => const {};

  @override
  Set<Type> get provides => const {};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime;
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) => child;
}
