import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/layout/grid_layout.dart';
import '../../basic/button/icon_button.dart';
import '../../basic/gravity_icons.g.dart';
import '../../basic/icon.dart';
import '../../behaviour/drag_and_drop/draggable.dart';
import '../contracts/selection_mode.dart';
import '../table/table_actions.dart';
import '../table/table_column.dart';
import '../table/table_text.dart';
import 'tree_event.dart';
import 'tree_state.dart';
import 'tree_view.dart';

typedef CarpenterTreeTableCellBuilder<T> =
    Widget Function(BuildContext context, CarpenterTreeNode<T> node);
typedef CarpenterTreeTableColumnWidthChanged =
    void Function(String columnId, LengthUnit width);

@immutable
final class CarpenterTreeTableColumn<T> {
  const CarpenterTreeTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.flex = 1,
    this.width,
    this.alignment = CarpenterTableColumnAlignment.start,
    this.verticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.resizable = true,
    this.semanticLabel,
  }) : assert(flex > 0);

  /// Creates a compact action column using the same action-lane semantics as a
  /// regular [CarpenterTable].
  factory CarpenterTreeTableColumn.actions({
    required String id,
    required String header,
    required CarpenterTreeActionsBuilder<T> actions,
    CarpenterTreeActionsBuilder<T>? secondaryActions,
    CarpenterTableColumnAlignment alignment = CarpenterTableColumnAlignment.end,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.actionLane(),
    bool resizable = false,
    String? semanticLabel,
    String overflowLabel = 'More actions',
  }) => CarpenterTreeTableColumn<T>(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, node) => CarpenterTableActionCell(
      primary: actions(node),
      secondary: secondaryActions?.call(node) ?? const [],
      overflowLabel: overflowLabel,
      semanticLabel: 'Actions for ${node.effectiveSemanticLabel}',
    ),
  );

  final String id;
  final String header;
  final CarpenterTreeTableCellBuilder<T> cellBuilder;

  /// Legacy shorthand retained for source compatibility. When [width] is not
  /// supplied it becomes a flexible table width with this flex value.
  final int flex;
  final CarpenterTableColumnWidth? width;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final bool resizable;
  final String? semanticLabel;

  CarpenterTableColumnWidth get effectiveWidth =>
      width ?? CarpenterTableColumnWidth.flexible(flex: flex);
}

/// Tabular projection of [CarpenterTreeView]. Expansion, selection, activation,
/// filtering, reveal and DnD use exactly the same contracts as the regular
/// tree.
///
/// Cell geometry is shared by header and rows. Column widths can be supplied
/// through [columnWidths], while direct pointer resizing works without a
/// callback and is reported through [onColumnWidthChanged] when provided.
final class CarpenterTreeTable<T> extends StatefulWidget {
  const CarpenterTreeTable({
    super.key,
    required this.nodes,
    this.controller,
    this.treeColumnId = 'tree',
    this.treeHeader = 'Name',
    this.treeFlex = 2,
    this.treeWidth,
    this.treeAlignment = CarpenterTableColumnAlignment.start,
    this.treeVerticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.treeResizable = true,
    this.columns = const [],
    this.columnWidths = const {},
    this.onColumnWidthChanged,
    this.expandedIds = const {},
    this.selectedIds = const {},
    this.selectionMode = CarpenterTreeSelectionMode.single,
    this.multipleSelectionBehavior = CollectionMultiSelectionBehavior.toggle,
    this.scrollController,
    this.onExpansionChanged,
    this.onSelectionChanged,
    this.onActivated,
    this.filter,
    this.onDrop,
    this.canDrop,
    this.onRetryLoad,
    this.actions,
    this.secondaryActions,
    this.actionsHeader = '',
    this.actionsOverflowLabel = 'More actions',
    this.iconBuilder,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.framed = true,
    this.semanticLabel = 'Tree table',
  }) : assert(treeFlex > 0);

  final List<CarpenterTreeNode<T>> nodes;
  final CarpenterTreeController? controller;
  final String treeColumnId;
  final String treeHeader;
  final int treeFlex;
  final CarpenterTableColumnWidth? treeWidth;
  final CarpenterTableColumnAlignment treeAlignment;
  final CarpenterTableColumnVerticalAlignment treeVerticalAlignment;
  final bool treeResizable;
  final List<CarpenterTreeTableColumn<T>> columns;
  final Map<String, LengthUnit> columnWidths;
  final CarpenterTreeTableColumnWidthChanged? onColumnWidthChanged;
  final Set<Object> expandedIds;
  final Set<Object> selectedIds;
  final CarpenterTreeSelectionMode selectionMode;
  final CollectionMultiSelectionBehavior multipleSelectionBehavior;
  final ScrollController? scrollController;
  final CarpenterTreeExpansionChanged? onExpansionChanged;
  final CarpenterTreeSelectionChanged? onSelectionChanged;
  final CarpenterTreeActivation<T>? onActivated;
  final CarpenterTreeNodePredicate<T>? filter;
  final CarpenterTreeDropCallback<T>? onDrop;
  final CarpenterTreeDropAcceptance<T>? canDrop;
  final CarpenterTreeNodeCallback<T>? onRetryLoad;

