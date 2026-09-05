import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test(
    'tree custom columns use the same explicit width contract as tables',
    () {
      final column = CarpenterTreeTableColumn<String>.custom(
        id: 'value',
        header: 'Value',
        cellBuilder: (_, node) => Text(node.label),
      );

      expect(column.width, isNotNull);
      expect(
        column.effectiveWidth.policy,
        CarpenterTableColumnWidthPolicy.flexible,
      );
      expect(column.effectiveWidth.flex, 1);
    },
  );

  test('legacy tree flex still resolves through the compatibility path', () {
    const column = CarpenterTreeTableColumn<String>(
      id: 'legacy',
      header: 'Legacy',
      flex: 3,
      cellBuilder: _legacyTreeCell,
    );

    expect(column.width, isNull);
    expect(
      column.effectiveWidth.policy,
      CarpenterTableColumnWidthPolicy.flexible,
    );
    expect(column.effectiveWidth.flex, 3);
  });
  test('tree action columns use the semantic action-lane width policy', () {
    final column = CarpenterTreeTableColumn<String>.actions(
      id: 'actions',
      header: 'Actions',
      actions: (_) => const [],
    );

    expect(
      column.effectiveWidth.policy,
      CarpenterTableColumnWidthPolicy.actionLane,
    );
    expect(column.effectiveWidth.flex, 0);
    expect(column.resizable, isFalse);
  });

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

  testWidgets('explicit tree action columns share the ellipsis contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterTreeTable<String>(
          nodes: const [
            CarpenterTreeNode<String>(id: 'root', value: 'root', label: 'Root'),
          ],
          columns: [
            CarpenterTreeTableColumn<String>.actions(
              id: 'actions',
              header: 'Actions',
              actions: (_) => const [],
              secondaryActions: (_) => [
                const CarpenterActionDescriptor(
                  id: 'archive',
                  label: 'Archive',
                  onInvoke: null,
                ),
              ],
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

  testWidgets('legacy tree row actions still use the ellipsis lane', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
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

  testWidgets('legacy tree action shorthand keeps row geometry stable', (
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

Widget _legacyTreeCell(BuildContext context, CarpenterTreeNode<String> node) =>
    Text(node.label);
