import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/layout/grid_layout.dart';
import '../../basic/button/icon_button.dart';
import '../../basic/gravity_icons.g.dart';
import '../../basic/icon.dart';
import '../../basic/status_indicator.dart';
import '../../behaviour/context_actions.dart';
import '../../behaviour/drag_and_drop/drag_operation.dart';
import '../../behaviour/drag_and_drop/draggable.dart';
import '../contracts/selection_mode.dart';
import '../table_metrics.dart';
import '../table/table_actions.dart';
import '../table/table_cell.dart';
import '../table/table_column.dart';
import '../table/table_text.dart';
import 'tree_event.dart';
import 'tree_state.dart';
import 'tree_view.dart';

/// Builds the content displayed in one tree-table cell for [node].
typedef CarpenterTreeTableCellBuilder<T> =
    Widget Function(BuildContext context, CarpenterTreeNode<T> node);

/// Builds the editable/display content of the leading tree column.
typedef CarpenterTreeTableTreeCellBuilder<T> =
    Widget Function(
      BuildContext context,
      CarpenterTreeNode<T> node,
      CarpenterTreeRowState<T> state,
    );

/// Reports the caller-visible width selected for a resized tree-table column.
typedef CarpenterTreeTableColumnWidthChanged =
    void Function(String columnId, LengthUnit width);

/// Builds the primary and secondary semantic actions represented by a tree-table column.
typedef CarpenterTreeTableActionsBuilder<T> =
    CarpenterTableActions Function(CarpenterTreeNode<T> node);

@immutable
final class CarpenterTreeTableColumn<T> {
  /// Creates a tree-table column through the legacy flex-based width shorthand.
  ///
  /// Prefer [CarpenterTreeTableColumn.custom]. [actionsBuilder] is optional
  /// semantic metadata used by action-lane contextual presentation.
  @Deprecated(
    'Use CarpenterTreeTableColumn.custom(...) with an explicit width contract.',
  )
  const CarpenterTreeTableColumn({
    required this.id,
    required this.header,
    required this.cellBuilder,
    @Deprecated(
      'Use width: CarpenterTableColumnWidth.flexible(flex: ...) instead.',
    )
    this.flex = 1,
    this.width,
    this.alignment = CarpenterTableColumnAlignment.start,
    this.verticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.resizable = true,
    this.semanticLabel,
    this.actionsBuilder,
  }) : assert(flex > 0);

  /// Creates a tree-table column with an explicit width and caller-owned cell.
  ///
  /// [actionsBuilder] is optional semantic metadata for actions represented by
  /// this column and is reused by contextual action presentation.
  const CarpenterTreeTableColumn.custom({
    required this.id,
    required this.header,
    required this.cellBuilder,
    this.width = const CarpenterTableColumnWidth.flexible(),
    this.alignment = CarpenterTableColumnAlignment.start,
    this.verticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.resizable = true,
    this.semanticLabel,
    this.actionsBuilder,
  }) : flex = 1;

  factory CarpenterTreeTableColumn.text({
    required String id,
    required String header,
    required String Function(CarpenterTreeNode<T> node) value,
    CarpenterTableColumnAlignment alignment =
        CarpenterTableColumnAlignment.start,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTreeTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, node) => CarpenterTableText.cell(
      value(node),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  );

  factory CarpenterTreeTableColumn.number({
    required String id,
    required String header,
    required num? Function(CarpenterTreeNode<T> node) value,
    String Function(num value)? formatter,
    CarpenterTableColumnAlignment alignment = CarpenterTableColumnAlignment.end,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTreeTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, node) {
      final number = value(node);
      return CarpenterTableText.cell(
        number == null ? '' : formatter?.call(number) ?? '$number',
        textAlign: switch (alignment) {
          CarpenterTableColumnAlignment.start => TextAlign.start,
          CarpenterTableColumnAlignment.center => TextAlign.center,
          CarpenterTableColumnAlignment.end => TextAlign.end,
        },
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    },
  );

  factory CarpenterTreeTableColumn.status({
    required String id,
    required String header,
    required String Function(CarpenterTreeNode<T> node) label,
    required FeedbackColorRole Function(CarpenterTreeNode<T> node) role,
    CarpenterTableColumnAlignment alignment =
        CarpenterTableColumnAlignment.start,
    CarpenterTableColumnVerticalAlignment verticalAlignment =
        CarpenterTableColumnVerticalAlignment.center,
    CarpenterTableColumnWidth width =
        const CarpenterTableColumnWidth.flexible(),
    bool resizable = true,
    String? semanticLabel,
  }) => CarpenterTreeTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    cellBuilder: (context, node) =>
        CarpenterStatusIndicator(label: label(node), role: role(node)),
  );

  /// Creates a pinned trailing action column using the same semantic actions
  /// for inline, overflow and contextual invocation.
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
    String overflowLabel = 'Действия',
  }) => CarpenterTreeTableColumn<T>.custom(
    id: id,
    header: header,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    width: width,
    resizable: resizable,
    semanticLabel: semanticLabel,
    actionsBuilder: (node) => CarpenterTableActions(
      primary: actions(node),
      secondary: secondaryActions?.call(node) ?? const [],
    ),
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

  /// Semantic actions represented by this column, when available.
  final CarpenterTreeTableActionsBuilder<T>? actionsBuilder;

  CarpenterTableColumnWidth get effectiveWidth =>
      width ?? CarpenterTableColumnWidth.flexible(flex: flex);
}