  /// Compatibility shorthand for a trailing action column.
  ///
  /// New code should prefer [CarpenterTreeTableColumn.actions] in [columns].
  final CarpenterTreeActionsBuilder<T>? actions;

  /// Compatibility shorthand for secondary actions in the trailing action
  /// column. New code should prefer [CarpenterTreeTableColumn.actions].
  final CarpenterTreeActionsBuilder<T>? secondaryActions;
  final String actionsHeader;
  final String actionsOverflowLabel;
  final CarpenterTreeIconBuilder<T>? iconBuilder;
  final CarpenterDragActivation dragActivation;
  final bool framed;
  final String semanticLabel;

  @override
  State<CarpenterTreeTable<T>> createState() => _CarpenterTreeTableState<T>();
}

final class _CarpenterTreeTableState<T> extends State<CarpenterTreeTable<T>> {
  final Map<String, LengthUnit> _localColumnWidths = {};

  CarpenterTableColumnWidth get _effectiveTreeWidth =>
      widget.treeWidth ??
      CarpenterTableColumnWidth.flexible(flex: widget.treeFlex);

  bool get _hasLegacyActions =>
      widget.actions != null || widget.secondaryActions != null;

  String get _legacyActionColumnId {
    final used = <String>{
      widget.treeColumnId,
      ...widget.columns.map((column) => column.id),
    };
    var candidate = r'$carpenter.actions';
    while (used.contains(candidate)) {
      candidate = '_$candidate';
    }
    return candidate;
  }

  List<CarpenterTreeTableColumn<T>> get _effectiveColumns {
    if (!_hasLegacyActions) return widget.columns;
    return [
      ...widget.columns,
      CarpenterTreeTableColumn<T>.actions(
        id: _legacyActionColumnId,
        header: widget.actionsHeader,
        semanticLabel: 'Actions',
        actions:
            widget.actions ?? (_) => const <CarpenterActionDescriptor>[],
        secondaryActions: widget.secondaryActions,
        overflowLabel: widget.actionsOverflowLabel,
      ),
    ];
  }

  @override
  void didUpdateWidget(CarpenterTreeTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = <String>{
      widget.treeColumnId,
      ..._effectiveColumns.map((column) => column.id),
    };
    _localColumnWidths.removeWhere((id, _) => !ids.contains(id));
    for (final entry in widget.columnWidths.entries) {
      if (oldWidget.columnWidths[entry.key] != entry.value) {
        _localColumnWidths.remove(entry.key);
      }
    }
  }

  void _resizeColumn(String id, double value, BuildContext context) {
    final width = Rem(value / context.units(1.rem));
    setState(() => _localColumnWidths[id] = width);
    widget.onColumnWidthChanged?.call(id, width);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final outerPadding = context.units(theme.spacing.tableHorizontal);
    final gap = context.units(theme.spacing.tableCellGap);
    final columns = _effectiveColumns;

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _resolveLayout(
          context,
          constraints.maxWidth,
          columns: columns,
          outerPadding: outerPadding,
          gap: gap,
        );
        final tree = CarpenterTreeView<T>(
          nodes: widget.nodes,
          controller: widget.controller,
          expandedIds: widget.expandedIds,
          selectedIds: widget.selectedIds,
          selectionMode: widget.selectionMode,
          multipleSelectionBehavior: widget.multipleSelectionBehavior,
          scrollController: widget.scrollController,
          onExpansionChanged: widget.onExpansionChanged,
          onSelectionChanged: widget.onSelectionChanged,
          onActivated: widget.onActivated,
          filter: widget.filter,
          onDrop: widget.onDrop,
          canDrop: widget.canDrop,
          onRetryLoad: widget.onRetryLoad,
          actions: null,
          iconBuilder: null,
          tableRows: true,
          dragActivation: widget.dragActivation,
          semanticLabel: '${widget.semanticLabel} rows',
          rowBuilder: (context, node, state, _) =>
              _buildRow(context, layout, columns, node, state, gap),
        );
        Widget content = Column(
          mainAxisSize: widget.scrollController == null
              ? MainAxisSize.min
              : MainAxisSize.max,
          children: [
            _buildHeader(context, layout, columns, outerPadding, gap),
            if (widget.scrollController == null)
              tree
            else
              Expanded(child: tree),
          ],
        );
        content = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(width: layout.totalWidth, child: content),
        );

