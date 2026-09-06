import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/selection_control.dart';

/// Controlled binary setting with a visible label and optional supporting
/// description.
///
/// Activation proposes the opposite [value]. Keep the authoritative setting
/// and any persistence logic outside the widget.
final class CarpenterSwitch extends StatelessWidget {
  /// Creates a switch from the current [value]. Null [onChanged] makes it
  /// noninteractive.
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

  /// Current enabled/disabled value of the setting, independent of whether
  /// the control itself is interactive.
  final bool value;

  /// Receives the proposed opposite setting. Store it and rebuild; null
  /// disables interaction.
  final ValueChanged<bool>? onChanged;

  /// Visible text naming the control or choice; keep it meaningful without
  /// relying on an icon.
  final String label;

  /// Optional supporting text explaining the choice without replacing its
  /// accessible name.
  final String? description;

  /// Accessible name supplied to assistive technology. When omitted, the
  /// visible label is used.
  final String? semanticLabel;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final SelectionColorRole colorRole;

  /// Optional caller-owned focus node. Dispose a supplied node in its owner,
  /// not in the widget.
  final FocusNode? focusNode;

  /// Whether the control requests focus when first attached. Defaults to
  /// false.
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
