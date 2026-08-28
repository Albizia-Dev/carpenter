import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

enum _CollectionFailureMode { none, initial, query, refresh, loadMore }

enum _InspectorSample { nested, compact, empty, list }

final collectionLifecycleComponent = WidgetbookComponent(
  name: 'Collection Lifecycle',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _lifecyclePlayground),
  ],
);

final listTileComponent = WidgetbookComponent(
  name: 'List Tile',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _listTilePlayground),
    WidgetbookUseCase(name: 'State matrix', builder: _listTiles),
  ],
);

final paginationBarComponent = WidgetbookComponent(
  name: 'Pagination Bar',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _pagination),
    WidgetbookUseCase(name: 'Scenarios', builder: _paginationScenarios),
  ],
);

final inspectorComponent = WidgetbookComponent(
  name: 'Inspector',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _inspector)],
);

Widget _lifecyclePlayground(BuildContext context) {
  final delayMs = context.knobs.double.slider(
    label: 'Network · Delay (ms)',
    initialValue: 550,
    min: 0,
    max: 2000,
    divisions: 20,
  );
  final debounceMs = context.knobs.double.slider(
    label: 'Search · Debounce (ms)',
    initialValue: 350,
    min: 0,
    max: 1000,
    divisions: 20,
  );
  final failureMode = context.knobs.object.segmented(
    label: 'Network · Failure',
    options: _CollectionFailureMode.values,
    initialOption: _CollectionFailureMode.none,
    labelBuilder: (value) => value.name,
  );
  final hasMore = context.knobs.boolean(
    label: 'Paging · Has next page',
    initialValue: true,
  );
  final searchLabel = context.knobs.string(
    label: 'Content · Search label',
    initialValue: 'Search',
  );
  final placeholder = context.knobs.string(
    label: 'Content · Search placeholder',
    initialValue: 'Type quickly to exercise cancellation',
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 680,
    min: 320,
    max: 1000,
    divisions: 34,
  );

  return _LifecyclePreview(
    key: ValueKey((delayMs, debounceMs, failureMode, hasMore)),
    delay: Duration(milliseconds: delayMs.round()),
    debounce: Duration(milliseconds: debounceMs.round()),
    failureMode: failureMode,
    hasMore: hasMore,
    searchLabel: searchLabel,
    placeholder: placeholder,
    width: width,
  );
}

final class _LifecyclePreview extends StatefulWidget {
  const _LifecyclePreview({
    super.key,
    required this.delay,
    required this.debounce,
    required this.failureMode,
    required this.hasMore,
    required this.searchLabel,
    required this.placeholder,
    required this.width,
  });

  final Duration delay;
  final Duration debounce;
  final _CollectionFailureMode failureMode;
  final bool hasMore;
  final String searchLabel;
  final String placeholder;
  final double width;

  @override
  State<_LifecyclePreview> createState() => _LifecyclePreviewState();
}

final class _LifecyclePreviewState extends State<_LifecyclePreview> {
  late final CollectionLifecycleController<String, String, String> _controller =
      CollectionLifecycleController<String, String, String>(
        query: CollectionQuery<String>(search: ''),
        keyOf: (item) => item,
        searchDebounce: widget.debounce,
        load: (query, request) async {
          await Future<void>.delayed(widget.delay);
          if (request.cancellation.isCancelled) {
            return CollectionSnapshot<String>.initialLoading();
          }
          if (_shouldFail(request.reason)) {
            throw StateError('Simulated ${request.reason.name} failure');
          }
          final search = (query.search ?? '').toLowerCase();
          final source = [
            'Invoice 001',
            'Invoice 002',
            'Payment 103',
            'Contract 440',
          ];
          final items = source
              .where((item) => item.toLowerCase().contains(search))
              .toList();
          return CollectionSnapshot<String>(
            items: items,
            contentState: items.isEmpty
                ? CollectionContentState.emptyResult
                : CollectionContentState.content,
            pageInfo: CollectionProgressivePageInfo(
              loadedItems: items.length,
              hasMore: widget.hasMore,
              totalItems: items.length + (widget.hasMore ? 2 : 0),
            ),
          );
        },
        loadMore: (query, current, request) async {
          await Future<void>.delayed(widget.delay);
          if (_shouldFail(request.reason)) {
            throw StateError('Simulated load-more failure');
          }
          final item = 'Loaded later ${current.items.length + 1}';
          return current.copyWith(
            items: [...current.items, item],
            pageInfo: CollectionProgressivePageInfo(
              loadedItems: current.items.length + 1,
              hasMore: false,
              totalItems: current.items.length + 1,
            ),
          );
        },
      );

