import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/text.dart';
import '../../behaviour/drag_and_drop/draggable.dart';
import 'tree_event.dart';
import 'tree_state.dart';
import 'tree_view.dart';

typedef CarpenterTreeTableCellBuilder<T> =
    Widget Function(BuildContext context, CarpenterTreeNode<T> node);

@immutable
final class CarpenterTreeTableColumn<T> {
  const CarpenterTreeTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.semanticLabel,
  }) : assert(flex > 0);

  final String id;
  final String header;
  final CarpenterTreeTableCellBuilder<T> cellBuilder;
  final int flex;
  final String? semanticLabel;
}

/// Tabular projection of [CarpenterTreeView]. Expansion, selection and DnD use
/// exactly the same controlled contracts as the regular tree.
///
/// The table is flat by default so it can participate in a continuous page
/// flow. Set [framed] only when the table is intentionally an independent
/// surface, for example inside an overlay or side panel.
final class CarpenterTreeTable<T> extends StatelessWidget {
  const CarpenterTreeTable({
    super.key,
    required this.nodes,
    this.treeHeader = 'Name',
    this.treeFlex = 2,
    this.columns = const [],
    this.expandedIds = const {},
    this.selectedIds = const {},
    this.selectionMode = CarpenterTreeSelectionMode.single,
    this.onExpansionChanged,
    this.onSelectionChanged,
    this.onDrop,
    this.canDrop,
    this.onRetryLoad,
    this.actions,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.framed = false,
    this.semanticLabel = 'Tree table',
  }) : assert(treeFlex > 0);

  final List<CarpenterTreeNode<T>> nodes;
  final String treeHeader;
  final int treeFlex;
  final List<CarpenterTreeTableColumn<T>> columns;
  final Set<Object> expandedIds;
  final Set<Object> selectedIds;
  final CarpenterTreeSelectionMode selectionMode;
  final CarpenterTreeExpansionChanged? onExpansionChanged;
  final CarpenterTreeSelectionChanged? onSelectionChanged;
  final CarpenterTreeDropCallback<T>? onDrop;
  final CarpenterTreeDropAcceptance<T>? canDrop;
  final CarpenterTreeNodeCallback<T>? onRetryLoad;
  final CarpenterTreeActionsBuilder<T>? actions;
  final CarpenterDragActivation dragActivation;
  final bool framed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: theme.surface.subtle,
          padding: EdgeInsets.symmetric(horizontal: gap, vertical: gap / 2),
          child: Row(
            children: [
              Expanded(
                flex: treeFlex,
                child: CarpenterText.label(
                  treeHeader,
                  emphasis: TypographyEmphasis.strong,
                ),
              ),
              for (final column in columns) ...[
                SizedBox(width: gap),
                Expanded(
                  flex: column.flex,
                  child: CarpenterText.label(
                    column.header,
                    semanticsLabel: column.semanticLabel,
                    emphasis: TypographyEmphasis.strong,
                  ),
                ),
              ],
            ],
          ),
        ),
        CarpenterTreeView<T>(
          nodes: nodes,
          expandedIds: expandedIds,
          selectedIds: selectedIds,
          selectionMode: selectionMode,
          onExpansionChanged: onExpansionChanged,
          onSelectionChanged: onSelectionChanged,
          onDrop: onDrop,
          canDrop: canDrop,
          onRetryLoad: onRetryLoad,
          actions: actions,
          dragActivation: dragActivation,
          semanticLabel: '$semanticLabel rows',
          itemBuilder: (context, node, state) => Row(
            children: [
              Expanded(
                flex: treeFlex,
                child: CarpenterText.label(
                  node.label,
                  emphasis: state.selected || state.focused
                      ? TypographyEmphasis.medium
                      : TypographyEmphasis.regular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              for (final column in columns) ...[
                SizedBox(width: gap),
                Expanded(
                  flex: column.flex,
                  child: column.cellBuilder(context, node),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (framed) {
      final borderWidth = context.units(theme.shapes.tableBorderWidth);
      final radius = context.units(theme.shapes.tableSurfaceRadius);
      content = DecoratedBox(
        decoration: BoxDecoration(
          color: theme.overlay.background,
          border: Border.all(color: theme.overlay.border, width: borderWidth),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: content,
        ),
      );
    }

    return Semantics(container: true, label: semanticLabel, child: content);
  }
}
