import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/demo_invoice_widgets.dart';
import '../../helpers/demo_network.dart';
import '../../helpers/layout_viewport.dart';

final applicationShellComponent = WidgetbookComponent(
  name: 'Application Shell',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _shellPlayground),
    WidgetbookUseCase(name: 'Invoice workspace', builder: _workspaceCase),
  ],
);

final toolbarComponent = WidgetbookComponent(
  name: 'Toolbar',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _toolbarPlayground),
    WidgetbookUseCase(name: 'Async actions', builder: _asyncToolbarCase),
  ],
);

final splitViewComponent = WidgetbookComponent(
  name: 'Split View',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _splitPlayground)],
);

final adaptiveRegionComponent = WidgetbookComponent(
  name: 'Adaptive Region',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _adaptivePlayground),
  ],
);

final masterDetailComponent = WidgetbookComponent(
  name: 'Master / Detail',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _masterDetailPlayground),
    WidgetbookUseCase(name: 'Network records', builder: _networkRecordsCase),
  ],
);

Widget _workspaceCase(BuildContext context) => layoutViewportPreview(
  context,
  offHeight: const Px(840),
  child: buildInvoiceWorkspaceDemo(),
);

Widget _asyncToolbarCase(BuildContext context) => layoutViewportPreview(
  context,
  child: const Align(
    alignment: AlignmentDirectional.topStart,
    child: _AsyncToolbar(),
  ),
);

Widget _networkRecordsCase(BuildContext context) =>
    layoutViewportPreview(context, child: buildNetworkRecordsDemo());

Widget buildInvoiceWorkspaceDemo() => const _InvoiceWorkspace();

Widget buildNetworkRecordsDemo() => const _NetworkMasterDetail();

Widget _shellPlayground(BuildContext context) {
  final touch = context.knobs.boolean(label: 'Capabilities · Touch oriented');
  final showSecondary = context.knobs.boolean(
    label: 'Regions · Show secondary',
  );
  return layoutViewportPreview(
    context,
    child: CarpenterCapabilityScope(
      capabilities: touch
          ? CarpenterInputCapabilities.touchOriented
          : CarpenterInputCapabilities.pointerOriented,
      child: CarpenterApplicationShell(
        navigation: CarpenterNavigationRegion(
          builder: (context, presentation) => Center(
            child: CarpenterText.label('Navigation: ${presentation.name}'),
          ),
        ),
        primaryContent: const Center(child: CarpenterText.title('Workspace')),
        secondaryRegion: const Center(child: CarpenterText.body('Inspector')),
        secondaryVisible: showSecondary,
        globalActions: const CarpenterPageHeader(title: 'Application'),
      ),
    ),
  );
}

Widget _toolbarPlayground(BuildContext context) {
  final count = context.knobs.int.slider(
    label: 'Actions · Count',
    initialValue: 5,
    min: 1,
    max: 8,
  );
  return layoutViewportPreview(
    context,
    child: Align(
      alignment: AlignmentDirectional.topStart,
      child: CarpenterToolbar(
        items: [
          for (var index = 0; index < count; index++)
            CarpenterToolbarItem(
              action: CarpenterActionDescriptor(
                id: 'toolbar-$index',
                label: 'Action ${index + 1}',
                onInvoke: () {},
              ),
              priority: index == 0
                  ? CarpenterToolbarPriority.critical
                  : CarpenterToolbarPriority.normal,
              prominence: index == 0
                  ? ActionProminence.high
                  : ActionProminence.ghost,
            ),
        ],
      ),
    ),
  );
}

Widget _splitPlayground(BuildContext context) {
  final initialPosition = context.knobs.double.slider(
    label: 'Split · Position',
    initialValue: 0.45,
    min: 0.2,
    max: 0.8,
  );
  final orientation = context.knobs.object.segmented(
    label: 'Split · Orientation',
    options: CarpenterSplitOrientation.values,
    labelBuilder: semanticValueLabel,
  );
  return layoutViewportPreview(
    context,
    child: _ControlledSplit(
      position: initialPosition,
      orientation: orientation,
    ),
  );
}

