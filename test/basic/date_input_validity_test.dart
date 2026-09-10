import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  testWidgets(
    'validity precedes accepted dates; partial and impossible edits keep the value',
    (tester) async {
      final events = <Object?>[];
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterDateInput(
            value: DateTime(2026, 9, 10),
            firstDate: DateTime(2026),
            lastDate: DateTime(2026, 12, 31),
            onInputValidityChanged: events.add,
            onChanged: (value) => events.add(value),
          ),
        ),
      );
      expect(events, isEmpty);
      final input = find.byType(EditableText);
      await tester.enterText(input, '12');
      expect(events, [false]);
      events.clear();
      await tester.enterText(input, '31.02.2026');
      expect(events, [false]);
      events.clear();
      await tester.enterText(input, '10.09.2025');
      expect(events, [false]);
      events.clear();
      await tester.enterText(input, '11.09.2026');
      expect(events, [true, DateTime(2026, 9, 11)]);
      events.clear();
      await tester.enterText(input, '');
      expect(events, [true, null]);
    },
  );

  testWidgets('required empty input is invalid', (tester) async {
    final valid = <bool>[];
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterDateInput(
          value: DateTime(2026),
          required: true,
          onChanged: (_) {},
          onInputValidityChanged: valid.add,
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), '');
    expect(valid, [false]);
  });
}
