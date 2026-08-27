import 'dart:async';

import 'package:carpenter/src/legacy/src/block/page_blocks.dart';
import 'package:carpenter/src/components/basic/button/button.dart';
import 'package:carpenter/src/components/basic/card.dart';
import 'package:carpenter/src/components/basic/input/input.dart';
import 'package:carpenter/src/foundation/roles.dart';
import 'package:carpenter/src/legacy/src/component/loader/carpenter_loader.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/page/capability.dart';
import 'package:carpenter/src/legacy/src/page/command.dart';
import 'package:carpenter/src/legacy/src/page/controller.dart';
import 'package:carpenter/src/legacy/src/page/descriptor.dart';
import 'package:carpenter/src/legacy/src/page/state.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum CarpenterCollectionLoadReason { initial, query, refresh, nextPage }

/// Cancellation signal owned by a collection controller.
class CarpenterCollectionCancellation extends ChangeNotifier {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    notifyListeners();
  }
}

final class CarpenterCollectionLoadRequest {
  const CarpenterCollectionLoadRequest({
    required this.reason,
    required this.cancellation,
  });

  final CarpenterCollectionLoadReason reason;
  final CarpenterCollectionCancellation cancellation;

  bool get refresh => reason == CarpenterCollectionLoadReason.refresh;
}

final class CarpenterCollectionQuery<TFilter, TSort> {
  const CarpenterCollectionQuery({
    required this.search,
    required this.filter,
    required this.sort,
  });

  final String search;
  final TFilter filter;
  final TSort sort;

  CarpenterCollectionQuery<TFilter, TSort> copyWith({
    String? search,
    TFilter? filter,
    TSort? sort,
  }) => CarpenterCollectionQuery(
    search: search ?? this.search,
    filter: filter ?? this.filter,
    sort: sort ?? this.sort,
  );
}

sealed class CarpenterCollectionState<T> {
  const CarpenterCollectionState();

  List<T> get visibleItems => const [];
}

final class CarpenterCollectionInitialLoading<T>
    extends CarpenterCollectionState<T> {
  const CarpenterCollectionInitialLoading();
}

final class CarpenterCollectionReady<T> extends CarpenterCollectionState<T> {
  const CarpenterCollectionReady({
    required this.items,
    this.refreshing = false,
    this.hasNextPage = false,
    this.page = 1,
    this.totalPages = 1,
    this.totalItems,
  });

  final List<T> items;
  final bool refreshing;
  final bool hasNextPage;
  final int page;
  final int totalPages;
  final int? totalItems;

  @override
  List<T> get visibleItems => items;
}

final class CarpenterCollectionEmpty<T> extends CarpenterCollectionState<T> {
  const CarpenterCollectionEmpty({this.filtered = false});

  final bool filtered;
}

final class CarpenterCollectionFailure<T> extends CarpenterCollectionState<T> {
  const CarpenterCollectionFailure({required this.error, this.message});

  final Object error;
  final String? message;
}

final class CarpenterCollectionLoadingNext<T>
    extends CarpenterCollectionState<T> {
  const CarpenterCollectionLoadingNext({required this.items});

  final List<T> items;

  @override
  List<T> get visibleItems => items;
}

final class CarpenterCollectionPartialFailure<T>
    extends CarpenterCollectionState<T> {
  const CarpenterCollectionPartialFailure({
    required this.items,
    required this.error,
  });

  final List<T> items;
  final Object error;

  @override
  List<T> get visibleItems => items;
}

abstract interface class CarpenterDataCollectionController<T, TFilter, TSort>
    implements ValueListenable<CarpenterCollectionState<T>> {
  CarpenterCollectionQuery<TFilter, TSort> get query;

  CarpenterSelectionController<T>? get selection;

  Future<void> refresh();

  Future<void> loadNext();

  void updateSearch(String value);

  Future<void> goToPage(int page);
}

