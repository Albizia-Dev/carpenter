import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/demo_invoice_widgets.dart';
import '../../helpers/demo_network.dart';
import '../../helpers/layout_viewport.dart';

enum _CollectionScenario {
  loaded,
  initialLoading,
  refreshing,
  initialError,
  refreshError,
  zero,
  emptyResult,
}

final collectionPageComponent = WidgetbookComponent(
  name: 'Collection Page',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _collectionPlayground),
    WidgetbookUseCase(
      name: 'Network workflow',
      builder: _networkCollectionCase,
    ),
  ],
);

final objectPageComponent = WidgetbookComponent(
  name: 'Object Page',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _objectPlayground),
    WidgetbookUseCase(name: 'Loaded invoice', builder: _networkObjectCase),
  ],
);

final formPageComponent = WidgetbookComponent(
  name: 'Form Page',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _formPlayground),
    WidgetbookUseCase(name: 'Async save', builder: _networkFormCase),
  ],
);

final masterDetailPageComponent = WidgetbookComponent(
  name: 'Master Detail Page',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _masterDetailPlayground),
    WidgetbookUseCase(name: 'Invoice inbox', builder: _networkMasterDetailCase),
  ],
);

Widget _networkCollectionCase(BuildContext context) => layoutViewportPreview(
  context,
  offHeight: const Rem(52.5),
  child: buildNetworkCollectionPageDemo(),
);

Widget _networkObjectCase(BuildContext context) =>
    layoutViewportPreview(context, child: buildNetworkObjectPageDemo());

Widget _networkFormCase(BuildContext context) =>
    layoutViewportPreview(context, child: buildNetworkFormPageDemo());

Widget _networkMasterDetailCase(BuildContext context) =>
    layoutViewportPreview(context, child: buildNetworkMasterDetailPageDemo());

Widget buildNetworkCollectionPageDemo() => const _NetworkCollectionPage();

Widget buildNetworkObjectPageDemo() => const _NetworkObjectPage();

Widget buildNetworkFormPageDemo() => const _NetworkFormPage();

Widget buildNetworkMasterDetailPageDemo() => const _NetworkMasterDetailPage();

Widget _collectionPlayground(BuildContext context) {
  final rowCount = context.knobs.int.slider(
    label: 'Collection · Rows',
    initialValue: 12,
    min: 0,
    max: 50,
  );
  final scenario = context.knobs.object.dropdown(
    label: 'Collection · State',
    options: _CollectionScenario.values,
    labelBuilder: semanticValueLabel,
  );
  final selected = context.knobs.boolean(label: 'Selection · Has selection');
  return layoutViewportPreview(
    context,
    child: _CollectionPagePreview(
      rowCount: rowCount,
      scenario: scenario,
      selected: selected,
    ),
  );
}

Widget _objectPlayground(BuildContext context) {
  final showSecondary = context.knobs.boolean(
    label: 'Regions · Show secondary',
    initialValue: true,
  );
  final longContent = context.knobs.boolean(label: 'Content · Long text');
  return layoutViewportPreview(
    context,
    child: CarpenterObjectPage(
      title: 'Document 1542',
      subtitle: longContent
          ? 'A long object description that demonstrates responsive header and region composition.'
          : 'Object overview',
      status: const CarpenterPageStatus(
        label: 'In review',
        role: FeedbackColorRole.info,
      ),
      primaryActions: [_action('edit', 'Edit')],
      secondaryActions: [_action('copy', 'Copy link')],
      primaryContent: const CarpenterText.body('Primary object content'),
      metadata: const CarpenterText.caption('Created today · Owner: Carpenter'),
      secondaryRegion: const CarpenterText.body('Related information'),
      secondaryVisible: showSecondary,
    ),
  );
}

Widget _formPlayground(BuildContext context) {
  final dirty = context.knobs.boolean(
    label: 'Form · Dirty',
    initialValue: true,
  );
  final validation = context.knobs.boolean(label: 'Form · Validation summary');
  final phase = context.knobs.object.segmented(
    label: 'Save · Execution',
    options: ActionExecutionPhase.values,
    labelBuilder: semanticValueLabel,
  );
  return layoutViewportPreview(
    context,
    child: _FormPagePreview(
      dirty: dirty,
      showValidation: validation,
      phase: phase,
    ),
  );
}

