import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:carpenter/src/legacy/src/root/face.dart';

/// Visual runtime Carpenter.
///
/// `Carpenter` собирается из `CarpenterConfig` и вычисляет визуальный язык
/// приложения. Компоненты не должны обращаться к runtime напрямую: для них
/// публичной поверхностью является `context.face`.
class Carpenter {
  /// Создает runtime из декларативного конфига.
  Carpenter.fromConfig(this.config) : face = CarpenterFace.fromConfig(config);

  /// Исходная декларация visual runtime.
  final CarpenterConfig config;

  /// Фасад визуального языка, который читают компоненты.
  final CarpenterFace face;

  /// Совместимость со старым именем до введения `Face`.
  ///
  /// Новый код должен использовать `face`.
  @Deprecated('Используйте face: CarpenterStyle заменен на CarpenterFace.')
  CarpenterFace get theme => face;

  /// Возвращает размер в физических пикселях из rem-единиц.
  double rem(double value) => face.rem(value);
}
