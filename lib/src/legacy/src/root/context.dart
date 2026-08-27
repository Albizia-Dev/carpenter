import 'package:carpenter/src/legacy/src/root/face.dart';
import 'package:carpenter/src/legacy/src/root/scope.dart';
import 'package:carpenter/src/legacy/src/root/system.dart';
import 'package:flutter/widgets.dart';

/// Доступ к visual runtime Carpenter из `BuildContext`.
///
/// Главный метод для компонентов - `context.face`. Он возвращает фасад
/// визуального языка и скрывает внутренности runtime.
extension CarpenterContext on BuildContext {
  /// Низкоуровневый доступ к runtime.
  ///
  /// Компоненты обычно не должны использовать это свойство. Оно оставлено для
  /// корневых интеграций, диагностики и редких случаев, где нужен сам runtime.
  Carpenter get carpenter => CarpenterScope.of(this);

  /// Фасад визуального языка для компонентов.
  CarpenterFace get face => carpenter.face;
}