Widget _masterDetailPlayground(BuildContext context) {
  final selected = context.knobs.boolean(
    label: 'Selection · Has detail',
    initialValue: true,
  );
  return layoutViewportPreview(
    context,
    child: CarpenterMasterDetailPage<int>(
      title: 'Documents',
      subtitle: 'Controlled master and detail regions',
      master: const Center(child: CarpenterText.body('Document list')),
      selectedValue: selected ? 1542 : null,
      detailBuilder: (context, value) =>
          Center(child: CarpenterText.title('Document $value')),
      onDetailClosed: () {},
    ),
  );
}

final class _CollectionPagePreview extends StatefulWidget {
  const _CollectionPagePreview({
    required this.rowCount,
    required this.scenario,
    required this.selected,
  });

  final int rowCount;
  final _CollectionScenario scenario;
  final bool selected;

  @override
  State<_CollectionPagePreview> createState() => _CollectionPagePreviewState();
}

final class _CollectionPagePreviewState extends State<_CollectionPagePreview> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = List.generate(
      widget.rowCount,
      (index) => _PageRow(index + 1, 'Document ${index + 1}'),
    );
    final snapshot = _snapshot(rows, widget.scenario);
    return CarpenterCollectionPage<_PageRow, int>(
      title: 'Documents',
      subtitle: 'CollectionSnapshot drives the visible page state',
      snapshot: snapshot,
      selection: widget.selected
          ? CollectionSelection<int>.multiple(const [1])
          : CollectionSelection<int>.multiple(),
      primaryActions: [_action('create', 'Create')],
      selectionActions: [_action('archive', 'Archive selected')],
      retryAction: _action('retry', 'Retry'),
      filterBar: CarpenterFilterBar(
        searchController: _searchController,
        onSearchChanged: (_) => setState(() {}),
        activeFilterCount: _searchController.text.isEmpty ? 0 : 1,
        clearAction: _searchController.text.isEmpty
            ? null
            : CarpenterActionDescriptor(
                id: 'clear',
                label: 'Clear',
                onInvoke: () => setState(_searchController.clear),
              ),
      ),
      collectionBuilder: (context, value) => CarpenterTable<_PageRow, int>(
        snapshot: value,
        rowKey: (row) => row.id,
        rowSemanticLabel: (row) => '${row.name}, identifier ${row.id}',
        selection: widget.selected
            ? CollectionSelection<int>.multiple(const [1])
            : CollectionSelection<int>.multiple(),
        columns: [
          CarpenterTableColumn<_PageRow>.text(
            id: 'name',
            header: 'Name',
            value: (row) => row.name,
          ),
          CarpenterTableColumn<_PageRow>.number(
            id: 'id',
            header: 'ID',
            value: (row) => row.id,
          ),
        ],
      ),
    );
  }
}

final class _FormPagePreview extends StatefulWidget {
  const _FormPagePreview({
    required this.dirty,
    required this.showValidation,
    required this.phase,
  });

  final bool dirty;
  final bool showValidation;
  final ActionExecutionPhase phase;

  @override
  State<_FormPagePreview> createState() => _FormPagePreviewState();
}

final class _FormPagePreviewState extends State<_FormPagePreview> {
  final _titleController = TextEditingController(text: 'Document title');
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterFormPage(
    title: 'Edit document',
    dirty: widget.dirty,
    saveExecutionPhase: widget.phase,
    saveAction: _action('save', 'Save'),
    cancelAction: _action('cancel', 'Cancel'),
    validationSummary: widget.showValidation
        ? const CarpenterPageStatePresentation(
            kind: CarpenterPageStateKind.initialError,
            title: 'Review the highlighted fields',
          )
        : null,
    formContent: Column(
      children: [
        CarpenterInput(controller: _titleController, label: 'Title'),
        CarpenterTextArea(
          controller: _notesController,
          label: 'Notes',
          minLines: 4,
          maxLines: 8,
        ),
      ],
    ),
  );
}

