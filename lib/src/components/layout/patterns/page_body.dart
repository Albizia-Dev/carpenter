import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';

/// Standard non-scrollable page document body with Carpenter section spacing.
///
/// Scroll ownership belongs to [CarpenterPage] or [CarpenterPageRegion]. This
/// widget only arranges semantic page blocks inside that viewport. Collection
/// renderers that own their own viewport should be passed directly to a page
/// with child-owned scrolling instead of being nested here.
final class CarpenterPageBody extends StatelessWidget {
  const CarpenterPageBody({
    super.key,
    required this.children,
    this.padding,
    this.spacing,
    this.controller,
    this.physics,
    this.semanticLabel,
  });

  final List<Widget> children;

  /// Optional local inset for the document body. Page-level inset is owned by
  /// the surrounding page region, so this defaults to zero.
  final EdgeInsetsGeometry? padding;

  /// Gap between top-level semantic sections.
  final LengthUnit? spacing;

  /// Retained for source compatibility. Scrolling is owned by the page region.
  @Deprecated('Scrolling is owned by CarpenterPage or CarpenterPageRegion.')
  final ScrollController? controller;

  /// Retained for source compatibility. Scrolling is owned by the page region.
  @Deprecated('Scrolling is owned by CarpenterPage or CarpenterPageRegion.')
  final ScrollPhysics? physics;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(spacing ?? theme.spacing.layoutSection);
    Widget body = Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index < children.length - 1) SizedBox(height: gap),
          ],
        ],
      ),
    );
    final label = semanticLabel;
    if (label != null) {
      body = Semantics(container: true, label: label, child: body);
    }
    return body;
  }
}