  bool _shouldFail(
    CollectionRequestReason reason,
  ) => switch (widget.failureMode) {
    _CollectionFailureMode.none => false,
    _CollectionFailureMode.initial => reason == CollectionRequestReason.initial,
    _CollectionFailureMode.query => reason == CollectionRequestReason.query,
    _CollectionFailureMode.refresh => reason == CollectionRequestReason.refresh,
    _CollectionFailureMode.loadMore =>
      reason == CollectionRequestReason.loadMore,
  };

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    height: context.units(32.5.rem),
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterCollectionSearchField<String, String, String>(
            controller: _controller,
            label: widget.searchLabel,
            placeholder: widget.placeholder,
            width: widget.width,
          ),
          SizedBox(height: context.units(.75.rem)),
          Expanded(
            child: CarpenterDataList<String, String>(
              snapshot: _controller.snapshot,
              itemKey: (item) => item,
              itemSemanticLabel: (item) => item,
              itemBuilder: (context, item) => CarpenterText.body(item),
              selection: CollectionSelection<String>.none(),
              onLoadMore: _controller.snapshot.pageInfo.hasNext
                  ? () => unawaited(_controller.loadMore())
                  : null,
              retryAction: CarpenterActionDescriptor(
                id: 'retry',
                label: 'Retry',
                onInvoke: () => unawaited(_controller.refresh()),
              ),
            ),
          ),
          SizedBox(height: context.units(.75.rem)),
          Wrap(
            spacing: context.units(.5.rem),
            runSpacing: context.units(.5.rem),
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CarpenterButton(
                label: 'Refresh',
                prominence: ActionProminence.outlined,
                onInvoke: () => unawaited(_controller.refresh()),
              ),
              CarpenterStatusIndicator(
                label: _controller.snapshot.loadPhase.name,
                role:
                    _controller.snapshot.isRefreshing ||
                        _controller.snapshot.isLoadingMore
                    ? FeedbackColorRole.info
                    : _controller.snapshot.refreshFailure != null ||
                          _controller.snapshot.initialFailure != null
                    ? FeedbackColorRole.danger
                    : FeedbackColorRole.neutral,
              ),
              CarpenterText.caption(
                'query="${_controller.query.search ?? ''}" · freshness=${_controller.snapshot.freshness.name}',
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _listTilePlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Invoice INV-440',
  );
  final subtitle = context.knobs.stringOrNull(
    label: 'Content · Subtitle',
    initialValue: 'Albizia LLC · 125,000.40 ₽',
    defaultToNull: false,
  );
  final selected = context.knobs.boolean(
    label: 'State · Selected',
    initialValue: false,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final showLeading = context.knobs.boolean(
    label: 'Content · Leading avatar',
    initialValue: true,
  );
  final showTrailing = context.knobs.boolean(
    label: 'Content · Trailing tag',
    initialValue: true,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 600,
    min: 240,
    max: 900,
    divisions: 33,
  );

  return preview(
    SizedBox(
      width: width,
      child: CarpenterListTile(
        leading: showLeading
            ? const CarpenterAvatar(initials: 'AB', size: 32)
            : null,
        title: CarpenterText.label(title),
        subtitle: subtitle == null
            ? null
            : CarpenterText.body(
                subtitle,
                colorRole: ContentColorRole.secondary,
              ),
        trailing: showTrailing
            ? CarpenterTag(
                label: selected ? 'Selected' : 'Pending',
                tone: selected
                    ? CarpenterTagTone.info
                    : CarpenterTagTone.neutral,
              )
            : null,
        selected: selected,
        onInvoke: enabled ? () {} : null,
      ),
    ),
  );
}

Widget _listTiles(BuildContext context) => previewColumn([
  const SizedBox(
    width: context.units(37.5.rem),
    child: CarpenterListTile(
      title: CarpenterText.label('Plain record'),
      subtitle: CarpenterText.body(
        'Secondary information',
        colorRole: ContentColorRole.secondary,
      ),
    ),
  ),
  SizedBox(
    width: context.units(37.5.rem),
    child: CarpenterListTile(
      selected: true,
      title: const CarpenterText.label('Selected record'),
      trailing: const CarpenterTag(
        label: 'Selected',
        tone: CarpenterTagTone.info,
      ),
      onInvoke: () {},
    ),
  ),
  const SizedBox(
    width: context.units(37.5.rem),
    child: CarpenterListTile(
      title: CarpenterText.label('Disabled record'),
      subtitle: CarpenterText.caption('No onInvoke callback'),
    ),
  ),
  SizedBox(
    width: context.units(22.5.rem),
    child: CarpenterListTile(
      leading: const CarpenterAvatar(initials: 'AB', size: 32),
      title: const CarpenterText.label(
        'Narrow row with a long title that needs room',
      ),
      subtitle: const CarpenterText.caption(
        'Collection rows stay semantic and keyboard-aware.',
      ),
      onInvoke: () {},
    ),
  ),
]);

Widget _pagination(BuildContext context) {
  final totalPages = context.knobs.double
      .slider(
        label: 'Data · Total pages',
        initialValue: 37,
        min: 1,
        max: 500,
        divisions: 499,
      )
      .round();
  final initialPage = context.knobs.double
      .slider(
        label: 'Data · Initial page',
        initialValue: 18,
        min: 1,
        max: 500,
        divisions: 499,
      )
      .round();
  final siblingCount = context.knobs.int.slider(
    label: 'Navigation · Sibling pages',
    initialValue: 1,
    min: 0,
    max: 4,
  );
  final leading = context.knobs.stringOrNull(
    label: 'Content · Leading text',
    initialValue: '1–50 of 1,842 records',
    defaultToNull: false,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 820,
    min: 260,
    max: 1200,
    divisions: 47,
  );
  return _PaginationPreview(
    initialPage: initialPage,
    totalPages: totalPages,
    siblingCount: siblingCount,
    leading: leading,
    width: width,
  );
}

Widget _paginationScenarios(BuildContext context) => previewColumn([
  const _PaginationPreview(
    initialPage: 1,
    totalPages: 3,
    siblingCount: 1,
    leading: 'Small result set',
    width: context.units(45.rem),
  ),
  const _PaginationPreview(
    initialPage: 18,
    totalPages: 37,
    siblingCount: 1,
    leading: '1–50 of 1,842 records',
    width: context.units(56.25.rem),
  ),
  const _PaginationPreview(
    initialPage: 243,
    totalPages: 500,
    siblingCount: 2,
    leading: 'Large data set',
    width: context.units(68.75.rem),
  ),
  const _PaginationPreview(
    initialPage: 18,
    totalPages: 37,
    siblingCount: 1,
    leading: null,
    width: context.units(22.5.rem),
  ),
]);

final class _PaginationPreview extends StatefulWidget {
  const _PaginationPreview({
    required this.initialPage,
    required this.totalPages,
    required this.siblingCount,
    required this.leading,
    required this.width,
  });

  final int initialPage;
  final int totalPages;
  final int siblingCount;
  final String? leading;
  final double width;

  @override
  State<_PaginationPreview> createState() => _PaginationPreviewState();
}

final class _PaginationPreviewState extends State<_PaginationPreview> {
  late int _page = _normalized(widget.initialPage);

  int _normalized(int value) {
    if (value < 1) return 1;
    if (value > widget.totalPages) return widget.totalPages;
    return value;
  }

  @override
  void didUpdateWidget(_PaginationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      _page = _normalized(widget.initialPage);
    } else if (_page > widget.totalPages) {
      _page = widget.totalPages;
    }
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: widget.width,
      child: CarpenterPaginationBar(
        page: _page,
        totalPages: widget.totalPages,
        siblingCount: widget.siblingCount,
        leading: widget.leading == null
            ? null
            : CarpenterText.caption(widget.leading!),
        onPageChanged: (page) => setState(() => _page = page),
      ),
    ),
  );
}

