import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/components/basic/input/input.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

typedef CarpenterTableValue<T> = Object? Function(T item);
typedef CarpenterTableCellBuilder<T> =
    Widget Function(BuildContext context, T item);

final class CarpenterTableColumn<T> {
  const CarpenterTableColumn({
    required this.id,
    required this.label,
    required this.value,
    this.cell,
    this.filterValue,
    this.width = 160,
    this.sortable = true,
    this.searchable = true,
    this.filterable = false,
    this.align = Alignment.centerLeft,
  });

  final String id;
  final String label;
  final CarpenterTableValue<T> value;
  final CarpenterTableCellBuilder<T>? cell;
  final CarpenterTableValue<T>? filterValue;
  final double width;
  final bool sortable;
  final bool searchable;
  final bool filterable;
  final Alignment align;
}

/// A declarative, client-side data table with configurable columns, search,
/// per-column value filters and stable sorting.
final class CarpenterTable<T> extends StatefulWidget {
  const CarpenterTable({
    super.key,
    required this.items,
    required this.columns,
    this.initialSortColumnId,
    this.initialSortAscending = true,
    this.searchPlaceholder = 'Поиск по таблице',
    this.emptyMessage = 'Строки не найдены',
    this.onRowActivate,
    this.rowIdentity,
    this.showToolbar = true,
    this.rowHeight = 42,
    this.headerHeight = 40,
    this.maxBodyHeight,
  });

  final List<T> items;
  final List<CarpenterTableColumn<T>> columns;
  final String? initialSortColumnId;
  final bool initialSortAscending;
  final String searchPlaceholder;
  final String emptyMessage;
  final ValueChanged<T>? onRowActivate;
  final Object Function(T item)? rowIdentity;
  final bool showToolbar;
  final double rowHeight;
  final double headerHeight;
  final double? maxBodyHeight;

  @override
  State<CarpenterTable<T>> createState() => _CarpenterTableState<T>();
}

final class _CarpenterTableState<T> extends State<CarpenterTable<T>> {
  final TextEditingController search = TextEditingController();
  final Map<String, String> filters = {};
  String? sortColumnId;
  late bool sortAscending;

  @override
  void initState() {
    super.initState();
    sortColumnId = widget.initialSortColumnId;
    sortAscending = widget.initialSortAscending;
  }

