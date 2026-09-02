import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';

/// Standard scrollable page body with Carpenter spacing and padding.
///
/// Use this for ordinary application pages instead of repeating a [ListView],
/// page padding, and spacer widgets between every top-level block. More complex
/// layouts can still opt into custom slivers or scroll views directly.
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

  /// Structural escape hatch. Defaults to the page-layout spacing on every
  /// side.
  final EdgeInsetsGeometry? padding;

  /// Gap between top-level page sections. It is intentionally larger than
  /// field and block gaps so separate semantic groups read as separate groups.
  final LengthUnit? spacing;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(spacing ?? theme.spacing.layoutPage);
    final list = ListView.separated(
      controller: controller,
      physics: physics,
      padding: padding ?? EdgeInsets.all(gap),
      itemCount: children.length,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: (context, index) => children[index],
    );
    final label = semanticLabel;
    if (label == null) return list;
    return Semantics(container: true, label: label, child: list);
  }
}