/// A reusable controller adapter for domain-owned collection loading.
class CarpenterDataCollectionControllerBase<T, TFilter, TSort>
    extends ValueNotifier<CarpenterCollectionState<T>>
    implements CarpenterDataCollectionController<T, TFilter, TSort> {
  CarpenterDataCollectionControllerBase({
    required this.query,
    required Future<CarpenterCollectionState<T>> Function(
      CarpenterCollectionQuery<TFilter, TSort> query,
      CarpenterCollectionLoadRequest request,
    )
    loadRequest,
    Future<CarpenterCollectionState<T>> Function(
      CarpenterCollectionQuery<TFilter, TSort> query,
      CarpenterCollectionState<T> current,
    )?
    loadNext,
    this.selection,
    CarpenterCollectionState<T>? initialState,
    CarpenterCollectionQuery<TFilter, TSort> Function(
      CarpenterCollectionQuery<TFilter, TSort> query,
      String search,
    )?
    queryForSearch,
    CarpenterCollectionQuery<TFilter, TSort> Function(
      CarpenterCollectionQuery<TFilter, TSort> query,
      int page,
    )?
    queryForPage,
    this.searchDebounce = const Duration(milliseconds: 350),
    this.errorMessage,
  }) : _loadRequest = loadRequest,
       _loadNext = loadNext,
       _queryForSearch = queryForSearch,
       _queryForPage = queryForPage,
       super(initialState ?? CarpenterCollectionInitialLoading<T>());

  @override
  CarpenterCollectionQuery<TFilter, TSort> query;
  final Future<CarpenterCollectionState<T>> Function(
    CarpenterCollectionQuery<TFilter, TSort> query,
    CarpenterCollectionLoadRequest request,
  )
  _loadRequest;
  final Future<CarpenterCollectionState<T>> Function(
    CarpenterCollectionQuery<TFilter, TSort> query,
    CarpenterCollectionState<T> current,
  )?
  _loadNext;
  final CarpenterCollectionQuery<TFilter, TSort> Function(
    CarpenterCollectionQuery<TFilter, TSort> query,
    String search,
  )?
  _queryForSearch;
  final CarpenterCollectionQuery<TFilter, TSort> Function(
    CarpenterCollectionQuery<TFilter, TSort> query,
    int page,
  )?
  _queryForPage;
  final Duration searchDebounce;
  final String Function(Object error)? errorMessage;
  Timer? _searchTimer;
  CarpenterCollectionCancellation? _cancellation;

  @override
  final CarpenterSelectionController<T>? selection;
  int _request = 0;

  Future<void> initialize() => _loadFor(CarpenterCollectionLoadReason.initial);

  @override
  Future<void> refresh() => _loadFor(CarpenterCollectionLoadReason.refresh);

  Future<void> _loadFor(CarpenterCollectionLoadReason reason) async {
    final request = ++_request;
    _cancellation?.cancel();
    final cancellation = CarpenterCollectionCancellation();
    _cancellation = cancellation;
    final items = value.visibleItems;
    final replaceContent =
        reason == CarpenterCollectionLoadReason.initial && items.isEmpty;
    value = replaceContent
        ? CarpenterCollectionInitialLoading<T>()
        : CarpenterCollectionReady<T>(items: items, refreshing: true);
    try {
      final next = await _loadRequest(
        query,
        CarpenterCollectionLoadRequest(
          reason: reason,
          cancellation: cancellation,
        ),
      );
      if (request == _request && !cancellation.isCancelled) {
        didLoad(next);
        value = next;
      }
    } catch (error) {
      if (request != _request || cancellation.isCancelled) return;
      value = replaceContent
          ? CarpenterCollectionFailure<T>(
              error: error,
              message: errorMessage?.call(error),
            )
          : CarpenterCollectionPartialFailure<T>(items: items, error: error);
    } finally {
      if (identical(_cancellation, cancellation)) {
        _cancellation = null;
      }
      cancellation.dispose();
    }
  }

  /// Hook for application controllers that keep derived summaries or groups.
  @protected
  void didLoad(CarpenterCollectionState<T> state) {}

  @override
  Future<void> loadNext() async {
    final loader = _loadNext;
    if (loader == null || value is CarpenterCollectionLoadingNext<T>) return;
    final current = value;
    final items = current.visibleItems;
    value = CarpenterCollectionLoadingNext<T>(items: items);
    try {
      value = await loader(query, current);
    } catch (error) {
      value = CarpenterCollectionPartialFailure<T>(items: items, error: error);
    }
  }

  @override
  void updateSearch(String value) {
    final normalized = value.trim();
    if (query.search == normalized) return;
    _searchTimer?.cancel();
    _searchTimer = Timer(searchDebounce, () {
      query =
          _queryForSearch?.call(query, normalized) ??
          query.copyWith(search: normalized);
      _loadFor(CarpenterCollectionLoadReason.query);
    });
  }

  void updateQuery(
    CarpenterCollectionQuery<TFilter, TSort> next, {
    bool load = true,
  }) {
    query = next;
    if (load) _loadFor(CarpenterCollectionLoadReason.query);
  }

  @override
  Future<void> goToPage(int page) async {
    final update = _queryForPage;
    if (update == null) return;
    query = update(query, page);
    await _loadFor(CarpenterCollectionLoadReason.query);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    _cancellation?.cancel();
    _cancellation?.dispose();
    super.dispose();
  }
}

