import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../behaviour/action_strip.dart';

@immutable
final class CarpenterTableActions {
  const CarpenterTableActions({
    this.primary = const [],
    this.secondary = const [],
  });

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
}

typedef CarpenterTableActionsBuilder<T> = CarpenterTableActions Function(
  T item,
);

/// Compact, geometry-stable action projection used by table and tree-table rows.
///
/// Up to two icon-bearing primary actions remain inline. Additional primary
/// actions, primary actions without icons, and every secondary action are
/// projected into the shared overflow behaviour used by page toolbars. The
/// owning table reserves the whole lane so action availability never changes
/// row geometry.
final class CarpenterTableActionCell extends StatelessWidget {
  const CarpenterTableActionCell({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.overflowLabel = 'More actions',
    this.semanticLabel = 'Row actions',
  });

  static const int inlinePrimaryLimit = 2;

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;
  final String overflowLabel;
  final String semanticLabel;

  static double preferredColumnWidth(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final padding = context.units(theme.spacing.tableHorizontal);
    return CarpenterActionStrip.compactExtent(
          context,
          inlineActions: inlinePrimaryLimit,
          reserveOverflow: true,
          size: ControlSize.xsmall,
        ) +
        padding * 2;
  }

  @override
  Widget build(BuildContext context) {
    var inlinePrimaryCount = 0;
    final items = <CarpenterActionStripItem>[];

    for (final action in primary) {
      final inline =
          action.icon != null && inlinePrimaryCount < inlinePrimaryLimit;
      if (inline) inlinePrimaryCount += 1;
      items.add(
        CarpenterActionStripItem(
          action: action,
          group: inline
              ? CarpenterActionStripGroup.primary
              : CarpenterActionStripGroup.overflow,
          presentation: inline
              ? CarpenterActionStripPresentation.icon
              : CarpenterActionStripPresentation.label,
          prominence: ActionProminence.ghost,
          size: ControlSize.xsmall,
        ),
      );
    }
    for (final action in secondary) {
      items.add(
        CarpenterActionStripItem(
          action: action,
          group: CarpenterActionStripGroup.overflow,
          prominence: ActionProminence.ghost,
          size: ControlSize.xsmall,
        ),
      );
    }

    return CarpenterActionStrip(
      items: items,
      alignment: AlignmentDirectional.centerEnd,
      overflowLabel: overflowLabel,
      overflowSize: ControlSize.xsmall,
      semanticLabel: semanticLabel,
    );
  }
}