CollectionSnapshot<_PageRow> _snapshot(
  List<_PageRow> rows,
  _CollectionScenario scenario,
) => switch (scenario) {
  _CollectionScenario.loaded => CollectionSnapshot<_PageRow>(items: rows),
  _CollectionScenario.initialLoading =>
    CollectionSnapshot<_PageRow>.initialLoading(),
  _CollectionScenario.refreshing => CollectionSnapshot<_PageRow>(
    items: rows,
    loadPhase: CollectionLoadPhase.refreshing,
    freshness: CollectionFreshness.stale,
  ),
  _CollectionScenario.initialError => CollectionSnapshot<_PageRow>(
    initialFailure: const CollectionFailure(
      error: 'offline',
      message: 'The collection is unavailable',
    ),
  ),
  _CollectionScenario.refreshError => CollectionSnapshot<_PageRow>(
    items: rows,
    freshness: CollectionFreshness.stale,
    refreshFailure: const CollectionFailure(
      error: 'timeout',
      message: 'Refresh failed; rows remain visible',
    ),
  ),
  _CollectionScenario.zero => CollectionSnapshot<_PageRow>(
    contentState: CollectionContentState.zero,
  ),
  _CollectionScenario.emptyResult => CollectionSnapshot<_PageRow>(
    contentState: CollectionContentState.emptyResult,
  ),
};

CarpenterActionDescriptor _action(String id, String label) =>
    CarpenterActionDescriptor(id: id, label: label, onInvoke: () {});

final class _PageRow {
  const _PageRow(this.id, this.name);
  final int id;
  final String name;
}

final class _NetworkCollectionPage extends StatefulWidget {
  const _NetworkCollectionPage();

  @override
  State<_NetworkCollectionPage> createState() => _NetworkCollectionPageState();
}

final class _NetworkCollectionPageState extends State<_NetworkCollectionPage> {
  final _source = DemoNetworkSource<DemoInvoice>(
    records: demoInvoices,
    searchText: (invoice) => invoice.searchableText,
  );
  final _searchController = TextEditingController();
  var _snapshot = CollectionSnapshot<DemoInvoice>.initialLoading();
  var _selection = CollectionSelection<int>.multiple();
  var _query = '';
  var _requestSerial = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false, bool more = false}) async {
    final serial = ++_requestSerial;
    final pageInfo = _snapshot.pageInfo;
    final cursor = more && pageInfo is CollectionCursorPageInfo
        ? pageInfo.nextCursor
        : null;
    setState(() {
      _snapshot = more
          ? _snapshot.beginLoadingMore()
          : refresh
          ? _snapshot.beginRefresh()
          : CollectionSnapshot<DemoInvoice>.initialLoading();
    });
    try {
      final page = await _source.fetch(query: _query, cursor: cursor, limit: 3);
      if (!mounted || serial != _requestSerial) return;
      final items = more ? [..._snapshot.items, ...page.items] : page.items;
      setState(() {
        _snapshot = CollectionSnapshot<DemoInvoice>(
          items: items,
          loadPhase: CollectionLoadPhase.ready,
          contentState: items.isEmpty
              ? _query.isEmpty
                    ? CollectionContentState.zero
                    : CollectionContentState.emptyResult
              : CollectionContentState.content,
          pageInfo: CollectionCursorPageInfo(
            itemCount: items.length,
            nextCursor: page.nextCursor,
          ),
        );
      });
    } on DemoNetworkFailure catch (error) {
      if (!mounted || serial != _requestSerial) return;
      setState(() {
        _snapshot = _snapshot.withLoadFailure(
          CollectionFailure(error: error, message: error.message),
        );
      });
    }
  }

  void _search(String value) {
    _query = value;
    _load(refresh: _snapshot.hasData);
  }

  void _clear() {
    _searchController.clear();
    _query = '';
    _load(refresh: _snapshot.hasData);
  }

  void _failRefresh() {
    _source.failNextRequest();
    _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) =>
      CarpenterCollectionPage<DemoInvoice, int>(
        title: 'Invoices',
        subtitle: 'Network-like cursor pagination with stale-data refresh',
        snapshot: _snapshot,
        selection: _selection,
        primaryActions: [
          CarpenterActionDescriptor(
            id: 'refresh',
            label: 'Refresh',
            onInvoke: () => _load(refresh: true),
          ),
        ],
        secondaryActions: [
          CarpenterActionDescriptor(
            id: 'fail-refresh',
            label: 'Simulate timeout',
            colorRole: ActionColorRole.warning,
            onInvoke: _snapshot.hasData ? _failRefresh : null,
          ),
        ],
        selectionActions: [
          CarpenterActionDescriptor(
            id: 'approve-selected',
            label: 'Approve selected',
            colorRole: ActionColorRole.success,
            onInvoke: () {},
          ),
        ],
        retryAction: CarpenterActionDescriptor(
          id: 'retry',
          label: 'Retry',
          onInvoke: _load,
        ),
        filterBar: CarpenterFilterBar(
          searchController: _searchController,
          onSearchChanged: _search,
          searchPlaceholder: 'Number, customer or purpose',
          activeFilterCount: _query.isEmpty ? 0 : 1,
          clearAction: _query.isEmpty
              ? null
              : CarpenterActionDescriptor(
                  id: 'clear-query',
                  label: 'Clear search',
                  onInvoke: _clear,
                ),
        ),
        summary: CarpenterText.caption(
          '${_snapshot.items.length} loaded · total intentionally unknown',
        ),
        collectionBuilder: (context, snapshot) => demoInvoiceTable(
          snapshot: snapshot,
          selection: _selection,
          onSelectionChanged: (value) => setState(() => _selection = value),
          onLoadMore: snapshot.pageInfo.hasNext
              ? () => _load(more: true)
              : null,
        ),
      );
}

