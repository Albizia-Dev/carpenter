import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../behaviour/request_gate.dart';
import 'collection_event.dart';
import 'collection_load_phase.dart';
import 'collection_query.dart';
import 'collection_snapshot.dart';

/// Why a lifecycle controller invoked its loader, so adapters can choose
/// appropriate fetching or caching behavior.
enum CollectionRequestReason {
  /// Explicit initialization of the collection.
  initial,

  /// Search, filter, sort, or page input changed.
  query,

  /// Explicit revalidation of the current query.
  refresh,

  /// A request to extend the currently accumulated items.
  loadMore,
}

/// Collection-specific compatibility type over Carpenter's shared cancellation
/// signal.
final class CollectionRequestCancellation extends CarpenterCancellationSignal {}

/// Context of one collection request, including its reason and cooperative
/// cancellation signal.
final class CollectionLoadRequest {
  /// Describes a request with a controller-owned [cancellation] signal.
  const CollectionLoadRequest({
    required this.reason,
    required this.cancellation,
  });

  /// Operation that caused the loader invocation.
  final CollectionRequestReason reason;

  /// Signal raised when a newer request supersedes this request or the
  /// controller is disposed. Adapters may translate it into transport
  /// cancellation; do not dispose it yourself.
  final CollectionRequestCancellation cancellation;
}

/// Loads a complete snapshot for [query] and the supplied request context.
///
/// Observe cancellation where the transport supports it. The controller
/// ignores late results even when transport cancellation is unavailable and
/// converts thrown errors into collection failure state.
typedef CollectionLifecycleLoader<T, F> =
    Future<CollectionSnapshot<T>> Function(
      CollectionQuery<F> query,
      CollectionLoadRequest request,
    );

/// Returns the complete accumulated snapshot after loading another batch.
///
/// The controller does not concatenate items automatically. Merge the new
/// batch with [current], preserve stable keys, and supply updated pagination
/// metadata. Observe the request cancellation signal where supported.
typedef CollectionLoadMore<T, F> = Future<CollectionSnapshot<T>> Function(
  CollectionQuery<F> query,
  CollectionSnapshot<T> current,
  CollectionLoadRequest request,
);

/// Full collection lifecycle controller: debounce, cancellation,
/// stale-response protection, refresh and progressive loading.
final class CollectionLifecycleController<T, K, F> extends ChangeNotifier {
  /// Creates a lifecycle owner without starting a request.
  ///
  /// Call [initialize] explicitly and dispose the controller when its owner
  /// ends. [load] returns replacement snapshots; [loadMore], when supplied,
  /// must return already accumulated items. [keyOf] identifies items for
  /// event application. The default snapshot is initial-loading and search
  /// debounce is 350 milliseconds.
  CollectionLifecycleController({
    required CollectionLifecycleLoader<T, F> load,
    required CollectionQuery<F> query,
    required K Function(T item) keyOf,
    CollectionLoadMore<T, F>? loadMore,
    CollectionSnapshot<T>? initialSnapshot,
    this.searchDebounce = const Duration(milliseconds: 350),
  }) : _load = load,
       _loadMore = loadMore,
       _query = query,
       _keyOf = keyOf,
       _snapshot = initialSnapshot ?? CollectionSnapshot<T>.initialLoading();

  final CollectionLifecycleLoader<T, F> _load;
  final CollectionLoadMore<T, F>? _loadMore;
  final K Function(T item) _keyOf;

  /// Delay before a changed trimmed search string is committed to [query] and
  /// loaded.
  final Duration searchDebounce;
  final CarpenterRequestGate<CollectionRequestCancellation> _requests =
      CarpenterRequestGate<CollectionRequestCancellation>(
        createCancellation: CollectionRequestCancellation.new,
      );
  CollectionQuery<F> _query;
  CollectionSnapshot<T> _snapshot;
  Timer? _searchTimer;

  /// Most recently committed query. A search still waiting for debounce is
  /// not included yet.
  CollectionQuery<F> get query => _query;

