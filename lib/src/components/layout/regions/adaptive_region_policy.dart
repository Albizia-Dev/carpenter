import 'package:flutter/foundation.dart';

import '../../../foundation/adaptive.dart';
import 'region_presentation.dart';
import 'region_role.dart';

abstract interface class CarpenterAdaptiveRegionPolicy {
  CarpenterRegionPresentation resolve(
    CarpenterAdaptiveContext context,
    CarpenterRegionRole role,
  );
}

@immutable
final class CarpenterBreakpointRegionPolicy
    implements CarpenterAdaptiveRegionPolicy {
  const CarpenterBreakpointRegionPolicy({
    required this.narrow,
    required this.medium,
    required this.wide,
  });

  static const masterDetail = CarpenterBreakpointRegionPolicy(
    narrow: CarpenterRegionPresentation.pushed,
    medium: CarpenterRegionPresentation.inline,
    wide: CarpenterRegionPresentation.inline,
  );

  static const secondary = CarpenterBreakpointRegionPolicy(
    narrow: CarpenterRegionPresentation.overlay,
    medium: CarpenterRegionPresentation.overlay,
    wide: CarpenterRegionPresentation.inline,
  );

  final CarpenterRegionPresentation narrow;
  final CarpenterRegionPresentation medium;
  final CarpenterRegionPresentation wide;

  @override
  CarpenterRegionPresentation resolve(
    CarpenterAdaptiveContext context,
    CarpenterRegionRole role,
  ) => switch (context.viewportClass) {
    CarpenterViewportClass.narrow => narrow,
    CarpenterViewportClass.medium => medium,
    CarpenterViewportClass.wide => wide,
  };
}
