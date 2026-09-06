import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('progress is indeterminate when value is omitted', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const SizedBox(
          width: 240,
          child: CarpenterProgress(semanticLabel: 'Background work'),
        ),
      ),
    );

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Background work'),
    );
    expect(semantics.value, isEmpty);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'progress exposes determinate percentage when value is supplied',
    (tester) async {
      await tester.pumpWidget(
        carpenterHarness(
          const SizedBox(
            width: 240,
            child: CarpenterProgress(
              value: .42,
              semanticLabel: 'Background work',
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.bySemanticsLabel('Background work')).value,
        '42%',
      );
    },
  );
}
