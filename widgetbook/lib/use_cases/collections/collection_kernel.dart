import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/collection_fixtures.dart';
import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final collectionKernelComponent = WidgetbookComponent(
  name: 'Collection Kernel',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final scenario = context.knobs.object.dropdown(
    label: 'Snapshot · Scenario',
    options: DemoCollectionScenario.values,
    initialOption: DemoCollectionScenario.refreshing,
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
  final optimistic = context.knobs.boolean(
    label: 'Mutation · Optimistic',
    initialValue: true,
  );
  final snapshot = demoCollectionSnapshot<String>(
    items: const ['Alpha', 'Beta', 'Gamma'],
    scenario: scenario,
    pagination: pagination,
  );
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
                : snapshot.isRefreshing ||
                      snapshot.loadPhase == CollectionLoadPhase.loadingMore
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
