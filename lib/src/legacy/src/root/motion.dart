import 'package:carpenter/src/legacy/src/root/config.dart';
import 'package:flutter/widgets.dart';

/// Motion-токены visual runtime.
///
/// Компоненты используют эти значения для единообразных transition и feedback
/// состояний. Конкретная анимация остается внутри компонента, но ее темп и
/// кривая приходят из `Face`.
class CarpenterMotion {
  /// Создает набор motion-токенов.
  const CarpenterMotion({
    required this.fast,
    required this.normal,
    required this.slow,
    required this.curve,
  });

  /// Создает motion-токены из конфига runtime.
  factory CarpenterMotion.fromConfig(CarpenterConfig config) {
    final density = config.density.clamp(0.75, 1.25);

    return CarpenterMotion(
      fast: Duration(milliseconds: (90 * density).round()),
      normal: Duration(milliseconds: (150 * density).round()),
      slow: Duration(milliseconds: (240 * density).round()),
      curve: Curves.easeOutCubic,
    );
  }

  /// Быстрое движение для hover, press и небольших feedback-состояний.
  final Duration fast;

  /// Базовое движение для обычных transitions.
  final Duration normal;

  /// Медленное движение для крупных раскрытий и смены поверхностей.
  final Duration slow;

  /// Базовая кривая Carpenter.
  final Curve curve;
}
