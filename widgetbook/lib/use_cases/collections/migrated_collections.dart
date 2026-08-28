import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final collectionLifecycleComponent = WidgetbookComponent(
  name: 'Collection Lifecycle',
  useCases: [
    WidgetbookUseCase(
      name: 'Async controller',
      builder: (_) => const _LifecyclePreview(),
    ),
  ],
);

final listTileComponent = WidgetbookComponent(
  name: 'List Tile',
  useCases: [WidgetbookUseCase(name: 'States', builder: _listTiles)],
);

final paginationBarComponent = WidgetbookComponent(
  name: 'Pagination Bar',
  useCases: [
    WidgetbookUseCase(
      name: 'Interactive',
      builder: (_) => const _PaginationPreview(),
    ),
  ],
);

final inspectorComponent = WidgetbookComponent(
  name: 'Inspector',
  useCases: [WidgetbookUseCase(name: 'Nested payload', builder: _inspector)],
);

final class _LifecyclePreview extends StatefulWidget {
  const _LifecyclePreview();
  @override
  State<_LifecyclePreview> createState() => _LifecyclePreviewState();
}

final class _LifecyclePreviewState extends State<_LifecyclePreview> {
  int _request = 0;
  late final CollectionLifecycleController<String, String, String> _controller =
      CollectionLifecycleController<String, String, String>(
        query: CollectionQuery<String>(search: ''),
        keyOf: (item) => item,
        load: (query, request) async {
          final generation = ++_request;
          await Future<void>.delayed(const Duration(milliseconds: 550));
          if (request.cancellation.isCancelled) {
            return CollectionSnapshot<String>.initialLoading();
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
              hasMore: generation.isOdd,
              totalItems: items.length + 2,
            ),
          );
        },
        loadMore: (query, current, request) async {
          await Future<void>.delayed(const Duration(milliseconds: 450));
          return current.copyWith(
            items: [
              ...current.items,
              'Loaded later ${current.items.length + 1}',
            ],
            pageInfo: CollectionProgressivePageInfo(
              loadedItems: current.items.length + 1,
              hasMore: false,
              totalItems: current.items.length + 1,
            ),
          );
        },
      );
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _search.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 680,
    height: 480,
    child: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterInput(
            controller: _search,
            label: 'Search',
            placeholder: 'Type quickly to exercise cancellation',
            onChanged: _controller.updateSearch,
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                    : FeedbackColorRole.neutral,
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _listTiles(BuildContext context) => previewColumn([
  const SizedBox(
    width: 600,
    child: CarpenterListTile(
      title: CarpenterText.label('Plain record'),
      subtitle: CarpenterText.body(
        'Secondary information',
        colorRole: ContentColorRole.secondary,
      ),
    ),
  ),
  SizedBox(
    width: 600,
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
  SizedBox(
    width: 360,
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

final class _PaginationPreview extends StatefulWidget {
  const _PaginationPreview();
  @override
  State<_PaginationPreview> createState() => _PaginationPreviewState();
}

final class _PaginationPreviewState extends State<_PaginationPreview> {
  int _page = 4;
  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 640,
      child: CarpenterPaginationBar(
        page: _page,
        totalPages: 17,
        leading: const CarpenterText.caption('132 records'),
        onPageChanged: (page) => setState(() => _page = page),
      ),
    ),
  );
}

Widget _inspector(BuildContext context) => preview(
  const SizedBox(
    width: 720,
    child: CarpenterCard(
      child: CarpenterInspector(
        value: {
          'id': 'payment-103',
          'status': 'pending',
          'amount': 125000.40,
          'counterparty': {'name': 'Albizia LLC', 'inn': '7712345678'},
          'links': [
            {'type': 'invoice', 'id': 'INV-440'},
            {'type': 'contract', 'id': 'CTR-22'},
          ],
        },
      ),
    ),
  ),
);