final class _NetworkObjectPage extends StatefulWidget {
  const _NetworkObjectPage();

  @override
  State<_NetworkObjectPage> createState() => _NetworkObjectPageState();
}

final class _NetworkObjectPageState extends State<_NetworkObjectPage> {
  final _source = DemoNetworkSource<DemoInvoice>(
    records: demoInvoices,
    searchText: (invoice) => invoice.searchableText,
  );
  DemoInvoice? _invoice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fail = false}) async {
    if (fail) _source.failNextRequest();
    setState(() => _error = null);
    try {
      final page = await _source.fetch(query: 'INV-2026-0412', limit: 1);
      if (!mounted) return;
      setState(() => _invoice = page.items.firstOrNull);
    } on DemoNetworkFailure catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    if (invoice == null) {
      return CarpenterPageStatePresentation(
        kind: _error == null
            ? CarpenterPageStateKind.initialLoading
            : CarpenterPageStateKind.initialError,
        title: _error ?? 'Loading invoice',
        action: _error == null
            ? null
            : CarpenterActionDescriptor(
                id: 'retry-object',
                label: 'Retry',
                onInvoke: _load,
              ),
      );
    }
    return CarpenterObjectPage(
      title: invoice.number,
      subtitle: invoice.purpose,
      status: CarpenterPageStatus(
        label: demoInvoiceStatusLabel(invoice.status),
        role: demoInvoiceStatusRole(invoice.status),
      ),
      breadcrumbs: const CarpenterText.caption('Invoices / August 2026'),
      primaryActions: [_action('approve', 'Approve')],
      secondaryActions: [
        CarpenterActionDescriptor(
          id: 'reload-object',
          label: 'Reload',
          onInvoke: _load,
        ),
        CarpenterActionDescriptor(
          id: 'fail-object',
          label: 'Simulate timeout',
          colorRole: ActionColorRole.warning,
          onInvoke: () => _load(fail: true),
        ),
      ],
      primaryContent: demoInvoiceDetails(invoice),
      metadata: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.caption('Stable record key: ${invoice.id}'),
          if (_error != null)
            CarpenterStatusIndicator(
              label: _error!,
              role: FeedbackColorRole.danger,
            ),
        ],
      ),
      secondaryRegion: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CarpenterText.title('Activity'),
          CarpenterText.body('Invoice imported from billing gateway'),
          CarpenterText.body('Review requested by finance'),
        ],
      ),
    );
  }
}

final class _NetworkFormPage extends StatefulWidget {
  const _NetworkFormPage();

