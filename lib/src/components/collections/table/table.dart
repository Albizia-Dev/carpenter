import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/layout/grid_layout.dart';
import '../../basic/button/button.dart';
import '../../basic/checkbox.dart';
import '../../basic/status_indicator.dart';
import '../../behaviour/context_actions.dart';
import '../contracts/collection_load_phase.dart';
import '../contracts/collection_query.dart';
import '../contracts/collection_snapshot.dart';
import '../contracts/selection_state.dart';
import '../table_metrics.dart';
import 'table_actions.dart';
import 'table_cell.dart';
import 'table_column.dart';
import 'table_state.dart';
import 'table_text.dart';

typedef CarpenterTableColumnWidthChanged =
    void Function(String columnId, LengthUnit width);

final class CarpenterTable<T, K> extends StatefulWidget {
  const CarpenterTable({
    super.key,
    required this.snapshot,
    required this.rowKey,
    required this.rowSemanticLabel,
    required this.columns,
    required this.selection,
    this.onSelectionChanged,
    this.sorting = const [],
    this.onSortingChanged,
    this.multiSort = false,
    this.showSelectionColumn = true,
    this.columnWidths = const {},
    this.onColumnWidthChanged,
    this.onLoadMore,
    this.retryAction,
    this.messages = const CarpenterTableMessages(),
    this.stickyHeader = true,
    this.semanticLabel = 'Data table',
  }) : assert(columns.length > 0);

  final CollectionSnapshot<T> snapshot;
  final K Function(T item) rowKey;
  final String Function(T item) rowSemanticLabel;
  final List<CarpenterTableColumn<T>> columns;
  final CollectionSelection<K> selection;
  final ValueChanged<CollectionSelection<K>>? onSelectionChanged;
  final List<CollectionSort> sorting;
  final ValueChanged<List<CollectionSort>>? onSortingChanged;
  final bool multiSort;
  final bool showSelectionColumn;
  final Map<String, LengthUnit> columnWidths;
  final CarpenterTableColumnWidthChanged? onColumnWidthChanged;
  final VoidCallback? onLoadMore;
  final CarpenterActionDescriptor? retryAction;
  final CarpenterTableMessages messages;
  final bool stickyHeader;
  final String semanticLabel;

  @override
  State<CarpenterTable<T, K>> createState() => _CarpenterTableState<T, K>();
}

final class _CarpenterTableState<T, K> extends State<CarpenterTable<T, K>> {
  final Map<K, FocusNode> _rowFocusNodes = {};
  final Map<String, LengthUnit> _localColumnWidths = {};
  final ScrollController _horizontalScrollController = ScrollController();

  List<CarpenterTableColumn<T>> get _dataColumns => widget.columns
      .where(
        (column) =>
            column.effectiveWidth.policy !=
            CarpenterTableColumnWidthPolicy.actionLane,
      )
      .toList(growable: false);

  List<CarpenterTableColumn<T>> get _actionColumns => widget.columns
      .where(
        (column) =>
            column.effectiveWidth.policy ==
            CarpenterTableColumnWidthPolicy.actionLane,
      )
      .toList(growable: false);

  @override
  void didUpdateWidget(CarpenterTable<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentKeys = widget.snapshot.items.map(widget.rowKey).toSet();
    final staleKeys = _rowFocusNodes.keys
        .where((key) => !currentKeys.contains(key))
        .toList(growable: false);
    for (final key in staleKeys) {
      _rowFocusNodes.remove(key)?.dispose();
    }

    final columnIds = widget.columns.map((column) => column.id).toSet();
    _localColumnWidths.removeWhere((id, _) => !columnIds.contains(id));
    for (final entry in widget.columnWidths.entries) {
      if (oldWidget.columnWidths[entry.key] != entry.value) {
        _localColumnWidths.remove(entry.key);
      }
    }
  }

  @override
  void dispose() {
    for (final node in _rowFocusNodes.values) {
      node.dispose();
    }
    _horizontalScrollController.dispose();
    super.dispose();
  }

  void _moveFocus(int currentIndex, int targetIndex) {
    if (widget.snapshot.items.isEmpty) return;
    final bounded = targetIndex.clamp(0, widget.snapshot.items.length - 1);
    final key = widget.rowKey(widget.snapshot.items[bounded]);
    _rowFocusNodes.putIfAbsent(key, FocusNode.new).requestFocus();
  }

