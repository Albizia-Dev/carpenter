import 'package:flutter/widgets.dart';

import 'regions/adaptive_region.dart';
import 'regions/adaptive_region_policy.dart';
import 'regions/detail_region.dart';
import 'regions/primary_region.dart';
import 'regions/region_role.dart';

final class CarpenterMasterDetail extends StatelessWidget {
  const CarpenterMasterDetail({
    super.key,
    required this.master,
    required this.detail,
    required this.onDetailVisibilityChanged,
    this.policy = CarpenterBreakpointRegionPolicy.masterDetail,
    this.splitPosition = 0.42,
    this.onSplitPositionChanged,
    this.masterFocusNode,
    this.detailFocusNode,
    this.masterSemanticLabel = 'Master region',
    this.detailSemanticLabel = 'Detail region',
  });

  final Widget master;
  final Widget? detail;
  final ValueChanged<bool>? onDetailVisibilityChanged;
  final CarpenterAdaptiveRegionPolicy policy;
  final double splitPosition;
  final ValueChanged<double>? onSplitPositionChanged;
  final FocusNode? masterFocusNode;
  final FocusNode? detailFocusNode;
  final String masterSemanticLabel;
  final String detailSemanticLabel;

  @override
  Widget build(BuildContext context) => CarpenterAdaptiveRegion(
    primary: CarpenterPrimaryRegion(
      semanticLabel: masterSemanticLabel,
      child: master,
    ),
    region: CarpenterDetailRegion(
      semanticLabel: detailSemanticLabel,
      child: detail ?? const SizedBox.shrink(),
    ),
    role: CarpenterRegionRole.detail,
    policy: policy,
    regionVisible: detail != null,
    onRegionVisibilityChanged: onDetailVisibilityChanged,
    splitPosition: splitPosition,
    onSplitPositionChanged: onSplitPositionChanged,
    primaryFocusNode: masterFocusNode,
    regionFocusNode: detailFocusNode,
    overlaySemanticLabel: detailSemanticLabel,
  );
}
