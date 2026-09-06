import 'package:flutter/foundation.dart';

import '../pagination.dart';
import 'collection_load_phase.dart';

/// Marker interface for application-owned metadata accompanying a
/// [CollectionSnapshot].
abstract interface class CollectionMetadata {}

/// Immutable collection presentation state shared by tables, lists, and page
/// patterns.
///
/// Items are defensively copied. Initial loading and initial failure are
/// distinct from refresh or load-more activity over existing data.
/// [CollectionContentState.zero] and [CollectionContentState.emptyResult]
/// require an empty item list. A snapshot with [initialFailure] cannot
/// contain items.
@immutable
final class CollectionSnapshot<T> {
  /// Creates a snapshot and copies [items] into an unmodifiable list.
  ///
  /// When [pageInfo] is omitted, an unpaged result with the current item
  /// count is assumed. Assertions reject items in zero/empty-result states
  /// and items combined with [initialFailure].
  CollectionSnapshot({
    List<T> items = const [],
    this.loadPhase = CollectionLoadPhase.idle,
    this.freshness = CollectionFreshness.current,
    this.contentState = CollectionContentState.content,
    this.initialFailure,
    this.refreshFailure,
    CollectionPageInfo? pageInfo,
    this.metadata,
  }) : items = List.unmodifiable(items),
       pageInfo = pageInfo ?? CollectionUnpagedInfo(itemCount: items.length),
       assert(
         contentState == CollectionContentState.content || items.isEmpty,
         'Zero and empty-result snapshots cannot contain items.',
       ),
       assert(
         initialFailure == null || items.isEmpty,
         'Initial failures cannot replace existing data.',
       );

  /// Creates an empty snapshot in [CollectionLoadPhase.initialLoading]. This
  /// factory does not start a request.
  factory CollectionSnapshot.initialLoading() =>
      CollectionSnapshot<T>(loadPhase: CollectionLoadPhase.initialLoading);

  /// Unmodifiable items currently available for rendering; keep their stable
  /// keys unchanged across refreshes.
  final List<T> items;

  /// Request activity affecting this snapshot, independently of whether
  /// [items] are already available.
  final CollectionLoadPhase loadPhase;

  /// Whether visible items are current or retained stale data.
  final CollectionFreshness freshness;

  /// Distinguishes ordinary content, an empty underlying collection, and zero
  /// query results.
  final CollectionContentState contentState;

  /// Failure before usable items exist. Must be null when [items] is
  /// nonempty.
  final CollectionFailure? initialFailure;

  /// Failure while reloading or extending usable data; consumers can retain
  /// the current items.
  final CollectionFailure? refreshFailure;

  /// Source-provided pagination metadata. Its subtype determines which
  /// navigation operations are meaningful.
  final CollectionPageInfo pageInfo;

  /// Optional application-owned metadata that does not change the collection
  /// rendering contract.
  final CollectionMetadata? metadata;

  /// Whether any usable items are currently present, regardless of
  /// [loadPhase].
  bool get hasData => items.isNotEmpty;

  /// Whether [loadPhase] is the initial request phase.
  bool get isInitialLoading => loadPhase == CollectionLoadPhase.initialLoading;

  /// Whether [loadPhase] represents a refresh over existing data.
  bool get isRefreshing => loadPhase == CollectionLoadPhase.refreshing;

  /// Whether [loadPhase] represents a request for another batch.
  bool get isLoadingMore => loadPhase == CollectionLoadPhase.loadingMore;

  /// Returns a loading snapshot without discarding [items].
  ///
  /// An empty snapshot becomes initial-loading/current; a populated snapshot
  /// becomes refreshing/stale. Both failure slots are cleared. No request is
  /// executed.
  CollectionSnapshot<T> beginRefresh() => copyWith(
    loadPhase: items.isEmpty
        ? CollectionLoadPhase.initialLoading
        : CollectionLoadPhase.refreshing,
    freshness: items.isEmpty
        ? CollectionFreshness.current
        : CollectionFreshness.stale,
    clearInitialFailure: true,
    clearRefreshFailure: true,
  );

  /// Returns a snapshot with the same items in the loading-more phase and
  /// clears [refreshFailure]. No request is executed.
  CollectionSnapshot<T> beginLoadingMore() => copyWith(
    loadPhase: CollectionLoadPhase.loadingMore,
    clearRefreshFailure: true,
  );

  /// Records [failure] without destroying usable data.
  ///
  /// Empty snapshots become idle with [initialFailure]. Populated snapshots
  /// become ready/stale with [refreshFailure]. The opposite failure slot is
  /// cleared.
  CollectionSnapshot<T> withLoadFailure(CollectionFailure failure) =>
      items.isEmpty
      ? copyWith(
          loadPhase: CollectionLoadPhase.idle,
          initialFailure: failure,
          clearRefreshFailure: true,
        )
      : copyWith(
          loadPhase: CollectionLoadPhase.ready,
          freshness: CollectionFreshness.stale,
          refreshFailure: failure,
          clearInitialFailure: true,
        );

  /// Returns a snapshot with supplied replacements while retaining
  /// unspecified values.
  ///
  /// Nullable failures and metadata are retained when null is passed; use the
  /// corresponding clear flags to remove them. Clearing takes precedence.
  /// Replacing [items] does not recompute [pageInfo] or [contentState];
  /// provide consistent replacements explicitly.
  CollectionSnapshot<T> copyWith({
    List<T>? items,
    CollectionLoadPhase? loadPhase,
    CollectionFreshness? freshness,
    CollectionContentState? contentState,
    CollectionFailure? initialFailure,
    bool clearInitialFailure = false,
    CollectionFailure? refreshFailure,
    bool clearRefreshFailure = false,
    CollectionPageInfo? pageInfo,
    CollectionMetadata? metadata,
    bool clearMetadata = false,
  }) => CollectionSnapshot<T>(
    items: items ?? this.items,
    loadPhase: loadPhase ?? this.loadPhase,
    freshness: freshness ?? this.freshness,
    contentState: contentState ?? this.contentState,
    initialFailure: clearInitialFailure
        ? null
        : initialFailure ?? this.initialFailure,
    refreshFailure: clearRefreshFailure
        ? null
        : refreshFailure ?? this.refreshFailure,
    pageInfo: pageInfo ?? this.pageInfo,
    metadata: clearMetadata ? null : metadata ?? this.metadata,
  );
}
