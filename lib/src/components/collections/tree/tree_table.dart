import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/text.dart';
import '../../behaviour/drag_and_drop/draggable.dart';
import '../table/table_column.dart';
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
    this.width,
    this.alignment = CarpenterTableColumnAlignment.start,
    this.semanticLabel,
  }) : assert(flex > 0);

  final String id;
  final String header;
  final CarpenterTreeTableCellBuilder<T> cellBuilder;

  /// Legacy shorthand retained for source compatibility. When [width] is not
  /// supplied it becomes a flexible table width with this flex value.
  final int flex;
  final CarpenterTableColumnWidth? width;
  final CarpenterTableColumnAlignment alignment;
  final String? semanticLabel;

  CarpenterTableColumnWidth get effectiveWidth =>
      width ?? CarpenterTableColumnWidth.flexible(flex: flex);
}

/// Tabular projection of [CarpenterTreeView]. Expansion, selection, activation,
/// filtering, reveal and DnD use exactly the same contracts as the regular
/// tree.
///
/// The table is flat by default so it can participate in a continuous page
/// flow. Set [framed] only when the table is intentionally an independent
/// surface, for example inside an overlay or side panel.
final class CarpenterTreeTable<T> extends StatelessWidget {
  const CarpenterTreeTable({
    super.key,
    required this.nodes,
    this.controller,
    this.treeHeader = 'Name',
    this.treeFlex = 2,
    this.treeWidth,
    this.treeAlignment = CarpenterTableColumnAlignment.start,
    this.columns = const [],
    this.expandedIds = const {},
    this.selectedIds = const {},
    this.selectionMode = CarpenterTreeSelectionMode.single,
    this.onExpansionChanged,
    this.onSelectionChanged,
    this.onActivated,
    this.filter,
    this.onDrop,
    this.canDrop,
    this.onRetryLoad,
    this.actions,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.framed = false,
    this.semanticLabel = 'Tree table',
  }) : assert(treeFlex > 0);

  final List<CarpenterTreeNode<T>> nodes;
  final CarpenterTreeController? controller;
  final String treeHeader;
  final int treeFlex;
  final CarpenterTableColumnWidth? treeWidth;
  final CarpenterTableColumnAlignment treeAlignment;
  final List<CarpenterTreeTableColumn<T>> columns;
  final Set<Object> expandedIds;
  final Set<Object> selectedIds;
  final CarpenterTreeSelectionMode selectionMode;
  final CarpenterTreeExpansionChanged? onExpansionChanged;
  final CarpenterTreeSelectionChanged? onSelectionChanged;
  final CarpenterTreeActivation<T>? onActivated;
  final CarpenterTreeNodePredicate<T>? filter;
  final CarpenterTreeDropCallback<T>? onDrop;
  final CarpenterTreeDropAcceptance<T>? canDrop;
  final CarpenterTreeNodeCallback<T>? onRetryLoad;
  final CarpenterTreeActionsBuilder<T>? actions;
  final CarpenterDragActivation dragActivation;
  final bool framed;
  final String semanticLabel;

  CarpenterTableColumnWidth get _effectiveTreeWidth =>
      treeWidth ?? CarpenterTableColumnWidth.flexible(flex: treeFlex);

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
              _TreeTableSlot(
                width: _effectiveTreeWidth,
                alignment: treeAlignment,
                child: CarpenterText.label(
                  treeHeader,
                  emphasis: TypographyEmphasis.strong,
                ),
              ),
              for (final column in columns) ...[
                SizedBox(width: gap),
                _TreeTableSlot(
                  width: column.effectiveWidth,
                  alignment: column.alignment,
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
          controller: controller,
          expandedIds: expandedIds,
          selectedIds: selectedIds,
          selectionMode: selectionMode,
          onExpansionChanged: onExpansionChanged,
          onSelectionChanged: onSelectionChanged,
          onActivated: onActivated,
          filter: filter,
          onDrop: onDrop,
          canDrop: canDrop,
          onRetryLoad: onRetryLoad,
          actions: actions,
          dragActivation: dragActivation,
          semanticLabel: '$semanticLabel rows',
          itemBuilder: (context, node, state) => Row(
            children: [
              _TreeTableSlot(
                width: _effectiveTreeWidth,
                alignment: treeAlignment,
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
                _TreeTableSlot(
                  width: column.effectiveWidth,
                  alignment: column.alignment,
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

final class _TreeTableSlot extends StatelessWidget {
  const _TreeTableSlot({
    required this.width,
    required this.alignment,
    required this.child,
  });

  final CarpenterTableColumnWidth width;
  final CarpenterTableColumnAlignment alignment;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final resolvedAlignment = switch (alignment) {
      CarpenterTableColumnAlignment.start => AlignmentDirectional.centerStart,
      CarpenterTableColumnAlignment.center => AlignmentDirectional.center,
      CarpenterTableColumnAlignment.end => AlignmentDirectional.centerEnd,
    };
    final minimum = width.minimum == null ? 0.0 : context.units(width.minimum!);
    final maximum = width.maximum == null
        ? double.infinity
        : context.units(width.maximum!);
    final aligned = Align(alignment: resolvedAlignment, child: child);

    if (width.policy == CarpenterTableColumnWidthPolicy.fixed) {
      final preferred = context.units(width.preferred!);
      return ConstrainedBox(
        constraints: BoxConstraints(minWidth: minimum, maxWidth: maximum),
        child: SizedBox(width: preferred, child: aligned),
      );
    }

    return Flexible(
      flex: width.flex,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: minimum, maxWidth: maximum),
        child: aligned,
      ),
    );
  }
}
