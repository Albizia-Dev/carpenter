import 'package:flutter/widgets.dart';

import '../../components/layout/regions/region_role.dart';

final class SemanticRegion extends StatelessWidget {
  const SemanticRegion({
    super.key,
    required this.role,
    required this.child,
    required this.scrollOwnership,
    this.scrollController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final CarpenterRegionRole role;
  final Widget child;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = scrollOwnership == CarpenterRegionScrollOwnership.region
        ? SingleChildScrollView(controller: scrollController, child: child)
        : child;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel ?? '${role.name} region',
      child: Focus(focusNode: focusNode, autofocus: autofocus, child: content),
    );
  }
}
