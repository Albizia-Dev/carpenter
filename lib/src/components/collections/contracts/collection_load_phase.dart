/// Load operation currently affecting a collection, separate from freshness,
/// content emptiness, and item mutations.
enum CollectionLoadPhase {
  /// No load operation is active; data may not have been requested yet.
  idle,

  /// Loading before usable items are available.
  initialLoading,

  /// A load has completed and the current snapshot can be presented.
  ready,

  /// Replacing or revalidating previously usable data without discarding it.
  refreshing,

  /// Fetching another batch while keeping the accumulated items visible.
  loadingMore,
}

/// Whether the currently visible items are considered up to date.
enum CollectionFreshness {
  /// The snapshot is considered up to date by its producer.
  current,

  /// The visible items may be out of date but can still be useful.
  stale,
}

/// Meaning of collection content, distinct from an active request or request
/// failure.
enum CollectionContentState {
  /// The normal content presentation, including transient snapshots before a
  /// load finishes.
  content,

  /// There are no items in the underlying collection, for example before the
  /// first record is created.
  zero,

  /// The current query has no matching items, even though the underlying
  /// collection may contain data.
  emptyResult,
}

/// Transport-neutral failure information for collection loading or mutation.
///
/// Provide a safe [message] for user-facing presentation rather than exposing
/// arbitrary exception details.
final class CollectionFailure {
  /// Records [error] with an optional display [message] and diagnostic
  /// [stackTrace].
  const CollectionFailure({required this.error, this.message, this.stackTrace});

  /// Original failure object for diagnostics and application-level handling.
  final Object error;

  /// Optional user-facing explanation; may be omitted when the presentation
  /// supplies a fallback.
  final String? message;

  /// Optional diagnostic stack trace associated with [error].
  final StackTrace? stackTrace;
}
