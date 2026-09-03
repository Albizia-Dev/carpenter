import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../layout/toolbar.dart';

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

/// Compact action surface used by table and tree-table rows.
///
/// Primary actions stay inline whenever the reserved lane can contain them.
/// Secondary actions are intentionally placed in the ellipsis menu. The lane
/// itself is reserved by the owning table, so action visibility never changes
/// row geometry.
final class CarpenterTableActionCell extends StatelessWidget {
  const CarpenterTableActionCell({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.overflowLabel = 'More actions',
    this.semanticLabel = 'Row actions',
  });

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;
  final String overflowLabel;
  final String semanticLabel;

  static double preferredColumnWidth(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final control = context.units(theme.sizes.actionHeight(ControlSize.xsmall));
    final gap = context.units(theme.spacing.layoutToolbar);
    final padding = context.units(theme.spacing.tableHorizontal);

    // Two primary icon slots plus a stable overflow slot is a useful default.
    // Label-only actions still work: the toolbar moves them into overflow when
    // they cannot fit instead of widening the row.
    return control * 3 + gap * 2 + padding * 2;
  }

  @override
  Widget build(BuildContext context) => CarpenterToolbar(
    alignment: AlignmentDirectional.centerEnd,
    overflowLabel: overflowLabel,
    overflowSize: ControlSize.xsmall,
    semanticLabel: semanticLabel,
    items: [
      for (final action in primary)
        CarpenterToolbarItem(
          action: action,
          group: CarpenterToolbarGroup.primary,
          presentation: action.icon == null
              ? CarpenterToolbarPresentation.label
              : CarpenterToolbarPresentation.icon,
          prominence: ActionProminence.ghost,
          size: ControlSize.xsmall,
        ),
      for (final action in secondary)
        CarpenterToolbarItem(
          action: action,
          group: CarpenterToolbarGroup.overflow,
          prominence: ActionProminence.ghost,
          size: ControlSize.xsmall,
        ),
    ],
  );
}
