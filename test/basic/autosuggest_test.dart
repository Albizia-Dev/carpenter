import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/internal/selection/menu_panel.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('free query stays editable and selection replaces query', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];
    CarpenterOption<int>? selected;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterAutosuggest<int>(
          controller: controller,
          onQueryChanged: queries.add,
          onSuggestionSelected: (option) => selected = option,
          open: true,
          onOpenChanged: (_) {},
          suggestions: const [
            CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
          ],
          autofocus: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'arbitrary');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(queries, contains('arbitrary'));
    expect(selected?.id, 'a');
    expect(controller.text, 'Alpha');
  });

  testWidgets(
    'pointer selection retains editing focus and keeps the popup closed',
    (tester) async {
      final controller = TextEditingController();
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);
      final visibility = <bool>[];
      CarpenterOption<int>? selected;

      await tester.pumpWidget(
        carpenterOverlayHarness(
          CarpenterAutosuggest<int>(
            controller: controller,
            focusNode: focusNode,
            onQueryChanged: (_) {},
            onSuggestionSelected: (option) => selected = option,
            onOpenChanged: visibility.add,
            suggestions: const [
              CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
              CarpenterOption(id: 'b', value: 2, label: 'Bravo'),
            ],
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);
      expect(find.byType(MenuPanel), findsOneWidget);

      await tester.tap(find.text('Bravo').last);
      await tester.pumpAndSettle();

      expect(selected?.id, 'b');
      expect(controller.text, 'Bravo');
      expect(visibility.last, isFalse);
      expect(find.byType(MenuPanel), findsNothing);
      expect(focusNode.hasFocus, isTrue);

      await tester.enterText(find.byType(EditableText), 'Br');
      await tester.pumpAndSettle();
      expect(find.byType(MenuPanel), findsOneWidget);
    },
  );
}
