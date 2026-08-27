import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

enum _TableScenario {
  loaded,
  initialLoading,
  refreshing,
  initialError,
  refreshError,
  zero,
  emptyResult,
  loadingMore,
}

enum _TablePagination { cursor, keyset, progressive, unknownTotal }

final tableComponent = WidgetbookComponent(
  name: 'Table',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Edge cases', builder: _edgeCases),
  ],
);

Widget _playground(BuildContext context) {
  final rowCount = context.knobs.int.slider(
    label: 'Data · Rows',
    initialValue: 12,
    min: 0,
    max: 100,
  );
  final scenario = context.knobs.object.dropdown(
    label: 'Snapshot · Scenario',
    options: _TableScenario.values,
    labelBuilder: semanticValueLabel,
  );
  final pagination = context.knobs.object.segmented(
    label: 'Pagination · Contract',
    options: _TablePagination.values,
    labelBuilder: semanticValueLabel,
  );
  final selectionMode = context.knobs.object.segmented(
    label: 'Selection · Mode',
    options: CollectionSelectionMode.values,
    initialOption: CollectionSelectionMode.multiple,
    labelBuilder: semanticValueLabel,
  );
  final resizable = context.knobs.boolean(
    label: 'Columns · Resizable',
    initialValue: true,
  );
  final narrow = context.knobs.boolean(label: 'Viewport · Narrow');
  final longText = context.knobs.boolean(label: 'Content · Long text');
  final manyColumns = context.knobs.boolean(label: 'Columns · Many columns');

  return preview(
    SizedBox(
      width: narrow ? 320 : 900,
      child: _TablePreview(
        rowCount: rowCount,
        scenario: scenario,
        pagination: pagination,
        selectionMode: selectionMode,
        resizable: resizable,
        longText: longText,
        manyColumns: manyColumns,
      ),
    ),
  );
}

Widget _edgeCases(BuildContext context) => preview(
  const SizedBox(
    width: 320,
    child: _TablePreview(
      rowCount: 20,
      scenario: _TableScenario.refreshError,
      pagination: _TablePagination.unknownTotal,
      selectionMode: CollectionSelectionMode.multiple,
      resizable: true,
      longText: true,
      manyColumns: true,
    ),
  ),
);

final class _TablePreview extends StatefulWidget {
  const _TablePreview({
    required this.rowCount,
    required this.scenario,
    required this.pagination,
    required this.selectionMode,
    required this.resizable,
    required this.longText,
    required this.manyColumns,
  });

  final int rowCount;
  final _TableScenario scenario;
  final _TablePagination pagination;
  final CollectionSelectionMode selectionMode;
  final bool resizable;
  final bool longText;
  final bool manyColumns;

  @override
  State<_TablePreview> createState() => _TablePreviewState();
}

final class _TablePreviewState extends State<_TablePreview> {
  var _sorting = <CollectionSort>[];
  var _selection = CollectionSelection<int>.multiple();
  final _widths = <String, LengthUnit>{};

