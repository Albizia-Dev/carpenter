import 'package:flutter/widgets.dart';

import '../../../internal/layout/semantic_region.dart';
import 'region_role.dart';

final class CarpenterSecondaryRegion extends StatelessWidget {
  const CarpenterSecondaryRegion({
    super.key,
    required this.child,
    this.scrollOwnership = CarpenterRegionScrollOwnership.region,
    this.scrollController,
    this.semanticLabel,
  });

  final Widget child;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final ScrollController? scrollController;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SemanticRegion(
    role: CarpenterRegionRole.secondary,
    scrollOwnership: scrollOwnership,
    scrollController: scrollController,
    semanticLabel: semanticLabel,
    child: child,
  );
}
