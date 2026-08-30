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

  testWidgets('reorderable collection emits controlled movement', (
    tester,
  ) async {
    CarpenterReorderDetails<String>? movement;
    await tester.pumpWidget(
      carpenterHarness(
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
