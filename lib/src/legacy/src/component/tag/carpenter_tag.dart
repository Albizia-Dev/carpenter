import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Семантический тон tag-компонента.
enum CarpenterTagTone {
  /// Нейтральный tag.
  neutral,

  /// Успешное состояние.
  success,

  /// Предупреждение.
  warning,

  /// Ошибка или опасное состояние.
  danger,

  /// Информационное состояние.
  info,
}

/// Компактная статусная метка Carpenter.
///
/// `CarpenterTag` используется для коротких статусов и категорий. Цвета берутся
/// только из semantic layer `Face`.
class CarpenterTag extends StatelessWidget {
  /// Создает tag с текстовой подписью.
  const CarpenterTag({
    super.key,
    required this.label,
    this.tone = CarpenterTagTone.neutral,
  });

  /// Текст tag.
  final String label;

  /// Семантический тон tag.
  final CarpenterTagTone tone;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final (background, foreground, border) = switch (tone) {
      CarpenterTagTone.neutral => (
        face.color('surface.muted'),
        face.color('text.secondary'),
        face.color('border.subtle'),
      ),
      CarpenterTagTone.success => (
        face.color('status.success.surface'),
        face.color('status.success'),
        face.color('status.success'),
      ),
      CarpenterTagTone.warning => (
        face.color('status.warning.surface'),
        face.color('status.warning'),
        face.color('status.warning'),
      ),
      CarpenterTagTone.danger => (
        face.color('status.danger.surface'),
        face.color('status.danger'),
        face.color('status.danger'),
      ),
      CarpenterTagTone.info => (
        face.color('status.info.surface'),
        face.color('status.info'),
        face.color('status.info'),
      ),
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(face.radius('pill')),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: face.space('0.625'),
          vertical: face.space('0.25'),
        ),
        child: Text(
          label,
          style: face.type('caption').copyWith(color: foreground),
        ),
      ),
    );
  }
}
