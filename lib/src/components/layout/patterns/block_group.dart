import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';

/// Groups related content blocks with a gap larger than field-to-field spacing.
final class CarpenterBlockGroup extends StatelessWidget {
  const CarpenterBlockGroup({
    super.key,
    required this.children,
    this.spacing,
  });

  final List<Widget> children;
  final LengthUnit? spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final gap = context.units(
      spacing ?? CarpenterTheme.of(context).spacing.layoutSection,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < children.length; index++) ...[
          children[index],
          if (index < children.length - 1) SizedBox(height: gap),
        ],
      ],
    );
  }
}