Widget _adaptivePlayground(BuildContext context) {
  final visible = context.knobs.boolean(
    label: 'Region · Visible',
    initialValue: true,
  );
  final role = context.knobs.object.segmented(
    label: 'Region · Role',
    options: CarpenterRegionRole.values,
    initialOption: CarpenterRegionRole.secondary,
    labelBuilder: semanticValueLabel,
  );
  return layoutViewportPreview(
    context,
    child: CarpenterAdaptiveRegion(
      primary: const Center(child: CarpenterText.title('Primary region')),
      region: const Center(child: CarpenterText.body('Adaptive region')),
      role: role,
      policy: CarpenterBreakpointRegionPolicy.secondary,
      regionVisible: visible,
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
    child: CarpenterMasterDetail(
      master: const Center(child: CarpenterText.title('Master list')),
      detail: selected
          ? const Center(child: CarpenterText.title('Selected detail'))
          : null,
      onDetailVisibilityChanged: (_) {},
    ),
  );
}

final class _ControlledSplit extends StatefulWidget {
  const _ControlledSplit({required this.position, required this.orientation});

  final double position;
  final CarpenterSplitOrientation orientation;

  @override
  State<_ControlledSplit> createState() => _ControlledSplitState();
}

final class _ControlledSplitState extends State<_ControlledSplit> {
  late double _position = widget.position;

  @override
  void didUpdateWidget(_ControlledSplit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) _position = widget.position;
  }

  @override
  Widget build(BuildContext context) => CarpenterSplitView(
    primary: const Center(child: CarpenterText.body('Primary')),
    secondary: const Center(child: CarpenterText.body('Secondary')),
    position: _position,
    orientation: widget.orientation,
    onPositionChanged: (value) => setState(() => _position = value),
  );
}

final class _InvoiceWorkspace extends StatefulWidget {
  const _InvoiceWorkspace();

  @override
  State<_InvoiceWorkspace> createState() => _InvoiceWorkspaceState();
}

final class _InvoiceWorkspaceState extends State<_InvoiceWorkspace> {
  final _source = DemoNetworkSource<DemoInvoice>(
    records: demoInvoices,
    searchText: (invoice) => invoice.searchableText,
  );
  var _snapshot = CollectionSnapshot<DemoInvoice>.initialLoading();
  var _selection = CollectionSelection<int>.multiple();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (refresh) setState(() => _snapshot = _snapshot.beginRefresh());
    try {
      final page = await _source.fetch(limit: 3);
      if (!mounted) return;
      setState(() {
        _snapshot = CollectionSnapshot<DemoInvoice>(
          items: page.items,
          loadPhase: CollectionLoadPhase.ready,
          pageInfo: CollectionCursorPageInfo(
            itemCount: page.items.length,
            nextCursor: page.nextCursor,
          ),
        );
      });
    } on DemoNetworkFailure catch (error) {
      if (!mounted) return;
      setState(() {
        _snapshot = _snapshot.withLoadFailure(
          CollectionFailure(error: error, message: error.message),
        );
      });
    }
  }

  void _simulateFailure() {
    _source.failNextRequest();
    _load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = _selection.selectedKeys.firstOrNull;
    final selected = demoInvoices
        .where((item) => item.id == selectedId)
        .firstOrNull;
    return CarpenterApplicationShell(
      navigation: CarpenterNavigationRegion(
        builder: (context, presentation) {
          final actions = [
            CarpenterActionDescriptor(
              id: 'invoices',
              label: 'Invoices',
              onInvoke: () {},
            ),
            CarpenterActionDescriptor(
              id: 'customers',
              label: 'Customers',
              onInvoke: () {},
            ),
            CarpenterActionDescriptor(
              id: 'reports',
              label: 'Reports',
              onInvoke: () {},
            ),
          ];
          final buttons = [
            for (final action in actions)
              CarpenterButton.fromAction(
                action,
                prominence: ActionProminence.ghost,
                size: ControlSize.small,
              ),
          ];
          return presentation == CarpenterNavigationPresentation.bottom
              ? Row(children: buttons)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: buttons,
                );
        },
      ),
      globalActions: CarpenterToolbar(
        items: [
          CarpenterToolbarItem(
            action: CarpenterActionDescriptor(
              id: 'refresh',
              label: 'Refresh',
              onInvoke: () => _load(refresh: true),
            ),
          ),
          CarpenterToolbarItem(
            action: CarpenterActionDescriptor(
              id: 'timeout',
              label: 'Simulate timeout',
              colorRole: ActionColorRole.warning,
              onInvoke: _simulateFailure,
            ),
          ),
        ],
      ),
      primaryContent: CarpenterCollectionPage<DemoInvoice, int>(
        title: 'Accounts receivable',
        subtitle: 'Cursor page from the deterministic demo service',
        snapshot: _snapshot,
        selection: _selection,
        collectionBuilder: (context, snapshot) => demoInvoiceTable(
          snapshot: snapshot,
          selection: _selection,
          onSelectionChanged: (value) => setState(() => _selection = value),
        ),
        retryAction: CarpenterActionDescriptor(
          id: 'retry',
          label: 'Retry',
          onInvoke: _load,
        ),
      ),
      secondaryRegion: selected == null
          ? const Center(child: CarpenterText.body('Select an invoice'))
          : CarpenterSecondaryRegion(
              scrollOwnership: CarpenterRegionScrollOwnership.region,
              child: demoInvoiceDetails(selected),
            ),
      secondaryVisible: selected != null,
      onSecondaryVisibilityChanged: (visible) {
        if (!visible) {
          setState(() => _selection = CollectionSelection.multiple());
        }
      },
    );
  }
}

