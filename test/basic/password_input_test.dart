import 'package:flutter/services.dart';
import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets(
    'input forwards capitalization and keeps units outside edited value',
    (tester) async {
      final controller = TextEditingController(text: '123');
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterInput(
            controller: controller,
            suffixText: 'RUB',
            textCapitalization: TextCapitalization.characters,
          ),
        ),
      );
      expect(find.text('RUB'), findsOneWidget);
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .textCapitalization,
        TextCapitalization.characters,
      );
      expect(controller.text, '123');
    },
  );

  testWidgets('password visibility is controlled without leaking semantics', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Secret42');
    addTearDown(controller.dispose);
    var hidden = true;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterInput(
              controller: controller,
              label: 'Password',
              obscureText: hidden,
            );
          },
        ),
      ),
    );
    var editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.obscureText, isTrue);
    expect(editor.autocorrect, isFalse);
    expect(editor.enableSuggestions, isFalse);
    for (final element in find.byType(Semantics).evaluate()) {
      expect((element.widget as Semantics).properties.value, isNot('Secret42'));
    }
    await tester.enterText(find.byType(EditableText), 'Changed42');
    expect(controller.text, 'Changed42');
    update(() => hidden = false);
    await tester.pump();
    editor = tester.widget<EditableText>(find.byType(EditableText));
    expect(editor.obscureText, isFalse);
    expect(controller.text, 'Changed42');
    expect(tester.takeException(), isNull);
  });
}
