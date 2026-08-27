import 'package:carpenter/src/legacy/src/navigation/route.dart';
import 'package:carpenter/src/legacy/src/shell/shell.dart';

/// Независимый feature module Carpenter.
///
/// Модуль приносит собственные routes и, если нужно, shell-и/capabilities.
/// Ядро приложения только подключает модули и не знает их внутренние pages.
abstract interface class CarpenterModule {
  /// Стабильный id модуля.
  String get id;

  /// Capabilities, которые нужны модулю на app-level.
  Set<Type> get requires;

  /// Capabilities, которые модуль обещает предоставить своими shell-ами.
  Set<Type> get provides;

  /// Shell-и модуля.
  List<CarpenterShell> get shells;

  /// Root routes модуля.
  List<CarpenterRoute> get routes;
}

/// Удобная база для модулей.
abstract class CarpenterModuleBase implements CarpenterModule {
  /// Создает base module.
  const CarpenterModuleBase();

  @override
  Set<Type> get requires => const {};

  @override
  Set<Type> get provides => const {};

  @override
  List<CarpenterShell> get shells => const [];
}
