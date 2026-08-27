import 'package:flutter/widgets.dart';

import '../../../foundation/adaptive.dart';

enum CarpenterNavigationPresentation { side, compactSide, bottom }

typedef CarpenterNavigationBuilder =
    Widget Function(
      BuildContext context,
      CarpenterNavigationPresentation presentation,
    );

abstract interface class CarpenterNavigationPolicy {
  CarpenterNavigationPresentation resolve(CarpenterAdaptiveContext context);
}

@immutable
final class CarpenterStandardNavigationPolicy
    implements CarpenterNavigationPolicy {
  const CarpenterStandardNavigationPolicy();

  @override
  CarpenterNavigationPresentation resolve(CarpenterAdaptiveContext context) =>
      switch (context.viewportClass) {
        CarpenterViewportClass.wide => CarpenterNavigationPresentation.side,
        CarpenterViewportClass.medium =>
          CarpenterNavigationPresentation.compactSide,
        CarpenterViewportClass.narrow =>
          context.capabilities.touch && !context.capabilities.precisePointer
              ? CarpenterNavigationPresentation.bottom
              : CarpenterNavigationPresentation.compactSide,
      };
}

final class CarpenterNavigationRegion extends StatelessWidget {
  const CarpenterNavigationRegion({
    super.key,
    required this.builder,
    this.policy = const CarpenterStandardNavigationPolicy(),
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.semanticLabel = 'Primary navigation',
  });

  final CarpenterNavigationBuilder builder;
  final CarpenterNavigationPolicy policy;
  final CarpenterViewportPolicy viewportPolicy;
  final String semanticLabel;

  CarpenterNavigationPresentation resolve(BuildContext context, double width) =>
      policy.resolve(viewportPolicy.contextFor(context, width));

  Widget buildPresentation(
    BuildContext context,
    CarpenterNavigationPresentation presentation,
  ) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    child: builder(context, presentation),
  );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        buildPresentation(context, resolve(context, constraints.maxWidth)),
  );
}
