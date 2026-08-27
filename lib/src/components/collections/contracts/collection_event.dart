import 'collection_load_phase.dart';
import 'collection_snapshot.dart';

sealed class CollectionEvent<T, K> {
  const CollectionEvent();
}

final class CollectionInserted<T, K> extends CollectionEvent<T, K> {
  const CollectionInserted({required this.item, required this.key, this.index});
  final T item;
  final K key;
  final int? index;
}

final class CollectionUpdated<T, K> extends CollectionEvent<T, K> {
  const CollectionUpdated({required this.item, required this.key});
  final T item;
  final K key;
}

final class CollectionRemoved<T, K> extends CollectionEvent<T, K> {
  const CollectionRemoved(
    this.key, {
    this.emptyState = CollectionContentState.emptyResult,
  });
  final K key;
  final CollectionContentState emptyState;
}

final class CollectionReset<T, K> extends CollectionEvent<T, K> {
  const CollectionReset(
    this.items, {
    this.contentState = CollectionContentState.content,
  });
  final List<T> items;
  final CollectionContentState contentState;
}

final class CollectionRefreshRequested<T, K> extends CollectionEvent<T, K> {
  const CollectionRefreshRequested();
}

final class CollectionReordered<T, K> extends CollectionEvent<T, K> {
  const CollectionReordered({required this.key, required this.toIndex});
  final K key;
  final int toIndex;
}

extension CollectionEventApplication<T> on CollectionSnapshot<T> {
  CollectionSnapshot<T> applyEvent<K>(
    CollectionEvent<T, K> event, {
    required K Function(T item) keyOf,
  }) {
    switch (event) {
      case CollectionRefreshRequested<T, K>():
        return beginRefresh();
      case CollectionReset<T, K>():
        return copyWith(
          items: event.items,
          contentState: event.contentState,
          loadPhase: CollectionLoadPhase.ready,
          freshness: CollectionFreshness.current,
          clearInitialFailure: true,
          clearRefreshFailure: true,
        );
      case CollectionInserted<T, K>():
        final next = [...items];
        final existing = next.indexWhere((item) => keyOf(item) == event.key);
        if (existing >= 0) {
          next[existing] = event.item;
        } else {
          final index = (event.index ?? next.length).clamp(0, next.length);
          next.insert(index, event.item);
        }
        return copyWith(
          items: next,
          contentState: CollectionContentState.content,
        );
      case CollectionUpdated<T, K>():
        final index = items.indexWhere((item) => keyOf(item) == event.key);
        if (index < 0) return this;
        final next = [...items]..[index] = event.item;
        return copyWith(items: next);
      case CollectionRemoved<T, K>():
        final next = items.where((item) => keyOf(item) != event.key).toList();
        return next.length == items.length
            ? this
            : copyWith(
                items: next,
                contentState: next.isEmpty
                    ? event.emptyState
                    : CollectionContentState.content,
              );
      case CollectionReordered<T, K>():
        final from = items.indexWhere((item) => keyOf(item) == event.key);
        if (from < 0) return this;
        final next = [...items];
        final item = next.removeAt(from);
        next.insert(event.toIndex.clamp(0, next.length), item);
        return copyWith(items: next);
    }
  }
}