        if (widget.framed) {
          final borderWidth = context.units(theme.shapes.tableBorderWidth);
          final radius = context.units(theme.shapes.tableSurfaceRadius);
          content = DecoratedBox(
            decoration: BoxDecoration(
              color: theme.overlay.background,
              border: Border.all(
                color: theme.overlay.border,
                width: borderWidth,
              ),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: content,
            ),
          );
        }

        return Semantics(
          container: true,
          label: widget.semanticLabel,
          child: content,
        );
      },
    );
  }

  _TreeTableLayout _resolveLayout(
    BuildContext context,
    double viewportWidth, {
    required List<CarpenterTreeTableColumn<T>> columns,
    required double outerPadding,
    required double gap,
  }) {
    final theme = CarpenterTheme.of(context);
    final publicSpecs = <({String id, CarpenterTableColumnWidth width})>[
      (id: widget.treeColumnId, width: _effectiveTreeWidth),
      for (final column in columns)
        (id: column.id, width: column.effectiveWidth),
    ];
    final resolvedColumns = <GridColumnSpec>[];
    for (final spec in publicSpecs) {
      final minimum = context.units(
        spec.width.minimum ?? theme.sizes.tableColumnMin,
      );
      final maximum = context.units(
        spec.width.maximum ?? theme.sizes.tableColumnMax,
      );
      final pinned =
          _localColumnWidths.containsKey(spec.id) ||
          widget.columnWidths.containsKey(spec.id);
      final explicit =
          _localColumnWidths[spec.id] ??
          widget.columnWidths[spec.id] ??
          spec.width.preferred;
      final preferred =
          explicit == null &&
              spec.width.policy == CarpenterTableColumnWidthPolicy.actionLane
          ? CarpenterTableActionCell.preferredColumnWidth(context)
          : context.units(explicit ?? theme.sizes.tableColumn);
      resolvedColumns.add(
        GridColumnSpec(
          id: spec.id,
          preferred: preferred,
          minimum: minimum,
          maximum: maximum,
          flex: spec.width.flex,
          flexible: spec.width.isFlexible,
          pinned: pinned,
        ),
      );
    }
    final resolved = GridLayoutResolver.resolve(
      columns: resolvedColumns,
      viewportWidth: viewportWidth,
      outerInset: outerPadding,
      gap: gap,
    );
    return _TreeTableLayout(
      widths: resolved.widths,
      minimums: resolved.minimums,
      maximums: resolved.maximums,
      totalWidth: resolved.totalWidth,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    _TreeTableLayout layout,
    List<CarpenterTreeTableColumn<T>> columns,
    double outerPadding,
    double gap,
  ) {
    final theme = CarpenterTheme.of(context);
    final height = MediaQuery.textScalerOf(
      context,
    ).scale(context.units(theme.sizes.tableHeaderHeight));
    return Container(
      color: theme.surface.subtle,
      height: height,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: outerPadding,
        vertical: context.units(theme.spacing.tableVertical),
      ),
      child: Row(
        children: [
          _TreeHeaderCell(
            id: widget.treeColumnId,
            label: widget.treeHeader,
            semanticLabel: widget.treeHeader,
            width: layout.widths[widget.treeColumnId]!,
            minimumWidth: layout.minimums[widget.treeColumnId]!,
            maximumWidth: layout.maximums[widget.treeColumnId]!,
            alignment: widget.treeAlignment,
            verticalAlignment: widget.treeVerticalAlignment,
            resizable: widget.treeResizable,
            onWidthChanged: (value) =>
                _resizeColumn(widget.treeColumnId, value, context),
          ),
          for (final column in columns) ...[
            SizedBox(width: gap),
            _TreeHeaderCell(
              id: column.id,
              label: column.header,
              semanticLabel: column.semanticLabel ?? column.header,
              width: layout.widths[column.id]!,
              minimumWidth: layout.minimums[column.id]!,
              maximumWidth: layout.maximums[column.id]!,
              alignment: column.alignment,
              verticalAlignment: column.verticalAlignment,
              resizable: column.resizable,
              onWidthChanged: (value) =>
                  _resizeColumn(column.id, value, context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    _TreeTableLayout layout,
    List<CarpenterTreeTableColumn<T>> columns,
    CarpenterTreeNode<T> node,
    CarpenterTreeRowState<T> state,
    double gap,
  ) {
    return Row(
      children: [
        _TreeTableSlot(
          width: layout.widths[widget.treeColumnId]!,
          alignment: widget.treeAlignment,
          verticalAlignment: widget.treeVerticalAlignment,
          child: Row(
            children: [
              _TreeTablePrefix<T>(
                node: node,
                depth: state.depth,
                expanded: state.expanded,
                icon: widget.iconBuilder?.call(node),
                onToggle: () => widget.onExpansionChanged?.call(
                  node.id,
                  !widget.expandedIds.contains(node.id),
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: CarpenterTableText.cell(
                  node.label,
                  emphasis: state.selected || state.focused
                      ? TypographyEmphasis.medium
                      : TypographyEmphasis.regular,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        for (final column in columns) ...[
          SizedBox(width: gap),
          _TreeTableSlot(
            width: layout.widths[column.id]!,
            alignment: column.alignment,
            verticalAlignment: column.verticalAlignment,
            child: column.cellBuilder(context, node),
          ),
        ],
      ],
    );
  }
}

final class _TreeTableLayout {
  const _TreeTableLayout({
    required this.widths,
    required this.minimums,
    required this.maximums,
    required this.totalWidth,
  });

  final Map<String, double> widths;
  final Map<String, double> minimums;
  final Map<String, double> maximums;
  final double totalWidth;
}

final class _TreeHeaderCell extends StatelessWidget {
  const _TreeHeaderCell({
    required this.id,
    required this.label,
    required this.semanticLabel,
    required this.width,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.alignment,
    required this.verticalAlignment,
    required this.resizable,
    required this.onWidthChanged,
  });

  final String id;
  final String label;
  final String semanticLabel;
  final double width;
  final double minimumWidth;
  final double maximumWidth;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final bool resizable;
  final ValueChanged<double> onWidthChanged;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: carpenterTableCellAlignment(
              alignment,
              verticalAlignment,
            ),
            child: CarpenterTableText.header(
              label,
              semanticsLabel: semanticLabel,
            ),
          ),
          if (resizable)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _TreeResizeHandle(
                key: ValueKey('tree-table-resize-$id'),
                width: context.units(theme.sizes.tableResizeHandle),
                currentWidth: width,
                minimumWidth: minimumWidth,
                maximumWidth: maximumWidth,
                onChanged: onWidthChanged,
              ),
            ),
        ],
      ),
    );
  }
}

final class _TreeResizeHandle extends StatefulWidget {
  const _TreeResizeHandle({
    super.key,
    required this.width,
    required this.currentWidth,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.onChanged,
  });

  final double width;
  final double currentWidth;
  final double minimumWidth;
  final double maximumWidth;
  final ValueChanged<double> onChanged;

  @override
  State<_TreeResizeHandle> createState() => _TreeResizeHandleState();
}

final class _TreeResizeHandleState extends State<_TreeResizeHandle> {
  late double _dragWidth;
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final active = _hovered || _dragging;
    final strokeWidth = active
        ? context.units(theme.focus.width)
        : context.units(theme.shapes.tableBorderWidth);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragWidth = widget.currentWidth;
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (details) {
          final logicalDelta = Directionality.of(context) == TextDirection.rtl
              ? -details.delta.dx
              : details.delta.dx;
          _dragWidth = (_dragWidth + logicalDelta).clamp(
            widget.minimumWidth,
            widget.maximumWidth,
          );
          widget.onChanged(_dragWidth);
        },
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.width,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: strokeWidth,
              height: double.infinity,
              child: ColoredBox(
                color: active ? theme.focus.color : theme.overlay.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _TreeTableSlot extends StatelessWidget {
  const _TreeTableSlot({
    required this.width,
    required this.alignment,
    required this.verticalAlignment,
    required this.child,
  });

  final double width;
  final CarpenterTableColumnAlignment alignment;
  final CarpenterTableColumnVerticalAlignment verticalAlignment;
  final Widget child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Align(
      alignment: carpenterTableCellAlignment(alignment, verticalAlignment),
      child: child,
    ),
  );
}

final class _TreeTablePrefix<T> extends StatelessWidget {
  const _TreeTablePrefix({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.icon,
    required this.onToggle,
  });

  final CarpenterTreeNode<T> node;
  final int depth;
  final bool expanded;
  final CarpenterIconSource? icon;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final indent = context.units(theme.spacing.large) * depth;
    final gap = context.units(theme.spacing.small);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: indent),
        if (node.canExpand)
          CarpenterIconButton(
            icon: expanded
                ? GravityIcons.chevronDown
                : GravityIcons.chevronRight,
            semanticLabel: expanded
                ? 'Collapse ${node.label}'
                : 'Expand ${node.label}',
            prominence: ActionProminence.ghost,
            size: ControlSize.xsmall,
            onPressed: onToggle,
          )
        else
          SizedBox(
            width: context.units(theme.sizes.control(ControlSize.xsmall)),
          ),
        if (icon != null) ...[
          SizedBox(width: gap),
          CarpenterIcon(icon!, size: IconSize.small),
        ],
      ],
    );
  }
}
