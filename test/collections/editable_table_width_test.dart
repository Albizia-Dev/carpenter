import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('frozen editor retains position and focus in $direction', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Project 104');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        carpenterHarness(
          Directionality(
            textDirection: direction,
            child: Center(
              child: SizedBox(
                width: 500,
                child: CarpenterEditableTable<String>(
                  freezeFirstColumn: true,
                  items: const ['row'],
                  minimumWidth: const Px(300),
                  columns: [
                    CarpenterTableColumn<String>.custom(
                      id: 'name',
                      header: 'Project',
                      width: const CarpenterTableColumnWidth.fixed(
                        width: Px(200),
                      ),
                      cellBuilder: (_, item) =>
                          CarpenterInput(controller: controller),
                    ),
                    for (var i = 1; i < 3; i++)
                      CarpenterTableColumn<String>.text(
                        id: '$i',
                        header: 'Column $i',
                        width: const CarpenterTableColumnWidth.fixed(
                          width: Px(240),
                        ),
                        value: (_) => 'Value $i',
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final field = find.byType(EditableText);
      final before = tester.getTopLeft(field);
      final scroll = tester
          .stateList<ScrollableState>(find.byType(Scrollable))
          .firstWhere(
            (state) =>
                state.position.axis == Axis.horizontal &&
                state.position.maxScrollExtent > 0,
          );
      scroll.position.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      expect((tester.getTopLeft(field) - before).distance, lessThan(.1));
      expect(field, findsOneWidget);
      await tester.tap(field);
      await tester.enterText(field, 'Updated project');
      expect(controller.text, 'Updated project');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'fixed columns wider than minimum remain horizontally reachable',
    (tester) async {
      await tester.pumpWidget(
        carpenterHarness(
          Center(
            child: SizedBox(
              width: 400,
              child: CarpenterEditableTable<String>(
                minimumWidth: const Px(300),
                items: const ['row'],
                columns: [
                  for (var i = 0; i < 3; i++)
                    CarpenterTableColumn<String>.text(
                      id: '$i',
                      header: 'Column $i',
                      value: (_) => 'Value $i',
                      width: const CarpenterTableColumnWidth.fixed(
                        width: Px(240),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final scroll = find.byType(SingleChildScrollView);
      expect(scroll, findsOneWidget);
      await tester.drag(scroll, const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Value 2').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
