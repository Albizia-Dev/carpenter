import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('tree row actions may omit icons', (tester) async {
    var invoked = false;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeView<String>(
          nodes: const [
            CarpenterTreeNode<String>(id: 'root', value: 'root', label: 'Root'),
          ],
          actions: (_) => [
            CarpenterActionDescriptor(
              id: 'inspect',
              label: 'Inspect',
              onInvoke: () => invoked = true,
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Inspect'), findsOneWidget);
    await tester.tap(find.text('Inspect'));
    expect(invoked, isTrue);
  });
}
