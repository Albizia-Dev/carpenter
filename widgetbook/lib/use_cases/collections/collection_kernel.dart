import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

enum _CollectionScenario {
  initialLoading,
  loaded,
  refreshing,
  initialError,
  refreshError,
  zero,
  emptyResult,
}

enum _PaginationFixture { cursor, keyset, progressive, unknownTotal }

final collectionKernelComponent = WidgetbookComponent(
  name: 'Collection Kernel',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final scenario = context.knobs.object.dropdown(
    label: 'Snapshot · Scenario',
    options: _CollectionScenario.values,
    initialOption: _CollectionScenario.refreshing,
    labelBuilder: semanticValueLabel,
  );
  final pagination = context.knobs.object.segmented(
    label: 'Pagination · Contract',
    options: _PaginationFixture.values,
    labelBuilder: semanticValueLabel,
  );
  final selectionMode = context.knobs.object.segmented(
    label: 'Selection · Mode',
    options: CollectionSelectionMode.values,
    initialOption: CollectionSelectionMode.multiple,
    labelBuilder: semanticValueLabel,
  );
  final optimistic = context.knobs.boolean(
    label: 'Mutation · Optimistic',
    initialValue: true,
  );
  final snapshot = _snapshot(scenario, pagination);
  final selection = _selection(selectionMode);
  final mutation = optimistic
      ? CollectionMutationState<int>().running([2], optimistic: true)
      : CollectionMutationState<int>();

  return preview(
    SizedBox(
      width: 520,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterStatusIndicator(
            label: semanticValueLabel(scenario),
            role:
                snapshot.initialFailure != null ||
                    snapshot.refreshFailure != null
                ? FeedbackColorRole.danger
                : snapshot.isRefreshing
                ? FeedbackColorRole.info
                : FeedbackColorRole.neutral,
          ),
          const SizedBox(height: 12),
          CarpenterText.body('Items retained: ${snapshot.items.length}'),
          CarpenterText.body(
            'Load: ${semanticValueLabel(snapshot.loadPhase)} · '
            'Freshness: ${semanticValueLabel(snapshot.freshness)}',
          ),
          CarpenterText.body(
            'Pagination: ${snapshot.pageInfo.runtimeType} · '
            'total: ${snapshot.pageInfo.totalItems ?? 'unknown'}',
          ),
          CarpenterText.body(
            'Selection: ${semanticValueLabel(selection.mode)} · '
            'keys: ${selection.selectedKeys.join(', ')}',
          ),
          CarpenterText.body(
            'Mutation: ${semanticValueLabel(mutation.phase)} · '
            'reconciliation: ${semanticValueLabel(mutation.reconciliation)}',
          ),
        ],
      ),
    ),
  );
}

CollectionSnapshot<String> _snapshot(
  _CollectionScenario scenario,
  _PaginationFixture pagination,
) {
  final pageInfo = switch (pagination) {
    _PaginationFixture.cursor => const CollectionCursorPageInfo(
      itemCount: 3,
      nextCursor: 'opaque-next',
    ),
    _PaginationFixture.keyset => const CollectionKeysetPageInfo<int>(
      itemCount: 3,
      nextKey: 103,
    ),
    _PaginationFixture.progressive => const CollectionProgressivePageInfo(
      loadedItems: 3,
      hasMore: true,
      totalItems: 30,
    ),
    _PaginationFixture.unknownTotal => const CollectionOffsetPageInfo(
      offset: 0,
      limit: 3,
      itemCount: 3,
      moreAvailable: true,
    ),
  };
  const items = ['Alpha', 'Beta', 'Gamma'];
  return switch (scenario) {
    _CollectionScenario.initialLoading =>
      CollectionSnapshot<String>.initialLoading(),
    _CollectionScenario.loaded => CollectionSnapshot<String>(
      items: items,
      pageInfo: pageInfo,
    ),
    _CollectionScenario.refreshing => CollectionSnapshot<String>(
      items: items,
      loadPhase: CollectionLoadPhase.refreshing,
      freshness: CollectionFreshness.stale,
      pageInfo: pageInfo,
    ),
    _CollectionScenario.initialError => CollectionSnapshot<String>(
      initialFailure: const CollectionFailure(
        error: 'network',
        message: 'Initial load failed',
      ),
    ),
    _CollectionScenario.refreshError => CollectionSnapshot<String>(
      items: items,
      freshness: CollectionFreshness.stale,
      refreshFailure: const CollectionFailure(
        error: 'network',
        message: 'Refresh failed; data retained',
      ),
      pageInfo: pageInfo,
    ),
    _CollectionScenario.zero => CollectionSnapshot<String>(
      contentState: CollectionContentState.zero,
    ),
    _CollectionScenario.emptyResult => CollectionSnapshot<String>(
      contentState: CollectionContentState.emptyResult,
    ),
  };
}

CollectionSelection<int> _selection(CollectionSelectionMode mode) =>
    switch (mode) {
      CollectionSelectionMode.none => CollectionSelection<int>.none(),
      CollectionSelectionMode.single => CollectionSelection<int>.single(1),
      CollectionSelectionMode.multiple => CollectionSelection<int>.multiple([
        1,
        101,
      ]),
      CollectionSelectionMode.allMatching =>
        CollectionSelection<int>.allMatching([7]),
    };
