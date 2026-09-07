import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/status_indicator.dart';
import 'contracts/collection_load_phase.dart';
import 'contracts/collection_snapshot.dart';
import 'contracts/selection_state.dart';

typedef CarpenterDataListItemBuilder<T> =
    Widget Function(BuildContext context, T item);

@immutable
final class CarpenterDataListMessages {
  const CarpenterDataListMessages({
    this.initialLoading = 'Loading data',
    this.refreshing = 'Refreshing data',
    this.loadingMore = 'Loading more',
    this.zero = 'No data yet',
    this.emptyResult = 'No matching results',
    this.initialError = 'Data could not be loaded',
    this.refreshError = 'Refresh failed. Existing data may be stale.',
    this.loadMore = 'Load more',
  });

  final String initialLoading;
  final String refreshing;
  final String loadingMore;
  final String zero;
  final String emptyResult;
  final String initialError;
  final String refreshError;
  final String loadMore;
}

/// A structured, scroll-owning list backed by Carpenter collection contracts.
///
/// Item identity and selection are controlled by the caller. The builder owns
/// item content only; list interaction, focus, selection and transient
/// collection states remain consistent across consumers.
final class CarpenterDataList<T, K> extends StatefulWidget {
  const CarpenterDataList({
    super.key,
    required this.snapshot,
    required this.itemKey,
    required this.itemSemanticLabel,
    required this.itemBuilder,
    required this.selection,
    this.onSelectionChanged,
    this.onLoadMore,
    this.retryAction,
    this.messages = const CarpenterDataListMessages(),
    this.colorRole = SelectionColorRole.primary,
    this.semanticLabel = 'Data list',
  });

  final CollectionSnapshot<T> snapshot;
  final K Function(T item) itemKey;
  final String Function(T item) itemSemanticLabel;
  final CarpenterDataListItemBuilder<T> itemBuilder;
  final CollectionSelection<K> selection;
  final ValueChanged<CollectionSelection<K>>? onSelectionChanged;
  final VoidCallback? onLoadMore;
  final CarpenterActionDescriptor? retryAction;
  final CarpenterDataListMessages messages;
  final SelectionColorRole colorRole;
  final String semanticLabel;

  @override
  State<CarpenterDataList<T, K>> createState() =>
      _CarpenterDataListState<T, K>();
}

final class _CarpenterDataListState<T, K>
    extends State<CarpenterDataList<T, K>> {
  final Map<K, FocusNode> _focusNodes = {};

  @override
  void didUpdateWidget(CarpenterDataList<T, K> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final keys = widget.snapshot.items.map(widget.itemKey).toSet();
    for (final stale
        in _focusNodes.keys
            .where((key) => !keys.contains(key))
            .toList(growable: false)) {
      _focusNodes.remove(stale)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _select(K key) {
    final callback = widget.onSelectionChanged;
    if (callback == null || !widget.selection.isEnabled) return;
    callback(widget.selection.toggle(key));
  }

  void _moveFocus(int target) {
    if (widget.snapshot.items.isEmpty) return;
    final index = target.clamp(0, widget.snapshot.items.length - 1);
    final key = widget.itemKey(widget.snapshot.items[index]);
    _focusNodes.putIfAbsent(key, FocusNode.new).requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final radius = context.units(theme.shapes.radius(ShapeRole.rounded));
    final state = _exclusiveState();
    final banner = _banner();
    final footer = _footer();
    final itemCount = state == null
        ? widget.snapshot.items.length +
              (banner == null ? 0 : 1) +
              (footer == null ? 0 : 1)
        : 1;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.overlay.background,
          border: Border.all(
            color: theme.overlay.border,
            width: context.units(theme.shapes.borderWidth),
          ),
          borderRadius: BorderRadius.circular(radius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: ListView.builder(
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (state != null) return state;
              var contentIndex = index;
              if (banner != null) {
                if (contentIndex == 0) return banner;
                contentIndex -= 1;
              }
              if (contentIndex < widget.snapshot.items.length) {
                final item = widget.snapshot.items[contentIndex];
                final key = widget.itemKey(item);
                return _DataListItem<T>(
                  key: ValueKey<K>(key),
                  item: item,
                  semanticLabel: widget.itemSemanticLabel(item),
                  selected: widget.selection.contains(key),
                  enabled:
                      widget.selection.isEnabled &&
                      widget.onSelectionChanged != null,
                  colorRole: widget.colorRole,
                  focusNode: _focusNodes.putIfAbsent(key, FocusNode.new),
                  itemBuilder: widget.itemBuilder,
                  onSelect: () => _select(key),
                  onPrevious: () => _moveFocus(contentIndex - 1),
                  onNext: () => _moveFocus(contentIndex + 1),
                  onFirst: () => _moveFocus(0),
                  onLast: () => _moveFocus(widget.snapshot.items.length - 1),
                );
              }
              return footer!;
            },
          ),
        ),
      ),
    );
  }

  Widget? _exclusiveState() {
    final snapshot = widget.snapshot;
    if (snapshot.isInitialLoading) {
      return _DataListState(message: widget.messages.initialLoading);
    }
    if (snapshot.initialFailure != null) {
      return _DataListState(
        message:
            snapshot.initialFailure!.message ?? widget.messages.initialError,
        role: FeedbackColorRole.danger,
        action: widget.retryAction,
      );
    }
    if (snapshot.contentState == CollectionContentState.zero) {
      return _DataListState(message: widget.messages.zero);
    }
    if (snapshot.contentState == CollectionContentState.emptyResult) {
      return _DataListState(message: widget.messages.emptyResult);
    }
    return null;
  }

  Widget? _banner() {
    final snapshot = widget.snapshot;
    if (snapshot.refreshFailure != null) {
      return _DataListBanner(
        message:
            snapshot.refreshFailure!.message ?? widget.messages.refreshError,
        role: FeedbackColorRole.danger,
      );
    }
    if (snapshot.isRefreshing) {
      return _DataListBanner(
        message: widget.messages.refreshing,
        role: FeedbackColorRole.info,
      );
    }
    return null;
  }

  Widget? _footer() {
    if (widget.snapshot.isLoadingMore) {
      return _DataListBanner(
        message: widget.messages.loadingMore,
        role: FeedbackColorRole.info,
      );
    }
    if (!widget.snapshot.pageInfo.hasNext || widget.onLoadMore == null) {
      return null;
    }
    return _DataListFooter(
      label: widget.messages.loadMore,
      onInvoke: widget.onLoadMore!,
    );
  }
}

