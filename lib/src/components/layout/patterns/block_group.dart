import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';

/// Groups related local content blocks without introducing another page-level
/// section gap.
///
/// Page roots and semantic sections own the larger document rhythm. A block
/// group is intentionally denser so nested composition does not accumulate the
/// same large spacing at every level.
final class CarpenterBlockGroup extends StatelessWidget {
  const CarpenterBlockGroup({super.key, required this.children, this.spacing});

  final List<Widget> children;
  final LengthUnit? spacing;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final gap = context.units(
      spacing ?? CarpenterTheme.of(context).spacing.medium,
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
