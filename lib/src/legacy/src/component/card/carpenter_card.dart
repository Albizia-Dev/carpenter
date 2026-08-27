import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Поверхность-контейнер Carpenter.
///
/// `CarpenterCard` задает семантическую surface-область: фон, границу, радиус
/// и внутренний отступ берутся из `Face`.
class CarpenterCard extends StatelessWidget {
  /// Создает card-поверхность.
  const CarpenterCard({
    super.key,
    required this.child,
    this.padding,
    this.muted = false,
    this.backgroundColor,
  });

  /// Содержимое поверхности.
  final Widget child;

  /// Внутренний отступ. Если не задан, используется `face.space('1')`.
  final EdgeInsetsGeometry? padding;

  /// Использовать приглушенную surface-роль вместо raised.
  final bool muted;

  /// Overrides the semantic surface color when a card communicates status.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final face = context.face;

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (muted
                ? face.color('surface.muted')
                : face.color('surface.raised')),
        border: Border.all(color: face.color('border.subtle')),
        borderRadius: BorderRadius.circular(face.radius('lg')),
      ),
      child: Padding(
        padding: padding ?? EdgeInsets.all(face.space('1')),
        child: DefaultTextStyle.merge(
          style: face.type('body').copyWith(color: face.color('text.primary')),
          child: child,
        ),
      ),
    );
  }
}