final class _DataListItem<T> extends StatefulWidget {
  const _DataListItem({
    super.key,
    required this.item,
    required this.semanticLabel,
    required this.selected,
    required this.enabled,
    required this.colorRole,
    required this.focusNode,
    required this.itemBuilder,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
    required this.onFirst,
    required this.onLast,
  });

  final T item;
  final String semanticLabel;
  final bool selected;
  final bool enabled;
  final SelectionColorRole colorRole;
  final FocusNode focusNode;
  final CarpenterDataListItemBuilder<T> itemBuilder;
  final VoidCallback onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onFirst;
  final VoidCallback onLast;

  @override
  State<_DataListItem<T>> createState() => _DataListItemState<T>();
}

final class _DataListItemState<T> extends State<_DataListItem<T>> {
  var _hovered = false;
  var _focused = false;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!node.hasPrimaryFocus || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onPrevious();
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onNext();
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      widget.onFirst();
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      widget.onLast();
    } else if ((event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space) &&
        widget.enabled) {
      widget.onSelect();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final states = <WidgetState>{
      if (_hovered && widget.enabled) WidgetState.hovered,
      if (_focused) WidgetState.focused,
    };
    final style = theme.selection.resolve(
      role: widget.colorRole,
      selected: widget.selected,
      states: states,
    );
    return Semantics(
      container: true,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.enabled ? widget.onSelect : null,
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (value) => setState(() => _focused = value),
        onKeyEvent: _handleKey,
        child: MouseRegion(
          cursor: widget.enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: widget.enabled
              ? (_) => setState(() => _hovered = true)
              : null,
          onExit: widget.enabled
              ? (_) => setState(() => _hovered = false)
              : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.enabled
                ? () {
                    widget.focusNode.requestFocus();
                    widget.onSelect();
                  }
                : null,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: style.background,
                border: Border(
                  bottom: BorderSide(
                    color: theme.overlay.border,
                    width: context.units(theme.shapes.borderWidth),
                  ),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(context.units(theme.spacing.medium)),
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: style.foreground),
                  child: widget.itemBuilder(context, widget.item),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DataListState extends StatelessWidget {
  const _DataListState({required this.message, this.role, this.action});

  final String message;
  final FeedbackColorRole? role;
  final CarpenterActionDescriptor? action;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(context.units(theme.spacing.large)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CarpenterStatusIndicator(
              label: message,
              role: role ?? FeedbackColorRole.neutral,
            ),
            if (action != null) ...[
              SizedBox(height: context.units(theme.spacing.medium)),
              CarpenterButton.fromAction(action!),
            ],
          ],
        ),
      ),
    );
  }
}

final class _DataListBanner extends StatelessWidget {
  const _DataListBanner({required this.message, required this.role});

  final String message;
  final FeedbackColorRole role;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(context.units(theme.spacing.medium)),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CarpenterStatusIndicator(label: message, role: role),
      ),
    );
  }
}

final class _DataListFooter extends StatelessWidget {
  const _DataListFooter({required this.label, required this.onInvoke});

  final String label;
  final VoidCallback onInvoke;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Padding(
      padding: EdgeInsets.all(context.units(theme.spacing.medium)),
      child: Align(
        child: CarpenterButton(
          label: label,
          prominence: ActionProminence.ghost,
          size: ControlSize.small,
          onInvoke: onInvoke,
        ),
      ),
    );
  }
}
