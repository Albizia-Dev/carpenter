import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:carpenter/src/legacy/src/root/system.dart';
import 'package:flutter/widgets.dart';

/// InheritedWidget, который помещает visual runtime Carpenter в дерево Flutter.
///
/// `CarpenterScope` является корневым мостом между `Carpenter` и компонентами.
/// Обычные компоненты получают визуальный язык через `context.face`, а не через
/// прямую работу со scope.
class CarpenterScope extends InheritedWidget {
  /// Помещает готовый runtime в дерево.
  const CarpenterScope({
    super.key,
    required this.carpenter,
    required super.child,
  });

  /// Создает runtime из конфига и сразу помещает его в дерево.
  factory CarpenterScope.fromConfig({
    Key? key,
    required CarpenterConfig config,
    required Widget child,
  }) {
    return CarpenterScope(
      key: key,
      carpenter: Carpenter.fromConfig(config),
      child: child,
    );
  }

  /// Runtime, доступный текущему поддереву.
  final Carpenter carpenter;

  /// Возвращает ближайший runtime Carpenter из `BuildContext`.
  static Carpenter of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CarpenterScope>();
    assert(scope != null, 'No CarpenterScope found in context');
    return scope!.carpenter;
  }

  @override
  bool updateShouldNotify(CarpenterScope oldWidget) {
    return carpenter != oldWidget.carpenter;
  }
}
