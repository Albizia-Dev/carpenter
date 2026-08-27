import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Одна опция segmented radio.
class CarpenterSegmentedOption<T> {
  /// Создает опцию segmented radio.
  const CarpenterSegmentedOption({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  /// Значение опции.
  final T value;

  /// Видимая подпись опции.
  final String label;

  /// Accessibility-подпись, если она отличается от видимой.
  final String? semanticLabel;
}

/// SegmentedRadio Carpenter.
///
/// Это компактный выбор одного значения из нескольких. Компонент управляется
/// снаружи через `value` и `onChanged`.
class CarpenterSegmentedRadio<T> extends StatelessWidget {
  /// Создает segmented radio.
  const CarpenterSegmentedRadio({
    super.key,
    required this.options,
    required this.value,
    this.onChanged,
  });

  /// Список доступных опций.
  final List<CarpenterSegmentedOption<T>> options;

  /// Текущее выбранное значение.
  final T value;

  /// Обработчик выбора. Если `null`, весь control недоступен.
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final face = context.face;

    return AnimatedContainer(
      duration: face.motion.fast,
      curve: face.motion.curve,
      decoration: BoxDecoration(
        color: face.color('surface.muted'),
        border: Border.all(color: face.color('border.subtle')),
        borderRadius: BorderRadius.circular(face.radius('lg')),
      ),
      child: Padding(
        padding: EdgeInsets.all(face.space('0.125')),
        child: Wrap(
          spacing: face.space('0.125'),
          runSpacing: face.space('0.125'),
          children: [
            for (final option in options)
              _CarpenterSegmentedRadioItem<T>(
                option: option,
                selected: option.value == value,
                onChanged: onChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class _CarpenterSegmentedRadioItem<T> extends StatelessWidget {
  const _CarpenterSegmentedRadioItem({
    required this.option,
    required this.selected,
    required this.onChanged,
  });

  final CarpenterSegmentedOption<T> option;
  final bool selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return CarpenterControl(
      onTap: onChanged == null ? null : () => onChanged!(option.value),
      semanticLabel: option.semanticLabel ?? option.label,
      semanticButton: false,
      semanticChecked: selected,
      semanticSelected: selected,
      builder: (context, state) {
        final face = context.face;
        final background = !state.enabled
            ? face.color('action.disabled')
            : selected
            ? face.color('surface.raised')
            : state.pressed
            ? Color.lerp(
                const Color(0x00000000),
                face.color('action.primary'),
                0.12,
              )!
            : state.hovered || state.focused
            ? Color.lerp(
                const Color(0x00000000),
                face.color('action.primary'),
                0.07,
              )!
            : const Color(0x00000000);
        final foreground = !state.enabled
            ? face.color('action.disabled.text')
            : selected
            ? face.color('text.primary')
            : face.color('text.secondary');

        return AnimatedContainer(
          duration: face.motion.fast,
          curve: face.motion.curve,
          decoration: BoxDecoration(
            color: background,
            border: Border.all(
              color: state.focused
                  ? face.color('border.focus')
                  : const Color(0x00000000),
            ),
            borderRadius: BorderRadius.circular(face.radius('md')),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: face.space('0.75'),
            vertical: face.space('0.375'),
          ),
          child: AnimatedDefaultTextStyle(
            duration: face.motion.fast,
            curve: face.motion.curve,
            style: face.type('label.strong').copyWith(color: foreground),
            child: Text(option.label),
          ),
        );
      },
    );
  }
}
