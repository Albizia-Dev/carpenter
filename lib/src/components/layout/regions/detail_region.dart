import 'package:flutter/widgets.dart';

import '../../../internal/layout/semantic_region.dart';
import 'region_role.dart';

final class CarpenterDetailRegion extends StatelessWidget {
  const CarpenterDetailRegion({
    super.key,
    required this.child,
    this.scrollOwnership = CarpenterRegionScrollOwnership.region,
    this.scrollController,
    this.focusNode,
    this.semanticLabel,
  });

  final Widget child;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SemanticRegion(
    role: CarpenterRegionRole.detail,
    scrollOwnership: scrollOwnership,
    scrollController: scrollController,
    focusNode: focusNode,
    semanticLabel: semanticLabel,
    child: child,
  );
}
