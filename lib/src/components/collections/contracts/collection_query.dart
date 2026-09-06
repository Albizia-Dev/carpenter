import 'package:flutter/foundation.dart';

/// Ordering requested for one collection sort key; the data adapter performs
/// the sort.
enum CollectionSortDirection {
  /// Order from lower to higher values according to the adapter's comparison
  /// rules.
  ascending,

  /// Order from higher to lower values according to the adapter's comparison
  /// rules.
  descending,
}

/// One immutable sort criterion, identified independently of a rendered
/// column.
///
/// The order of criteria in [CollectionQuery.sorting] determines their
/// precedence. This descriptor does not sort items itself.
@immutable
final class CollectionSort {
  /// Creates a sort criterion for [id] in [direction].
  const CollectionSort({required this.id, required this.direction});

  /// Stable identifier understood by the collection loader, typically a
  /// column or domain sort key.
  final String id;

  /// Requested ordering of values for [id].
  final CollectionSortDirection direction;

  /// Returns a new criterion with the same [id] and the opposite [direction].
  CollectionSort reversed() => CollectionSort(
    id: id,
    direction: direction == CollectionSortDirection.ascending
        ? CollectionSortDirection.descending
        : CollectionSortDirection.ascending,
  );

  /// Compares both [id] and [direction]; two equivalent sort requests compare
  /// equal.
  @override
  bool operator ==(Object other) =>
      other is CollectionSort && other.id == id && other.direction == direction;

  /// Hash derived from [id] and [direction], consistent with equality.
  @override
  int get hashCode => Object.hash(id, direction);
}

/// Backend-neutral pagination request carried by [CollectionQuery].
///
/// Choose the subtype supported by the loader. A cursor or keyset request
/// does not imply that an offset or total count is available.
sealed class CollectionPageRequest {
  /// Base constructor for the supported pagination request variants.
  const CollectionPageRequest();
}

/// Requests a collection without a paging boundary. The loader decides the
/// size of the returned snapshot.
final class CollectionUnpagedRequest extends CollectionPageRequest {
  /// Creates a request without offset, cursor, or batch constraints.
  const CollectionUnpagedRequest();
}

/// Requests a bounded range using a zero-based offset. Use only when the data
/// source supports offset pagination.
final class CollectionOffsetPageRequest extends CollectionPageRequest {
  /// Creates an offset request. Asserts that [offset] is nonnegative and
  /// [limit] is positive.
  const CollectionOffsetPageRequest({required this.offset, required this.limit})
    : assert(offset >= 0),
      assert(limit > 0);

  /// Number of matching items to skip before returning the page.
  final int offset;

  /// Maximum requested number of items; must be greater than zero.
  final int limit;
}

/// Requests a page using an opaque, source-owned cursor. Consumers must not
/// interpret the cursor as an offset.
final class CollectionCursorPageRequest extends CollectionPageRequest {
  /// Creates a cursor request. Omit [cursor] for the initial page; [limit]
  /// must be positive.
  const CollectionCursorPageRequest({this.cursor, required this.limit})
    : assert(limit > 0);

  /// Opaque continuation token returned by the source, or null for the
  /// initial request.
  final String? cursor;

  /// Maximum requested number of items; must be greater than zero.
  final int limit;
}

/// Requests a page on one side of a stable ordering key.
///
/// The loader owns key comparison and ordering. [after] and [before] are
/// mutually exclusive; neither being supplied requests the initial page.
final class CollectionKeysetPageRequest<K> extends CollectionPageRequest {
  /// Creates a keyset request. Asserts a positive [limit] and that at most
  /// one of [after] and [before] is supplied.
  const CollectionKeysetPageRequest({
    this.after,
    this.before,
    required this.limit,
  }) : assert(after == null || before == null),
       assert(limit > 0);

  /// Exclusive lower continuation boundary, interpreted by the loader.
  final K? after;

  /// Exclusive upper continuation boundary, interpreted by the loader.
  final K? before;

  /// Maximum requested number of items; must be greater than zero.
  final int limit;
}

/// Requests another batch after an already accumulated set of items.
///
/// This descriptor describes progressive loading, not a requirement that the
/// backend expose numbered pages.
final class CollectionProgressivePageRequest extends CollectionPageRequest {
  /// Creates a batch request. Asserts a nonnegative [loadedCount] and
  /// positive [batchSize].
  const CollectionProgressivePageRequest({
    required this.loadedCount,
    required this.batchSize,
  }) : assert(loadedCount >= 0),
       assert(batchSize > 0);

  /// Number of items already accumulated by the caller.
  final int loadedCount;

  /// Requested maximum number of additional items.
  final int batchSize;
}

/// Immutable input to a collection loader: domain filter, search, ordered
/// sort criteria, and a paging request.
///
/// [F] remains application-owned. Carpenter does not translate the filter
/// into HTTP, SQL, or repository operations. The sorting list is copied into
/// an unmodifiable list.
@immutable
final class CollectionQuery<F> {
  /// Creates a query and defensively copies [sorting]. Omitted [page]
  /// requests an unpaged result.
  CollectionQuery({
    this.filter,
    this.search,
    List<CollectionSort> sorting = const [],
    this.page = const CollectionUnpagedRequest(),
  }) : sorting = List.unmodifiable(sorting);

  /// Optional application-defined filter. The loader owns its interpretation
  /// and validation.
  final F? filter;

  /// Optional search text understood by the loader. This model does not trim
  /// or normalize it.
  final String? search;

  /// Unmodifiable sort criteria in precedence order; the loader applies them.
  final List<CollectionSort> sorting;

  /// Pagination strategy and boundary for this request.
  final CollectionPageRequest page;

  /// Returns a query with supplied replacements.
  ///
  /// Null [filter] or [search] retains the current value; use [clearFilter]
  /// or [clearSearch] to explicitly remove it. Clearing takes precedence over
  /// a replacement. An omitted [sorting] or [page] is retained.
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