typedef CarpenterCollectionControllerFactory<
  T,
  TFilter,
  TSort,
  C extends CarpenterDataCollectionControllerBase<T, TFilter, TSort>
> = C Function(BuildContext context);

/// Owns a collection controller lifecycle outside the domain page widget.
class CarpenterCollectionControllerHost<
  T,
  TFilter,
  TSort,
  C extends CarpenterDataCollectionControllerBase<T, TFilter, TSort>
>
    extends StatefulWidget {
  const CarpenterCollectionControllerHost({
    super.key,
    required this.create,
    required this.builder,
  });

  final CarpenterCollectionControllerFactory<T, TFilter, TSort, C> create;
  final Widget Function(BuildContext context, C controller) builder;

  @override
  State<CarpenterCollectionControllerHost<T, TFilter, TSort, C>>
  createState() =>
      _CarpenterCollectionControllerHostState<T, TFilter, TSort, C>();
}

class _CarpenterCollectionControllerHostState<
  T,
  TFilter,
  TSort,
  C extends CarpenterDataCollectionControllerBase<T, TFilter, TSort>
>
    extends State<CarpenterCollectionControllerHost<T, TFilter, TSort, C>> {
  C? controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (controller != null) return;
    final created = widget.create(context);
    controller = created;
    unawaited(created.initialize());
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, controller!);
}

/// Search input whose debounce and query mutation are controller-owned.
class CarpenterCollectionSearchField<T, TFilter, TSort> extends StatefulWidget {
  const CarpenterCollectionSearchField({
    super.key,
    required this.controller,
    this.placeholder,
    this.prefix,
    this.width = 520,
  });

  final CarpenterDataCollectionControllerBase<T, TFilter, TSort> controller;
  final String? placeholder;
  final Widget? prefix;
  final double width;

  @override
  State<CarpenterCollectionSearchField<T, TFilter, TSort>> createState() =>
      _CarpenterCollectionSearchFieldState<T, TFilter, TSort>();
}

class _CarpenterCollectionSearchFieldState<T, TFilter, TSort>
    extends State<CarpenterCollectionSearchField<T, TFilter, TSort>> {
  late final TextEditingController text = TextEditingController(
    text: widget.controller.query.search,
  );
  late final FocusNode focusNode = FocusNode();

  @override
  void dispose() {
    focusNode.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: widget.width,
    child: CarpenterInput(
      controller: text,
      focusNode: focusNode,
      placeholder: widget.placeholder,
      leadingIcon: switch (widget.prefix) {
        Icon(:final icon) => icon,
        _ => null,
      },
      trailingAction: text.text.isEmpty
          ? null
          : CarpenterActionDescriptor(
              id: 'clear-search',
              label: 'Очистить поиск',
              icon: CarpenterIcons.clear,
              onInvoke: () {
                text.clear();
                widget.controller.updateSearch('');
                setState(() {});
              },
            ),
      onChanged: (value) {
        widget.controller.updateSearch(value);
        setState(() {});
      },
    ),
  );
}

