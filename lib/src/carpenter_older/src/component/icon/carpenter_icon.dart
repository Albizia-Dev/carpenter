// Bundled in carpenter: legacy package imports relocated; behavior unchanged.
import 'package:carpenter/src/carpenter_older/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Семантический цвет иконки Carpenter.
enum CarpenterIconTone {
  /// Основная иконка.
  primary,

  /// Второстепенная иконка.
  secondary,

  /// Приглушенная иконка.
  muted,

  /// Иконка на насыщенной поверхности.
  inverse,

  /// Иконка успешного состояния.
  success,

  /// Иконка предупреждения.
  warning,

  /// Иконка опасного или ошибочного состояния.
  danger,

  /// Информационная иконка.
  info,
}

/// Иконочный primitive Carpenter.
///
/// Компонент принимает `IconData`, но размер и цвет берет из `Face`. Так иконка
/// остается частью visual runtime, а не локальной ручной настройкой.
class CarpenterIcon extends StatelessWidget {
  /// Создает иконку.
  const CarpenterIcon(
    this.icon, {
    super.key,
    this.tone = CarpenterIconTone.primary,
    this.size,
    this.semanticLabel,
  });

  /// Глиф иконки.
  final IconData icon;

  /// Семантический цвет иконки.
  final CarpenterIconTone tone;

  /// Размер иконки. Если не задан, используется `face.size('icon')`.
  final double? size;

  /// Accessibility-подпись иконки.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final color = switch (tone) {
      CarpenterIconTone.primary => face.color('text.primary'),
      CarpenterIconTone.secondary => face.color('text.secondary'),
      CarpenterIconTone.muted => face.color('text.muted'),
      CarpenterIconTone.inverse => face.color('text.inverse'),
      CarpenterIconTone.success => face.color('status.success'),
      CarpenterIconTone.warning => face.color('status.warning'),
      CarpenterIconTone.danger => face.color('status.danger'),
      CarpenterIconTone.info => face.color('status.info'),
    };

    return Icon(
      icon,
      color: color,
      size: size ?? face.size('icon'),
      semanticLabel: semanticLabel,
    );
  }
}
