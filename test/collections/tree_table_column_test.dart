import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('semantic tree column factories share table width defaults', () {
    final text = CarpenterTreeTableColumn<String>.text(
      id: 'text',
      header: 'Text',
      value: (node) => node.label,
    );
    final number = CarpenterTreeTableColumn<String>.number(
      id: 'number',
      header: 'Number',
      value: (_) => 12,
    );
    final status = CarpenterTreeTableColumn<String>.status(
      id: 'status',
      header: 'Status',
      label: (_) => 'Ready',
      role: (_) => FeedbackColorRole.success,
    );

    expect(text.effectiveWidth.policy, CarpenterTableColumnWidthPolicy.flexible);
    expect(number.effectiveWidth.policy, CarpenterTableColumnWidthPolicy.flexible);
    expect(status.effectiveWidth.policy, CarpenterTableColumnWidthPolicy.flexible);
    expect(number.alignment, CarpenterTableColumnAlignment.end);
    expect(text.resizable, isTrue);
    expect(status.resizable, isTrue);
  });

  testWidgets('semantic tree column factories render shared table primitives', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeTable<String>(
          nodes: const [
            CarpenterTreeNode<String>(id: 'root', value: 'root', label: 'Root'),
          ],
          columns: [
            CarpenterTreeTableColumn<String>.text(
              id: 'text',
              header: 'Text',
              value: (node) => 'Value ${node.label}',
            ),
            CarpenterTreeTableColumn<String>.number(
              id: 'number',
              header: 'Number',
              value: (_) => 12.5,
              formatter: (value) => value.toStringAsFixed(1),
            ),
            CarpenterTreeTableColumn<String>.status(
              id: 'status',
              header: 'Status',
              label: (_) => 'Ready',
              role: (_) => FeedbackColorRole.success,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Value Root'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.byType(CarpenterStatusIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
