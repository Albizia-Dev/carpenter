import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('edits multiline content with configured line bounds', (
    tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTextArea(
          controller: controller,
          label: 'Notes',
          minLines: 2,
          maxLines: 4,
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), 'First\nSecond');
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(controller.text, 'First\nSecond');
    expect(editable.minLines, 2);
    expect(editable.maxLines, 4);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      matchesSemantics(
        label: 'Notes',
        isTextField: true,
        isMultiline: true,
        hasEnabledState: true,
        isEnabled: true,
      ),
    );

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('readOnly and disabled multiline fields do not mutate', (
    tester,
  ) async {
    for (final availability in [
      FieldAvailability.readOnly,
      FieldAvailability.disabled,
    ]) {
      final controller = TextEditingController(text: 'Stable');
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterTextArea(
            controller: controller,
            label: availability.name,
            availability: availability,
          ),
        ),
      );
      await tester.tap(find.byType(EditableText), warnIfMissed: false);
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(controller.text, 'Stable');
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    }
  });

  testWidgets('handles error, RTL, and 200% text in dark high contrast', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'سطر أول\nسطر ثان');
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTextArea(
          controller: controller,
          label: 'التفاصيل',
          errorText: 'مطلوب',
          required: true,
          minLines: 3,
          maxLines: null,
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(find.text('مطلوب'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
