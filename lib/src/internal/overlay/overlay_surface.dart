import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

enum OverlaySurfaceKind { standard, tooltip }

final class OverlaySurface extends StatelessWidget {
  const OverlaySurface({
    super.key,
    required this.child,
    this.kind = OverlaySurfaceKind.standard,
    this.padded = true,
  });

  final Widget child;
  final OverlaySurfaceKind kind;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final tooltip = kind == OverlaySurfaceKind.tooltip;
    final background = tooltip
        ? theme.overlay.tooltipBackground
        : theme.overlay.background;
    final padding = padded
        ? tooltip
              ? EdgeInsets.symmetric(
                  horizontal: context.units(
                    theme.spacing.overlayTooltipHorizontal,
                  ),
                  vertical: context.units(theme.spacing.overlayTooltipVertical),
                )
              : EdgeInsets.all(
                  context.units(theme.spacing.overlaySurfacePadding),
                )
        : EdgeInsets.zero;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(
          context.units(theme.shapes.overlaySurfaceRadius),
        ),
        border: tooltip
            ? null
            : Border.all(
                color: theme.overlay.border,
                width: context.units(theme.shapes.overlayBorderWidth),
              ),
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