  void _toggleRow(K key) {
    final callback = widget.onSelectionChanged;
    if (callback == null || !widget.selection.isEnabled) return;
    callback(widget.selection.toggle(key));
  }

  void _toggleLoadedSelection() {
    final callback = widget.onSelectionChanged;
    if (callback == null) return;
    final keys = widget.snapshot.items.map(widget.rowKey).toList();
    final allSelected =
        keys.isNotEmpty && keys.every(widget.selection.contains);
    callback(
      allSelected
          ? widget.selection.unselectLoaded(keys)
          : widget.selection.selectLoaded(keys),
    );
  }

  void _resizeColumn(String id, LengthUnit width) {
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
    final borderWidth = metrics.borderWidth;
    final radius = metrics.surfaceRadius;
    return LayoutBuilder(
      builder: (context, constraints) {
        final dataColumns = _dataColumns;
        final actionColumns = _actionColumns;
        final layout = _resolveColumnLayout(
          context,
          constraints.maxWidth,
          dataColumns: dataColumns,
          actionColumns: actionColumns,
        );
        final headerHeight = widget.stickyHeader ? metrics.headerHeight : 0.0;
        final availableBodyHeight = constraints.maxHeight.isFinite
            ? math.max(0.0, constraints.maxHeight - headerHeight)
            : null;
        return Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel,
          child: DecoratedBox(
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
              child: SingleChildScrollView(
                controller: _horizontalScrollController,
                scrollDirection: Axis.horizontal,
                child: AnimatedBuilder(
                  animation: _horizontalScrollController,
                  builder: (context, _) {
                    final body = _buildBody(
                      context,
                      layout,
                      dataColumns: dataColumns,
                      actionColumns: actionColumns,
                      availableHeight: availableBodyHeight,
                      horizontalOffset: _horizontalOffset,
                    );
                    final header = _buildHeader(
                      context,
                      layout,
                      dataColumns: dataColumns,
                      actionColumns: actionColumns,
                      horizontalOffset: _horizontalOffset,
                    );
                    return SizedBox(
                      width: layout.totalWidth,
                      child: widget.stickyHeader
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [header, body],
                            )
                          : body,
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _TableColumnLayout _resolveColumnLayout(
    BuildContext context,
    double viewportWidth, {
    required List<CarpenterTableColumn<T>> dataColumns,
    required List<CarpenterTableColumn<T>> actionColumns,
  }) {
    final metrics = CarpenterTableMetrics.resolve(context);
    final selectionWidth =
        widget.showSelectionColumn && widget.selection.isEnabled
        ? metrics.selectionColumnWidth
        : 0.0;
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
      final explicitWidth =
          _localColumnWidths[column.id] ??
          widget.columnWidths[column.id] ??
          width.preferred;
      final preferred = explicitWidth == null
          ? CarpenterTableActionCell.preferredColumnWidth(context)
          : context.units(explicitWidth);
      final resolved = preferred.clamp(minimum, maximum).toDouble();
      widths[column.id] = resolved;
      minimums[column.id] = minimum;
      maximums[column.id] = maximum;
      actionWidth += resolved;
    }

    final dataViewportWidth = viewportWidth.isFinite
        ? math.max(0.0, viewportWidth - actionWidth)
        : viewportWidth;
    final specs = <GridColumnSpec>[];
    for (final column in dataColumns) {
      final width = column.effectiveWidth;
      final minimum = width.minimum == null
          ? metrics.minimumColumnWidth
          : context.units(width.minimum!);
      final maximum = width.maximum == null
          ? metrics.maximumColumnWidth
          : context.units(width.maximum!);
      final pinned =
          _localColumnWidths.containsKey(column.id) ||
          widget.columnWidths.containsKey(column.id);
      final explicitWidth =
          _localColumnWidths[column.id] ??
          widget.columnWidths[column.id] ??
          width.preferred;
      final preferred = explicitWidth == null
          ? metrics.defaultColumnWidth
          : context.units(explicitWidth);
      specs.add(
        GridColumnSpec(
          id: column.id,
          preferred: preferred,
          minimum: minimum,
          maximum: maximum,
          flex: width.flex,
          flexible: width.isFlexible,
          pinned: pinned,
        ),
      );
    }
    final resolved = GridLayoutResolver.resolve(
      columns: specs,
      viewportWidth: dataViewportWidth,
      fixedExtent: selectionWidth,
    );
    widths.addAll(resolved.widths);
    minimums.addAll(resolved.minimums);
    maximums.addAll(resolved.maximums);
    final naturalWidth = resolved.totalWidth + actionWidth;
    final totalWidth = viewportWidth.isFinite
        ? math.max(viewportWidth, naturalWidth)
        : naturalWidth;
    return _TableColumnLayout(
      widths: widths,
      minimums: minimums,
      maximums: maximums,
      selectionWidth: selectionWidth,
      actionWidth: actionWidth,
      viewportWidth: viewportWidth,
      totalWidth: totalWidth,
    );
  }

  Widget _buildHeader(
    BuildContext context,
    _TableColumnLayout layout, {
    required List<CarpenterTableColumn<T>> dataColumns,
    required List<CarpenterTableColumn<T>> actionColumns,
    required double horizontalOffset,
  }) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final height = metrics.headerHeight;
    final loadedKeys = widget.snapshot.items.map(widget.rowKey).toList();
    final selectedCount = loadedKeys.where(widget.selection.contains).length;
    final checkboxValue = selectedCount == 0
        ? CheckboxValue.unchecked
        : selectedCount == loadedKeys.length
        ? CheckboxValue.checked
        : CheckboxValue.mixed;
    return SizedBox(
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: theme.surface.subtle,
              child: Row(
                children: [
                  if (layout.selectionWidth > 0)
                    SizedBox(
                      width: layout.selectionWidth,
                      child: Center(
                        child: CarpenterCheckbox(
                          value: checkboxValue,
                          label: '',
                          semanticLabel: checkboxValue == CheckboxValue.checked
                              ? widget.messages.clearLoadedSelection
                              : widget.messages.selectAllLoaded,
                          size: ControlSize.small,
                          onChanged: widget.onSelectionChanged == null
                              ? null
                              : (_) => _toggleLoadedSelection(),
                        ),
                      ),
                    ),
                  for (final column in dataColumns)
                    _HeaderCell<T>(
                      column: column,
                      width: layout.widths[column.id]!,
                      minimumWidth: layout.minimums[column.id]!,
                      maximumWidth: layout.maximums[column.id]!,
                      sorting: widget.sorting,
                      onSortingChanged: widget.onSortingChanged,
                      multiSort: widget.multiSort,
                      onWidthChanged: _resizeColumn,
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
                      _HeaderCell<T>(
                        column: column,
                        width: layout.widths[column.id]!,
                        minimumWidth: layout.minimums[column.id]!,
                        maximumWidth: layout.maximums[column.id]!,
                        sorting: widget.sorting,
                        onSortingChanged: widget.onSortingChanged,
                        multiSort: widget.multiSort,
                        onWidthChanged: _resizeColumn,
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    _TableColumnLayout layout, {
    required List<CarpenterTableColumn<T>> dataColumns,
    required List<CarpenterTableColumn<T>> actionColumns,
    required double? availableHeight,
    required double horizontalOffset,
  }) {
    final metrics = CarpenterTableMetrics.resolve(context);
    final rowHeight = metrics.rowHeight;
    final maxHeight = metrics.bodyMaxHeight;
    final stateHeight = metrics.stateHeight;
    final state = _exclusiveState(context);
    final banner = _banner(context);
    final footer = _footer(context);
    final bannerCount = banner == null ? 0 : 1;
    final footerCount = footer == null ? 0 : 1;
    final headerCount = widget.stickyHeader ? 0 : 1;
    final contentRows =
        widget.snapshot.items.length + bannerCount + footerCount;
    final desiredBodyHeight = state == null
        ? math.min(maxHeight, math.max(rowHeight, contentRows * rowHeight))
        : math.min(maxHeight, stateHeight);
    final bodyHeight = availableHeight == null
        ? desiredBodyHeight
        : math.min(desiredBodyHeight, availableHeight);
    final itemCount = headerCount + (state == null ? contentRows : 1);
    return SizedBox(
      height: bodyHeight + (widget.stickyHeader ? 0 : rowHeight),
      child: ListView.builder(
        itemCount: itemCount,
        itemBuilder: (context, index) {
          var contentIndex = index;
          if (!widget.stickyHeader) {
            if (contentIndex == 0) {
              return _buildHeader(
                context,
                layout,
                dataColumns: dataColumns,
                actionColumns: actionColumns,
                horizontalOffset: horizontalOffset,
              );
            }
            contentIndex -= 1;
          }
          if (state != null) {
            return SizedBox(height: stateHeight, child: state);
          }
          if (banner != null) {
            if (contentIndex == 0) {
              return SizedBox(height: rowHeight, child: banner);
            }
            contentIndex -= 1;
          }
          if (contentIndex < widget.snapshot.items.length) {
            return _buildRow(
              context,
              layout,
              contentIndex,
              rowHeight,
              dataColumns: dataColumns,
              actionColumns: actionColumns,
              horizontalOffset: horizontalOffset,
            );
          }
          return SizedBox(height: rowHeight, child: footer);
        },
      ),
    );
  }

  Widget? _exclusiveState(BuildContext context) {
    final snapshot = widget.snapshot;
    if (snapshot.isInitialLoading) {
      return _StatePanel(message: widget.messages.initialLoading);
    }
    if (snapshot.initialFailure != null) {
      return _StatePanel(
        message:
            snapshot.initialFailure!.message ?? widget.messages.initialError,
        role: FeedbackColorRole.danger,
        action: widget.retryAction,
      );
    }
    if (snapshot.contentState == CollectionContentState.zero) {
      return _StatePanel(message: widget.messages.zero);
    }
    if (snapshot.contentState == CollectionContentState.emptyResult) {
      return _StatePanel(message: widget.messages.emptyResult);
    }
    return null;
  }

  Widget? _banner(BuildContext context) {
    final snapshot = widget.snapshot;
    if (snapshot.refreshFailure != null) {
      return _TableBanner(
        message:
            snapshot.refreshFailure!.message ?? widget.messages.refreshError,
        role: FeedbackColorRole.danger,
      );
    }
    if (snapshot.isRefreshing) {
      return _TableBanner(
        message: widget.messages.refreshing,
        role: FeedbackColorRole.info,
      );
    }
    return null;
  }

  Widget? _footer(BuildContext context) {
    final snapshot = widget.snapshot;
    if (snapshot.isLoadingMore) {
      return _TableBanner(
        message: widget.messages.loadingMore,
        role: FeedbackColorRole.info,
      );
    }
    if (!snapshot.pageInfo.hasNext || widget.onLoadMore == null) return null;
    return Align(
      alignment: AlignmentDirectional.center,
      child: CarpenterButton(
        label: widget.messages.loadMore,
        onInvoke: widget.onLoadMore,
        prominence: ActionProminence.ghost,
        size: ControlSize.small,
      ),
    );
  }

  List<CarpenterActionDescriptor> _contextActions(
    T item,
    List<CarpenterTableColumn<T>> actionColumns,
  ) {
    final primary = <CarpenterActionDescriptor>[];
    final secondary = <CarpenterActionDescriptor>[];
    for (final column in actionColumns) {
      final actions = column.actionsBuilder?.call(item);
      if (actions == null) continue;
      primary.addAll(actions.primary);
      secondary.addAll(actions.secondary);
    }
    return [...primary, ...secondary];
  }

  Widget _buildRow(
    BuildContext context,
    _TableColumnLayout layout,
    int index,
    double height, {
    required List<CarpenterTableColumn<T>> dataColumns,
    required List<CarpenterTableColumn<T>> actionColumns,
    required double horizontalOffset,
  }) {
    final item = widget.snapshot.items[index];
    final key = widget.rowKey(item);
    final node = _rowFocusNodes.putIfAbsent(key, FocusNode.new);
    return _TableRow<T, K>(
      key: ValueKey<K>(key),
      item: item,
      rowKey: key,
      semanticLabel: widget.rowSemanticLabel(item),
      selected: widget.selection.contains(key),
      selectionEnabled:
          widget.selection.isEnabled && widget.onSelectionChanged != null,
      showSelection: layout.selectionWidth > 0,
      selectionWidth: layout.selectionWidth,
      dataColumns: dataColumns,
      actionColumns: actionColumns,
      widths: layout.widths,
      actionWidth: layout.actionWidth,
      trailingCompensation: layout.trailingCompensation(horizontalOffset),
      contextActions: _contextActions(item, actionColumns),
      height: height,
      focusNode: node,
      onToggle: () => _toggleRow(key),
      onPrevious: () => _moveFocus(index, index - 1),
      onNext: () => _moveFocus(index, index + 1),
      onFirst: () => _moveFocus(index, 0),
      onLast: () => _moveFocus(index, widget.snapshot.items.length - 1),
    );
  }
}

final class _TableColumnLayout {
  const _TableColumnLayout({
    required this.widths,
    required this.minimums,
    required this.maximums,
    required this.selectionWidth,
    required this.actionWidth,
    required this.viewportWidth,
    required this.totalWidth,
  });

  final Map<String, double> widths;
  final Map<String, double> minimums;
  final Map<String, double> maximums;
  final double selectionWidth;
  final double actionWidth;
  final double viewportWidth;
  final double totalWidth;

  double trailingCompensation(double offset) {
    if (!viewportWidth.isFinite) return 0;
    final maximum = math.max(0.0, totalWidth - viewportWidth);
    return (maximum - offset).clamp(0.0, maximum).toDouble();
  }
}

final class _HeaderCell<T> extends StatelessWidget {
  const _HeaderCell({
    required this.column,
    required this.width,
    required this.minimumWidth,
    required this.maximumWidth,
    required this.sorting,
    required this.onSortingChanged,
    required this.multiSort,
    required this.onWidthChanged,
  });

  final CarpenterTableColumn<T> column;
  final double width;
  final double minimumWidth;
  final double maximumWidth;
  final List<CollectionSort> sorting;
  final ValueChanged<List<CollectionSort>>? onSortingChanged;
  final bool multiSort;
  final CarpenterTableColumnWidthChanged onWidthChanged;

  void _toggleSort() {
    final callback = onSortingChanged;
    if (callback == null || !column.sortable) return;
    final existingIndex = sorting.indexWhere((sort) => sort.id == column.id);
    final next = multiSort ? [...sorting] : <CollectionSort>[];
    if (existingIndex < 0) {
      next.add(
        CollectionSort(
          id: column.id,
          direction: CollectionSortDirection.ascending,
        ),
      );
    } else {
      final existing = sorting[existingIndex];
      if (existing.direction == CollectionSortDirection.ascending) {
        final descending = CollectionSort(
          id: column.id,
          direction: CollectionSortDirection.descending,
        );
        if (multiSort) {
          next[existingIndex] = descending;
        } else {
          next.add(descending);
        }
      } else if (multiSort) {
        next.removeAt(existingIndex);
      }
    }
    callback(List.unmodifiable(next));
  }

  @override
  Widget build(BuildContext context) {
    final sort = sorting
        .where((candidate) => candidate.id == column.id)
        .firstOrNull;
    final suffix = switch (sort?.direction) {
      CollectionSortDirection.ascending => ' ↑',
      CollectionSortDirection.descending => ' ↓',
      null => '',
    };
    return CarpenterTableHeaderCellChrome(
      id: column.id,
      width: width,
      minimumWidth: minimumWidth,
      maximumWidth: maximumWidth,
      alignment: column.alignment,
      verticalAlignment: column.verticalAlignment,
      resizable: column.resizable,
      hoverFeedback: true,
      resizeHandleKey: ValueKey('table-resize-${column.id}'),
      onActivate: column.sortable && onSortingChanged != null
          ? _toggleSort
          : null,
      onWidthChanged: (value) =>
          onWidthChanged(column.id, Rem(value / context.units(1.rem))),
      child: CarpenterTableText.header(
        '${column.header}$suffix',
        semanticsLabel: column.semanticLabel ?? column.header,
      ),
    );
  }
}

final class _TableRow<T, K> extends StatefulWidget {
  const _TableRow({
    super.key,
    required this.item,
    required this.rowKey,
    required this.semanticLabel,
    required this.selected,
    required this.selectionEnabled,
    required this.showSelection,
    required this.selectionWidth,
    required this.dataColumns,
    required this.actionColumns,
    required this.widths,
    required this.actionWidth,
    required this.trailingCompensation,
    required this.contextActions,
    required this.height,
    required this.focusNode,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
    required this.onFirst,
    required this.onLast,
  });

  final T item;
  final K rowKey;
  final String semanticLabel;
  final bool selected;
  final bool selectionEnabled;
  final bool showSelection;
  final double selectionWidth;
  final List<CarpenterTableColumn<T>> dataColumns;
  final List<CarpenterTableColumn<T>> actionColumns;
  final Map<String, double> widths;
  final double actionWidth;
  final double trailingCompensation;
  final List<CarpenterActionDescriptor> contextActions;
  final double height;
  final FocusNode focusNode;
  final VoidCallback onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFirst;
  final VoidCallback onLast;

  @override
  State<_TableRow<T, K>> createState() => _TableRowState<T, K>();
}

final class _TableRowState<T, K> extends State<_TableRow<T, K>> {
  bool _hovered = false;
  bool _focused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onPrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onNext();
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      widget.onFirst();
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      widget.onLast();
    } else if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) &&
        widget.selectionEnabled) {
      widget.onToggle();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final background = widget.selected
        ? theme.overlay.selected
        : _hovered
        ? theme.overlay.hovered
        : theme.overlay.background;
    final focusWidth = context.units(theme.focus.width);
    Widget row = Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: background,
        border: Border(
          bottom: BorderSide(
            color: theme.overlay.border,
            width: metrics.borderWidth,
          ),
        ),
      ),
      foregroundDecoration: _focused
          ? BoxDecoration(
              border: Border.all(
                color: theme.focus.color,
                width: focusWidth,
              ),
            )
          : null,
      child: Stack(
        children: [
          Positioned.fill(
            child: Row(
              children: [
                if (widget.showSelection)
                  SizedBox(
                    width: widget.selectionWidth,
                    child: Center(
                      child: CarpenterCheckbox(
                        value: widget.selected
                            ? CheckboxValue.checked
                            : CheckboxValue.unchecked,
                        label: '',
                        semanticLabel: widget.semanticLabel,
                        size: ControlSize.small,
                        onChanged: widget.selectionEnabled
                            ? (_) => widget.onToggle()
                            : null,
                      ),
                    ),
                  ),
                for (final column in widget.dataColumns)
                  CarpenterTableCellChrome(
                    width: widget.widths[column.id]!,
                    alignment: column.alignment,
                    verticalAlignment: column.verticalAlignment,
                    child: column.cellBuilder(context, widget.item),
                  ),
                SizedBox(width: widget.actionWidth),
              ],
            ),
          ),
          if (widget.actionColumns.isNotEmpty)
            PositionedDirectional(
              top: 0,
              bottom: 0,
              end: widget.trailingCompensation,
              width: widget.actionWidth,
              child: ColoredBox(
                color: background,
                child: Row(
                  children: [
                    for (final column in widget.actionColumns)
                      CarpenterTableCellChrome(
                        width: widget.widths[column.id]!,
                        alignment: column.alignment,
                        verticalAlignment: column.verticalAlignment,
                        child: column.cellBuilder(context, widget.item),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
    if (widget.contextActions.isNotEmpty) {
      row = CarpenterContextActionRegion(
        actions: widget.contextActions,
        semanticLabel: 'Actions for ${widget.semanticLabel}',
        onOpen: (_) => widget.focusNode.requestFocus(),
        child: row,
      );
    }
    return Semantics(
      container: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.selectionEnabled ? widget.onToggle : null,
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _handleKey,
        child: MouseRegion(
          cursor: widget.selectionEnabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.selectionEnabled
                ? () {
                    widget.focusNode.requestFocus();
                    widget.onToggle();
                  }
                : null,
            child: row,
          ),
        ),
      ),
    );
  }
}

final class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.message,
    this.role = FeedbackColorRole.neutral,
    this.action,
  });
  final String message;
  final FeedbackColorRole role;
  final CarpenterActionDescriptor? action;

  @override
  Widget build(BuildContext context) {
    final metrics = CarpenterTableMetrics.resolve(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(metrics.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterStatusIndicator(label: message, role: role),
            if (action != null) ...[
              SizedBox(height: metrics.stateGap),
              CarpenterButton.fromAction(action!),
            ],
          ],
        ),
      ),
    );
  }
}

final class _TableBanner extends StatelessWidget {
  const _TableBanner({required this.message, required this.role});
  final String message;
  final FeedbackColorRole role;

  @override
  Widget build(BuildContext context) {
    final metrics = CarpenterTableMetrics.resolve(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: metrics.horizontalPadding,
        ),
        child: CarpenterStatusIndicator(label: message, role: role),
      ),
    );
  }
}
