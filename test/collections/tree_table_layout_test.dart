import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('tree table uses chevrons and resizes without a callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeTable<String>(
          nodes: const [
            CarpenterTreeNode<String>(
              id: 'root',
              value: 'root',
              label: 'Root',
              children: [
                CarpenterTreeNode<String>(
                  id: 'child',
                  value: 'child',
                  label: 'Child',
                ),
              ],
            ),
          ],
          treeWidth: const CarpenterTableColumnWidth.fixed(
            width: Px(180),
            minimum: Px(120),
            maximum: Px(280),
          ),
        ),
      ),
    );

    final chevron = tester.widget<CarpenterIconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is CarpenterIconButton &&
            widget.semanticLabel == 'Expand Root',
      ),
    );
    expect(chevron.icon, GravityIcons.chevronRight);

    final handle = find.byKey(const ValueKey('tree-table-resize-tree'));
    expect(handle, findsOneWidget);
    final before = tester.getCenter(handle).dx;
    await tester.drag(handle, const Offset(40, 0));
    await tester.pump();
    expect(tester.getCenter(handle).dx, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree table secondary row actions use the ellipsis lane', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeTable<String>(
          nodes: const [
            CarpenterTreeNode<String>(id: 'root', value: 'root', label: 'Root'),
          ],
          actions: (_) => const [],
          secondaryActions: (_) => [
            const CarpenterActionDescriptor(
              id: 'archive',
              label: 'Archive',
              onInvoke: null,
            ),
          ],
        ),
      ),
    );

    expect(find.text('Archive'), findsNothing);
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('tree table reserves the action lane for every row', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTreeTable<String>(
          nodes: const [
            CarpenterTreeNode<String>(id: 'a', value: 'a', label: 'A'),
            CarpenterTreeNode<String>(id: 'b', value: 'b', label: 'B'),
          ],
          columns: [
            CarpenterTreeTableColumn<String>(
              id: 'value',
              header: 'Value',
              cellBuilder: (_, node) =>
                  CarpenterTableText.cell('value-${node.label}'),
            ),
          ],
          actions: (node) => node.id == 'a'
              ? [
                  const CarpenterActionDescriptor(
                    id: 'inspect',
                    label: 'Inspect',
                    onInvoke: null,
                  ),
                ]
              : const [],
        ),
      ),
    );

    expect(
      tester.getTopLeft(find.text('value-A')).dx,
      tester.getTopLeft(find.text('value-B')).dx,
    );
    expect(tester.takeException(), isNull);
  });
}
