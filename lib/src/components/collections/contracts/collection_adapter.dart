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
  /// Loads a complete snapshot for [query]. New cancellation-aware
  /// integrations should use [CollectionLifecycleController] directly.
  Future<CollectionSnapshot<T>> load(CollectionQuery<F> query);
}

/// Compatibility loader returning a complete snapshot for a query without
/// request-reason or cancellation context.
typedef CollectionLoader<T, F> = Future<CollectionSnapshot<T>> Function(
  CollectionQuery<F> query,
);

/// Adapts a plain asynchronous loader to the legacy [CollectionAdapter]
/// interface without adding transport behavior.
final class CallbackCollectionAdapter<T, F> implements CollectionAdapter<T, F> {
  /// Wraps [loader] without executing it.
  const CallbackCollectionAdapter(this.loader);

  /// Callback invoked for every load request.
  final CollectionLoader<T, F> loader;

  /// Forwards [query] to [loader], returning its future and propagating its
  /// errors.
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
  /// Creates the compatibility facade and its owned lifecycle controller. No
  /// request starts until [load] or [refresh] is invoked.
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

  /// Current query of the underlying lifecycle owner.
  CollectionQuery<F> get query => _lifecycle.query;

  /// Current immutable snapshot of the underlying lifecycle owner.
  CollectionSnapshot<T> get snapshot => _lifecycle.snapshot;

  /// Replaces the query and awaits the canonical lifecycle loader. Prefer
  /// [CollectionLifecycleController.updateQuery] in new integrations.
  Future<void> load(CollectionQuery<F> query) => _lifecycle.updateQuery(query);

  /// Refreshes the current query through the canonical lifecycle, retaining
  /// usable data.
  Future<void> refresh() => _lifecycle.refresh();

  /// Applies a presentation event and forwards the underlying lifecycle
  /// notification.
  void apply(CollectionEvent<T, K> event) => _lifecycle.apply(event);

  void _forwardLifecycleChange() => notifyListeners();

  /// Detaches forwarding and disposes the owned lifecycle controller,
  /// cancelling its pending work.
  @override
  void dispose() {
    _lifecycle.removeListener(_forwardLifecycleChange);
    _lifecycle.dispose();
    super.dispose();
  }
}
