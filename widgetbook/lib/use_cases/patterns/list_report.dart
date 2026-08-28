import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/collection_fixtures.dart';
import '../../helpers/labels.dart';
import '../../helpers/layout_viewport.dart';

final listReportComponent = WidgetbookComponent(
  name: 'List Report',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Operational report', builder: _operationalReport),
  ],
);

Widget _playground(BuildContext context) {
  final scenario = context.knobs.object.dropdown(
    label: 'Collection · State',
    options: DemoCollectionScenario.values,
    initialOption: DemoCollectionScenario.loaded,
    labelBuilder: semanticValueLabel,
  );
  final rows = context.knobs.int.slider(
    label: 'Collection · Rows',
    initialValue: 8,
    min: 0,
    max: 40,
  );
  return layoutViewportPreview(
    context,
    offHeight: const Px(840),
    child: _ListReportPreview(scenario: scenario, rowCount: rows),
  );
}

Widget _operationalReport(BuildContext context) => layoutViewportPreview(
  context,
  offHeight: const Px(840),
  child: const _ListReportPreview(
    scenario: DemoCollectionScenario.refreshError,
    rowCount: 12,
    selected: true,
  ),
);

final class _ListReportPreview extends StatefulWidget {
  const _ListReportPreview({
    required this.scenario,
    required this.rowCount,
    this.selected = false,
  });

  final DemoCollectionScenario scenario;
  final int rowCount;
  final bool selected;

  @override
  State<_ListReportPreview> createState() => _ListReportPreviewState();
}

final class _ListReportPreviewState extends State<_ListReportPreview> {
  final _searchController = TextEditingController();
  var _selection = CollectionSelection<int>.multiple();

  @override
  void initState() {
    super.initState();
    if (widget.selected)
      _selection = CollectionSelection<int>.multiple(const [1, 2]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(
      widget.rowCount,
      (index) => _ReportRow(
        id: index + 1,
        name: 'Counterparty ${index + 1}',
        amount: (index + 1) * 18500,
      ),
    );
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? rows
        : rows.where((row) => row.name.toLowerCase().contains(query)).toList();
    final effectiveScenario = query.isNotEmpty && filtered.isEmpty
        ? DemoCollectionScenario.emptyResult
        : widget.scenario;
    final snapshot = demoCollectionSnapshot<_ReportRow>(
      items: filtered,
      scenario: effectiveScenario,
      pagination: DemoPaginationFixture.unknownTotal,
    );

    return CarpenterListReport<_ReportRow, int>(
      title: 'Accounts receivable',
      subtitle: 'Operational list report with retained-data refresh semantics',
      status: const CarpenterPageStatus(
        label: 'Live',
        role: FeedbackColorRole.success,
      ),
      snapshot: snapshot,
      selection: _selection,
      primaryActions: [_action('create', 'Create record')],
      secondaryActions: [_action('refresh', 'Refresh')],
      exportAction: _action('export', 'Export'),
      retryAction: _action('retry', 'Retry'),
      filterBar: CarpenterFilterBar(
        searchController: _searchController,
        searchPlaceholder: 'Counterparty or document',
        onSearchChanged: (_) => setState(() {}),
        activeFilterCount: query.isEmpty ? 0 : 1,
        clearAction: query.isEmpty
            ? null
            : CarpenterActionDescriptor(
                id: 'clear',
                label: 'Clear',
                onInvoke: () => setState(_searchController.clear),
              ),
      ),
      summary: CarpenterText.caption(
        '${filtered.length} loaded · total intentionally unknown',
      ),
      collectionBuilder: (context, value) => CarpenterTable<_ReportRow, int>(
        semanticLabel: 'Accounts receivable report',
        snapshot: value,
        rowKey: (row) => row.id,
        rowSemanticLabel: (row) => '${row.name}, ${row.amount} rubles',
        selection: _selection,
        onSelectionChanged: (selection) =>
            setState(() => _selection = selection),
        columns: [
          CarpenterTableColumn<_ReportRow>.text(
            id: 'name',
            header: 'Counterparty',
            value: (row) => row.name,
            sortable: true,
          ),
          CarpenterTableColumn<_ReportRow>.number(
            id: 'amount',
            header: 'Amount',
            value: (row) => row.amount,
            formatter: (value) => '${value.toInt()} ₽',
            sortable: true,
          ),
          CarpenterTableColumn<_ReportRow>.actions(
            id: 'actions',
            header: 'Actions',
            actions: (row) => [_action('open-${row.id}', 'Open')],
          ),
        ],
      ),
    );
  }
}

CarpenterActionDescriptor _action(String id, String label) =>
    CarpenterActionDescriptor(id: id, label: label, onInvoke: () {});

final class _ReportRow {
  const _ReportRow({
    required this.id,
    required this.name,
    required this.amount,
  });

  final int id;
  final String name;
  final int amount;
}
