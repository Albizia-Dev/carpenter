import 'package:flutter/foundation.dart';

import 'collection_event.dart';
import 'collection_lifecycle_controller.dart';
import 'collection_query.dart';
import 'collection_snapshot.dart';

/// Minimal compatibility adapter for collection sources that only expose load.
///
/// New integrations that need cancellation, load-more, or request reasons
/// should construct [CollectionLifecycleController] with a lifecycle loader
/// directly. This adapter deliberately remains transport-neutral.
abstract interface class CollectionAdapter<T, F> {
  Future<CollectionSnapshot<T>> load(CollectionQuery<F> query);
}

typedef CollectionLoader<T, F> =
    Future<CollectionSnapshot<T>> Function(CollectionQuery<F> query);

final class CallbackCollectionAdapter<T, F> implements CollectionAdapter<T, F> {
  const CallbackCollectionAdapter(this.loader);

  final CollectionLoader<T, F> loader;

  @override
  Future<CollectionSnapshot<T>> load(CollectionQuery<F> query) => loader(query);
}

/// Compatibility facade over Carpenter's canonical collection lifecycle.
///
/// Historically this controller implemented its own generation-based stale
/// response protection. That duplicated [CollectionLifecycleController] and
/// made the two collection APIs subtly diverge. Existing adapter-based callers
/// may keep using this facade while all loading, failure, refresh, cancellation,
/// and event semantics are owned by one lifecycle implementation underneath.
@Deprecated('Use CollectionLifecycleController for new collection data flows.')
final class CollectionController<T, K, F> extends ChangeNotifier {
  CollectionController({
    required CollectionAdapter<T, F> adapter,
    required CollectionQuery<F> query,
    required CollectionSnapshot<T> snapshot,
    required K Function(T item) keyOf,
  }) : _lifecycle = CollectionLifecycleController<T, K, F>(
         load: (query, request) => adapter.load(query),
         query: query,
         keyOf: keyOf,
         initialSnapshot: snapshot,
       ) {
    _lifecycle.addListener(_forwardLifecycleChange);
  }

  final CollectionLifecycleController<T, K, F> _lifecycle;

  CollectionQuery<F> get query => _lifecycle.query;
  CollectionSnapshot<T> get snapshot => _lifecycle.snapshot;

  Future<void> load(CollectionQuery<F> query) => _lifecycle.updateQuery(query);

  Future<void> refresh() => _lifecycle.refresh();

  void apply(CollectionEvent<T, K> event) => _lifecycle.apply(event);

  void _forwardLifecycleChange() => notifyListeners();

  @override
  void dispose() {
    _lifecycle.removeListener(_forwardLifecycleChange);
    _lifecycle.dispose();
    super.dispose();
  }
}
