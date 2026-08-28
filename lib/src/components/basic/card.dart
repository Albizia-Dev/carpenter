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
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.bordered = true,
    this.shape = ShapeRole.rounded,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final String? semanticLabel;

  /// Compatibility switch for the default Carpenter card inset.
  final bool padded;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool bordered;
  final ShapeRole shape;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final radius = context.units(theme.shapes.radius(shape));
    final effectivePadding = padding ??
        (padded
            ? EdgeInsets.all(context.units(theme.spacing.large))
            : EdgeInsets.zero);
    final content = Padding(padding: effectivePadding, child: child);
    final decoration = BoxDecoration(
      color: backgroundColor ?? theme.overlay.background,
      border: bordered
          ? Border.all(
              color: borderColor ?? theme.overlay.border,
              width: context.units(theme.shapes.borderWidth),
            )
          : null,
      borderRadius: BorderRadius.circular(radius),
    );

    return Semantics(
      container: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: clipBehavior,
          child: content,
        ),
      ),
    );
  }
}
