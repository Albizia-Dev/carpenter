import 'dart:async';

import 'package:flutter/foundation.dart';

import 'collection_event.dart';
import 'collection_load_phase.dart';
import 'collection_query.dart';
import 'collection_snapshot.dart';

enum CollectionRequestReason { initial, query, refresh, loadMore }

final class CollectionRequestCancellation extends ChangeNotifier {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() {
    if (!_cancelled) {
      _cancelled = true;
      notifyListeners();
    }
  }
}

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

/// Full collection lifecycle controller: debounce, cancellation, stale-response protection, refresh and progressive loading.
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
  CollectionQuery<F> _query;
  CollectionSnapshot<T> _snapshot;
  Timer? _searchTimer;
  CollectionRequestCancellation? _cancellation;
  int _generation = 0;

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
    final generation = ++_generation;
    _cancellation?.cancel();
    _cancellation?.dispose();
    final cancellation = CollectionRequestCancellation();
    _cancellation = cancellation;
    _snapshot = _snapshot.beginRefresh();
    notifyListeners();
    try {
      final result = await _load(
        _query,
        CollectionLoadRequest(reason: reason, cancellation: cancellation),
      );
      if (generation != _generation || cancellation.isCancelled) return;
      _snapshot = result.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        freshness: CollectionFreshness.current,
        clearInitialFailure: true,
        clearRefreshFailure: true,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (generation != _generation || cancellation.isCancelled) return;
      _snapshot = _snapshot.withLoadFailure(
        CollectionFailure(error: error, stackTrace: stackTrace),
      );
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    final loader = _loadMore;
    if (loader == null || _snapshot.isLoadingMore) return;
    final generation = ++_generation;
    final cancellation = CollectionRequestCancellation();
    _cancellation?.cancel();
    _cancellation?.dispose();
    _cancellation = cancellation;
    final current = _snapshot;
    _snapshot = current.beginLoadingMore();
    notifyListeners();
    try {
      final result = await loader(
        _query,
        current,
        CollectionLoadRequest(
          reason: CollectionRequestReason.loadMore,
          cancellation: cancellation,
        ),
      );
      if (generation != _generation || cancellation.isCancelled) return;
      _snapshot = result.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        clearRefreshFailure: true,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (generation != _generation || cancellation.isCancelled) return;
      _snapshot = current.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        freshness: CollectionFreshness.stale,
        refreshFailure: CollectionFailure(error: error, stackTrace: stackTrace),
      );
      notifyListeners();
    }
  }

  void apply(CollectionEvent<T, K> event) {
    _snapshot = _snapshot.applyEvent(event, keyOf: _keyOf);
    notifyListeners();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _cancellation?.cancel();
    _cancellation?.dispose();
    super.dispose();
  }
}
