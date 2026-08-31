import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('tree flattening follows controlled expansion', () {
    const roots = <CarpenterTreeNode<String>>[
      CarpenterTreeNode<String>(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [
          CarpenterTreeNode<String>(
            id: 'child',
            value: 'child',
            label: 'Child',
          ),
        ],
      ),
    ];

    expect(flattenCarpenterTree(roots, const {}).length, 1);
    final expanded = flattenCarpenterTree(roots, const {'root'});
    expect(expanded.map((entry) => entry.node.id), ['root', 'child']);
    expect(carpenterTreeContains(roots.first, 'child'), isTrue);
  });

  testWidgets('tree delegates expansion and selection', (tester) async {
    Object? expandedId;
    bool? expandedValue;
    Set<Object>? selection;
    const roots = <CarpenterTreeNode<String>>[
      CarpenterTreeNode<String>(
        id: 'root',
        value: 'root',
        label: 'Root',
        children: [
          CarpenterTreeNode<String>(
            id: 'child',
            value: 'child',
            label: 'Child',
          ),
        ],
      ),
    ];

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeView<String>(
          nodes: roots,
          onExpansionChanged: (id, expanded) {
            expandedId = id;
            expandedValue = expanded;
          },
          onSelectionChanged: (ids) => selection = ids,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Expand Root'));
    expect(expandedId, 'root');
    expect(expandedValue, isTrue);

    await tester.tap(find.text('Root'));
    expect(selection, {'root'});
  });

  testWidgets('drag feedback preserves source geometry', (tester) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 320,
          child: CarpenterReorderableCollection<String>(
            items: const ['A', 'B'],
            itemKey: (item) => item,
            onReorder: (_) {},
            itemBuilder: (context, item, state) => SizedBox(
              key: ValueKey<String>('geometry-$item'),
              height: 48,
              child: CarpenterCard(child: CarpenterText.label(item)),
            ),
          ),
        ),
      ),
    );

    final item = find.byKey(const ValueKey<String>('geometry-A'));
    final sourceSize = tester.getSize(item);
    final gesture = await tester.startGesture(tester.getCenter(item));
    await tester.pump();

    expect(item, findsNWidgets(2));
    final renderedSizes = item.evaluate().map((element) {
      final renderObject = element.renderObject;
      expect(renderObject, isA<RenderBox>());
      return (renderObject! as RenderBox).size;
    });
    expect(renderedSizes, everyElement(sourceSize));

    await gesture.up();
    await tester.pump();
  });

  testWidgets('reorderable collection emits controlled movement', (
    tester,
  ) async {
    CarpenterReorderDetails<String>? movement;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterReorderableCollection<String>(
          items: const ['A', 'B', 'C'],
          itemKey: (item) => item,
          onReorder: (details) => movement = details,
          itemBuilder: (context, item, state) => SizedBox(
            height: 56,
            child: CarpenterCard(child: CarpenterText.label(item)),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(find.text('A')));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(find.text('C')));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(movement, isNotNull);
    expect(movement!.item, 'A');
    expect(movement!.oldIndex, 0);
    expect(movement!.newIndex, greaterThan(0));
  });

  testWidgets('kanban accepts drops across the full empty column', (
    tester,
  ) async {
    final group = Object();
    CarpenterKanbanMoveDetails<String, String>? movement;
    const source = CarpenterKanbanColumn<String, String>(
      id: 'source',
      value: 'source',
      title: 'Source',
      cards: ['Source card'],
    );
    const target = CarpenterKanbanColumn<String, String>(
      id: 'target',
      value: 'target',
      title: 'Target',
    );

    Widget cardBuilder(
      BuildContext context,
      String card,
      CarpenterKanbanCardState<String> state,
    ) => SizedBox(
      height: 48,
      child: CarpenterCard(child: CarpenterText.label(card)),
    );

    await tester.pumpWidget(
      carpenterOverlayHarness(
        Column(
          children: [
            CarpenterKanban<String, String>(
              columns: const [source],
              cardKey: (card) => card,
              cardBuilder: cardBuilder,
              dragGroupId: group,
              onMove: (_) {},
            ),
            CarpenterKanban<String, String>(
              columns: const [target],
              cardKey: (card) => card,
              cardBuilder: cardBuilder,
              dragGroupId: group,
              onMove: (details) => movement = details,
            ),
          ],
        ),
      ),
    );

    final targetColumn = find.byKey(
      const ValueKey<String>('kanban.column.target.drop'),
    );
    expect(tester.getSize(targetColumn).height, greaterThan(0));

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Source card')),
    );
    await tester.pump();
    await gesture.moveTo(tester.getCenter(targetColumn));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(movement, isNotNull);
    expect(movement!.card, 'Source card');
    expect(movement!.sourceColumn.id, 'source');
    expect(movement!.targetColumn.id, 'target');
    expect(movement!.targetIndex, 0);
  });

  testWidgets('kanban renders empty columns and planning lanes collapse', (
    tester,
  ) async {
    Object? laneId;
    bool? expanded;
    const columns = <CarpenterKanbanColumn<String, String>>[
      CarpenterKanbanColumn<String, String>(
        id: 'todo',
        value: 'todo',
        title: 'To do',
        cards: ['Task'],
      ),
      CarpenterKanbanColumn<String, String>(
        id: 'done',
        value: 'done',
        title: 'Done',
      ),
    ];

    await tester.pumpWidget(
      carpenterHarness(
        CarpenterPlanningBoard<String, String, String>(
          lanes: const [
            CarpenterPlanningLane<String, String, String>(
              id: 'lane',
              value: 'lane',
              title: 'Sprint',
              columns: columns,
            ),
          ],
          cardKey: (card) => card,
          cardBuilder: (context, card, state) =>
              CarpenterCard(child: CarpenterText.label(card)),
          onLaneExpansionChanged: (id, value) {
            laneId = id;
            expanded = value;
          },
        ),
      ),
    );

    expect(find.text('No cards'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Collapse Sprint'));
    expect(laneId, 'lane');
    expect(expanded, isFalse);
  });
}
