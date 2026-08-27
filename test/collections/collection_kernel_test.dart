import 'dart:async';

import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CollectionSnapshot', () {
    test('refresh preserves data and marks it stale', () {
      final snapshot = CollectionSnapshot<int>(items: [1, 2, 3]);
      final refreshing = snapshot.beginRefresh();

      expect(refreshing.items, [1, 2, 3]);
      expect(refreshing.loadPhase, CollectionLoadPhase.refreshing);
      expect(refreshing.freshness, CollectionFreshness.stale);
    });

    test('initial failure and refresh failure remain distinct', () {
      const initialFailure = CollectionFailure(error: 'initial');
      const refreshFailure = CollectionFailure(error: 'refresh');

      final initial = CollectionSnapshot<int>().withLoadFailure(initialFailure);
      final refresh = CollectionSnapshot<int>(
        items: [1],
      ).withLoadFailure(refreshFailure);

      expect(initial.initialFailure, same(initialFailure));
      expect(initial.refreshFailure, isNull);
      expect(refresh.initialFailure, isNull);
      expect(refresh.refreshFailure, same(refreshFailure));
      expect(refresh.items, [1]);
    });

    test('zero and filtered empty result are explicit', () {
      final zero = CollectionSnapshot<int>(
        contentState: CollectionContentState.zero,
      );
      final empty = CollectionSnapshot<int>(
        contentState: CollectionContentState.emptyResult,
      );

      expect(zero.contentState, CollectionContentState.zero);
      expect(empty.contentState, CollectionContentState.emptyResult);
    });
  });

  group('pagination', () {
    test('query keeps typed filters separate from transport concerns', () {
      final query = CollectionQuery<_Filter>(
        filter: const _Filter(active: true),
        search: 'needle',
        sorting: const [
          CollectionSort(
            id: 'name',
            direction: CollectionSortDirection.descending,
          ),
        ],
        page: const CollectionKeysetPageRequest<int>(after: 41, limit: 20),
      );

      expect(query.filter!.active, isTrue);
      expect(query.page, isA<CollectionKeysetPageRequest<int>>());
      expect(
        query.sorting.single.reversed().direction,
        CollectionSortDirection.ascending,
      );
    });

    test('cursor and keyset expose opaque continuation identity', () {
      const cursor = CollectionCursorPageInfo(
        itemCount: 20,
        nextCursor: 'opaque-next',
      );
      const keyset = CollectionKeysetPageInfo<int>(itemCount: 20, nextKey: 42);

      expect(cursor.hasNext, isTrue);
      expect(cursor.hasKnownTotal, isFalse);
      expect(keyset.hasNext, isTrue);
      expect(keyset.nextKey, 42);
    });

    test('unknown offset total uses explicit more-available evidence', () {
      const info = CollectionOffsetPageInfo(
        offset: 40,
        limit: 20,
        itemCount: 3,
        moreAvailable: true,
      );

      expect(info.totalItems, isNull);
      expect(info.hasNext, isTrue);
    });
  });

  group('selection', () {
    test('uses stable keys and survives pagination', () {
      var selection = CollectionSelection<int>.multiple([1, 2]);
      selection = selection.selectLoaded([101, 102]);

      expect(selection.contains(1), isTrue);
      expect(selection.contains(101), isTrue);
      expect(selection.selectedKeys, {1, 2, 101, 102});
    });

    test('all matching tracks only exclusions', () {
      final selection = CollectionSelection<String>.allMatching()
          .unselect('hidden-on-page')
          .select('hidden-on-page');

      expect(selection.contains('any-other-key'), isTrue);
      expect(selection.excludedKeys, isEmpty);
    });
  });

  test('optimistic mutation records reconciliation and rollback', () {
    final mutation = CollectionMutationState<int>()
        .running([7], optimistic: true)
        .failed(const CollectionFailure(error: 'rejected'), rolledBack: true);

    expect(mutation.phase, CollectionMutationPhase.failed);
    expect(mutation.affectedKeys, {7});
    expect(mutation.reconciliation, CollectionReconciliation.rolledBack);
  });

  test('typed events update by key and can request refresh', () {
    final original = CollectionSnapshot<_Row>(
      items: const [_Row(1, 'one'), _Row(2, 'two')],
    );
    final updated = original.applyEvent<int>(
      const CollectionUpdated(item: _Row(2, 'changed'), key: 2),
      keyOf: (row) => row.id,
    );
    final inserted = updated.applyEvent<int>(
      const CollectionInserted(item: _Row(3, 'three'), key: 3, index: 1),
      keyOf: (row) => row.id,
    );
    final refreshing = inserted.applyEvent<int>(
      const CollectionRefreshRequested(),
      keyOf: (row) => row.id,
    );

    expect(updated.items[1].label, 'changed');
    expect(inserted.items.map((row) => row.id), [1, 3, 2]);
    expect(refreshing.items, inserted.items);
    expect(refreshing.loadPhase, CollectionLoadPhase.refreshing);
  });

  test('removing the final item records an explicit empty-result state', () {
    final snapshot = CollectionSnapshot<_Row>(items: const [_Row(1, 'one')]);
    final removed = snapshot.applyEvent<int>(
      const CollectionRemoved(1),
      keyOf: (row) => row.id,
    );

    expect(removed.items, isEmpty);
    expect(removed.contentState, CollectionContentState.emptyResult);
  });

  test('controller ignores stale async results', () async {
    final first = Completer<CollectionSnapshot<int>>();
    final second = Completer<CollectionSnapshot<int>>();
    var invocation = 0;
    final controller = CollectionController<int, int, String>(
      adapter: CallbackCollectionAdapter((query) {
        invocation += 1;
        return invocation == 1 ? first.future : second.future;
      }),
      query: CollectionQuery<String>(),
      snapshot: CollectionSnapshot<int>(items: [0]),
      keyOf: (item) => item,
    );

    final oldRequest = controller.load(CollectionQuery<String>(search: 'old'));
    final newRequest = controller.load(CollectionQuery<String>(search: 'new'));
    second.complete(CollectionSnapshot<int>(items: [2]));
    await newRequest;
    first.complete(CollectionSnapshot<int>(items: [1]));
    await oldRequest;

    expect(controller.snapshot.items, [2]);
    expect(controller.query.search, 'new');
    controller.dispose();
  });
}

final class _Row {
  const _Row(this.id, this.label);
  final int id;
  final String label;
}

final class _Filter {
  const _Filter({required this.active});
  final bool active;
}
