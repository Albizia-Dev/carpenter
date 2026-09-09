import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/selection_control.dart';

/// Controlled selection control with unchecked, checked, and mixed
/// presentation.
///
/// A mixed value represents partial selection. Activation changes mixed or
/// unchecked to checked, and checked to unchecked; it does not cycle through
/// all three states.
final class CarpenterCheckbox extends StatelessWidget {
  /// Creates a checkbox with externally owned [value]. Omit [onChanged] to
  /// disable interaction.
  const CarpenterCheckbox({
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

  /// Current tri-state selection. Mixed is supplied by the owner, not reached
  /// by ordinary toggling.
  final CheckboxValue value;

  /// Receives the next selection value on activation. Rebuild with that value
  /// to commit it; null disables the control.
  final ValueChanged<CheckboxValue>? onChanged;

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

  CheckboxValue get _nextValue => switch (value) {
    CheckboxValue.unchecked => CheckboxValue.checked,
    CheckboxValue.checked => CheckboxValue.unchecked,
    CheckboxValue.mixed => CheckboxValue.checked,
  };

  @override
  Widget build(BuildContext context) {
    return SelectionControl(
      kind: SelectionControlKind.checkbox,
      selected: value == CheckboxValue.checked,
      mixed: value == CheckboxValue.mixed,
      label: label,
      description: description,
      semanticLabel: semanticLabel,
      size: size,
      colorRole: colorRole,
      onActivate: onChanged == null ? null : () => onChanged!(_nextValue),
      focusNode: focusNode,
      autofocus: autofocus,
      indicatorBuilder: (context, style, indicatorSize) => _CheckboxIndicator(
        value: value,
        style: style,
        size: indicatorSize,
        sizeRole: size,
      ),
    );
  }
}

final class _CheckboxIndicator extends StatelessWidget {
  const _CheckboxIndicator({
    required this.value,
    required this.style,
    required this.size,
    required this.sizeRole,
  });

  final CheckboxValue value;
  final CarpenterSelectionStyle style;
  final Size size;
  final ControlSize sizeRole;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final inset = context.units(theme.spacing.checkboxMarkInset(sizeRole));
    final strokeWidth = context.units(theme.shapes.checkboxBorderWidth);
    final radius = context.units(theme.shapes.checkboxRadius(sizeRole));
    return AnimatedContainer(
      duration: theme.motion.transitionDuration(context),
      curve: theme.motion.stateCurve,
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: style.border, width: strokeWidth),
      ),
      child: value == CheckboxValue.unchecked
          ? null
          : CustomPaint(
              painter: _CheckboxMarkPainter(
                mixed: value == CheckboxValue.mixed,
                color: style.mark,
                inset: inset,
                strokeWidth: context.units(
                  theme.shapes.checkboxMarkStrokeWidth,
                ),
              ),
            ),
    );
  }
}

final class _CheckboxMarkPainter extends CustomPainter {
  const _CheckboxMarkPainter({
    required this.mixed,
    required this.color,
    required this.inset,
    required this.strokeWidth,
  });

  final bool mixed;
  final Color color;
  final double inset;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inner = rect.deflate(inset);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (mixed) {
      canvas.drawLine(inner.centerLeft, inner.centerRight, paint);
      return;
    }
    final path = Path()
      ..moveTo(inner.left, inner.center.dy)
      ..lineTo(inner.left + inner.width * 0.38, inner.bottom)
      ..lineTo(inner.right, inner.top);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CheckboxMarkPainter oldDelegate) =>
      oldDelegate.mixed != mixed ||
      oldDelegate.color != color ||
      oldDelegate.inset != inset ||
      oldDelegate.strokeWidth != strokeWidth;
}
