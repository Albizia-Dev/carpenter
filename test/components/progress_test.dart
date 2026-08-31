import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('progress exposes determinate semantics', (tester) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterProgress(
          value: .42,
          semanticLabel: 'Upload progress',
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(CarpenterProgress));
    expect(semantics.label, 'Upload progress');
    expect(semantics.value, '42%');
  });

  testWidgets('progress supports indeterminate mode', (tester) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterProgress(semanticLabel: 'Loading results'),
      ),
    );

    expect(find.byType(CarpenterProgress), findsOneWidget);
    final semantics = tester.getSemantics(find.byType(CarpenterProgress));
    expect(semantics.label, 'Loading results');
    expect(semantics.value, isEmpty);

    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });
}
