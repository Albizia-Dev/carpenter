import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/collection_fixtures.dart';
import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

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
    options: DemoCollectionScenario.values,
    initialOption: DemoCollectionScenario.loaded,
    labelBuilder: semanticValueLabel,
  );
  final pagination = context.knobs.object.segmented(
    label: 'Pagination · Contract',
    options: DemoPaginationFixture.values,
    initialOption: DemoPaginationFixture.cursor,
    labelBuilder: semanticValueLabel,
  );
  final selectionMode = context.knobs.object.segmented(
    label: 'Selection · Mode',
    options: CollectionSelectionMode.values,
    initialOption: CollectionSelectionMode.multiple,
    labelBuilder: semanticValueLabel,
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
        longText: longText,
        manyColumns: manyColumns,
      ),
    ),
  );
}

Widget _edgeCases(BuildContext context) => preview(
  SizedBox(
    width: context.units(20.rem),
    child: const _TablePreview(
      rowCount: 20,
      scenario: DemoCollectionScenario.refreshError,
      pagination: DemoPaginationFixture.unknownTotal,
      selectionMode: CollectionSelectionMode.multiple,
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
    required this.longText,
    required this.manyColumns,
  });

  final int rowCount;
  final DemoCollectionScenario scenario;
  final DemoPaginationFixture pagination;
  final CollectionSelectionMode selectionMode;
  final bool longText;
  final bool manyColumns;

  @override
  State<_TablePreview> createState() => _TablePreviewState();
}

final class _TablePreviewState extends State<_TablePreview> {
  var _sorting = <CollectionSort>[];
  var _selection = CollectionSelection<int>.multiple();
  final _widths = <String, LengthUnit>{};
  String _lastAction = 'No row action invoked';

  @override
  void didUpdateWidget(_TablePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectionMode != widget.selectionMode) {
      _selection = _selectionFor(widget.selectionMode);
    }
  }

  void _reportAction(String action, _ExampleRow row) {
    setState(() => _lastAction = '$action: ${row.name}');
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
    final snapshot = demoCollectionSnapshot<_ExampleRow>(
      items: rows,
      scenario: widget.scenario,
      pagination: widget.pagination,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterText.caption(
          '$_lastAction · Two primary actions stay inline; extra primary and '
          'secondary actions stay behind the ellipsis.',
          colorRole: ContentColorRole.secondary,
        ),
        SizedBox(height: context.units(.5.rem)),
        CarpenterTable<_ExampleRow, int>(
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
              width: CarpenterTableColumnWidth.flexible(
                flex: 2,
                preferred: 14.rem,
                minimum: 8.rem,
                maximum: 30.rem,
              ),
            ),
            CarpenterTableColumn<_ExampleRow>.number(
              id: 'amount',
              header: 'Amount',
              value: (row) => row.amount,
              formatter: (value) => '${value.toInt()} ₽',
              sortable: true,
              width: CarpenterTableColumnWidth.fixed(
                width: 10.rem,
                minimum: 6.rem,
                maximum: 18.rem,
              ),
            ),
            CarpenterTableColumn<_ExampleRow>.status(
              id: 'state',
              header: 'State',
              label: (row) => row.active ? 'Active' : 'Paused',
              role: (row) => row.active
                  ? FeedbackColorRole.success
                  : FeedbackColorRole.warning,
              width: CarpenterTableColumnWidth.fixed(
                width: 8.rem,
                minimum: 6.rem,
                maximum: 14.rem,
              ),
            ),
            if (widget.manyColumns)
              CarpenterTableColumn<_ExampleRow>.text(
                id: 'identity',
                header: 'Stable identity',
                value: (row) => 'record-${row.id}',
                width: CarpenterTableColumnWidth.fixed(
                  width: 12.rem,
                  minimum: 8.rem,
                  maximum: 20.rem,
                ),
              ),
            CarpenterTableColumn<_ExampleRow>.actions(
              id: 'actions',
              header: 'Actions',
              actions: (row) => [
                CarpenterActionDescriptor(
                  id: 'open-${row.id}',
                  label: 'Open',
                  icon: CarpenterIcons.openFile,
                  onInvoke: () => _reportAction('Open', row),
                ),
                CarpenterActionDescriptor(
                  id: 'edit-${row.id}',
                  label: 'Edit',
                  icon: CarpenterIcons.edit,
                  onInvoke: () => _reportAction('Edit', row),
                ),
                CarpenterActionDescriptor(
                  id: 'copy-${row.id}',
                  label: 'Duplicate',
                  icon: CarpenterIcons.copy,
                  onInvoke: () => _reportAction('Duplicate', row),
                ),
              ],
              secondaryActions: (row) => [
                CarpenterActionDescriptor(
                  id: 'archive-${row.id}',
                  label: 'Archive',
                  icon: CarpenterIcons.archive,
                  onInvoke: () => _reportAction('Archive', row),
                ),
              ],
            ),
          ],
          selection: _selection,
          onSelectionChanged:
              widget.selectionMode == CollectionSelectionMode.none
              ? null
              : (value) => setState(() => _selection = value),
          sorting: _sorting,
          onSortingChanged: (value) => setState(() => _sorting = value),
          multiSort: true,
          columnWidths: _widths,
          onColumnWidthChanged: (id, width) =>
              setState(() => _widths[id] = width),
          onLoadMore: snapshot.pageInfo.hasNext ? () {} : null,
          retryAction: CarpenterActionDescriptor(
            id: 'retry',
            label: 'Retry',
            onInvoke: () {},
          ),
        ),
      ],
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