final class _AsyncToolbar extends StatefulWidget {
  const _AsyncToolbar();

  @override
  State<_AsyncToolbar> createState() => _AsyncToolbarState();
}

final class _AsyncToolbarState extends State<_AsyncToolbar> {
  var _saving = false;
  var _syncing = false;

  Future<void> _run({required bool save}) async {
    setState(() => save ? _saving = true : _syncing = true);
    await Future<void>.delayed(const Milliseconds(700).toDuration());
    if (!mounted) return;
    setState(() => save ? _saving = false : _syncing = false);
  }

  @override
  Widget build(BuildContext context) => CarpenterToolbar(
    alignment: AlignmentDirectional.centerStart,
    items: [
      CarpenterToolbarItem(
        action: CarpenterActionDescriptor(
          id: 'save-draft',
          label: 'Save draft',
          colorRole: ActionColorRole.primary,
          onInvoke: _saving ? null : () => _run(save: true),
        ),
        priority: CarpenterToolbarPriority.critical,
        prominence: ActionProminence.high,
        executionPhase: _saving
            ? ActionExecutionPhase.running
            : ActionExecutionPhase.idle,
      ),
      CarpenterToolbarItem(
        action: CarpenterActionDescriptor(
          id: 'sync',
          label: 'Synchronize ledger',
          onInvoke: _syncing ? null : () => _run(save: false),
        ),
        executionPhase: _syncing
            ? ActionExecutionPhase.running
            : ActionExecutionPhase.idle,
      ),
      CarpenterToolbarItem(
        action: CarpenterActionDescriptor(
          id: 'export',
          label: 'Export report',
          onInvoke: () {},
        ),
        priority: CarpenterToolbarPriority.overflow,
      ),
    ],
  );
}

final class _NetworkMasterDetail extends StatefulWidget {
  const _NetworkMasterDetail();

  @override
  State<_NetworkMasterDetail> createState() => _NetworkMasterDetailState();
}

final class _NetworkMasterDetailState extends State<_NetworkMasterDetail> {
  final _source = DemoNetworkSource<DemoInvoice>(
    records: demoInvoices,
    searchText: (invoice) => invoice.searchableText,
  );
  var _loading = true;
  var _items = <DemoInvoice>[];
  DemoInvoice? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final page = await _source.fetch(limit: 6);
    if (!mounted) return;
    setState(() {
      _items = page.items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => CarpenterMasterDetail(
    master: _loading
        ? const CarpenterPageStatePresentation.loading(
            title: 'Loading invoices',
          )
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
    detail: _selected == null ? null : demoInvoiceDetails(_selected!),
    onDetailVisibilityChanged: (visible) {
      if (!visible) setState(() => _selected = null);
    },
  );
}
