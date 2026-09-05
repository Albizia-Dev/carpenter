import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('tree table widths are cell-box widths without hidden gaps', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        SizedBox(
          width: 420,
          child: CarpenterTreeTable<String>(
            framed: false,
            nodes: const [
              CarpenterTreeNode<String>(
                id: 'root',
                value: 'root',
                label: 'Root',
              ),
            ],
            treeResizable: false,
            treeWidth: const CarpenterTableColumnWidth.fixed(
              width: Px(180),
              minimum: Px(180),
              maximum: Px(180),
            ),
            columns: [
              CarpenterTreeTableColumn<String>.text(
                id: 'value',
                header: 'Value',
                value: (_) => 'Cell value',
                resizable: false,
                width: const CarpenterTableColumnWidth.fixed(
                  width: Px(120),
                  minimum: Px(120),
                  maximum: Px(120),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final treeHeaderX = tester.getTopLeft(find.text('Name')).dx;
    final valueHeaderX = tester.getTopLeft(find.text('Value')).dx;
    final valueCellX = tester.getTopLeft(find.text('Cell value')).dx;

    expect(valueHeaderX - treeHeaderX, closeTo(180, 0.1));
    expect(valueCellX, closeTo(valueHeaderX, 0.1));
    expect(tester.takeException(), isNull);
  });
}
