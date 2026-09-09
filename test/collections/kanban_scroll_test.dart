import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  Widget board({bool bounded = true}) {
    final kanban = CarpenterKanban<String, int>(
      columns: [
        CarpenterKanbanColumn(
          id: 'todo',
          value: 'todo',
          title: 'To do',
          cards: List.generate(30, (i) => i),
        ),
        const CarpenterKanbanColumn(id: 'done', value: 'done', title: 'Done'),
      ],
      cardKey: (card) => card,
      cardBuilder: (_, card, _) =>
          SizedBox(height: 60, child: Text('Card $card')),
    );
    return carpenterHarness(
      bounded
          ? SizedBox(height: 300, child: kanban)
          : SingleChildScrollView(child: kanban),
    );
  }

  testWidgets(
    'bounded columns scroll below a fixed heading and retain offset',
    (tester) async {
      await tester.pumpWidget(board());
      expect(tester.takeException(), isNull);
      final heading = tester.getTopLeft(find.text('To do'));
      final list = find.byType(ListView).first;
      await tester.drag(list, const Offset(0, -250));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('To do')), heading);
      final position = tester
          .state<ScrollableState>(
            find.descendant(of: list, matching: find.byType(Scrollable)),
          )
          .position;
      expect(position.pixels, greaterThan(0));
      final offset = position.pixels;
      await tester.pumpWidget(board());
      expect(position.pixels, offset);
      position.jumpTo(position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(find.text('Card 29').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unbounded board lets its parent scroll all content', (
    tester,
  ) async {
    await tester.pumpWidget(board(bounded: false));
    expect(tester.takeException(), isNull);
    expect(find.byType(ListView), findsNothing);
    expect(
      tester.getSize(find.byType(CarpenterKanban<String, int>)).height,
      greaterThan(1800),
    );
  });
}