final class CarpenterDataGroup<T> {
  const CarpenterDataGroup({
    required this.id,
    required this.header,
    required this.items,
    this.collapsible = true,
    this.initiallyExpanded = true,
    this.onExpandedChanged,
  });

  final Object id;
  final Widget header;
  final List<T> items;
  final bool collapsible;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onExpandedChanged;
}

typedef CarpenterDataCollectionItemBuilder<T> =
    Widget Function(BuildContext context, T item, bool selected);

/// Functional collection block with state, selection and pagination behavior.
class CarpenterDataCollection<T, TFilter, TSort> extends StatefulWidget {
  const CarpenterDataCollection({
    super.key,
    required this.controller,
    required this.itemIdentity,
    required this.itemBuilder,
    this.groupBy,
    this.itemActionsBuilder,
    this.onItemActivate,
    this.empty,
    this.filteredEmpty,
    this.separator,
    this.padding,
  });

  final CarpenterDataCollectionController<T, TFilter, TSort> controller;
  final Object Function(T item) itemIdentity;
  final CarpenterDataCollectionItemBuilder<T> itemBuilder;
  final List<CarpenterDataGroup<T>> Function(List<T> items)? groupBy;
  final List<Widget> Function(BuildContext context, T item)? itemActionsBuilder;
  final ValueChanged<T>? onItemActivate;
  final CarpenterEmptyStateDescriptor? empty;
  final CarpenterEmptyStateDescriptor? filteredEmpty;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;

  @override
  State<CarpenterDataCollection<T, TFilter, TSort>> createState() =>
      _CarpenterDataCollectionState<T, TFilter, TSort>();
}

