import 'package:flutter/foundation.dart';

import '../pagination.dart';
import 'collection_load_phase.dart';

abstract interface class CollectionMetadata {}

@immutable
final class CollectionSnapshot<T> {
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

  factory CollectionSnapshot.initialLoading() =>
      CollectionSnapshot<T>(loadPhase: CollectionLoadPhase.initialLoading);

  final List<T> items;
  final CollectionLoadPhase loadPhase;
  final CollectionFreshness freshness;
  final CollectionContentState contentState;
  final CollectionFailure? initialFailure;
  final CollectionFailure? refreshFailure;
  final CollectionPageInfo pageInfo;
  final CollectionMetadata? metadata;

  bool get hasData => items.isNotEmpty;
  bool get isInitialLoading => loadPhase == CollectionLoadPhase.initialLoading;
  bool get isRefreshing => loadPhase == CollectionLoadPhase.refreshing;
  bool get isLoadingMore => loadPhase == CollectionLoadPhase.loadingMore;

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

  CollectionSnapshot<T> beginLoadingMore() => copyWith(
    loadPhase: CollectionLoadPhase.loadingMore,
    clearRefreshFailure: true,
  );

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
