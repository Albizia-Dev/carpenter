import 'package:flutter/widgets.dart';

import 'regions/adaptive_region.dart';
import '../../foundation/adaptive.dart';
import 'regions/adaptive_region_policy.dart';
import 'regions/detail_region.dart';
import 'regions/primary_region.dart';
import 'regions/region_role.dart';

final class CarpenterMasterDetail extends StatelessWidget {
  /// Composes list and detail regions with Russian default accessibility names.
  const CarpenterMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    required this.onDetailVisibilityChanged,
    this.policy = CarpenterBreakpointRegionPolicy.masterDetail,
    this.splitPosition = 0.42,
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.onSplitPositionChanged,
    this.masterFocusNode,
    this.detailFocusNode,
    this.masterSemanticLabel = 'Список',
    this.detailSemanticLabel = 'Карточка',
    this.detailScrollOwnership = CarpenterRegionScrollOwnership.region,
  });

  final Widget master;
  final Widget? detail;
  final ValueChanged<bool>? onDetailVisibilityChanged;
  final CarpenterAdaptiveRegionPolicy policy;
  final double splitPosition;

  /// Controls width classification; opt into text-scale-aware workspaces.
  final CarpenterViewportPolicy viewportPolicy;
  final ValueChanged<double>? onSplitPositionChanged;
  final FocusNode? masterFocusNode;
  final FocusNode? detailFocusNode;
  final String masterSemanticLabel;
  final String detailSemanticLabel;

  /// The detail region scrolls document content by default. Select [CarpenterRegionScrollOwnership.child]
  /// for bounded workspaces containing their own list viewport and pinned tools.
  final CarpenterRegionScrollOwnership detailScrollOwnership;

  @override
  Widget build(BuildContext context) => CarpenterAdaptiveRegion(
    primary: CarpenterPrimaryRegion(
      semanticLabel: masterSemanticLabel,
      child: master,
    ),
    region: CarpenterDetailRegion(
      semanticLabel: detailSemanticLabel,
      scrollOwnership: detailScrollOwnership,
      child: detail ?? const SizedBox.shrink(),
    ),
    role: CarpenterRegionRole.detail,
    policy: policy,
    viewportPolicy: viewportPolicy,
    regionVisible: detail != null,
    onRegionVisibilityChanged: onDetailVisibilityChanged,
    splitPosition: splitPosition,
    onSplitPositionChanged: onSplitPositionChanged,
    primaryFocusNode: masterFocusNode,
    regionFocusNode: detailFocusNode,
    overlaySemanticLabel: detailSemanticLabel,
  );
}