class _CarpenterDataCollectionState<T, TFilter, TSort>
    extends State<CarpenterDataCollection<T, TFilter, TSort>> {
  int focusedIndex = 0;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<CarpenterCollectionState<T>>(
        valueListenable: widget.controller,
        builder: (context, state, _) => _state(context, state),
      );

  Widget _state(BuildContext context, CarpenterCollectionState<T> state) {
    return switch (state) {
      CarpenterCollectionInitialLoading<T>() => const Center(
        child: CarpenterLoader(),
      ),
      CarpenterCollectionEmpty<T>(:final filtered) => CarpenterEmptyState(
        descriptor: filtered
            ? widget.filteredEmpty ??
                  const CarpenterEmptyStateDescriptor(
                    title: 'По текущим условиям ничего не найдено',
                    kind: CarpenterEmptyStateKind.filtered,
                  )
            : widget.empty ??
                  const CarpenterEmptyStateDescriptor(
                    title: 'Записей пока нет',
                  ),
      ),
      CarpenterCollectionFailure<T>(:final error, :final message) => Center(
        child: CarpenterNotice(
          title: const Text('Не удалось загрузить данные'),
          content: Text(message ?? error.toString()),
          tone: CarpenterNoticeTone.danger,
          action: CarpenterButton(
            onInvoke: widget.controller.refresh,
            label: 'Повторить',
          ),
        ),
      ),
      CarpenterCollectionReady<T>() ||
      CarpenterCollectionLoadingNext<T>() ||
      CarpenterCollectionPartialFailure<T>() => _items(context, state),
    };
  }

  Widget _items(BuildContext context, CarpenterCollectionState<T> state) {
    final items = state.visibleItems;
    final grouped = widget.groupBy?.call(items);
    final rows = grouped == null
        ? <_CollectionRow<T>>[
            for (final item in items) _CollectionItemRow(item),
          ]
        : <_CollectionRow<T>>[
            for (final group in grouped) _CollectionGroupRow(group),
          ];
    final itemRows = grouped == null
        ? rows.whereType<_CollectionItemRow<T>>().toList()
        : [
            for (final group in grouped)
              for (final item in group.items) _CollectionItemRow(item),
          ];
    focusedIndex = focusedIndex
        .clamp(0, itemRows.isEmpty ? 0 : itemRows.length - 1)
        .toInt();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowDown): () {
          setState(() {
            focusedIndex = (focusedIndex + 1)
                .clamp(0, itemRows.isEmpty ? 0 : itemRows.length - 1)
                .toInt();
          });
        },
        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
          setState(
            () => focusedIndex = (focusedIndex - 1).clamp(0, 1 << 20).toInt(),
          );
        },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (itemRows.isNotEmpty) {
            widget.onItemActivate?.call(itemRows[focusedIndex].item);
          }
        },
        const SingleActivator(LogicalKeyboardKey.space): () {
          if (itemRows.isNotEmpty) {
            widget.controller.selection?.toggle(itemRows[focusedIndex].item);
          }
        },
      },
      child: Focus(
        autofocus: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state is CarpenterCollectionReady<T> && state.refreshing)
              const CarpenterPageLoadingBar(),
            if (state is CarpenterCollectionPartialFailure<T>)
              CarpenterNotice(
                title: const Text('Часть данных недоступна'),
                content: Text(state.error.toString()),
                tone: CarpenterNoticeTone.warning,
              ),
            Expanded(
              child: ListView.separated(
                padding: widget.padding,
                itemCount: rows.length,
                separatorBuilder: (_, _) =>
                    widget.separator ?? const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final row = rows[index];
                  if (row is _CollectionGroupRow<T>) {
                    final group = row.group;
                    final content = CarpenterBlockGroup(
                      children: [
                        for (final item in group.items) _item(context, item),
                      ],
                    );
                    if (!group.collapsible) {
                      return CarpenterPageSection(
                        id: CarpenterPageSectionId('collection.${group.id}'),
                        title: '',
                        child: content,
                      );
                    }
                    return CarpenterExpander(
                      key: ValueKey(group.id),
                      initiallyExpanded: group.initiallyExpanded,
                      onChanged: group.onExpandedChanged,
                      header: group.header,
                      content: content,
                    );
                  }
                  final item = (row as _CollectionItemRow<T>).item;
                  return _item(context, item);
                },
              ),
            ),
            if (state is CarpenterCollectionLoadingNext<T>)
              const Padding(
                padding: EdgeInsets.all(12),
                child: Center(child: CarpenterLoader()),
              )
            else if (state is CarpenterCollectionReady<T> && state.hasNextPage)
              Align(
                alignment: Alignment.center,
                child: CarpenterButton(
                  label: 'Загрузить ещё',
                  prominence: .outlined,
                  onInvoke: widget.controller.loadNext,
                ),
              )
            else if (state is CarpenterCollectionReady<T> &&
                state.totalPages > 1)
              LayoutBuilder(
                builder: (context, constraints) {
                  final controls = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Страница ${state.page} из ${state.totalPages}'
                        '${state.totalItems == null ? '' : ' · ${state.totalItems}'}',
                      ),
                      const SizedBox(width: 12),
                      CarpenterIconButton(
                        semanticLabel: 'Предыдущая страница',
                        onPressed: state.page <= 1
                            ? null
                            : () => widget.controller.goToPage(state.page - 1),
                        icon: const Text('‹'),
                      ),
                      CarpenterIconButton(
                        semanticLabel: 'Следующая страница',
                        onPressed: state.page >= state.totalPages
                            ? null
                            : () => widget.controller.goToPage(state.page + 1),
                        icon: const Text('›'),
                      ),
                    ],
                  );
                  return Align(
                    alignment: Alignment.centerRight,
                    child: constraints.maxWidth < 420
                        ? FittedBox(
                            alignment: Alignment.centerRight,
                            fit: BoxFit.scaleDown,
                            child: controls,
                          )
                        : controls,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, T item) {
    final selected = widget.controller.selection?.isSelected(item) ?? false;
    return ListenableBuilder(
      listenable: widget.controller.selection ?? const _NeverListenable(),
      builder: (context, _) {
        final currentSelected =
            widget.controller.selection?.isSelected(item) ?? selected;
        final actions = widget.itemActionsBuilder?.call(context, item);
        return KeyedSubtree(
          key: ValueKey(widget.itemIdentity(item)),
          child: Semantics(
            selected: currentSelected,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => widget.onItemActivate?.call(item),
              onLongPress: widget.controller.selection == null
                  ? null
                  : () => widget.controller.selection!.toggle(item),
              child: actions == null || actions.isEmpty
                  ? widget.itemBuilder(context, item, currentSelected)
                  : CarpenterCard(
                      padded: false,
                      child: CarpenterListTile(
                        title: widget.itemBuilder(
                          context,
                          item,
                          currentSelected,
                        ),
                        trailing: CarpenterTrailingActions(actions: actions),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

sealed class _CollectionRow<T> {
  const _CollectionRow();
}

final class _CollectionItemRow<T> extends _CollectionRow<T> {
  const _CollectionItemRow(this.item);

  final T item;
}

final class _CollectionGroupRow<T> extends _CollectionRow<T> {
  const _CollectionGroupRow(this.group);

  final CarpenterDataGroup<T> group;
}

class _NeverListenable implements Listenable {
  const _NeverListenable();

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// Standard page composition for collection scenarios.
class CarpenterCollectionPage<T, TFilter, TSort> extends StatelessWidget {
  const CarpenterCollectionPage({
    super.key,
    required this.descriptor,
    this.collection,
    this.dataController,
    this.itemIdentity,
    this.itemBuilder,
    this.groupBy,
    this.itemActionsBuilder,
    this.onItemActivate,
    this.empty,
    this.filteredEmpty,
    this.pageController,
    this.state = const CarpenterPageReady(),
    this.header,
    this.summary,
    this.queryBar,
    this.filterBar,
    this.actionBar,
    this.selectionBar,
    this.capabilities = const [],
    this.commands = const [],
    this.commandBindings = const [],
  });

  final CarpenterPageDescriptor descriptor;
  final CarpenterPageController? pageController;
  final CarpenterPageState state;
  final Widget? header;
  final Widget? summary;
  final Widget? queryBar;
  final Widget? filterBar;
  final Widget? actionBar;
  final Widget? collection;
  final CarpenterDataCollectionController<T, TFilter, TSort>? dataController;
  final Object Function(T item)? itemIdentity;
  final CarpenterDataCollectionItemBuilder<T>? itemBuilder;
  final List<CarpenterDataGroup<T>> Function(List<T> items)? groupBy;
  final List<Widget> Function(BuildContext context, T item)? itemActionsBuilder;
  final ValueChanged<T>? onItemActivate;
  final CarpenterEmptyStateDescriptor? empty;
  final CarpenterEmptyStateDescriptor? filteredEmpty;
  final Widget? selectionBar;
  final List<CarpenterPageCapability> capabilities;
  final List<CarpenterCommand<dynamic>> commands;
  final List<CarpenterCommandBinding<dynamic>> commandBindings;

  @override
  Widget build(BuildContext context) {
    assert(
      descriptor.kind == CarpenterPageKind.collection,
      'CarpenterCollectionPage requires a collection descriptor.',
    );
    assert(
      collection != null ||
          (dataController != null &&
              itemIdentity != null &&
              itemBuilder != null),
      'Provide either a custom collection or a typed dataController, '
      'itemIdentity and itemBuilder.',
    );
    final data = dataController;
    if (data != null) {
      return ValueListenableBuilder<CarpenterCollectionState<T>>(
        valueListenable: data,
        builder: (context, collectionState, _) => _buildPage(
          collectionState: collectionState,
          collection: CarpenterDataCollection<T, TFilter, TSort>(
            controller: data,
            itemIdentity: itemIdentity!,
            itemBuilder: itemBuilder!,
            groupBy: groupBy,
            itemActionsBuilder: itemActionsBuilder,
            onItemActivate: onItemActivate,
            empty: empty,
            filteredEmpty: filteredEmpty,
          ),
        ),
      );
    }
    return _buildPage(collection: collection!, collectionState: null);
  }

  Widget _buildPage({
    required Widget collection,
    required CarpenterCollectionState<T>? collectionState,
  }) {
    final effectiveState = collectionState == null
        ? state
        : switch (collectionState) {
            CarpenterCollectionInitialLoading<T>() =>
              const CarpenterPageInitialLoading(),
            CarpenterCollectionEmpty<T>() => const CarpenterPageReady(),
            CarpenterCollectionFailure<T>(:final error, :final message) =>
              CarpenterPageFailure(error: error, message: message),
            CarpenterCollectionReady<T>() => const CarpenterPageReady(),
            CarpenterCollectionLoadingNext<T>() ||
            CarpenterCollectionPartialFailure<T>() =>
              const CarpenterPageReady(),
          };
    return CarpenterPage(
      descriptor: descriptor,
      controller: pageController,
      state: pageController == null ? effectiveState : null,
      commands: commands,
      commandBindings: commandBindings,
      capabilities: capabilities,
      header:
          header ??
          CarpenterPageHeader(
            title: Text(descriptor.title),
            commandBar: actionBar,
          ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (summary != null) ...[summary!, const SizedBox(height: 12)],
          if (queryBar != null || filterBar != null) ...[
            CarpenterCollectionToolbar(
              child: CarpenterFilterBar(
                query: queryBar,
                filters: [if (filterBar != null) filterBar!],
              ),
            ),
          ],
          if (selectionBar != null) ...[
            selectionBar!,
            const SizedBox(height: 12),
          ],
          Expanded(child: collection),
        ],
      ),
    );
  }
}

/// Query/filter region pinned above the collection's own scrollable viewport.
class CarpenterCollectionToolbar extends StatelessWidget {
  const CarpenterCollectionToolbar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: context.face.color('surface.base'),
    child: Padding(
      padding: EdgeInsets.only(bottom: context.face.space('0.75')),
      child: child,
    ),
  );
}

/// Complete collection picker dialog with standard query, state, scrolling,
/// empty/error presentation and actions.
class CarpenterCollectionDialog<T, TFilter, TSort> extends StatelessWidget {
  const CarpenterCollectionDialog({
    super.key,
    required this.title,
    required this.controller,
    required this.itemIdentity,
    required this.itemBuilder,
    this.groupBy,
    this.onItemActivate,
    this.queryPlaceholder,
    this.empty,
    this.filteredEmpty,
    this.actions = const [],
    this.constraints = const BoxConstraints(maxWidth: 760, maxHeight: 650),
  });

  final Widget title;
  final CarpenterDataCollectionControllerBase<T, TFilter, TSort> controller;
  final Object Function(T item) itemIdentity;
  final CarpenterDataCollectionItemBuilder<T> itemBuilder;
  final List<CarpenterDataGroup<T>> Function(List<T> items)? groupBy;
  final ValueChanged<T>? onItemActivate;
  final String? queryPlaceholder;
  final CarpenterEmptyStateDescriptor? empty;
  final CarpenterEmptyStateDescriptor? filteredEmpty;
  final List<Widget> actions;
  final BoxConstraints constraints;

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    title: title,
    constraints: constraints,
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterCollectionSearchField(
          controller: controller,
          placeholder: queryPlaceholder,
          width: double.infinity,
          prefix: const Icon(CarpenterIcons.search),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: CarpenterDataCollection(
            controller: controller,
            itemIdentity: itemIdentity,
            itemBuilder: itemBuilder,
            groupBy: groupBy,
            onItemActivate: onItemActivate,
            empty: empty,
            filteredEmpty: filteredEmpty,
          ),
        ),
      ],
    ),
    actions: actions,
  );
}
