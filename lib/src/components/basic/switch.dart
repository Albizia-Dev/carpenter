import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/selection_control.dart';

final class CarpenterSwitch extends StatelessWidget {
  const CarpenterSwitch({
    super.key,
    required this.value,
    required this.label,
    this.onChanged,
    this.description,
    this.semanticLabel,
    this.size = ControlSize.medium,
    this.colorRole = SelectionColorRole.primary,
    this.focusNode,
    this.autofocus = false,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;
  final String? description;
  final String? semanticLabel;
  final ControlSize size;
  final SelectionColorRole colorRole;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return SelectionControl(
      kind: SelectionControlKind.toggle,
      selected: value,
      label: label,
      description: description,
      semanticLabel: semanticLabel,
      size: size,
      colorRole: colorRole,
      onActivate: onChanged == null ? null : () => onChanged!(!value),
      focusNode: focusNode,
      autofocus: autofocus,
      indicatorBuilder: (context, style, indicatorSize) => _SwitchIndicator(
        selected: value,
        style: style,
        size: indicatorSize,
        sizeRole: size,
      ),
    );
  }
}

final class _SwitchIndicator extends StatelessWidget {
  const _SwitchIndicator({
    required this.selected,
    required this.style,
    required this.size,
    required this.sizeRole,
  });

  final bool selected;
  final CarpenterSelectionStyle style;
  final Size size;
  final ControlSize sizeRole;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inset = context.units(theme.spacing.switchInsetFor(sizeRole));
    final handleDimension = (size.height - inset * 2).clamp(
      context.units(theme.sizes.zero),
      size.height,
    );
    return AnimatedContainer(
      duration: theme.motion.transitionDuration(context),
      curve: theme.motion.stateCurve,
      width: size.width,
      height: size.height,
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(
          context.units(theme.shapes.switchRadius(sizeRole)),
        ),
        border: Border.all(
          color: style.border,
          width: context.units(theme.shapes.switchBorderWidth),
        ),
      ),
      alignment: selected
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: AnimatedContainer(
        duration: theme.motion.transitionDuration(context),
        curve: theme.motion.stateCurve,
        width: handleDimension,
        height: handleDimension,
        decoration: BoxDecoration(
          color: selected ? style.mark : style.foreground,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