  @override
  void didUpdateWidget(_TablePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionMode != widget.selectionMode) {
      _selection = _selectionFor(widget.selectionMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selection.mode != widget.selectionMode) {
      _selection = _selectionFor(widget.selectionMode);
    }
    final rows = List.generate(
      widget.rowCount,
      (index) => _ExampleRow(
        id: index + 1,
        name: widget.longText
            ? 'Very long structured record ${index + 1} with contextual text'
            : 'Record ${index + 1}',
        amount: (index + 1) * 1250,
        active: index.isEven,
      ),
    );
    final snapshot = _snapshot(rows, widget.scenario, widget.pagination);
    return CarpenterTable<_ExampleRow, int>(
      semanticLabel: 'Example records',
      snapshot: snapshot,
      rowKey: (row) => row.id,
      rowSemanticLabel: (row) => '${row.name}, ${row.amount}',
      columns: [
        CarpenterTableColumn<_ExampleRow>.text(
          id: 'name',
          header: 'Name',
          value: (row) => row.name,
          sortable: true,
          resizable: widget.resizable,
        ),
        CarpenterTableColumn<_ExampleRow>.number(
          id: 'amount',
          header: 'Amount',
          value: (row) => row.amount,
          formatter: (value) => '${value.toInt()} ₽',
          sortable: true,
          resizable: widget.resizable,
        ),
        CarpenterTableColumn<_ExampleRow>.status(
          id: 'state',
          header: 'State',
          label: (row) => row.active ? 'Active' : 'Paused',
          role: (row) => row.active
              ? FeedbackColorRole.success
              : FeedbackColorRole.warning,
          resizable: widget.resizable,
        ),
        if (widget.manyColumns)
          CarpenterTableColumn<_ExampleRow>.text(
            id: 'identity',
            header: 'Stable identity',
            value: (row) => 'record-${row.id}',
            resizable: widget.resizable,
          ),
        CarpenterTableColumn<_ExampleRow>.actions(
          id: 'actions',
          header: 'Actions',
          actions: (row) => [
            CarpenterActionDescriptor(
              id: 'open-${row.id}',
              label: 'Open',
              onInvoke: () {},
            ),
          ],
          resizable: widget.resizable,
        ),
      ],
      selection: _selection,
      onSelectionChanged: widget.selectionMode == CollectionSelectionMode.none
          ? null
          : (value) => setState(() => _selection = value),
      sorting: _sorting,
      onSortingChanged: (value) => setState(() => _sorting = value),
      multiSort: true,
      columnWidths: _widths,
      onColumnWidthChanged: widget.resizable
          ? (id, width) => setState(() => _widths[id] = width)
          : null,
      onLoadMore: snapshot.pageInfo.hasNext ? () {} : null,
      retryAction: CarpenterActionDescriptor(
        id: 'retry',
        label: 'Retry',
        onInvoke: () {},
      ),
    );
  }
}

CollectionSelection<int> _selectionFor(CollectionSelectionMode mode) =>
    switch (mode) {
      CollectionSelectionMode.none => CollectionSelection<int>.none(),
      CollectionSelectionMode.single => CollectionSelection<int>.single(),
      CollectionSelectionMode.multiple => CollectionSelection<int>.multiple(),
      CollectionSelectionMode.allMatching =>
        CollectionSelection<int>.allMatching(),
    };

CollectionSnapshot<_ExampleRow> _snapshot(
  List<_ExampleRow> rows,
  _TableScenario scenario,
  _TablePagination pagination,
) {
  final pageInfo = switch (pagination) {
    _TablePagination.cursor => CollectionCursorPageInfo(
      itemCount: rows.length,
      nextCursor: 'next',
    ),
    _TablePagination.keyset => CollectionKeysetPageInfo<int>(
      itemCount: rows.length,
      nextKey: rows.isEmpty ? null : rows.last.id,
    ),
    _TablePagination.progressive => CollectionProgressivePageInfo(
      loadedItems: rows.length,
      hasMore: true,
      totalItems: 1000,
    ),
    _TablePagination.unknownTotal => CollectionOffsetPageInfo(
      offset: 0,
      limit: rows.isEmpty ? 1 : rows.length,
      itemCount: rows.length,
      moreAvailable: true,
    ),
  };
  return switch (scenario) {
    _TableScenario.loaded => CollectionSnapshot(
      items: rows,
      pageInfo: pageInfo,
    ),
    _TableScenario.initialLoading => CollectionSnapshot.initialLoading(),
    _TableScenario.refreshing => CollectionSnapshot(
      items: rows,
      loadPhase: CollectionLoadPhase.refreshing,
      freshness: CollectionFreshness.stale,
      pageInfo: pageInfo,
    ),
    _TableScenario.initialError => CollectionSnapshot(
      initialFailure: const CollectionFailure(
        error: 'offline',
        message: 'Initial request failed',
      ),
    ),
    _TableScenario.refreshError => CollectionSnapshot(
      items: rows,
      freshness: CollectionFreshness.stale,
      refreshFailure: const CollectionFailure(
        error: 'offline',
        message: 'Refresh failed; rows remain visible',
      ),
      pageInfo: pageInfo,
    ),
    _TableScenario.zero => CollectionSnapshot(
      contentState: CollectionContentState.zero,
    ),
    _TableScenario.emptyResult => CollectionSnapshot(
      contentState: CollectionContentState.emptyResult,
    ),
    _TableScenario.loadingMore => CollectionSnapshot(
      items: rows,
      loadPhase: CollectionLoadPhase.loadingMore,
      pageInfo: pageInfo,
    ),
  };
}

final class _ExampleRow {
  const _ExampleRow({
    required this.id,
    required this.name,
    required this.amount,
    required this.active,
  });
  final int id;
  final String name;
  final int amount;
  final bool active;
}
