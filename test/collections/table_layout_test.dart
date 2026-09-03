import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('resizable columns work without a width callback', (tester) async {
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
              cellBuilder: (_, _) => const SizedBox(
                key: cellKey,
                width: 8,
                height: 8,
              ),
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
      carpenterHarness(
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
    await tester.tap(find.bySemanticsLabel('More actions'));
    await tester.pumpAndSettle();
    expect(find.text('Archive'), findsOneWidget);
  });
}

final class _Row {
  const _Row(this.id, this.name);

  final int id;
  final String name;
}
