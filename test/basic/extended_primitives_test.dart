import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('number input emits typed decimal values', (tester) async {
    num? value;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterNumberInput(
          value: null,
          onChanged: (next) => value = next,
          label: 'Amount',
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '12,5');
    expect(value, 12.5);
  });

  testWidgets('number input reports range errors without emitting', (
    tester,
  ) async {
    num? value = 5;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterNumberInput(
          value: value,
          onChanged: (next) => value = next,
          min: 0,
          max: 10,
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText), '99');
    expect(find.text('Maximum is 10'), findsOneWidget);
    expect(value, 5);
  });

  testWidgets('badge count caps and avatar group exposes overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const Column(
          children: [
            CarpenterBadge.count(140),
            CarpenterAvatarGroup(
              maxVisible: 2,
              items: [
                CarpenterAvatarItem(initials: 'AA'),
                CarpenterAvatarItem(initials: 'BB'),
                CarpenterAvatarItem(initials: 'CC'),
                CarpenterAvatarItem(initials: 'DD'),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('99+'), findsOneWidget);
    expect(find.text('+2'), findsOneWidget);
  });

  testWidgets('time and range inputs expose formatted controlled values', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        Column(
          children: [
            CarpenterTimeInput(
              value: const CarpenterTime(hour: 14, minute: 30),
              onChanged: (_) {},
            ),
            CarpenterDateRangeInput(
              value: CarpenterDateRange(
                start: DateTime(2026, 9, 1),
                end: DateTime(2026, 9, 12),
              ),
              onChanged: (_) {},
            ),
          ],
        ),
      ),
    );

    expect(find.text('14:30'), findsOneWidget);
    expect(find.text('01.09.2026 – 12.09.2026'), findsOneWidget);
  });
}
