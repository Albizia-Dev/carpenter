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
  const CarpenterViewportPolicy();

  CarpenterViewportClass resolve(BuildContext context, double width) {
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
