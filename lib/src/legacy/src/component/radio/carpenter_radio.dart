import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/component/text/carpenter_text.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart' hide Text;

/// Radio Carpenter.
///
/// Компонент выбирает одно значение из группы. Он не хранит group-state внутри:
/// текущее значение приходит через `groupValue`.
class CarpenterRadio<T> extends StatelessWidget {
  /// Создает radio-элемент.
  const CarpenterRadio({
    super.key,
    required this.value,
    required this.groupValue,
    this.onChanged,
    this.label,
    this.semanticLabel,
  });

  /// Значение этого radio-элемента.
  final T value;

  /// Текущее выбранное значение группы.
  final T? groupValue;

  /// Обработчик выбора. Если `null`, radio недоступен.
  final ValueChanged<T>? onChanged;

  /// Текст рядом с radio.
  final String? label;

  /// Accessibility-подпись.
  final String? semanticLabel;

  bool get _selected => value == groupValue;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onChanged == null ? null : () => onChanged!(value),
      semanticLabel: semanticLabel ?? label,
      semanticButton: false,
      semanticChecked: _selected,
      semanticSelected: _selected,
      builder: (context, state) {
        final face = context.face;
        final borderColor = !state.enabled
            ? face.color('border.subtle')
            : state.focused
            ? face.color('border.focus')
            : _selected
            ? face.color('action.primary')
            : face.color('border.normal');
        final base = face.color('surface.raised');
        final outerColor = !state.enabled
            ? face.color('action.disabled')
            : state.pressed
            ? Color.lerp(base, face.color('action.primary'), 0.12)!
            : state.hovered || state.focused
            ? Color.lerp(base, face.color('action.primary'), 0.07)!
            : base;

        final control = AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          decoration: BoxDecoration(
            color: outerColor,
            border: Border.all(color: borderColor, width: face.space('0.125')),
            borderRadius: BorderRadius.circular(face.radius('pill')),
          ),
          child: SizedBox.square(
            dimension: face.size('control.mark'),
            child: Center(
              child: AnimatedContainer(
                duration: face.motion.fast,
                curve: face.motion.curve,
                width: _selected ? face.space('0.5') : 0,
                height: _selected ? face.space('0.5') : 0,
                decoration: BoxDecoration(
                  color: state.enabled
                      ? face.color('action.primary')
                      : face.color('action.disabled.text'),
                  borderRadius: BorderRadius.circular(face.radius('pill')),
                ),
              ),
            ),
          ),
        );

        if (label == null) {
          return control;
        }

        return Wrap(
          spacing: face.space('0.5'),
          runSpacing: face.space('0.25'),
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            control,
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
