import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/component/text/carpenter_text.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Switch Carpenter.
///
/// Switch управляется снаружи: `value` задает состояние, `onChanged` сообщает
/// новое значение.
class CarpenterSwitch extends StatelessWidget {
  /// Создает switch.
  const CarpenterSwitch({
    super.key,
    this.value,
    this.checked,
    this.onChanged,
    this.label,
    this.content,
    this.semanticLabel,
  }) : assert(value != null || checked != null);

  /// Текущее включенное состояние.
  final bool? value;

  /// Alias для миграции controlled controls.
  final bool? checked;

  /// Обработчик изменения значения. Если `null`, switch недоступен.
  final ValueChanged<bool>? onChanged;

  /// Текст рядом со switch.
  final String? label;

  /// Widget-подпись, если одной строки недостаточно.
  final Widget? content;

  /// Accessibility-подпись.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = value ?? checked!;
    return CarpenterControl(
      onTap: onChanged == null ? null : () => onChanged!(!effectiveValue),
      semanticLabel: semanticLabel ?? label,
      semanticButton: false,
      semanticToggled: effectiveValue,
      builder: (context, state) {
        final face = context.face;
        final trackColor = !state.enabled
            ? face.color('action.disabled')
            : effectiveValue
            ? state.pressed
                  ? face.color('action.primary.pressed')
                  : face.color('action.primary')
            : state.pressed
            ? Color.lerp(
                face.color('surface.muted'),
                face.color('action.primary'),
                0.12,
              )!
            : state.hovered || state.focused
            ? Color.lerp(
                face.color('surface.muted'),
                face.color('action.primary'),
                0.07,
              )!
            : face.color('surface.muted');
        final thumbColor = state.enabled
            ? face.color('surface.raised')
            : face.color('action.disabled.text');
        final trackWidth = face.size('control.switch.width');
        final thumbSize = face.size('control.mark');

        final control = AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          width: trackWidth,
          height: face.size('control.switch.height'),
          padding: EdgeInsets.all(face.space('0.125')),
          decoration: BoxDecoration(
            color: trackColor,
            border: Border.all(
              color: state.focused ? face.color('border.focus') : trackColor,
            ),
            borderRadius: BorderRadius.circular(face.radius('pill')),
          ),
          child: Align(
            alignment: effectiveValue
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: AnimatedContainer(
              duration: face.motion.fast,
              curve: face.motion.curve,
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: thumbColor,
                borderRadius: BorderRadius.circular(face.radius('pill')),
              ),
            ),
          ),
        );

        if (label == null && content == null) {
          return control;
        }

        return Wrap(
          spacing: face.space('0.5'),
          runSpacing: face.space('0.25'),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            control,
            content ??
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
