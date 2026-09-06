import 'package:flutter/foundation.dart';

/// Pagination metadata supplied by the data source for a snapshot.
///
/// Use subtype-specific cursor/key/offset data rather than assuming numbered
/// pages. [totalItems] may be unknown.
@immutable
sealed class CollectionPageInfo {
  /// Constructs page metadata with an optional known matching-item total.
  const CollectionPageInfo({this.totalItems});

  /// Total matching items across the source, or null when unknown.
  final int? totalItems;

  /// Whether the source metadata indicates another forward page or batch.
  bool get hasNext;

  /// Whether backward navigation is meaningful for this pagination strategy.
  bool get hasPrevious;

  /// Number of items represented by this page or accumulated batch, not
  /// necessarily the source total.
  int get loadedItems;

  /// Whether [totalItems] was supplied.
  bool get hasKnownTotal => totalItems != null;
}

/// Metadata for a complete unpaged result with no forward or backward
/// navigation.
final class CollectionUnpagedInfo extends CollectionPageInfo {
  /// Creates unpaged metadata with [itemCount] also used as the known total.
  const CollectionUnpagedInfo({required this.itemCount})
    : super(totalItems: itemCount);

  /// Number of items in the complete result.
  final int itemCount;

  /// Always false because this is an unpaged result.
  @override
  bool get hasNext => false;

  /// Always false because this is an unpaged result.
  @override
  bool get hasPrevious => false;

  /// Number of items in the complete result.
  @override
  int get loadedItems => itemCount;
}

/// Offset-page metadata supporting both known and unknown totals.
///
/// When [moreAvailable] is supplied it overrides inferred forward
/// availability; otherwise a full page implies more may exist when no total
/// is known.
final class CollectionOffsetPageInfo extends CollectionPageInfo {
  /// Describes an offset page using its requested size, returned count,
  /// optional total, and optional explicit continuation flag.
  const CollectionOffsetPageInfo({
    required this.offset,
    required this.limit,
    required this.itemCount,
    super.totalItems,
    this.moreAvailable,
  });

  /// Zero-based starting offset of this page.
  final int offset;

  /// Requested page size used to infer continuation when the total is
  /// unknown.
  final int limit;

  /// Actual number of items returned for this page.
  final int itemCount;

  /// Explicit continuation indicator, overriding total/count inference when
  /// provided.
  final bool? moreAvailable;

  /// Uses [moreAvailable] first, then compares offset plus count with the
  /// known total, or treats a full page as potentially having a successor.
  @override
  bool get hasNext =>
      moreAvailable ??
      (totalItems == null
          ? itemCount >= limit
          : offset + itemCount < totalItems!);

  /// Whether [offset] is greater than zero.
  @override
  bool get hasPrevious => offset > 0;

  /// Actual count returned for this page, not offset plus count.
  @override
  int get loadedItems => itemCount;
}

/// Page metadata navigated by a source-owned opaque cursor; a missing
/// boundary means navigation in that direction is unavailable.
final class CollectionCursorPageInfo extends CollectionPageInfo {
  /// Describes the returned page and optional continuation boundaries. A
  /// source total is not required.
  const CollectionCursorPageInfo({
    required this.itemCount,
    this.nextCursor,
    this.previousCursor,
    super.totalItems,
  });

  /// Actual number of items returned in this page.
  final int itemCount;

  /// Opaque cursor for the following page, or null when unavailable.
  final String? nextCursor;

  /// Opaque cursor for the preceding page, or null when unavailable.
  final String? previousCursor;

  /// Whether [nextCursor] is available.
  @override
  bool get hasNext => nextCursor != null;

  /// Whether [previousCursor] is available.
  @override
  bool get hasPrevious => previousCursor != null;

  /// Actual number of items in this page.
  @override
  int get loadedItems => itemCount;
}

/// Page metadata navigated by a source-owned typed ordering key; a missing
/// boundary means navigation in that direction is unavailable.
final class CollectionKeysetPageInfo<K> extends CollectionPageInfo {
  /// Describes the returned page and optional continuation boundaries. A
  /// source total is not required.
  const CollectionKeysetPageInfo({
    required this.itemCount,
    this.nextKey,
    this.previousKey,
    super.totalItems,
  });

  /// Actual number of items returned in this page.
  final int itemCount;

  /// Typed ordering key for the following page, or null when unavailable.
  final K? nextKey;

  /// Typed ordering key for the preceding page, or null when unavailable.
  final K? previousKey;

  /// Whether [nextKey] is available.
  @override
  bool get hasNext => nextKey != null;

  /// Whether [previousKey] is available.
  @override
  bool get hasPrevious => previousKey != null;

  /// Actual number of items in this page.
  @override
  int get loadedItems => itemCount;
}

/// Metadata for accumulated batches with forward loading but no backward page
/// navigation.
final class CollectionProgressivePageInfo extends CollectionPageInfo {
  /// Describes the accumulated item count and explicit availability of
  /// another batch.
  const CollectionProgressivePageInfo({
    required this.loadedItems,
    required this.hasMore,
    super.totalItems,
  });

  /// Number of items accumulated across all loaded batches.
  @override
  final int loadedItems;

  /// Whether the source allows another batch request.
  final bool hasMore;

  /// Whether [hasMore] allows loading another batch.
  @override
  bool get hasNext => hasMore;

  /// Always false; accumulated batches do not have a previous-page operation.
  @override
  bool get hasPrevious => false;
}
