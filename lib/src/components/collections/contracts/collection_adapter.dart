import 'package:flutter/foundation.dart';

import 'collection_event.dart';
import 'collection_load_phase.dart';
import 'collection_query.dart';
import 'collection_snapshot.dart';

abstract interface class CollectionAdapter<T, F> {
  Future<CollectionSnapshot<T>> load(CollectionQuery<F> query);
}

typedef CollectionLoader<T, F> = Future<CollectionSnapshot<T>> Function(
  CollectionQuery<F> query,
);

final class CallbackCollectionAdapter<T, F> implements CollectionAdapter<T, F> {
  const CallbackCollectionAdapter(this.loader);

  final CollectionLoader<T, F> loader;

  @override
  Future<CollectionSnapshot<T>> load(CollectionQuery<F> query) => loader(query);
}

final class CollectionController<T, K, F> extends ChangeNotifier {
  CollectionController({
    required this._adapter,
    required this._query,
    required this._snapshot,
    required this._keyOf,
  });

  final CollectionAdapter<T, F> _adapter;
  final K Function(T item) _keyOf;
  CollectionQuery<F> _query;
  CollectionSnapshot<T> _snapshot;
  int _requestGeneration = 0;

  CollectionQuery<F> get query => _query;
  CollectionSnapshot<T> get snapshot => _snapshot;

  Future<void> load(CollectionQuery<F> query) async {
    _query = query;
    final generation = ++_requestGeneration;
    _snapshot = _snapshot.beginRefresh();
    notifyListeners();
    try {
      final result = await _adapter.load(query);
      if (generation != _requestGeneration) return;
      _snapshot = result.copyWith(
        loadPhase: CollectionLoadPhase.ready,
        freshness: CollectionFreshness.current,
        clearInitialFailure: true,
        clearRefreshFailure: true,
      );
      notifyListeners();
    } catch (error, stackTrace) {
      if (generation != _requestGeneration) return;
      _snapshot = _snapshot.withLoadFailure(
        CollectionFailure(error: error, stackTrace: stackTrace),
      );
      notifyListeners();
    }
  }

  Future<void> refresh() => load(_query);

  void apply(CollectionEvent<T, K> event) {
    _snapshot = _snapshot.applyEvent(event, keyOf: _keyOf);
    notifyListeners();
  }
}
