import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Semantic background role for a [CarpenterCard].
enum CarpenterCardSurfaceRole { overlay, base, subtle }

/// A semantic surface grouping one related block of content.
final class CarpenterCard extends StatelessWidget {
  const CarpenterCard({
    super.key,
    required this.child,
    this.semanticLabel,
    this.padded = true,
    this.padding,
    this.surfaceRole = CarpenterCardSurfaceRole.overlay,
    this.feedbackRole,
    this.backgroundColor,
    this.borderColor,
    this.bordered = true,
    this.shape = ShapeRole.rounded,
    this.clipBehavior = Clip.antiAlias,
  });

  const CarpenterCard.feedback({
    super.key,
    required this.child,
    required FeedbackColorRole role,
    this.semanticLabel,
    this.padded = true,
    this.padding,
    this.bordered = true,
    this.shape = ShapeRole.rounded,
    this.clipBehavior = Clip.antiAlias,
  }) : surfaceRole = CarpenterCardSurfaceRole.overlay,
       feedbackRole = role,
       backgroundColor = null,
       borderColor = null;

  final Widget child;
  final String? semanticLabel;

  /// Compatibility switch for the default Carpenter card inset.
  final bool padded;

  /// Compatibility escape hatch for layouts that cannot use the default card
  /// inset yet. Prefer Carpenter spacing roles when composing new surfaces.
  final EdgeInsetsGeometry? padding;

  final CarpenterCardSurfaceRole surfaceRole;

  /// When set, feedback colors supersede [surfaceRole].
  final FeedbackColorRole? feedbackRole;

  /// Compatibility escape hatch for integrations that still need a raw color.
  /// New code should prefer [surfaceRole] or [CarpenterCard.feedback].
  final Color? backgroundColor;

  /// Compatibility escape hatch for integrations that still need a raw color.
  /// New code should prefer semantic card surfaces.
  final Color? borderColor;

  final bool bordered;
  final ShapeRole shape;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final radius = context.units(theme.shapes.radius(shape));
    final effectivePadding =
        padding ??
        (padded
            ? EdgeInsets.all(context.units(theme.spacing.large))
            : EdgeInsets.zero);
    final content = Padding(padding: effectivePadding, child: child);
    final feedback = feedbackRole == null
        ? null
        : theme.feedback.resolve(feedbackRole!);
    final semanticBackground = feedback?.background ??
        switch (surfaceRole) {
          CarpenterCardSurfaceRole.overlay => theme.overlay.background,
          CarpenterCardSurfaceRole.base => theme.surface.base,
          CarpenterCardSurfaceRole.subtle => theme.surface.subtle,
        };
    final semanticBorder = feedback?.foreground ?? theme.overlay.border;
    final decoration = BoxDecoration(
      color: backgroundColor ?? semanticBackground,
      border: bordered
          ? Border.all(
              color: borderColor ?? semanticBorder,
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
