import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  test('action columns use the semantic action-lane width policy', () {
    final column = CarpenterTableColumn<_Row>.actions(
      id: 'actions',
      header: 'Actions',
      actions: (_) => const [],
    );

    expect(column.width.policy, CarpenterTableColumnWidthPolicy.actionLane);
    expect(column.width.flex, 0);
    expect(column.resizable, isFalse);
  });

  test(
    'action columns expose the same semantic actions for context surfaces',
    () {
      const row = _Row(1, 'Alpha');
      final column = CarpenterTableColumn<_Row>.actions(
        id: 'actions',
        header: 'Actions',
        actions: (_) => const [
          CarpenterActionDescriptor(id: 'open', label: 'Open', onInvoke: null),
        ],
        secondaryActions: (_) => const [
          CarpenterActionDescriptor(
            id: 'archive',
            label: 'Archive',
            onInvoke: null,
          ),
        ],
      );

      final actions = column.actionsBuilder!(row);
      expect(actions.primary.map((action) => action.id), ['open']);
      expect(actions.secondary.map((action) => action.id), ['archive']);
    },
  );

  testWidgets('resizable columns work without a width callback', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTable<_Row, int>(
          snapshot: CollectionSnapshot(items: const [_Row(1, 'Alpha')]),
          rowKey: (row) => row.id,
          rowSemanticLabel: (row) => row.name,
          selection: CollectionSelection<int>.none(),
          columns: [
            CarpenterTableColumn<_Row>.text(
              id: 'name',
              header: 'Name',
              value: (row) => row.name,
              width: const CarpenterTableColumnWidth.fixed(
                width: Px(120),
                minimum: Px(80),
                maximum: Px(240),
              ),
            ),
            CarpenterTableColumn<_Row>.text(
              id: 'rest',
              header: 'Rest',
              value: (_) => 'Rest',
            ),
          ],
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('table-resize-name'));
    expect(handle, findsOneWidget);
    final before = tester.getCenter(handle).dx;

    await tester.drag(handle, const Offset(40, 0));
    await tester.pump();

    expect(tester.getCenter(handle).dx, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cell alignment supports both axes', (tester) async {
    const cellKey = ValueKey('aligned-cell');
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTable<_Row, int>(
          snapshot: CollectionSnapshot(items: const [_Row(1, 'Alpha')]),
          rowKey: (row) => row.id,
          rowSemanticLabel: (row) => row.name,
          selection: CollectionSelection<int>.none(),
          columns: [
            CarpenterTableColumn<_Row>.custom(
              id: 'aligned',
              header: 'Aligned',
              alignment: CarpenterTableColumnAlignment.end,
              verticalAlignment: CarpenterTableColumnVerticalAlignment.bottom,
              cellBuilder: (_, _) =>
                  const SizedBox(key: cellKey, width: 8, height: 8),
            ),
          ],
        ),
      ),
    );

    final aligns = tester
        .widgetList<Align>(
          find.ancestor(of: find.byKey(cellKey), matching: find.byType(Align)),
        )
        .map((widget) => widget.alignment);
    expect(aligns, contains(AlignmentDirectional.bottomEnd));
  });

  testWidgets('secondary row actions stay behind the ellipsis', (tester) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterTable<_Row, int>(
          snapshot: CollectionSnapshot(items: const [_Row(1, 'Alpha')]),
          rowKey: (row) => row.id,
          rowSemanticLabel: (row) => row.name,
          selection: CollectionSelection<int>.none(),
          columns: [
            CarpenterTableColumn<_Row>.actions(
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
    await tester.tap(find.bySemanticsLabel('Действия'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
  });

  testWidgets('action lane stays pinned while data columns scroll underneath', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 320,
          child: CarpenterTable<_Row, int>(
            snapshot: CollectionSnapshot(items: const [_Row(1, 'Alpha')]),
            rowKey: (row) => row.id,
            rowSemanticLabel: (row) => row.name,
            selection: CollectionSelection<int>.none(),
            columns: [
              CarpenterTableColumn<_Row>.text(
                id: 'name',
                header: 'Name',
                value: (row) => row.name,
                width: const CarpenterTableColumnWidth.fixed(width: Px(300)),
              ),
              CarpenterTableColumn<_Row>.text(
                id: 'detail',
                header: 'Detail',
                value: (_) => 'Wide detail',
                width: const CarpenterTableColumnWidth.fixed(width: Px(300)),
              ),
              CarpenterTableColumn<_Row>.actions(
                id: 'actions',
                header: 'Actions',
                actions: (_) => const [],
                secondaryActions: (_) => const [
                  CarpenterActionDescriptor(
                    id: 'archive',
                    label: 'Archive',
                    onInvoke: null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    final action = find.bySemanticsLabel('Действия');
    final before = tester.getCenter(action).dx;
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(-180, 0),
    );
    await tester.pump();

    expect(tester.getCenter(action).dx, closeTo(before, 0.5));
    expect(tester.takeException(), isNull);
  });
}

final class _Row {
  const _Row(this.id, this.name);

  final int id;
  final String name;
}