/// Tabular projection of [CarpenterTreeView]. Expansion, selection, activation,
/// filtering, reveal and DnD use exactly the same contracts as the regular
/// tree.
///
/// Action-lane columns remain pinned to the trailing edge while ordinary data
/// columns scroll underneath them. The same action descriptors open from the
/// pinned lane, secondary pointer press and touch long-press.
///
/// Cell geometry is shared by header and rows. Column widths can be supplied
/// through [columnWidths], while direct pointer resizing works without a
/// callback and is reported through [onColumnWidthChanged] when provided.
final class CarpenterTreeTable<T> extends StatefulWidget {
  /// Creates a controlled tree-table projection of [nodes].
  const CarpenterTreeTable({
    super.key,
    required this.nodes,
    this.controller,
    this.treeColumnId = 'tree',
    this.treeHeader = 'Name',
    @Deprecated(
      'Use treeWidth: CarpenterTableColumnWidth.flexible(flex: ...) instead.',
    )
    this.treeFlex = 2,
    this.treeWidth,
    this.treeAlignment = CarpenterTableColumnAlignment.start,
    this.treeVerticalAlignment = CarpenterTableColumnVerticalAlignment.center,
    this.treeResizable = true,
    this.treeCellBuilder,
    this.columns = const [],
    this.columnWidths = const {},
    this.onColumnWidthChanged,
    this.expandedIds = const {},
    this.selectedIds = const {},
    this.cutIds = const {},
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
    this.actionsOverflowLabel = 'Действия',
    this.iconBuilder,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.dragOperations = const {CarpenterDragOperation.move},
    this.framed = true,
    this.semanticLabel = 'Древовидная таблица',
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

  /// Optional builder for the leading tree cell of each node row.
  final CarpenterTreeTableTreeCellBuilder<T>? treeCellBuilder;
  final List<CarpenterTreeTableColumn<T>> columns;
  final Map<String, LengthUnit> columnWidths;
  final CarpenterTreeTableColumnWidthChanged? onColumnWidthChanged;
  final Set<Object> expandedIds;
  final Set<Object> selectedIds;

  /// Stable row ids that should use pending-cut presentation.
  final Set<Object> cutIds;
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

  /// Compatibility shorthand for a pinned trailing action column.
  ///
  /// New code should prefer [CarpenterTreeTableColumn.actions] in [columns].
  final CarpenterTreeActionsBuilder<T>? actions;

  /// Compatibility shorthand for secondary actions in the pinned trailing
  /// action column. New code should prefer [CarpenterTreeTableColumn.actions].
  final CarpenterTreeActionsBuilder<T>? secondaryActions;
  final String actionsHeader;
  final String actionsOverflowLabel;
  final CarpenterTreeIconBuilder<T>? iconBuilder;
  final CarpenterDragActivation dragActivation;

  /// Move/copy/link operations that rows may initiate through drag and drop.
  final Set<CarpenterDragOperation> dragOperations;
  final bool framed;
  final String semanticLabel;

  @override
  State<CarpenterTreeTable<T>> createState() => _CarpenterTreeTableState<T>();
}

final class _CarpenterTreeTableState<T> extends State<CarpenterTreeTable<T>> {
  final Map<String, LengthUnit> _localColumnWidths = {};
  final ScrollController _horizontalScrollController = ScrollController();

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
        semanticLabel: 'Действия со строкой',
        actions: widget.actions ?? (_) => const <CarpenterActionDescriptor>[],
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

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _resizeColumn(String id, double value, BuildContext context) {
    final width = Rem(value / context.units(1.rem));
    setState(() => _localColumnWidths[id] = width);
    widget.onColumnWidthChanged?.call(id, width);
  }

  double get _horizontalOffset => _horizontalScrollController.hasClients
      ? _horizontalScrollController.offset
      : 0.0;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final contentGap = metrics.cellGap;
    final columns = _effectiveColumns;
    final dataColumns = columns
        .where(
          (column) =>
              column.effectiveWidth.policy !=
              CarpenterTableColumnWidthPolicy.actionLane,
        )
        .toList(growable: false);
    final actionColumns = columns
        .where(
          (column) =>
              column.effectiveWidth.policy ==
              CarpenterTableColumnWidthPolicy.actionLane,
        )
        .toList(growable: false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _resolveLayout(
          context,
          constraints.maxWidth,
          dataColumns: dataColumns,
          actionColumns: actionColumns,
        );
        Widget content = SingleChildScrollView(
          controller: _horizontalScrollController,
          scrollDirection: Axis.horizontal,
          child: AnimatedBuilder(
            animation: _horizontalScrollController,
            builder: (context, _) {
              final offset = _horizontalOffset;
              final tree = CarpenterTreeView<T>(
                nodes: widget.nodes,
                controller: widget.controller,
                expandedIds: widget.expandedIds,
                selectedIds: widget.selectedIds,
                cutIds: widget.cutIds,
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
                tableRowContentPadding: false,
                dragActivation: widget.dragActivation,
                dragOperations: widget.dragOperations,
                semanticLabel: '${widget.semanticLabel} rows',
                rowBuilder: (context, node, state, _) => _buildRow(
                  context,
                  layout,
                  dataColumns,
                  actionColumns,
                  node,
                  state,
                  contentGap,
                  offset,
                ),
              );
              return SizedBox(
                width: layout.totalWidth,
                child: Column(
                  mainAxisSize: widget.scrollController == null
                      ? MainAxisSize.min
                      : MainAxisSize.max,
                  children: [
                    _buildHeader(
                      context,
                      layout,
                      dataColumns,
                      actionColumns,
                      offset,
                    ),
                    if (widget.scrollController == null)
                      tree
                    else
                      Expanded(child: tree),
                  ],
                ),
              );
            },
          ),
        );

        if (widget.framed) {
          final borderWidth = metrics.borderWidth;
          final radius = metrics.surfaceRadius;
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
    required List<CarpenterTreeTableColumn<T>> dataColumns,
    required List<CarpenterTreeTableColumn<T>> actionColumns,
  }) {
    final metrics = CarpenterTableMetrics.resolve(context);
    final widths = <String, double>{};
    final minimums = <String, double>{};
    final maximums = <String, double>{};
    var actionWidth = 0.0;

    for (final column in actionColumns) {
      final width = column.effectiveWidth;
      final minimum = width.minimum == null
          ? metrics.minimumColumnWidth
          : context.units(width.minimum!);
      final maximum = width.maximum == null
          ? metrics.maximumColumnWidth
          : context.units(width.maximum!);
      final explicit =
          _localColumnWidths[column.id] ??
          widget.columnWidths[column.id] ??
          width.preferred;
      final preferred = explicit == null
          ? CarpenterTableActionCell.preferredColumnWidth(context)
          : context.units(explicit);
      final resolved = preferred.clamp(minimum, maximum).toDouble();
      widths[column.id] = resolved;
      minimums[column.id] = minimum;
      maximums[column.id] = maximum;
      actionWidth += resolved;
    }

    final dataViewportWidth = viewportWidth.isFinite
        ? math.max(0.0, viewportWidth - actionWidth)
        : viewportWidth;
    final publicSpecs = <({String id, CarpenterTableColumnWidth width})>[
      (id: widget.treeColumnId, width: _effectiveTreeWidth),
      for (final column in dataColumns)
        (id: column.id, width: column.effectiveWidth),
    ];
    final resolvedColumns = <GridColumnSpec>[];
    for (final spec in publicSpecs) {
      final minimum = spec.width.minimum == null
          ? metrics.minimumColumnWidth
          : context.units(spec.width.minimum!);
      final maximum = spec.width.maximum == null
          ? metrics.maximumColumnWidth
          : context.units(spec.width.maximum!);
      final pinned =
          _localColumnWidths.containsKey(spec.id) ||
          widget.columnWidths.containsKey(spec.id);
      final explicit =
          _localColumnWidths[spec.id] ??
          widget.columnWidths[spec.id] ??
          spec.width.preferred;
      final preferred = explicit == null
          ? metrics.defaultColumnWidth
          : context.units(explicit);
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
      viewportWidth: dataViewportWidth,
    );
    widths.addAll(resolved.widths);
    minimums.addAll(resolved.minimums);
    maximums.addAll(resolved.maximums);
    final naturalWidth = resolved.totalWidth + actionWidth;
    final totalWidth = viewportWidth.isFinite
        ? math.max(viewportWidth, naturalWidth)
        : naturalWidth;
    return _TreeTableLayout(
      widths: widths,
      minimums: minimums,
      maximums: maximums,
      actionWidth: actionWidth,
      viewportWidth: viewportWidth,
      totalWidth: totalWidth,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    _TreeTableLayout layout,
    List<CarpenterTreeTableColumn<T>> dataColumns,
    List<CarpenterTreeTableColumn<T>> actionColumns,
    double horizontalOffset,
  ) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final height = metrics.headerHeight;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: theme.surface.subtle,
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
                  for (final column in dataColumns)
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
                  SizedBox(width: layout.actionWidth),
                ],
              ),
            ),
          ),
          if (actionColumns.isNotEmpty)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: layout.trailingCompensation(horizontalOffset),
              width: layout.actionWidth,
              child: ColoredBox(
                color: theme.surface.subtle,
                child: Row(
                  children: [
                    for (final column in actionColumns)
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
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<CarpenterActionDescriptor> _contextActions(
    CarpenterTreeNode<T> node,
    List<CarpenterTreeTableColumn<T>> actionColumns,
  ) {
    final primary = <CarpenterActionDescriptor>[];
    final secondary = <CarpenterActionDescriptor>[];
    for (final column in actionColumns) {
      final actions = column.actionsBuilder?.call(node);
      if (actions == null) continue;
      primary.addAll(actions.primary);
      secondary.addAll(actions.secondary);
    }
    return [...primary, ...secondary];
  }

  Widget _buildRow(
    BuildContext context,
    _TreeTableLayout layout,
    List<CarpenterTreeTableColumn<T>> dataColumns,
    List<CarpenterTreeTableColumn<T>> actionColumns,
    CarpenterTreeNode<T> node,
    CarpenterTreeRowState<T> state,
    double contentGap,
    double horizontalOffset,
  ) {
    final theme = CarpenterTheme.of(context);
    final background = state.selected
        ? theme.overlay.selected
        : state.hovering
        ? theme.overlay.hovered
        : theme.overlay.background;
    Widget row = Stack(
      children: [
        Row(
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
                  SizedBox(width: contentGap),
                  Expanded(
                    child:
                        widget.treeCellBuilder?.call(context, node, state) ??
                        CarpenterTableText.cell(
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
            for (final column in dataColumns)
              _TreeTableSlot(
                width: layout.widths[column.id]!,
                alignment: column.alignment,
                verticalAlignment: column.verticalAlignment,
                child: column.cellBuilder(context, node),
              ),
            SizedBox(width: layout.actionWidth),
          ],
        ),
        if (actionColumns.isNotEmpty)
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: layout.trailingCompensation(horizontalOffset),
            width: layout.actionWidth,
            child: ColoredBox(
              color: background,
              child: Row(
                children: [
                  for (final column in actionColumns)
                    _TreeTableSlot(
                      width: layout.widths[column.id]!,
                      alignment: column.alignment,
                      verticalAlignment: column.verticalAlignment,
                      child: column.cellBuilder(context, node),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
    final actions = _contextActions(node, actionColumns);
    if (actions.isNotEmpty) {
      row = CarpenterContextActionRegion(
        actions: actions,
        semanticLabel: 'Actions for ${node.effectiveSemanticLabel}',
        child: row,
      );
    }
    return state.cut ? Opacity(opacity: .55, child: row) : row;
  }
}

final class _TreeTableLayout {
  const _TreeTableLayout({
    required this.widths,
    required this.minimums,
    required this.maximums,
    required this.actionWidth,
    required this.viewportWidth,
    required this.totalWidth,
  });

  final Map<String, double> widths;
  final Map<String, double> minimums;
  final Map<String, double> maximums;
  final double actionWidth;
  final double viewportWidth;
  final double totalWidth;

  double trailingCompensation(double offset) {
    if (!viewportWidth.isFinite) return 0;
    final maximum = math.max(0.0, totalWidth - viewportWidth);
    return (maximum - offset).clamp(0.0, maximum).toDouble();
  }
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
  Widget build(BuildContext context) => CarpenterTableHeaderCellChrome(
    id: id,
    width: width,
    minimumWidth: minimumWidth,
    maximumWidth: maximumWidth,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    resizable: resizable,
    resizeHandleKey: ValueKey('tree-table-resize-$id'),
    onWidthChanged: onWidthChanged,
    child: CarpenterTableText.header(label, semanticsLabel: semanticLabel),
  );
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
  Widget build(BuildContext context) => CarpenterTableCellChrome(
    width: width,
    alignment: alignment,
    verticalAlignment: verticalAlignment,
    child: child,
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