  @override
  void didUpdateWidget(CarpenterTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = widget.columns.map((column) => column.id).toSet();
    filters.removeWhere((id, _) => !ids.contains(id));
    if (sortColumnId != null && !ids.contains(sortColumnId)) {
      sortColumnId = widget.initialSortColumnId;
    }
  }

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows();
    final width = widget.columns.fold<double>(
      0,
      (sum, column) => sum + column.width,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.showToolbar) ...[
          _toolbar(context, rows.length),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: context.face.color('border.subtle')),
            borderRadius: BorderRadius.circular(context.face.radius('md')),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(context.face.radius('md')),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_header(context), _body(context, rows)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, List<T> rows) {
    final body = rows.isEmpty
        ? SizedBox(
            height: widget.rowHeight * 2,
            child: Center(child: Text(widget.emptyMessage)),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < rows.length; index++)
                _row(context, rows[index], index),
            ],
          );
    final maxHeight = widget.maxBodyHeight;
    if (maxHeight == null) return body;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(child: body),
    );
  }

  Widget _toolbar(BuildContext context, int visibleCount) => Wrap(
    spacing: 8,
    runSpacing: 8,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 320,
        child: CarpenterInput(
          controller: search,
          placeholder: widget.searchPlaceholder,
          onChanged: (_) => setState(() {}),
        ),
      ),
      for (final column in widget.columns.where((column) => column.filterable))
        SizedBox(
          width: 190,
          child: CarpenterSelect<String?>(
            value: filters[column.id],
            placeholder: Text(column.label),
            items: [
              CarpenterSelectItem<String?>(
                value: null,
                child: Text('${column.label}: все'),
              ),
              for (final option in _filterOptions(column))
                CarpenterSelectItem<String?>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (value) => setState(() {
              if (value == null) {
                filters.remove(column.id);
              } else {
                filters[column.id] = value;
              }
            }),
          ),
        ),
      Text(
        'Строк: $visibleCount из ${widget.items.length}',
        style: context.face
            .type('caption')
            .copyWith(color: context.face.color('text.secondary')),
      ),
      if (search.text.isNotEmpty || filters.isNotEmpty)
        CarpenterButton(
          label: 'Сбросить',
          size: .small,
          prominence: .outlined,
          onInvoke: () => setState(() {
            search.clear();
            filters.clear();
          }),
        ),
    ],
  );

  Widget _header(BuildContext context) => Container(
    height: widget.headerHeight,
    color: context.face.color('surface.muted'),
    child: Row(
      children: [
        for (final column in widget.columns)
          _cell(
            column,
            MouseRegion(
              cursor: column.sortable
                  ? SystemMouseCursors.click
                  : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: column.sortable ? () => _sort(column.id) : null,
                child: Align(
                  alignment: column.align,
                  child: Text(
                    column.id == sortColumnId
                        ? '${column.label} ${sortAscending ? '▲' : '▼'}'
                        : column.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: context.face.type('label.strong'),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _row(BuildContext context, T item, int index) {
    final content = Container(
      key: ValueKey(widget.rowIdentity?.call(item) ?? index),
      height: widget.rowHeight,
      decoration: BoxDecoration(
        color: index.isOdd
            ? context.face.color('surface.muted')
            : context.face.color('surface.raised'),
        border: Border(
          top: BorderSide(color: context.face.color('border.subtle')),
        ),
      ),
      child: Row(
        children: [
          for (final column in widget.columns)
            _cell(
              column,
              Align(
                alignment: column.align,
                child:
                    column.cell?.call(context, item) ??
                    Text(
                      _text(column.value(item)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            ),
        ],
      ),
    );
    if (widget.onRowActivate == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onDoubleTap: () => widget.onRowActivate!(item),
      child: content,
    );
  }

  Widget _cell(CarpenterTableColumn<T> column, Widget child) => SizedBox(
    width: column.width,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: child,
    ),
  );

  List<T> _rows() {
    final needle = search.text.trim().toLowerCase();
    final rows = widget.items
        .where((item) {
          if (needle.isNotEmpty &&
              !widget.columns
                  .where((column) => column.searchable)
                  .any(
                    (column) => _text(
                      column.value(item),
                    ).toLowerCase().contains(needle),
                  )) {
            return false;
          }
          for (final filter in filters.entries) {
            final column = widget.columns.firstWhere(
              (column) => column.id == filter.key,
            );
            if (_text((column.filterValue ?? column.value)(item)) !=
                filter.value) {
              return false;
            }
          }
          return true;
        })
        .toList(growable: false);

    final id = sortColumnId;
    if (id == null) return rows;
    final column = widget.columns.firstWhere((column) => column.id == id);
    final indexed = rows.indexed.toList();
    indexed.sort((left, right) {
      final compared = _compare(column.value(left.$2), column.value(right.$2));
      if (compared != 0) return sortAscending ? compared : -compared;
      return left.$1.compareTo(right.$1);
    });
    return indexed.map((entry) => entry.$2).toList(growable: false);
  }

  List<String> _filterOptions(CarpenterTableColumn<T> column) {
    final values = widget.items
        .map((item) => _text((column.filterValue ?? column.value)(item)))
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    values.sort();
    return values;
  }

  void _sort(String id) => setState(() {
    if (sortColumnId == id) {
      sortAscending = !sortAscending;
    } else {
      sortColumnId = id;
      sortAscending = true;
    }
  });
}

int _compare(Object? left, Object? right) {
  if (identical(left, right)) return 0;
  if (left == null) return -1;
  if (right == null) return 1;
  if (left is num && right is num) return left.compareTo(right);
  if (left is DateTime && right is DateTime) return left.compareTo(right);
  return _text(left).toLowerCase().compareTo(_text(right).toLowerCase());
}

String _text(Object? value) => value?.toString().trim() ?? '';
