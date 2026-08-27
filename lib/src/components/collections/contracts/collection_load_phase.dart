enum CollectionLoadPhase {
  idle,
  initialLoading,
  ready,
  refreshing,
  loadingMore,
}

enum CollectionFreshness { current, stale }

enum CollectionContentState { content, zero, emptyResult }

final class CollectionFailure {
  const CollectionFailure({required this.error, this.message, this.stackTrace});

  final Object error;
  final String? message;
  final StackTrace? stackTrace;
}
