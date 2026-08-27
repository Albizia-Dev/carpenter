import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/component/text/carpenter_text.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Checkbox Carpenter.
///
/// Компонент управляется снаружи: значение приходит через `value`, а новое
/// значение отдается через `onChanged`.
class CarpenterCheckbox extends StatelessWidget {
  /// Создает checkbox.
  const CarpenterCheckbox({
    super.key,
    this.value,
    this.checked,
    this.onChanged,
    this.label,
    this.semanticLabel,
  }) : assert(value != null || checked != null);

  /// Текущее checked-состояние.
  final bool? value;

  final bool? checked;

  /// Обработчик изменения значения. Если `null`, checkbox недоступен.
  final ValueChanged<bool>? onChanged;

  /// Текст рядом с checkbox.
  final String? label;

  /// Accessibility-подпись.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value ?? checked!;
    return CarpenterControl(
      onTap: onChanged == null ? null : () => onChanged!(!effectiveValue),
      semanticLabel: semanticLabel ?? label,
      semanticButton: false,
      semanticChecked: effectiveValue,
      builder: (context, state) {
        final face = context.face;
        final borderColor = !state.enabled
            ? face.color('border.subtle')
            : state.focused
            ? face.color('border.focus')
            : effectiveValue
            ? face.color('action.primary')
            : face.color('border.normal');
        final fillColor = !state.enabled
            ? face.color('action.disabled')
            : effectiveValue
            ? state.pressed
                  ? face.color('action.primary.pressed')
                  : face.color('action.primary')
            : state.pressed
            ? Color.lerp(
                face.color('surface.raised'),
                face.color('action.primary'),
                0.12,
              )!
            : state.hovered || state.focused
            ? Color.lerp(
                face.color('surface.raised'),
                face.color('action.primary'),
                0.07,
              )!
            : face.color('surface.raised');

        final mark = AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          decoration: BoxDecoration(
            color: fillColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(face.radius('sm')),
          ),
          child: SizedBox.square(
            dimension: face.size('control.mark'),
            child: AnimatedOpacity(
              duration: face.motion.fast,
              curve: face.motion.curve,
              opacity: effectiveValue ? 1 : 0,
              child: Center(
                child: CarpenterText(
                  '✓',
                  style: face
                      .type('caption')
                      .copyWith(
                        color: face.color('action.primary.text'),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ),
          ),
        );

        if (label == null) {
          return mark;
        }

        return Wrap(
          spacing: face.space('0.5'),
          runSpacing: face.space('0.25'),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            mark,
            CarpenterText(
              label!,
              variant: CarpenterTextVariant.label,
              tone: state.enabled
                  ? CarpenterTextTone.primary
                  : CarpenterTextTone.disabled,
            ),
          ],
        );
      },
    );
  }
}
