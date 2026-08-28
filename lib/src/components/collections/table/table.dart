import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/interactive_region.dart';
import '../../basic/button/button.dart';
import '../../basic/checkbox.dart';
import '../../basic/status_indicator.dart';
import '../contracts/collection_load_phase.dart';
import '../contracts/collection_query.dart';
import '../contracts/collection_snapshot.dart';
import '../contracts/selection_state.dart';
import 'table_column.dart';
import 'table_state.dart';

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
  }

  @override
  void dispose() {
    for (final node in _rowFocusNodes.values) {
      node.dispose();
    }
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

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final borderWidth = context.units(theme.shapes.tableBorderWidth);
    final radius = context.units(theme.shapes.tableSurfaceRadius);
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = _resolveColumnLayout(context, constraints.maxWidth);
        final tableWidth = layout.totalWidth;
        final headerHeight = widget.stickyHeader
            ? MediaQuery.textScalerOf(
                context,
              ).scale(context.units(theme.sizes.tableHeaderHeight))
            : 0.0;
        final availableBodyHeight = constraints.maxHeight.isFinite
            ? math.max(0.0, constraints.maxHeight - headerHeight)
            : null;
        final body = _buildBody(
          context,
          layout,
          availableHeight: availableBodyHeight,
        );
        final header = _buildHeader(context, layout);
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
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: tableWidth,
                  child: widget.stickyHeader
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [header, body],
                        )
                      : body,
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
    double viewportWidth,
  ) {
    final theme = CarpenterTheme.of(context);
    final selectionWidth =
        widget.showSelectionColumn && widget.selection.isEnabled
        ? context.units(theme.sizes.tableSelectionColumn)
        : 0.0;
    final widths = <String, double>{};
    final minimums = <String, double>{};
    final maximums = <String, double>{};
    var preferredTotal = selectionWidth;
    var totalFlex = 0;
    for (final column in widget.columns) {
      final minimum = context.units(
        column.width.minimum ?? theme.sizes.tableColumnMin,
      );
      final maximum = context.units(
        column.width.maximum ?? theme.sizes.tableColumnMax,
      );
      final preferred = context
          .units(
            widget.columnWidths[column.id] ??
                column.width.preferred ??
                theme.sizes.tableColumn,
          )
          .clamp(minimum, maximum);
      widths[column.id] = preferred;
      minimums[column.id] = minimum;
      maximums[column.id] = maximum;
      preferredTotal += preferred;
      if (column.width.policy == CarpenterTableColumnWidthPolicy.flexible) {
        totalFlex += column.width.flex;
      }
    }
    if (viewportWidth.isFinite &&
        preferredTotal < viewportWidth &&
        totalFlex > 0) {
      final available = viewportWidth - preferredTotal;
      for (final column in widget.columns) {
        if (column.width.policy != CarpenterTableColumnWidthPolicy.flexible) {
          continue;
        }
        final share = available * column.width.flex / totalFlex;
        widths[column.id] = (widths[column.id]! + share).clamp(
          minimums[column.id]!,
          maximums[column.id]!,
        );
      }
    }
    final totalWidth =
        selectionWidth + widths.values.fold(0.0, (a, b) => a + b);
    return _TableColumnLayout(
      widths: widths,
      minimums: minimums,
      maximums: maximums,
      selectionWidth: selectionWidth,
      totalWidth: math.max(
        totalWidth,
        viewportWidth.isFinite ? viewportWidth : totalWidth,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, _TableColumnLayout layout) {
    final theme = CarpenterTheme.of(context);
    final height = MediaQuery.textScalerOf(
      context,
    ).scale(context.units(theme.sizes.tableHeaderHeight));
    final loadedKeys = widget.snapshot.items.map(widget.rowKey).toList();
    final selectedCount = loadedKeys.where(widget.selection.contains).length;
    final checkboxValue = selectedCount == 0
        ? CheckboxValue.unchecked
        : selectedCount == loadedKeys.length
        ? CheckboxValue.checked
        : CheckboxValue.mixed;
    return Container(
      height: height,
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
          for (final column in widget.columns)
            _HeaderCell<T>(
              column: column,
              width: layout.widths[column.id]!,
              minimumWidth: layout.minimums[column.id]!,
              maximumWidth: layout.maximums[column.id]!,
              sorting: widget.sorting,
              onSortingChanged: widget.onSortingChanged,
              multiSort: widget.multiSort,
              resizeHandleWidth: context.units(theme.sizes.tableResizeHandle),
              horizontalPadding: context.units(theme.spacing.tableHorizontal),
              onWidthChanged: widget.onColumnWidthChanged,
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    _TableColumnLayout layout, {
    required double? availableHeight,
  }) {
    final theme = CarpenterTheme.of(context);
    final rowHeight = MediaQuery.textScalerOf(
      context,
    ).scale(context.units(theme.sizes.tableRowHeight));
    final maxHeight = MediaQuery.textScalerOf(
      context,
    ).scale(context.units(theme.sizes.tableBodyMaxHeight));
    final stateHeight = MediaQuery.textScalerOf(
      context,
    ).scale(context.units(theme.sizes.tableStateHeight));
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
            if (contentIndex == 0) return _buildHeader(context, layout);
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
            return _buildRow(context, layout, contentIndex, rowHeight);
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

  Widget _buildRow(
    BuildContext context,
    _TableColumnLayout layout,
    int index,
    double height,
  ) {
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
      columns: widget.columns,
      widths: layout.widths,
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
    required this.totalWidth,
  });
  final Map<String, double> widths;
  final Map<String, double> minimums;
  final Map<String, double> maximums;
  final double selectionWidth;
  final double totalWidth;
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
    required this.resizeHandleWidth,
    required this.horizontalPadding,
    required this.onWidthChanged,
  });

  final CarpenterTableColumn<T> column;
  final double width;
  final double minimumWidth;
  final double maximumWidth;
  final List<CollectionSort> sorting;
  final ValueChanged<List<CollectionSort>>? onSortingChanged;
  final bool multiSort;
  final double resizeHandleWidth;
  final double horizontalPadding;
  final CarpenterTableColumnWidthChanged? onWidthChanged;

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
    final theme = CarpenterTheme.of(context);
    final sort = sorting
        .where((candidate) => candidate.id == column.id)
        .firstOrNull;
    final suffix = switch (sort?.direction) {
      CollectionSortDirection.ascending => ' ↑',
      CollectionSortDirection.descending => ' ↓',
      null => '',
    };
    return SizedBox(
      width: width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveRegion(
            onActivate: column.sortable && onSortingChanged != null
                ? _toggleSort
                : null,
            builder: (context, states, showFocusHighlight) => DecoratedBox(
              decoration: BoxDecoration(
                color: states.contains(WidgetState.hovered)
                    ? theme.overlay.hovered
                    : theme.surface.subtle,
                border: showFocusHighlight
                    ? Border.all(
                        color: theme.focus.color,
                        width: context.units(theme.focus.width),
                      )
                    : null,
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: horizontalPadding,
                ),
                child: Align(
                  alignment: _alignment(column.alignment),
                  child: Text(
                    '${column.header}$suffix',
                    semanticsLabel: column.semanticLabel ?? column.header,
                    style: theme.typography
                        .tableHeader(context, TypographyEmphasis.strong)
                        .copyWith(color: theme.content.primary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          if (column.resizable && onWidthChanged != null)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: _ResizeHandle(
                key: ValueKey('table-resize-${column.id}'),
                width: resizeHandleWidth,
                currentWidth: width,
                minimumWidth: minimumWidth,
                maximumWidth: maximumWidth,
                onChanged: (value) => onWidthChanged!(
                  column.id,
                  Rem(value / context.units(1.rem)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

final class _ResizeHandle extends StatefulWidget {
  const _ResizeHandle({
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
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

final class _ResizeHandleState extends State<_ResizeHandle> {
  late double _dragWidth;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragWidth = widget.currentWidth,
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
      child: SizedBox(width: widget.width, height: double.infinity),
    ),
  );
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
    required this.columns,
    required this.widths,
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
  final List<CarpenterTableColumn<T>> columns;
  final Map<String, double> widths;
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
    final background = widget.selected
        ? theme.overlay.selected
        : _hovered
        ? theme.overlay.hovered
        : theme.overlay.background;
    final focusWidth = context.units(theme.focus.width);
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
            child: Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: background,
                border: Border(
                  bottom: BorderSide(
                    color: theme.overlay.border,
                    width: context.units(theme.shapes.tableBorderWidth),
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
                  for (final column in widget.columns)
                    SizedBox(
                      width: widget.widths[column.id],
                      child: Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: context.units(
                            theme.spacing.tableHorizontal,
                          ),
                          vertical: context.units(theme.spacing.tableVertical),
                        ),
                        child: Align(
                          alignment: _alignment(column.alignment),
                          child: column.cellBuilder(context, widget.item),
                        ),
                      ),
                    ),
                ],
              ),
            ),
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
    final theme = CarpenterTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.units(theme.spacing.tableHorizontal)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterStatusIndicator(label: message, role: role),
            if (action != null) ...[
              SizedBox(height: context.units(theme.spacing.tableStateGap)),
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
    final theme = CarpenterTheme.of(context);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: context.units(theme.spacing.tableHorizontal),
        ),
        child: CarpenterStatusIndicator(label: message, role: role),
      ),
    );
  }
}

AlignmentDirectional _alignment(CarpenterTableColumnAlignment alignment) =>
    switch (alignment) {
      CarpenterTableColumnAlignment.start => AlignmentDirectional.centerStart,
      CarpenterTableColumnAlignment.center => AlignmentDirectional.center,
      CarpenterTableColumnAlignment.end => AlignmentDirectional.centerEnd,
    };
