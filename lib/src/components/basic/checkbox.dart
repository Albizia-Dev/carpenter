import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/selection_control.dart';

final class CarpenterCheckbox extends StatelessWidget {
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

  final CheckboxValue value;
  final ValueChanged<CheckboxValue>? onChanged;
  final String label;
  final String? description;
  final String? semanticLabel;
  final ControlSize size;
  final SelectionColorRole colorRole;
  final FocusNode? focusNode;
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
    final radius = switch (sizeRole) {
      ControlSize.xsmall || ControlSize.small =>
        context.units(theme.shapes.checkboxRadius(sizeRole)),
      ControlSize.medium || ControlSize.large || ControlSize.xlarge =>
        context.units(const Px(2)),
    };
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