  @override
  State<_NetworkFormPage> createState() => _NetworkFormPageState();
}

final class _NetworkFormPageState extends State<_NetworkFormPage> {
  final _customer = TextEditingController(text: 'Northwind Logistics');
  final _purpose = TextEditingController(
    text: 'Warehouse automation milestone',
  );
  var _dirty = false;
  var _phase = ActionExecutionPhase.idle;
  String? _validationMessage;

  @override
  void dispose() {
    _customer.dispose();
    _purpose.dispose();
    super.dispose();
  }

  void _changed(String _) => setState(() {
    _dirty = true;
    _phase = ActionExecutionPhase.idle;
  });

  Future<void> _save() async {
    if (_customer.text.trim().isEmpty || _purpose.text.trim().isEmpty) {
      setState(() => _validationMessage = 'Customer and purpose are required');
      return;
    }
    setState(() {
      _validationMessage = null;
      _phase = ActionExecutionPhase.running;
    });
    await Future<void>.delayed(const Milliseconds(650).toDuration());
    if (!mounted) return;
    setState(() {
      _dirty = false;
      _phase = ActionExecutionPhase.succeeded;
    });
  }

  void _cancel() => setState(() {
    _customer.text = 'Northwind Logistics';
    _purpose.text = 'Warehouse automation milestone';
    _dirty = false;
    _validationMessage = null;
    _phase = ActionExecutionPhase.idle;
  });

  @override
  Widget build(BuildContext context) => CarpenterFormPage(
    title: 'Edit INV-2026-0412',
    subtitle: 'Save is simulated with network latency',
    dirty: _dirty,
    saveExecutionPhase: _phase,
    saveAction: CarpenterActionDescriptor(
      id: 'save-invoice',
      label: 'Save changes',
      colorRole: ActionColorRole.primary,
      onInvoke: _phase == ActionExecutionPhase.running ? null : _save,
    ),
    cancelAction: CarpenterActionDescriptor(
      id: 'cancel-edit',
      label: 'Cancel',
      onInvoke: _cancel,
    ),
    validationSummary: _validationMessage == null
        ? null
        : CarpenterPageStatePresentation(
            kind: CarpenterPageStateKind.initialError,
            title: _validationMessage!,
          ),
    formContent: Column(
      children: [
        CarpenterInput(
          controller: _customer,
          label: 'Customer',
          required: true,
          onChanged: _changed,
        ),
        CarpenterTextArea(
          controller: _purpose,
          label: 'Purpose',
          required: true,
          minLines: 4,
          maxLines: 8,
          onChanged: _changed,
        ),
      ],
    ),
  );
}

final class _NetworkMasterDetailPage extends StatefulWidget {
  const _NetworkMasterDetailPage();

  @override
  State<_NetworkMasterDetailPage> createState() =>
      _NetworkMasterDetailPageState();
}

final class _NetworkMasterDetailPageState
    extends State<_NetworkMasterDetailPage> {
  final _source = DemoNetworkSource<DemoInvoice>(
    records: demoInvoices,
    searchText: (invoice) => invoice.searchableText,
  );
  var _items = <DemoInvoice>[];
  var _loading = true;
  DemoInvoice? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await _source.fetch(limit: 8);
    if (!mounted) return;
    setState(() {
      _items = page.items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => CarpenterMasterDetailPage<DemoInvoice>(
    title: 'Invoice review inbox',
    subtitle: 'Selection is controlled by the Widgetbook fixture',
    selectedValue: _selected,
    onDetailClosed: () => setState(() => _selected = null),
    master: _loading
        ? const CarpenterPageStatePresentation.loading(title: 'Loading inbox')
        : ListView(
            children: [
              for (final invoice in _items)
                CarpenterButton(
                  label: '${invoice.number} · ${invoice.customer}',
                  prominence: ActionProminence.ghost,
                  onInvoke: () => setState(() => _selected = invoice),
                ),
            ],
          ),
    detailBuilder: (context, invoice) => demoInvoiceDetails(invoice),
    primaryActions: [
      CarpenterActionDescriptor(
        id: 'refresh-inbox',
        label: 'Refresh inbox',
        onInvoke: _load,
      ),
    ],
  );
}