  /// Latest immutable presentation snapshot; listen to this controller for
  /// load and event updates.
  CollectionSnapshot<T> get snapshot => _snapshot;

  /// Runs the loader with an initial-request reason. This is explicit, not
  /// automatic, and is not restricted to a single call.
  Future<void> initialize() => _run(CollectionRequestReason.initial);

  /// Runs the current query with a refresh reason while retaining usable
  /// items. Starting it cancels the preceding active request; late results
  /// are ignored.
  Future<void> refresh() => _run(CollectionRequestReason.refresh);

  /// Debounces a trimmed search value before issuing a query load.
  ///
  /// An unchanged committed string is ignored; empty text clears search. This
  /// method does not reset pagination. Use [updateQuery] to change search and
  /// page together when that is required by the data source.
  void updateSearch(String value) {
    final normalized = value.trim();
    if ((_query.search ?? '') == normalized) return;
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () {
      _query = normalized.isEmpty
          ? _query.copyWith(clearSearch: true)
          : _query.copyWith(search: normalized);
      _run(CollectionRequestReason.query);
    });
  }

  /// Stores [query] and, by default, awaits a query load.
  ///
  /// With [load] false, only the query is stored: no request or notification
  /// is emitted. This does not cancel a pending search debounce; keep one
  /// owner for query changes.
  Future<void> updateQuery(CollectionQuery<F> query, {bool load = true}) async {
    _query = query;
    if (load) await _run(CollectionRequestReason.query);
  }

  /// Replaces only the paging request and loads the resulting query.
  Future<void> setPage(CollectionPageRequest page) =>
      updateQuery(_query.copyWith(page: page));

  Future<void> _run(CollectionRequestReason reason) async {
    final lease = _requests.begin();
    _snapshot = _snapshot.beginRefresh();
    notifyListeners();
    try {
      final result = await _load(
        _query,
        CollectionLoadRequest(reason: reason, cancellation: lease.cancellation),
      );
      if (!_requests.isCurrent(lease)) return;
      _snapshot = result.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        freshness: CollectionFreshness.current,
        clearInitialFailure: true,
        clearRefreshFailure: true,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(lease)) return;
      _snapshot = _snapshot.withLoadFailure(
        CollectionFailure(error: error, stackTrace: stackTrace),
      );
      notifyListeners();
    } finally {
      _requests.finish(lease);
    }
  }

  /// Calls the optional batch loader with the current snapshot and replaces
  /// the snapshot with its result.
  ///
  /// Does nothing when no batch loader exists or a batch request is already
  /// running. The loader must merge items itself and the caller must check
  /// whether more data is available. Failures retain the previous items and
  /// expose refresh failure state.
  Future<void> loadMore() async {
    final loader = _loadMore;
    if (loader == null || _snapshot.isLoadingMore) return;
    final lease = _requests.begin();
    final current = _snapshot;
    _snapshot = current.beginLoadingMore();
    notifyListeners();
    try {
      final result = await loader(
        _query,
        current,
        CollectionLoadRequest(
          reason: CollectionRequestReason.loadMore,
          cancellation: lease.cancellation,
        ),
      );
      if (!_requests.isCurrent(lease)) return;
      _snapshot = result.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        clearRefreshFailure: true,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (!_requests.isCurrent(lease)) return;
      _snapshot = current.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        freshness: CollectionFreshness.stale,
        refreshFailure: CollectionFailure(error: error, stackTrace: stackTrace),
      );
      notifyListeners();
    } finally {
      _requests.finish(lease);
    }
  }

  /// Applies a presentation event using the configured stable-key extractor
  /// and notifies listeners. This does not persist data or execute a loader,
  /// including for [CollectionRefreshRequested].
  void apply(CollectionEvent<T, K> event) {
    _snapshot = _snapshot.applyEvent(event, keyOf: _keyOf);
    notifyListeners();
  }

  /// Cancels pending search debounce and outstanding requests, disposes
  /// cancellation signals, and releases listeners. Do not use the controller
  /// after disposal.
  @override
  void dispose() {
    _searchTimer?.cancel();
    _requests.dispose();
    super.dispose();
  }
}
