import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/theme.dart';

/// Lays out related fields while preserving visual proximity.
///
/// Spacing inside each field is owned by the field itself. This component only
/// controls spacing *between* fields, so its default gaps are deliberately
/// larger than a label-to-control gap.
final class CarpenterFieldGroup extends StatelessWidget {
  const CarpenterFieldGroup({
    super.key,
    required this.children,
    this.columns = 1,
    this.columnSpacing,
    this.rowSpacing,
    this.minimumColumnWidth = const Rem(18),
  }) : assert(columns > 0);

  final List<Widget> children;
  final int columns;
  final LengthUnit? columnSpacing;
  final LengthUnit? rowSpacing;
  final LengthUnit minimumColumnWidth;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final theme = CarpenterTheme.of(context);
    final columnGap = context.units(columnSpacing ?? theme.spacing.layoutSection);
    final rowGap = context.units(rowSpacing ?? theme.spacing.large);
    final minWidth = context.units(minimumColumnWidth);

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth;
        final requestedColumns = available.isFinite
            ? ((available + columnGap) / (minWidth + columnGap)).floor()
            : columns;
        final effectiveColumns = requestedColumns.clamp(1, columns);
        if (effectiveColumns == 1 || !available.isFinite) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) SizedBox(height: rowGap),
              ],
            ],
          );
        }

        final itemWidth =
            (available - columnGap * (effectiveColumns - 1)) /
            effectiveColumns;
        return Wrap(
          spacing: columnGap,
          runSpacing: rowGap,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
