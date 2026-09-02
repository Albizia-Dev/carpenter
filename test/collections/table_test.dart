import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('renders stable row keys and preserves rows while refreshing', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot<_Record>(
            items: _records,
            loadPhase: CollectionLoadPhase.refreshing,
            freshness: CollectionFreshness.stale,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey(1)), findsOneWidget);
    expect(find.byKey(const ValueKey(2)), findsOneWidget);
    expect(find.text('Refreshing data'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets('sorting is controlled and cycles without sorting rows locally', (
    tester,
  ) async {
    List<CollectionSort>? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          onSortingChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.text('Name'));
    await tester.pump();

    expect(changed, [
      const CollectionSort(
        id: 'name',
        direction: CollectionSortDirection.ascending,
      ),
    ]);
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);

    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          sorting: changed!,
          onSortingChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.tap(find.text('Name ↑'));
    expect(changed!.single.direction, CollectionSortDirection.descending);

    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          sorting: changed!,
          onSortingChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.tap(find.text('Name ↓'));
    expect(changed, isEmpty);
  });

  testWidgets('single and multiple selection are emitted from stable keys', (
    tester,
  ) async {
    CollectionSelection<int>? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          selection: CollectionSelection<int>.multiple([99]),
          onSelectionChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey(2)));
    await tester.pump();

    expect(changed!.selectedKeys, {99, 2});
  });

  testWidgets('selection across pagination is not reduced to loaded rows', (
    tester,
  ) async {
    CollectionSelection<int>? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(
            items: _records,
            pageInfo: const CollectionCursorPageInfo(
              itemCount: 2,
              nextCursor: 'next',
            ),
          ),
          selection: CollectionSelection<int>.multiple([900]),
          onSelectionChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey(1)));
    expect(changed!.selectedKeys, {900, 1});
  });

  testWidgets('select loaded set preserves selection from other pages', (
    tester,
  ) async {
    CollectionSelection<int>? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          selection: CollectionSelection<int>.multiple([900]),
          onSelectionChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Select loaded rows'));
    expect(changed!.selectedKeys, {900, 1, 2});
  });

  testWidgets('unknown total exposes load-more without page assumptions', (
    tester,
  ) async {
    var loads = 0;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(
            items: _records,
            pageInfo: const CollectionProgressivePageInfo(
              loadedItems: 2,
              hasMore: true,
            ),
          ),
          onLoadMore: () => loads += 1,
        ),
      ),
    );

    await tester.tap(find.text('Load more'));
    expect(loads, 1);
  });

  testWidgets('column resize clamps controlled output to min and max', (
    tester,
  ) async {
    LengthUnit? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          onColumnWidthChanged: (id, width) {
            if (id == 'name') changed = width;
          },
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('table-resize-name'));
    await tester.drag(handle, const Offset(1000, 0));
    await tester.pump();

    expect(changed, isA<Rem>());
    expect((changed! as Rem).value, 15);
  });

  testWidgets('keyboard moves row focus and toggles selection', (tester) async {
    CollectionSelection<int>? changed;
    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(items: _records),
          selection: CollectionSelection<int>.single(),
          onSelectionChanged: (value) => changed = value,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey(1)));
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    expect(changed!.selectedKeys, {2});
  });

  testWidgets('interactive cell action activates once without selecting row', (
    tester,
  ) async {
    var actions = 0;
    var selections = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTable<_Record, int>(
          snapshot: CollectionSnapshot(items: _records),
          rowKey: (row) => row.id,
          rowSemanticLabel: (row) => row.name,
          columns: [
            CarpenterTableColumn<_Record>.actions(
              id: 'actions',
              header: 'Actions',
              actions: (_) => [
                CarpenterActionDescriptor(
                  id: 'open',
                  label: 'Open',
                  onInvoke: () => actions += 1,
                ),
              ],
            ),
          ],
          selection: CollectionSelection<int>.multiple(),
          onSelectionChanged: (_) => selections += 1,
        ),
      ),
    );

    await tester.tap(find.text('Open').first);
    await tester.pump();

    expect(actions, 1);
    expect(selections, 0);
  });

  testWidgets('states, RTL, text scaling and narrow scrolling remain usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        SizedBox(
          width: 220,
          child: _table(
            snapshot: CollectionSnapshot<_Record>(
              contentState: CollectionContentState.emptyResult,
            ),
          ),
        ),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );

    expect(find.text('No matching results'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Records'), findsOneWidget);
  });

  testWidgets('initial and refresh errors remain separate table states', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterTable<_Record, int>(
          semanticLabel: 'Failed records',
          snapshot: CollectionSnapshot(
            initialFailure: const CollectionFailure(
              error: 'offline',
              message: 'Initial unavailable',
            ),
          ),
          rowKey: (row) => row.id,
          rowSemanticLabel: (row) => row.name,
          columns: [
            CarpenterTableColumn<_Record>.text(
              id: 'name',
              header: 'Name',
              value: (row) => row.name,
            ),
          ],
          selection: CollectionSelection<int>.none(),
          retryAction: CarpenterActionDescriptor(
            id: 'retry',
            label: 'Retry',
            onInvoke: () => retries += 1,
          ),
        ),
      ),
    );

    expect(find.text('Initial unavailable'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(retries, 1);

    await tester.pumpWidget(
      carpenterHarness(
        _table(
          snapshot: CollectionSnapshot(
            items: _records,
            refreshFailure: const CollectionFailure(
              error: 'offline',
              message: 'Refresh unavailable',
            ),
          ),
        ),
      ),
    );
    expect(find.text('Refresh unavailable'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
  });

  testWidgets(
    'sticky header remains while the standard list viewport scrolls',
    (tester) async {
      final records = List.generate(
        40,
        (index) => _Record(index, 'Record $index', index),
      );
      await tester.pumpWidget(
        carpenterHarness(_table(snapshot: CollectionSnapshot(items: records))),
      );

      final before = tester.getTopLeft(find.text('Name')).dy;
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pump();

      expect(tester.getTopLeft(find.text('Name')).dy, before);
    },
  );

  testWidgets('clamps its scrollable body to short viewport constraints', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        SizedBox(
          width: 600,
          height: 66,
          child: _table(snapshot: CollectionSnapshot(items: _records)),
        ),
      ),
    );

    expect(find.text('Name'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders in dark high contrast without changing contracts', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        _table(snapshot: CollectionSnapshot(items: _records)),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
      ),
    );

    expect(find.text('Alpha'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _records = [const _Record(1, 'Alpha', 12), const _Record(2, 'Beta', 30)];

CarpenterTable<_Record, int> _table({
  required CollectionSnapshot<_Record> snapshot,
  CollectionSelection<int>? selection,
  ValueChanged<CollectionSelection<int>>? onSelectionChanged,
  List<CollectionSort> sorting = const [],
  ValueChanged<List<CollectionSort>>? onSortingChanged,
  CarpenterTableColumnWidthChanged? onColumnWidthChanged,
  VoidCallback? onLoadMore,
}) => CarpenterTable<_Record, int>(
  semanticLabel: 'Records',
  snapshot: snapshot,
  rowKey: (row) => row.id,
  rowSemanticLabel: (row) => '${row.name}, ${row.amount}',
  selection: selection ?? CollectionSelection<int>.none(),
  onSelectionChanged: onSelectionChanged,
  sorting: sorting,
  onSortingChanged: onSortingChanged,
  columnWidths: const {'name': Px(120), 'amount': Px(100)},
  onColumnWidthChanged: onColumnWidthChanged,
  onLoadMore: onLoadMore,
  columns: [
    CarpenterTableColumn<_Record>.text(
      id: 'name',
      header: 'Name',
      value: (row) => row.name,
      sortable: true,
      width: const CarpenterTableColumnWidth.flexible(
        minimum: Px(80),
        maximum: Px(240),
      ),
    ),
    CarpenterTableColumn<_Record>.number(
      id: 'amount',
      header: 'Amount',
      value: (row) => row.amount,
      sortable: true,
      width: const CarpenterTableColumnWidth.fixed(
        width: Px(100),
        minimum: Px(80),
        maximum: Px(180),
      ),
    ),
  ],
);

final class _Record {
  const _Record(this.id, this.name, this.amount);
  final int id;
  final String name;
  final num amount;
}
