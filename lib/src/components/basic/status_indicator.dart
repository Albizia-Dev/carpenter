import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

final class CarpenterStatusIndicator extends StatelessWidget {
  const CarpenterStatusIndicator({
    super.key,
    required this.label,
    required this.role,
    this.shape = CarpenterShape.circular,
  });

  final String label;
  final FeedbackColorRole role;
  final CarpenterShape shape;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final colors = theme.feedback.resolve(role);
    final startRadius = Radius.circular(
      context.units(theme.shapes.radiusForStatus(shape.start)),
    );
    final endRadius = Radius.circular(
      context.units(theme.shapes.radiusForStatus(shape.end)),
    );
    final borderRadius = BorderRadiusDirectional.only(
      topStart: startRadius,
      bottomStart: startRadius,
      topEnd: endRadius,
      bottomEnd: endRadius,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.units(theme.spacing.statusHorizontal),
          vertical: context.units(theme.spacing.statusVertical),
        ),
        child: Text(
          label,
          style: theme.typography
              .status(context, TypographyEmphasis.medium)
              .copyWith(color: colors.foreground),
        ),
      ),
    );
  }
}
