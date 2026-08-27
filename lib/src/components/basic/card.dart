import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// A semantic surface grouping one related block of content.
final class CarpenterCard extends StatelessWidget {
  const CarpenterCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.padded = true,
  });

  final Widget child;
  final String? semanticLabel;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final radius = context.units(theme.shapes.radius(ShapeRole.rounded));
    final content = padded
        ? Padding(
            padding: EdgeInsets.all(context.units(theme.spacing.large)),
            child: child,
          )
        : child;
    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.overlay.background,
          border: Border.all(
            color: theme.overlay.border,
            width: context.units(theme.shapes.borderWidth),
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      ),
    );
  }
}