Widget _inspector(BuildContext context) {
  final sample = context.knobs.object.segmented(
    label: 'Data · Sample',
    options: _InspectorSample.values,
    initialOption: _InspectorSample.nested,
    labelBuilder: (value) => value.name,
  );
  final emptyMessage = context.knobs.string(
    label: 'Content · Empty message',
    initialValue: 'No data',
  );
  final uppercaseLabels = context.knobs.boolean(
    label: 'Formatting · Uppercase labels',
    initialValue: false,
  );
  final hideTechnical = context.knobs.boolean(
    label: 'Formatting · Hide id fields',
    initialValue: false,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 720,
    min: 280,
    max: 1000,
    divisions: 36,
  );

  final Object value = switch (sample) {
    _InspectorSample.nested => {
      'id': 'payment-103',
      'status': 'pending',
      'amount': 125000.40,
      'counterparty': {'name': 'Albizia LLC', 'inn': '7712345678'},
      'links': [
        {'type': 'invoice', 'id': 'INV-440'},
        {'type': 'contract', 'id': 'CTR-22'},
      ],
    },
    _InspectorSample.compact => {'id': 'CTR-22', 'owner': 'NC', 'active': true},
    _InspectorSample.empty => const <String, Object?>{},
    _InspectorSample.list => const [
      {'name': 'INV-440', 'status': 'pending'},
      {'name': 'INV-441', 'status': 'approved'},
    ],
  };

  return preview(
    SizedBox(
      width: width,
      child: CarpenterCard(
        child: CarpenterInspector(
          value: value,
          emptyMessage: emptyMessage,
          labelBuilder: uppercaseLabels ? (key) => key.toUpperCase() : null,
          fieldFilter: hideTechnical
              ? (key, value) => key != 'id' && value != null
              : null,
        ),
      ),
    ),
  );
}
