import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Линейный индикатор прогресса Carpenter.
///
/// Значение прогресса задается в диапазоне `0..1`. Компонент сам ограничивает
/// значение и берет размеры, радиусы и цвета из `Face`.
class CarpenterProgress extends StatelessWidget {
  /// Создает линейный индикатор прогресса.
  const CarpenterProgress({super.key, required this.value, this.semanticLabel});

  /// Текущее значение прогресса от `0` до `1`.
  final double value;

  /// Accessibility-подпись индикатора.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final normalized = value.clamp(0.0, 1.0);

    return Semantics(
      label: semanticLabel,
      value: '${(normalized * 100).round()}%',
      child: SizedBox(
        height: face.size('progress.height'),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: face.color('surface.muted'),
            borderRadius: BorderRadius.circular(face.radius('pill')),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: normalized,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: face.color('action.primary'),
                borderRadius: BorderRadius.circular(face.radius('pill')),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
