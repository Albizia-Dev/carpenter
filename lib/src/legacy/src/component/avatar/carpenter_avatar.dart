import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Avatar Carpenter.
///
/// Компонент показывает короткие initials или произвольный child в круглой
/// semantic surface. Размер и цвета берутся из `Face`.
class CarpenterAvatar extends StatelessWidget {
  /// Создает avatar.
  const CarpenterAvatar({
    super.key,
    this.initials,
    this.child,
    this.size,
    this.semanticLabel,
  }) : assert(
         initials != null || child != null,
         'Нужно передать initials или child.',
       );

  /// Короткие инициалы, например `RR`.
  final String? initials;

  /// Произвольное содержимое avatar.
  final Widget? child;

  /// Размер avatar. Если не задан, используется `face.size('avatar')`.
  final double? size;

  /// Accessibility-подпись.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final dimension = size ?? face.size('avatar');

    return Semantics(
      label: semanticLabel ?? initials,
      image: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: face.color('action.primary'),
          borderRadius: BorderRadius.circular(face.radius('pill')),
        ),
        child: SizedBox.square(
          dimension: dimension,
          child: Center(
            child:
                child ??
                Text(
                  initials!,
                  style: face
                      .type('label.strong')
                      .copyWith(color: face.color('action.primary.text')),
                ),
          ),
        ),
      ),
    );
  }
}
