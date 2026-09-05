import 'dart:async';

import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    final query = controller.updateQuery(CollectionQuery<String>(search: 'new'));

    expect(firstCancellation?.isCancelled, isTrue);

    second.complete(CollectionSnapshot<int>(items: [2]));
    await query;
    first.complete(CollectionSnapshot<int>(items: [1]));
    await initial;

    expect(controller.snapshot.items, [2]);
    expect(controller.query.search, 'new');
  });
}
