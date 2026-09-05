import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('warning feedback drives border and supporting text', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterFieldShell(
          availability: FieldAvailability.enabled,
          size: FieldSize.medium,
          shape: CarpenterShape.rounded,
          states: {},
          feedback: CarpenterFieldFeedback.warning('Check this value'),
          child: Text('Value'),
        ),
      ),
    );

    final context = tester.element(find.text('Value'));
    final warning = CarpenterTheme.of(
      context,
    ).feedback.resolve(FeedbackColorRole.warning);
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(CarpenterFieldShell),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    final supporting = tester.widget<Text>(find.text('Check this value'));

    expect((decoration.border! as Border).top.color, warning.foreground);
    expect(supporting.style?.color, warning.foreground);
    expect(tester.takeException(), isNull);
  });

  testWidgets('errorText remains the strongest compatibility feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterFieldShell(
          availability: FieldAvailability.enabled,
          size: FieldSize.medium,
          shape: CarpenterShape.rounded,
          states: {},
          feedback: CarpenterFieldFeedback.success('Looks good'),
          errorText: 'Invalid value',
          child: Text('Value'),
        ),
      ),
    );

    final context = tester.element(find.text('Value'));
    final fieldError = CarpenterTheme.of(context).fields.borderError;
    final container = tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(CarpenterFieldShell),
        matching: find.byType(AnimatedContainer),
      ),
    );
    final decoration = container.decoration as BoxDecoration;

    expect(find.text('Invalid value'), findsOneWidget);
    expect(find.text('Looks good'), findsNothing);
    expect((decoration.border! as Border).top.color, fieldError);
    expect(tester.takeException(), isNull);
  });

  testWidgets('input and select accept the same feedback contract', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Draft');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      carpenterHarness(
        Column(
          children: [
            CarpenterInput(
              controller: controller,
              feedback: const CarpenterFieldFeedback.info('Saved remotely'),
            ),
            CarpenterSelect<int>(
              value: 1,
              onChanged: (_) {},
              options: const [CarpenterOption(id: 1, value: 1, label: 'One')],
              feedback: const CarpenterFieldFeedback.success('Ready'),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Saved remotely'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
