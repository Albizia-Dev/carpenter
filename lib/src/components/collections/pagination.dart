import 'package:flutter/foundation.dart';

@immutable
sealed class CollectionPageInfo {
  const CollectionPageInfo({this.totalItems});

  final int? totalItems;

  bool get hasNext;
  bool get hasPrevious;
  int get loadedItems;
  bool get hasKnownTotal => totalItems != null;
}

final class CollectionUnpagedInfo extends CollectionPageInfo {
  const CollectionUnpagedInfo({required this.itemCount})
    : super(totalItems: itemCount);

  final int itemCount;

  @override
  bool get hasNext => false;
  @override
  bool get hasPrevious => false;
  @override
  int get loadedItems => itemCount;
}

final class CollectionOffsetPageInfo extends CollectionPageInfo {
  const CollectionOffsetPageInfo({
    required this.offset,
    required this.limit,
    required this.itemCount,
    super.totalItems,
    this.moreAvailable,
  });

  final int offset;
  final int limit;
  final int itemCount;
  final bool? moreAvailable;

  @override
  bool get hasNext =>
      moreAvailable ??
      (totalItems == null
          ? itemCount >= limit
          : offset + itemCount < totalItems!);
  @override
  bool get hasPrevious => offset > 0;
  @override
  int get loadedItems => itemCount;
}

final class CollectionCursorPageInfo extends CollectionPageInfo {
  const CollectionCursorPageInfo({
    required this.itemCount,
    this.nextCursor,
    this.previousCursor,
    super.totalItems,
  });

  final int itemCount;
  final String? nextCursor;
  final String? previousCursor;

  @override
  bool get hasNext => nextCursor != null;
  @override
  bool get hasPrevious => previousCursor != null;
  @override
  int get loadedItems => itemCount;
}

final class CollectionKeysetPageInfo<K> extends CollectionPageInfo {
  const CollectionKeysetPageInfo({
    required this.itemCount,
    this.nextKey,
    this.previousKey,
    super.totalItems,
  });

  final int itemCount;
  final K? nextKey;
  final K? previousKey;

  @override
  bool get hasNext => nextKey != null;
  @override
  bool get hasPrevious => previousKey != null;
  @override
  int get loadedItems => itemCount;
}

final class CollectionProgressivePageInfo extends CollectionPageInfo {
  const CollectionProgressivePageInfo({
    required this.loadedItems,
    required this.hasMore,
    super.totalItems,
  });

  @override
  final int loadedItems;
  final bool hasMore;

  @override
  bool get hasNext => hasMore;
  @override
  bool get hasPrevious => false;
}
