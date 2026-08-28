import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';

enum _ListScenario { loaded, loading, refreshing, error, empty }

final dataListComponent = WidgetbookComponent(
  name: 'Data List',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final count = context.knobs.int.slider(
    label: 'Collection · Items',
    initialValue: 8,
    min: 0,
    max: 30,
  );
  final scenario = context.knobs.object.segmented(
    label: 'Collection · State',
    options: _ListScenario.values,
    labelBuilder: semanticValueLabel,
  );
  final selectable = context.knobs.boolean(
    label: 'Selection · Enabled',
    initialValue: true,
  );
  return SizedBox(
    height: context.units(32.5.rem),
    child: _DataListPreview(
      count: count,
      scenario: scenario,
      selectable: selectable,
    ),
  );
}

final class _DataListPreview extends StatefulWidget {
  const _DataListPreview({
    required this.count,
    required this.scenario,
    required this.selectable,
  });

  final int count;
  final _ListScenario scenario;
  final bool selectable;

  @override
  State<_DataListPreview> createState() => _DataListPreviewState();
}

final class _DataListPreviewState extends State<_DataListPreview> {
  var _selection = CollectionSelection<int>.single();

  CollectionSnapshot<int> get _snapshot {
    final items = List.generate(widget.count, (index) => index + 1);
    return switch (widget.scenario) {
      _ListScenario.loaded => CollectionSnapshot(items: items),
      _ListScenario.loading => CollectionSnapshot.initialLoading(),
      _ListScenario.refreshing => CollectionSnapshot(
        items: items,
        loadPhase: CollectionLoadPhase.refreshing,
        freshness: CollectionFreshness.stale,
      ),
      _ListScenario.error => CollectionSnapshot(
        initialFailure: const CollectionFailure(error: 'Demo failure'),
      ),
      _ListScenario.empty => CollectionSnapshot(
        contentState: CollectionContentState.emptyResult,
      ),
    };
  }

  @override
  Widget build(BuildContext context) => CarpenterDataList<int, int>(
    snapshot: _snapshot,
    itemKey: (item) => item,
    itemSemanticLabel: (item) => 'Record $item',
    itemBuilder: (context, item) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CarpenterText.label(
          'Record $item',
          emphasis: TypographyEmphasis.strong,
        ),
        const CarpenterText.caption(
          'Structured item content belongs to the consumer.',
          colorRole: ContentColorRole.secondary,
        ),
      ],
    ),
    selection: widget.selectable ? _selection : CollectionSelection<int>.none(),
    onSelectionChanged: widget.selectable
        ? (value) => setState(() => _selection = value)
        : null,
  );
}
