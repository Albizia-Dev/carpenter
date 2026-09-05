import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/focus_ring.dart';

/// Shared semantic frame for Carpenter field controls.
///
/// Field widgets own their interaction and value semantics. This shell owns the
/// common visual anatomy: label, required marker, control surface, leading and
/// trailing slots, supporting text, error presentation, focus ring, minimum
/// target size, and field-role theming.
final class CarpenterFieldShell extends StatelessWidget {
  const CarpenterFieldShell({
    super.key,
    required this.availability,
    required this.size,
    required this.shape,
    required this.states,
    required this.child,
    this.fixedHeight = true,
    this.label,
    this.description,
    this.errorText,
    this.required = false,
    this.leading,
    this.trailing,
  });

  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final Set<WidgetState> states;
  final Widget child;
  final bool fixedHeight;
  final String? label;
  final String? description;
  final String? errorText;
  final bool required;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = theme.fields.resolve(
      availability: availability,
      states: states,
      hasError: errorText != null,
    );
    final startRadius = Radius.circular(
      context.units(theme.shapes.radiusForField(shape.start, size)),
    );
    final endRadius = Radius.circular(
      context.units(theme.shapes.radiusForField(shape.end, size)),
    );
    final borderRadius = BorderRadiusDirectional.only(
      topStart: startRadius,
      bottomStart: startRadius,
      topEnd: endRadius,
      bottomEnd: endRadius,
    ).resolve(Directionality.of(context));
    final labelStyle = theme.typography
        .fieldLabel(context, size, TypographyEmphasis.medium)
        .copyWith(color: style.label);
    final supportingStyle = theme.typography
        .fieldSupporting(context, size, TypographyEmphasis.regular)
        .copyWith(color: errorText == null ? style.supporting : style.error);
    final fieldHeight = theme.sizes.fieldExtent(context, size);
    final horizontal = context.units(theme.spacing.fieldHorizontal(size));
    final vertical = context.units(theme.spacing.fieldVertical(size));
    final contentGap = context.units(theme.spacing.fieldContentGapFor(size));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text.rich(
            TextSpan(
              style: labelStyle,
              children: [
                TextSpan(text: label),
                if (required)
                  TextSpan(
                    text: ' *',
                    style: labelStyle.copyWith(color: style.error),
                  ),
              ],
            ),
          ),
          SizedBox(height: context.units(theme.spacing.fieldLabelGapFor(size))),
        ],
        _FieldControlTarget(
          fixedHeight: fixedHeight,
          minimumTarget: context.units(theme.sizes.minimumTarget),
          child: FocusRing(
            visible: states.contains(WidgetState.focused),
            borderRadius: borderRadius,
            child: AnimatedContainer(
              duration: theme.motion.transitionDuration(context),
              curve: theme.motion.stateCurve,
              height: fixedHeight ? fieldHeight : null,
              constraints: fixedHeight
                  ? null
                  : BoxConstraints(minHeight: fieldHeight),
              padding: EdgeInsets.symmetric(
                horizontal: horizontal,
                vertical: vertical,
              ),
              decoration: BoxDecoration(
                color: style.background,
                borderRadius: borderRadius,
                border: Border.all(
                  color: style.border,
                  width: context.units(theme.shapes.fieldBorderWidth),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    SizedBox(width: contentGap),
                  ],
                  Expanded(child: child),
                  if (trailing != null) ...[
                    SizedBox(width: contentGap),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
        if (errorText != null || description != null) ...[
          SizedBox(
            height: context.units(theme.spacing.fieldSupportingGapFor(size)),
          ),
          Text(errorText ?? description!, style: supportingStyle),
        ],
      ],
    );
  }
}

final class _FieldControlTarget extends StatelessWidget {
  const _FieldControlTarget({
    required this.fixedHeight,
    required this.minimumTarget,
    required this.child,
  });

  final bool fixedHeight;
  final double minimumTarget;
  final Widget child;

  @override
  Widget build(BuildContext context) => fixedHeight
      ? ConstrainedBox(
          constraints: BoxConstraints(minHeight: minimumTarget),
          child: Align(widthFactor: 1, heightFactor: 1, child: child),
        )
      : child;
}
