import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/internal/selection/menu_panel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  testWidgets(
    'search selects by id, preserves previous values and removes one',
    (tester) async {
      var selected = <CarpenterOption<int>>[
        const CarpenterOption(id: 1, value: 1, label: 'Existing'),
      ];
      var query = '';
      await tester.pumpWidget(
        carpenterOverlayHarness(
          StatefulBuilder(
            builder: (_, update) => CarpenterMultiSelect<int>(
              values: selected,
              suggestions: [
                for (var i = 1; i <= 500; i++)
                  if ('Entity $i'.contains(query))
                    CarpenterOption(id: i, value: i, label: 'Entity $i'),
              ],
              onQueryChanged: (value) => update(() => query = value),
              onChanged: (value) => update(() => selected = value),
            ),
          ),
        ),
      );
      await tester.enterText(find.byType(EditableText), 'Entity 499');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected.map((value) => value.id), [1, 499]);
      expect(query, isEmpty);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).controller.text,
        isEmpty,
      );
      await tester.tap(find.text('Existing'));
      await tester.pumpAndSettle();
      expect(selected.map((value) => value.id), [499]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('large result set is bounded and selected ids are excluded', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterMultiSelect<int>(
          values: const [CarpenterOption(id: 1, value: 1, label: 'Selected')],
          suggestions: [
            for (var i = 1; i <= 500; i++)
              CarpenterOption(id: i, value: i, label: 'Entity $i'),
          ],
          onQueryChanged: (_) {},
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pumpAndSettle();
    final entries = tester.widget<MenuPanel>(find.byType(MenuPanel)).entries;
    expect(entries.length, 20);
    expect(entries.any((entry) => entry.id == 1), isFalse);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuPanel), findsNothing);
  });

  testWidgets('read only values cannot be removed or searched', (tester) async {
    var changes = 0;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterMultiSelect<int>(
          values: const [CarpenterOption(id: 1, value: 1, label: 'Selected')],
          suggestions: const [],
          availability: FieldAvailability.readOnly,
          onQueryChanged: (_) => changes++,
          onChanged: (_) => changes++,
        ),
      ),
    );
    await tester.tap(find.text('Selected'));
    await tester.pumpAndSettle();
    expect(changes, 0);
    expect(find.byType(MenuPanel), findsNothing);
  });
}
