import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Текстовая ссылка Carpenter.
///
/// `CarpenterLink` использует `CarpenterControl` для focus/hover/press и
/// читает цвет/типографику только через `context.face`.
class CarpenterLink extends StatelessWidget {
  /// Создает ссылку с текстовой подписью.
  const CarpenterLink({
    super.key,
    required this.label,
    this.onPressed,
    this.semanticLabel,
  });

  /// Видимый текст ссылки.
  final String label;

  /// Действие при активации ссылки. Если `null`, ссылка недоступна.
  final VoidCallback? onPressed;

  /// Accessibility-подпись, если она отличается от видимого текста.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onPressed,
      semanticLabel: semanticLabel ?? label,
      semanticButton: false,
      semanticLink: true,
      builder: (context, state) {
        final face = context.face;
        final color = !state.enabled
            ? face.color('action.disabled.text')
            : state.pressed
            ? face.color('action.primary.pressed')
            : state.hovered || state.focused
            ? face.color('action.primary.hover')
            : face.color('action.primary');

        return AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: color.withValues(
                  alpha: state.hovered || state.focused ? 1 : 0,
                ),
              ),
            ),
          ),
          child: AnimatedDefaultTextStyle(
            duration: face.motion.fast,
            curve: face.motion.curve,
            style: face.type('label.strong').copyWith(color: color),
            child: Text(label),
          ),
        );
      },
    );
  }
}
