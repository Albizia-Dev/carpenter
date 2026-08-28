import 'package:carpenter/carpenter.dart';
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
}
