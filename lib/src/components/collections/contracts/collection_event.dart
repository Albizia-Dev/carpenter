import 'collection_load_phase.dart';
import 'collection_snapshot.dart';

/// Typed change to a collection snapshot.
///
/// These events update presentation data; applications remain responsible for
/// persistence, authoritative ordering, and pagination metadata.
sealed class CollectionEvent<T, K> {
  /// Base constructor for a typed collection change.
  const CollectionEvent();
}

/// Inserts an item, or replaces the existing item when its stable key is
/// already loaded.
final class CollectionInserted<T, K> extends CollectionEvent<T, K> {
  /// Creates an insertion/upsert event. Omit [index] to append; applying the
  /// event clamps the index to the current list bounds.
  const CollectionInserted({required this.item, required this.key, this.index});

  /// New item value to insert or replace.
  final T item;

  /// Stable key identifying the item; must agree with the consumer's key
  /// extractor.
  final K key;

  /// Optional desired insertion index for a new key, before bounds clamping.
  final int? index;
}

/// Replaces a loaded item with the same stable key. Applying an update for an
/// absent key leaves the snapshot unchanged.
final class CollectionUpdated<T, K> extends CollectionEvent<T, K> {
  /// Creates an update for an already loaded [key].
  const CollectionUpdated({required this.item, required this.key});

  /// Replacement value for the matching loaded item.
  final T item;

  /// Stable key to locate using the consumer's key extractor.
  final K key;
}

/// Removes a stable key from the loaded snapshot without deleting anything
/// from the data source.
final class CollectionRemoved<T, K> extends CollectionEvent<T, K> {
  /// Creates a removal event. [emptyState] is used only when removing the key
  /// leaves no loaded items.
  const CollectionRemoved(
    this.key, {
    this.emptyState = CollectionContentState.emptyResult,
  });

  /// Stable key of the item to remove.
  final K key;

  /// Content state to use after the last loaded item is removed; defaults to
  /// zero query results.
  final CollectionContentState emptyState;
}

/// Replaces loaded items and resets failure/freshness state through
/// [CollectionEventApplication.applyEvent].
final class CollectionReset<T, K> extends CollectionEvent<T, K> {
  /// Creates a reset event. [contentState] must be consistent with [items]
  /// when the event is applied.
  const CollectionReset(
    this.items, {
    this.contentState = CollectionContentState.content,
  });

  /// Replacement list; it is copied into an unmodifiable list by the
  /// resulting snapshot.
  final List<T> items;

  /// Meaning of the replacement content; non-content states require an empty
  /// list.
  final CollectionContentState contentState;
}

/// Marks a snapshot as refreshing.
///
/// Applying this event changes presentation state only. Invoke the lifecycle
/// controller's refresh method to execute a loader.
final class CollectionRefreshRequested<T, K> extends CollectionEvent<T, K> {
  /// Creates a presentation-only refresh request event.
  const CollectionRefreshRequested();
}

/// Moves a loaded item within the visible item list. This event does not
/// persist ordering.
final class CollectionReordered<T, K> extends CollectionEvent<T, K> {
  /// Creates a move of [key] to [toIndex] in the list after removal.
  const CollectionReordered({required this.key, required this.toIndex});

  /// Stable key of the loaded item to move.
  final K key;

  /// Destination index in the post-removal list; applying clamps it to valid
  /// bounds.
  final int toIndex;
}

/// Pure application of collection events to an immutable snapshot using
/// caller-owned stable keys.
extension CollectionEventApplication<T> on CollectionSnapshot<T> {
  /// Returns a snapshot with [event] applied using [keyOf].
  ///
  /// Insertion upserts a matching key; updating or removing an absent key is
  /// a no-op. Insert/reorder indices are clamped. Reset clears failures and
  /// marks data ready/current. Refresh only changes presentation state and
  /// does not execute a loader. Pagination metadata is retained; update it
  /// separately when a source change affects totals or cursors.
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
