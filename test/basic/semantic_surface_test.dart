import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('feedback card and text resolve the same semantic palette', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterCard.feedback(
          role: FeedbackColorRole.warning,
          child: CarpenterText.feedback(
            'Review required',
            feedbackRole: FeedbackColorRole.warning,
          ),
        ),
      ),
    );

    final context = tester.element(find.text('Review required'));
    final feedback = CarpenterTheme.of(
      context,
    ).feedback.resolve(FeedbackColorRole.warning);
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(CarpenterCard),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decorated.decoration as BoxDecoration;
    final text = tester.widget<Text>(find.text('Review required'));

    expect(decoration.color, feedback.background);
    expect((decoration.border! as Border).top.color, feedback.foreground);
    expect(text.style?.color, feedback.foreground);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card surface roles resolve without raw color overrides', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const Column(
          children: [
            CarpenterCard(
              surfaceRole: CarpenterCardSurfaceRole.base,
              child: Text('Base'),
            ),
            CarpenterCard(
              surfaceRole: CarpenterCardSurfaceRole.subtle,
              child: Text('Subtle'),
            ),
          ],
        ),
      ),
    );

    final theme = CarpenterTheme.of(tester.element(find.text('Base')));
    final decorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(CarpenterCard),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration as BoxDecoration)
        .toList();

    expect(decorations[0].color, theme.surface.base);
    expect(decorations[1].color, theme.surface.subtle);
    expect(tester.takeException(), isNull);
  });
}
