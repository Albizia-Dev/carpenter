import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/theme.dart';
import 'regions/adaptive_region.dart';
import 'regions/adaptive_region_policy.dart';
import 'regions/navigation_region.dart';
import 'regions/primary_region.dart';
import 'regions/region_role.dart';

final class CarpenterApplicationShell extends StatelessWidget {
  const CarpenterApplicationShell({
    super.key,
    required this.navigation,
    required this.primaryContent,
    this.secondaryRegion,
    this.secondaryVisible = false,
    this.onSecondaryVisibilityChanged,
    this.globalActions,
    this.secondaryPolicy = CarpenterBreakpointRegionPolicy.secondary,
    this.secondarySplitPosition = 0.72,
    this.onSecondarySplitPositionChanged,
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.semanticLabel = 'Application',
  });

  final CarpenterNavigationRegion navigation;
  final Widget primaryContent;
  final Widget? secondaryRegion;
  final bool secondaryVisible;
  final ValueChanged<bool>? onSecondaryVisibilityChanged;
  final Widget? globalActions;
  final CarpenterAdaptiveRegionPolicy secondaryPolicy;
  final double secondarySplitPosition;
  final ValueChanged<double>? onSecondarySplitPositionChanged;
  final CarpenterViewportPolicy viewportPolicy;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final navigationPresentation = navigation.resolve(
        context,
        constraints.maxWidth,
      );
      Widget content = CarpenterPrimaryRegion(child: primaryContent);
      if (secondaryRegion != null) {
        content = CarpenterAdaptiveRegion(
          primary: content,
          region: secondaryRegion!,
          role: CarpenterRegionRole.secondary,
          policy: secondaryPolicy,
          regionVisible: secondaryVisible,
          onRegionVisibilityChanged: onSecondaryVisibilityChanged,
          splitPosition: secondarySplitPosition,
          onSplitPositionChanged: onSecondarySplitPositionChanged,
        );
      }
      final navigationWidget = navigation.buildPresentation(
        context,
        navigationPresentation,
      );
      if (navigationPresentation == CarpenterNavigationPresentation.side ||
          navigationPresentation ==
              CarpenterNavigationPresentation.compactSide) {
        final width = context.units(
          navigationPresentation == CarpenterNavigationPresentation.side
              ? theme.sizes.layoutNavigationSide
              : theme.sizes.layoutNavigationCompact,
        );
        content = Row(
          children: [
            SizedBox(width: width, child: navigationWidget),
            Expanded(child: content),
          ],
        );
      } else {
        content = Column(
          children: [
            Expanded(child: content),
            navigationWidget,
          ],
        );
      }
      if (globalActions != null) {
        content = Column(
          children: [
            globalActions!,
            Expanded(child: content),
          ],
        );
      }
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: ColoredBox(color: theme.surface.base, child: content),
      );
    },
  );
}
