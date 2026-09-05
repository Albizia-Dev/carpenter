import 'package:carpenter/collections.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'compatibility controller shares lifecycle refresh failure semantics',
    () async {
      final controller = CollectionController<int, int, String>(
        adapter: CallbackCollectionAdapter((query) async {
          throw StateError('offline');
        }),
        query: CollectionQuery<String>(),
        snapshot: CollectionSnapshot<int>(items: [1]),
        keyOf: (item) => item,
      );
      addTearDown(controller.dispose);

      await controller.refresh();

      expect(controller.snapshot.items, [1]);
      expect(controller.snapshot.loadPhase, CollectionLoadPhase.ready);
      expect(controller.snapshot.freshness, CollectionFreshness.stale);
      expect(controller.snapshot.refreshFailure?.error, isA<StateError>());
    },
  );
}
