import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Compact supplementary label or count. Use status indicators for business status.
final class CarpenterBadge extends StatelessWidget {
  /// Creates a supplementary label using a semantic feedback color.
  const CarpenterBadge({
    super.key,
    required this.label,
    this.role = FeedbackColorRole.neutral,
    this.semanticLabel,
  });

  /// Formats a nonnegative [count], replacing values above positive [max]
  /// with "max+". Defaults to a danger-colored count badge.
  CarpenterBadge.count(
    int count, {
    super.key,
    int max = 99,
    this.role = FeedbackColorRole.danger,
    this.semanticLabel,
  }) : assert(count >= 0),
       assert(max > 0),
       label = count > max ? '$max+' : '$count';

  /// Compact supplementary text or count. Use a status indicator for business
  /// status instead.
  final String label;

  /// Feedback color role used for the badge background and foreground.
  final FeedbackColorRole role;

  /// Accessible badge meaning; defaults to the formatted label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final colors = theme.feedback.resolve(role);
    final horizontal = context.units(theme.spacing.statusHorizontal) * .75;
    final vertical = context.units(theme.spacing.statusVertical) * .75;
    return Semantics(
      label: semanticLabel ?? label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(context.units(10.rem)),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: theme.typography
                .status(context, TypographyEmphasis.strong)
                .copyWith(color: colors.foreground),
          ),
        ),
      ),
    );
  }
}
