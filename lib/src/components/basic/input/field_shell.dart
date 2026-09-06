import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/focus_ring.dart';

/// Semantic supporting feedback for a Carpenter field.
///
/// [errorText] on existing field APIs remains a compatibility shorthand for
/// danger feedback and always takes precedence when both are provided.
@immutable
final class CarpenterFieldFeedback {
  /// Associates a supporting message with a semantic feedback role. No
  /// validation or interaction occurs when feedback is constructed.
  const CarpenterFieldFeedback({required this.message, required this.role});

  /// Creates informational supporting feedback without marking the field as
  /// invalid.
  const CarpenterFieldFeedback.info(String message)
    : this(message: message, role: FeedbackColorRole.info);

  /// Creates successful supporting feedback without marking the field as
  /// invalid.
  const CarpenterFieldFeedback.success(String message)
    : this(message: message, role: FeedbackColorRole.success);

  /// Creates warning feedback without marking the field as invalid.
  const CarpenterFieldFeedback.warning(String message)
    : this(message: message, role: FeedbackColorRole.warning);

  /// Creates danger feedback, which makes isError true and selects the field
  /// error styling.
  const CarpenterFieldFeedback.danger(String message)
    : this(message: message, role: FeedbackColorRole.danger);

  /// Supporting text displayed by the field shell instead of its ordinary
  /// description.
  final String message;

  /// Semantic feedback palette used for the supporting text and border. Only
  /// danger is treated as an error.
  final FeedbackColorRole role;

  /// Whether role is danger. Informational, success, and warning feedback do
  /// not mark the field as invalid.
  bool get isError => role == FeedbackColorRole.danger;
}

/// Shared semantic frame for Carpenter field controls.
///
/// Field widgets own their interaction and value semantics. This shell owns the
/// common visual anatomy: label, required marker, control surface, leading and
/// trailing slots, supporting text, semantic feedback, focus ring, minimum
/// target size, and field-role theming.
final class CarpenterFieldShell extends StatelessWidget {
  /// Frames a caller-owned editing control. Supply the actual interaction
  /// states and enforce availability in the child; the shell styles the field
  /// but does not implement editing, focus ownership, validation, or event
  /// blocking.
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
    this.feedback,
    this.errorText,
    this.required = false,
    this.leading,
    this.trailing,
  });

  /// Availability used to resolve field colors and feedback styling. The
  /// child remains responsible for disabling or restricting editing.
  final FieldAvailability availability;

  /// Field role controlling height, typography, padding, and slot spacing
  /// through the active theme.
  final FieldSize size;

  /// Directional start and end shapes resolved to field radii for size and
  /// the surrounding text direction.
  final CarpenterShape shape;

  /// Current interaction states supplied by the control. In particular,
  /// focused drives the focus ring; the shell does not detect focus itself.
  final Set<WidgetState> states;

  /// Editing content placed in the expanding center slot. Its controller,
  /// focus node, and editing callbacks remain owned by the caller.
  final Widget child;

  /// Whether the control uses the themed fixed field height. When false, the
  /// field may grow beyond its themed minimum height for multiline content.
  final bool fixedHeight;

  /// Optional text above the control. A required marker is only drawn when a
  /// label is present.
  final String? label;

  /// Supporting text below the control when neither errorText nor feedback
  /// supplies a message.
  final String? description;

  /// Semantic supporting feedback. It replaces description and is overridden
  /// by any non-null errorText, including an empty string.
  final CarpenterFieldFeedback? feedback;

  /// Compatibility shorthand for danger feedback. Non-null values take
  /// precedence over feedback; this property displays an error but does not
  /// run validation.
  final String? errorText;

  /// Whether to append a required marker to label. This is presentational and
  /// does not make the child value mandatory.
  final bool required;

  /// Optional content before the expanding child, separated with the themed
  /// field-content gap.
  final Widget? leading;

  /// Optional content after the expanding child, separated with the themed
  /// field-content gap.
  final Widget? trailing;

  CarpenterFieldFeedback? get _effectiveFeedback =>
      errorText != null ? CarpenterFieldFeedback.danger(errorText!) : feedback;

  /// Resolves field geometry and feedback from CarpenterTheme, then composes
  /// the label, control slots, supporting text, and externally driven focus
  /// ring.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final effectiveFeedback = _effectiveFeedback;
    final style = theme.fields.resolve(
      availability: availability,
      states: states,
      hasError: effectiveFeedback?.isError ?? false,
    );
    final feedbackStyle =
        effectiveFeedback != null && availability != FieldAvailability.disabled
        ? theme.feedback.resolve(effectiveFeedback.role)
        : null;
    final feedbackForeground = availability == FieldAvailability.disabled
        ? null
        : effectiveFeedback?.isError ?? false
        ? style.error
        : feedbackStyle?.foreground;
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
        .copyWith(color: feedbackForeground ?? style.supporting);
    final fieldHeight = theme.sizes.fieldExtent(context, size);
    final horizontal = context.units(theme.spacing.fieldHorizontal(size));
    final vertical = context.units(theme.spacing.fieldVertical(size));
    final contentGap = context.units(theme.spacing.fieldContentGapFor(size));
    final supportingText = effectiveFeedback?.message ?? description;

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
                  color: feedbackForeground ?? style.border,
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
        if (supportingText != null) ...[
          SizedBox(
            height: context.units(theme.spacing.fieldSupportingGapFor(size)),
          ),
          Text(supportingText, style: supportingStyle),
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
