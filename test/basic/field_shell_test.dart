import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('field shell owns label, required marker, and supporting state', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterFieldShell(
          availability: FieldAvailability.enabled,
          size: FieldSize.medium,
          shape: CarpenterShape.rounded,
          states: {WidgetState.error},
          label: 'Amount',
          description: 'Supporting text',
          errorText: 'Invalid amount',
          required: true,
          child: Text('100'),
        ),
      ),
    );

    expect(find.text('Amount', findRichText: true), findsOneWidget);
    expect(find.text('Invalid amount'), findsOneWidget);
    expect(find.text('Supporting text'), findsNothing);
    expect(find.text('100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
