import 'package:flutter/foundation.dart';

enum CollectionSortDirection { ascending, descending }

@immutable
final class CollectionSort {
  const CollectionSort({required this.id, required this.direction});

  final String id;
  final CollectionSortDirection direction;

  CollectionSort reversed() => CollectionSort(
    id: id,
    direction: direction == CollectionSortDirection.ascending
        ? CollectionSortDirection.descending
        : CollectionSortDirection.ascending,
  );

  @override
  bool operator ==(Object other) =>
      other is CollectionSort && other.id == id && other.direction == direction;

  @override
  int get hashCode => Object.hash(id, direction);
}

sealed class CollectionPageRequest {
  const CollectionPageRequest();
}

final class CollectionUnpagedRequest extends CollectionPageRequest {
  const CollectionUnpagedRequest();
}

final class CollectionOffsetPageRequest extends CollectionPageRequest {
  const CollectionOffsetPageRequest({required this.offset, required this.limit})
    : assert(offset >= 0),
      assert(limit > 0);

  final int offset;
  final int limit;
}

final class CollectionCursorPageRequest extends CollectionPageRequest {
  const CollectionCursorPageRequest({this.cursor, required this.limit})
    : assert(limit > 0);

  final String? cursor;
  final int limit;
}

final class CollectionKeysetPageRequest<K> extends CollectionPageRequest {
  const CollectionKeysetPageRequest({
    this.after,
    this.before,
    required this.limit,
  }) : assert(after == null || before == null),
       assert(limit > 0);

  final K? after;
  final K? before;
  final int limit;
}

final class CollectionProgressivePageRequest extends CollectionPageRequest {
  const CollectionProgressivePageRequest({
    required this.loadedCount,
    required this.batchSize,
  }) : assert(loadedCount >= 0),
       assert(batchSize > 0);

  final int loadedCount;
  final int batchSize;
}

@immutable
final class CollectionQuery<F> {
  CollectionQuery({
    this.filter,
    this.search,
    List<CollectionSort> sorting = const [],
    this.page = const CollectionUnpagedRequest(),
  }) : sorting = List.unmodifiable(sorting);

  final F? filter;
  final String? search;
  final List<CollectionSort> sorting;
  final CollectionPageRequest page;

  CollectionQuery<F> copyWith({
    F? filter,
    bool clearFilter = false,
    String? search,
    bool clearSearch = false,
    List<CollectionSort>? sorting,
    CollectionPageRequest? page,
  }) => CollectionQuery<F>(
    filter: clearFilter ? null : filter ?? this.filter,
    search: clearSearch ? null : search ?? this.search,
    sorting: sorting ?? this.sorting,
    page: page ?? this.page,
  );
}
