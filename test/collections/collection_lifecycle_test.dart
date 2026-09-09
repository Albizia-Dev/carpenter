import 'dart:async';

import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'debounced search maps domain filter and resets page atomically',
    (tester) async {
      final queries = <CollectionQuery<String>>[];
      final controller = CollectionLifecycleController<int, int, String>(
        load: (query, _) async {
          queries.add(query);
          return CollectionSnapshot(items: [1]);
        },
        query: CollectionQuery(
          filter: 'old',
          search: '',
          page: const CollectionOffsetPageRequest(offset: 100, limit: 50),
        ),
        keyOf: (item) => item,
        queryForSearch: (query, search) => query.copyWith(
          filter: search,
          search: search,
          page: const CollectionOffsetPageRequest(offset: 0, limit: 50),
        ),
      );
      addTearDown(controller.dispose);
      controller.updateSearch('  new  ');
      await tester.pump(const Duration(milliseconds: 349));
      expect(queries, isEmpty);
      await tester.pump(const Duration(milliseconds: 1));
      expect(queries.single.search, 'new');
      expect(queries.single.filter, 'new');
      expect((queries.single.page as CollectionOffsetPageRequest).offset, 0);
    },
  );

  testWidgets(
    'clearing a draft and explicit query updates cancel stale debounce',
    (tester) async {
      var requests = 0;
      final controller = CollectionLifecycleController<int, int, String>(
        load: (_, _) async {
          requests++;
          return CollectionSnapshot(items: [1]);
        },
        query: CollectionQuery(search: ''),
        keyOf: (item) => item,
      );
      addTearDown(controller.dispose);
      controller.updateSearch('obsolete');
      controller.updateSearch('');
      await tester.pump(const Duration(seconds: 1));
      expect(requests, 0);
      controller.updateSearch('obsolete');
      await controller.updateQuery(CollectionQuery(search: 'explicit'));
      await tester.pump(const Duration(seconds: 1));
      expect(requests, 1);
      expect(controller.query.search, 'explicit');
    },
  );

  test('collection lifecycle cancels and ignores stale requests', () async {
    final first = Completer<CollectionSnapshot<int>>();
    final second = Completer<CollectionSnapshot<int>>();
    CollectionRequestCancellation? firstCancellation;
    var invocation = 0;
    final controller = CollectionLifecycleController<int, int, String>(
      load: (query, request) {
        invocation += 1;
        if (invocation == 1) {
          firstCancellation = request.cancellation;
          return first.future;
        }
        return second.future;
      },
      query: CollectionQuery<String>(),
      keyOf: (item) => item,
      initialSnapshot: CollectionSnapshot<int>(items: [0]),
    );
    addTearDown(controller.dispose);

    final initial = controller.initialize();
    final query = controller.updateQuery(
      CollectionQuery<String>(search: 'new'),
    );

    expect(firstCancellation?.isCancelled, isTrue);

    second.complete(CollectionSnapshot<int>(items: [2]));
    await query;
    first.complete(CollectionSnapshot<int>(items: [1]));
    await initial;

    expect(controller.snapshot.items, [2]);
    expect(controller.query.search, 'new');
  });
}
