import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../behaviour/request_gate.dart';
import 'collection_event.dart';
import 'collection_load_phase.dart';
import 'collection_query.dart';
import 'collection_snapshot.dart';

enum CollectionRequestReason { initial, query, refresh, loadMore }

/// Collection-specific compatibility type over Carpenter's shared cancellation
/// signal.
final class CollectionRequestCancellation
    extends CarpenterCancellationSignal {}

final class CollectionLoadRequest {
  const CollectionLoadRequest({
    required this.reason,
    required this.cancellation,
  });
  final CollectionRequestReason reason;
  final CollectionRequestCancellation cancellation;
}

typedef CollectionLifecycleLoader<T, F> =
    Future<CollectionSnapshot<T>> Function(
      CollectionQuery<F> query,
      CollectionLoadRequest request,
    );
typedef CollectionLoadMore<T, F> =
    Future<CollectionSnapshot<T>> Function(
      CollectionQuery<F> query,
      CollectionSnapshot<T> current,
      CollectionLoadRequest request,
    );

/// Full collection lifecycle controller: debounce, cancellation,
/// stale-response protection, refresh and progressive loading.
final class CollectionLifecycleController<T, K, F> extends ChangeNotifier {
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
  final Duration searchDebounce;
  final CarpenterRequestGate<CollectionRequestCancellation> _requests =
      CarpenterRequestGate<CollectionRequestCancellation>(
        createCancellation: CollectionRequestCancellation.new,
      );
  CollectionQuery<F> _query;
  CollectionSnapshot<T> _snapshot;
  Timer? _searchTimer;

  CollectionQuery<F> get query => _query;
  CollectionSnapshot<T> get snapshot => _snapshot;

  Future<void> initialize() => _run(CollectionRequestReason.initial);
  Future<void> refresh() => _run(CollectionRequestReason.refresh);

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

  Future<void> updateQuery(CollectionQuery<F> query, {bool load = true}) async {
    _query = query;
    if (load) await _run(CollectionRequestReason.query);
  }

  Future<void> setPage(CollectionPageRequest page) =>
      updateQuery(_query.copyWith(page: page));

  Future<void> _run(CollectionRequestReason reason) async {
    final lease = _requests.begin();
    _snapshot = _snapshot.beginRefresh();
    notifyListeners();
    try {
      final result = await _load(
        _query,
        CollectionLoadRequest(
          reason: reason,
          cancellation: lease.cancellation,
        ),
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

  void apply(CollectionEvent<T, K> event) {
    _snapshot = _snapshot.applyEvent(event, keyOf: _keyOf);
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _requests.dispose();
    super.dispose();
  }
}
