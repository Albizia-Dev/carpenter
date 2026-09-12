import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import 'breakpoints/viewport_class.dart';
import 'capabilities/capabilities_scope.dart';
import 'capabilities/input_capabilities.dart';
import 'theme.dart';

export 'breakpoints/viewport_class.dart';
export 'capabilities/capabilities_scope.dart';
export 'capabilities/input_capabilities.dart';

@immutable
final class CarpenterAdaptiveContext {
  const CarpenterAdaptiveContext({
    required this.viewportClass,
    required this.capabilities,
  });

  final CarpenterViewportClass viewportClass;
  final CarpenterInputCapabilities capabilities;
}

final class CarpenterViewportPolicy {
  /// By default physical width preserves existing layouts. Enable text-scale
  /// adjustment for dense workspaces that need readable adjacent regions.
  const CarpenterViewportPolicy({this.accountForTextScale = false});

  /// Classify logical room for content rather than raw width at enlarged text.
  final bool accountForTextScale;

  CarpenterViewportClass resolve(BuildContext context, double width) {
    if (accountForTextScale) {
      final scale = MediaQuery.textScalerOf(context).scale(16) / 16;
      if (scale > 1) width /= scale;
    }
    final sizes = CarpenterTheme.of(context).sizes;
    final narrowEnd = context.units(sizes.layoutNarrowEnd);
    final mediumEnd = context.units(sizes.layoutMediumEnd);
    if (width <= narrowEnd) return CarpenterViewportClass.narrow;
    if (width <= mediumEnd) return CarpenterViewportClass.medium;
    return CarpenterViewportClass.wide;
  }

  CarpenterAdaptiveContext contextFor(BuildContext context, double width) =>
      CarpenterAdaptiveContext(
        viewportClass: resolve(context, width),
        capabilities: CarpenterCapabilityScope.of(context),
      );
}
