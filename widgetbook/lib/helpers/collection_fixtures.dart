import 'package:carpenter/carpenter.dart';

enum DemoCollectionScenario {
  loaded,
  initialLoading,
  refreshing,
  initialError,
  refreshError,
  zero,
  emptyResult,
  loadingMore,
}

enum DemoPaginationFixture {
  unpaged,
  cursor,
  keyset,
  progressive,
  unknownTotal,
}

CollectionPageInfo demoPageInfo(
  DemoPaginationFixture fixture, {
  required int itemCount,
}) => switch (fixture) {
  DemoPaginationFixture.unpaged => CollectionUnpagedInfo(itemCount: itemCount),
  DemoPaginationFixture.cursor => CollectionCursorPageInfo(
    itemCount: itemCount,
    nextCursor: 'next',
  ),
  DemoPaginationFixture.keyset => CollectionKeysetPageInfo<int>(
    itemCount: itemCount,
    nextKey: itemCount + 1,
  ),
  DemoPaginationFixture.progressive => CollectionProgressivePageInfo(
    loadedItems: itemCount,
    hasMore: true,
    totalItems: itemCount + 30,
  ),
  DemoPaginationFixture.unknownTotal => CollectionOffsetPageInfo(
    offset: 0,
    limit: itemCount == 0 ? 1 : itemCount,
    itemCount: itemCount,
    moreAvailable: true,
  ),
};

CollectionSnapshot<T> demoCollectionSnapshot<T>({
  required List<T> items,
  required DemoCollectionScenario scenario,
  DemoPaginationFixture pagination = DemoPaginationFixture.unpaged,
}) {
  final pageInfo = demoPageInfo(pagination, itemCount: items.length);
  return switch (scenario) {
    DemoCollectionScenario.loaded => CollectionSnapshot<T>(
      items: items,
      pageInfo: pageInfo,
    ),
    DemoCollectionScenario.initialLoading => CollectionSnapshot<T>.initialLoading(),
    DemoCollectionScenario.refreshing => CollectionSnapshot<T>(
      items: items,
      loadPhase: CollectionLoadPhase.refreshing,
      freshness: CollectionFreshness.stale,
      pageInfo: pageInfo,
    ),
    DemoCollectionScenario.initialError => CollectionSnapshot<T>(
      initialFailure: const CollectionFailure(
        error: 'network',
        message: 'Initial load failed',
      ),
    ),
    DemoCollectionScenario.refreshError => CollectionSnapshot<T>(
      items: items,
      freshness: CollectionFreshness.stale,
      refreshFailure: const CollectionFailure(
        error: 'network',
        message: 'Refresh failed; existing data is retained',
      ),
      pageInfo: pageInfo,
    ),
    DemoCollectionScenario.zero => CollectionSnapshot<T>(
      contentState: CollectionContentState.zero,
    ),
    DemoCollectionScenario.emptyResult => CollectionSnapshot<T>(
      contentState: CollectionContentState.emptyResult,
    ),
    DemoCollectionScenario.loadingMore => CollectionSnapshot<T>(
      items: items,
      loadPhase: CollectionLoadPhase.loadingMore,
      pageInfo: pageInfo,
    ),
  };
}
