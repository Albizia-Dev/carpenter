import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';
import '../../basic/button/icon_button.dart';
import '../../basic/icons.dart';
import '../../basic/text.dart';
import '../../behaviour/drag_and_drop/drag_operation.dart';
import '../../behaviour/drag_and_drop/drag_payload.dart';
import '../../behaviour/drag_and_drop/drag_scope.dart';
import '../../behaviour/drag_and_drop/draggable.dart';
import '../../behaviour/drag_and_drop/drop_target.dart';
import '../list_tile.dart';
import 'tree_event.dart';
import 'tree_state.dart';

typedef CarpenterTreeNodeBuilder<T> =
    Widget Function(
      BuildContext context,
      CarpenterTreeNode<T> node,
      CarpenterTreeRowState<T> state,
    );
typedef CarpenterTreeActionsBuilder<T> =
    List<CarpenterActionDescriptor> Function(CarpenterTreeNode<T> node);
typedef CarpenterTreeActivation<T> = void Function(CarpenterTreeNode<T> node);

/// Imperative navigation surface for a controlled tree.
///
/// Expansion itself remains controlled by [CarpenterTreeView.expandedIds]. A
/// reveal request asks the tree to expand the target path through
/// [CarpenterTreeView.onExpansionChanged], focus the row and scroll it into the
/// nearest enclosing viewport once it becomes visible.
final class CarpenterTreeController extends ChangeNotifier {
  Object? _revealId;
  int _revealRevision = 0;

  Object? get revealId => _revealId;
  int get revealRevision => _revealRevision;

  void reveal(Object id) {
    _revealId = id;
    _revealRevision += 1;
    notifyListeners();
  }
}

/// Controlled hierarchical collection with keyboard navigation and DnD.
final class CarpenterTreeView<T> extends StatefulWidget {
  const CarpenterTreeView({
    super.key,
    required this.nodes,
    this.controller,
    this.expandedIds = const {},
    this.selectedIds = const {},
    this.selectionMode = CarpenterTreeSelectionMode.single,
    this.onExpansionChanged,
    this.onSelectionChanged,
    this.onActivated,
    this.filter,
    this.onDrop,
    this.canDrop,
    this.onRetryLoad,
    this.itemBuilder,
    this.actions,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.autoExpandOnHover = true,
    this.semanticLabel = 'Tree',
  });

  final List<CarpenterTreeNode<T>> nodes;
  final CarpenterTreeController? controller;
  final Set<Object> expandedIds;
  final Set<Object> selectedIds;
  final CarpenterTreeSelectionMode selectionMode;
  final CarpenterTreeExpansionChanged? onExpansionChanged;
  final CarpenterTreeSelectionChanged? onSelectionChanged;
  final CarpenterTreeActivation<T>? onActivated;
  final CarpenterTreeNodePredicate<T>? filter;
  final CarpenterTreeDropCallback<T>? onDrop;
  final CarpenterTreeDropAcceptance<T>? canDrop;
  final CarpenterTreeNodeCallback<T>? onRetryLoad;
  final CarpenterTreeNodeBuilder<T>? itemBuilder;
  final CarpenterTreeActionsBuilder<T>? actions;
  final CarpenterDragActivation dragActivation;
  final bool autoExpandOnHover;
  final String semanticLabel;

  @override
  State<CarpenterTreeView<T>> createState() => _CarpenterTreeViewState<T>();
}

final class _CarpenterTreeViewState<T> extends State<CarpenterTreeView<T>> {
  Object? _focusedId;
  Object? _draggingId;
  Object? _autoExpandId;
  Object? _pendingRevealId;
  Timer? _autoExpandTimer;
  final Map<Object, GlobalKey> _rowKeys = <Object, GlobalKey>{};

  List<CarpenterTreeFlatNode<T>> get _flat {
    final filter = widget.filter;
    if (filter == null) {
      return flattenCarpenterTree(widget.nodes, widget.expandedIds);
    }
    return flattenFilteredCarpenterTree(
      widget.nodes,
      widget.expandedIds,
      filter,
    );
  }

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_handleRevealRequest);
    if (widget.controller?.revealId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleRevealRequest());
    }
  }

  @override
  void didUpdateWidget(CarpenterTreeView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_handleRevealRequest);
      widget.controller?.addListener(_handleRevealRequest);
      if (widget.controller?.revealId != null) _handleRevealRequest();
    }
    if (_pendingRevealId != null) _scheduleReveal(_pendingRevealId!);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_handleRevealRequest);
    _autoExpandTimer?.cancel();
    super.dispose();
  }

  bool _subtreeMatchesFilter(CarpenterTreeNode<T> node) {
    final filter = widget.filter;
    if (filter == null) return false;
    return filter(node) || node.children.any(_subtreeMatchesFilter);
  }

  bool _visuallyExpanded(CarpenterTreeNode<T> node) =>
      widget.expandedIds.contains(node.id) ||
      (widget.filter != null && node.children.any(_subtreeMatchesFilter));

  void _handleRevealRequest() {
    if (!mounted) return;
    final id = widget.controller?.revealId;
    if (id == null) return;
    final path = findCarpenterTreePath(widget.nodes, id);
    if (path == null) return;
    for (final ancestor in path.take(path.length - 1)) {
      if (!widget.expandedIds.contains(ancestor.id)) {
        widget.onExpansionChanged?.call(ancestor.id, true);
      }
    }
    _pendingRevealId = id;
    setState(() => _focusedId = id);
    _scheduleReveal(id);
  }

  void _scheduleReveal(Object id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _pendingRevealId != id) return;
      final rowContext = _rowKeys[id]?.currentContext;
      if (rowContext == null) return;
      _pendingRevealId = null;
      unawaited(
        Scrollable.ensureVisible(
          rowContext,
          alignment: 0.5,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        ),
      );
    });
  }

  void _toggleExpansion(CarpenterTreeNode<T> node) {
    if (!node.canExpand) return;
    widget.onExpansionChanged?.call(
      node.id,
      !widget.expandedIds.contains(node.id),
    );
  }

  void _select(CarpenterTreeNode<T> node) {
    _focusedId = node.id;
    final callback = widget.onSelectionChanged;
    if (callback == null ||
        widget.selectionMode == CarpenterTreeSelectionMode.none) {
      setState(() {});
      return;
    }
    final next = switch (widget.selectionMode) {
      CarpenterTreeSelectionMode.none => widget.selectedIds,
      CarpenterTreeSelectionMode.single => <Object>{node.id},
      CarpenterTreeSelectionMode.multiple =>
        widget.selectedIds.contains(node.id)
            ? widget.selectedIds.where((id) => id != node.id).toSet()
            : {...widget.selectedIds, node.id},
    };
    callback(Set.unmodifiable(next));
    setState(() {});
  }

  void _activate(CarpenterTreeNode<T> node) {
    setState(() => _focusedId = node.id);
    widget.onActivated?.call(node);
  }

  KeyEventResult _handleKey(FocusNode focusNode, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final flat = _flat;
    if (flat.isEmpty) return KeyEventResult.ignored;
    var index = _focusedId == null
        ? 0
        : flat.indexWhere((entry) => entry.node.id == _focusedId);
    if (index < 0) index = 0;
    final current = flat[index];

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      final next = (index + 1).clamp(0, flat.length - 1);
      setState(() => _focusedId = flat[next].node.id);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      final next = (index - 1).clamp(0, flat.length - 1);
      setState(() => _focusedId = flat[next].node.id);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      if (current.node.canExpand &&
          !widget.expandedIds.contains(current.node.id)) {
        widget.onExpansionChanged?.call(current.node.id, true);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      if (widget.expandedIds.contains(current.node.id)) {
        widget.onExpansionChanged?.call(current.node.id, false);
      } else if (current.parentId != null) {
        setState(() => _focusedId = current.parentId);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _activate(current.node);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _select(current.node);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  bool _canDrop(
    CarpenterTreeNode<T> target,
    CarpenterDropDetails<CarpenterTreeNode<T>> details,
  ) {
    final dragged = details.payload.data;
    if (dragged.id == target.id || carpenterTreeContains(dragged, target.id)) {
      return false;
    }
    final treeDetails = CarpenterTreeDropDetails<T>(
      dragged: dragged,
      target: target,
      position: details.position,
      operation: details.operation,
    );
    return widget.canDrop?.call(treeDetails) ?? true;
  }

  void _drop(
    CarpenterTreeNode<T> target,
    CarpenterDropDetails<CarpenterTreeNode<T>> details,
  ) {
    widget.onDrop?.call(
      CarpenterTreeDropDetails<T>(
        dragged: details.payload.data,
        target: target,
        position: details.position,
        operation: details.operation,
      ),
    );
  }

  void _syncAutoExpand(
    CarpenterTreeNode<T> node,
    CarpenterDropTargetState<CarpenterTreeNode<T>> state,
  ) {
    final shouldExpand =
        widget.autoExpandOnHover &&
        state.hovering &&
        state.accepts &&
        state.position == CarpenterDropPosition.inside &&
        node.canExpand &&
        !widget.expandedIds.contains(node.id);
    if (!shouldExpand) {
      if (_autoExpandId == node.id) {
        _autoExpandTimer?.cancel();
        _autoExpandTimer = null;
        _autoExpandId = null;
      }
      return;
    }
    if (_autoExpandId == node.id && _autoExpandTimer != null) return;
    _autoExpandTimer?.cancel();
    _autoExpandId = node.id;
    _autoExpandTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || _autoExpandId != node.id) return;
      _autoExpandTimer = null;
      _autoExpandId = null;
      widget.onExpansionChanged?.call(node.id, true);
    });
  }

  Widget _row(BuildContext context, CarpenterTreeFlatNode<T> entry) {
    final node = entry.node;
    final expanded = _visuallyExpanded(node);
    Widget buildContent(
      CarpenterDropTargetState<CarpenterTreeNode<T>> dropState,
    ) {
      _syncAutoExpand(node, dropState);
      final state = CarpenterTreeRowState<T>(
        node: node,
        depth: entry.depth,
        expanded: expanded,
        selected: widget.selectedIds.contains(node.id),
        focused: _focusedId == node.id,
        dragging: _draggingId == node.id,
        hovering: dropState.hovering,
        acceptsDrop: dropState.accepts,
        dropPosition: dropState.position,
      );
      final theme = CarpenterTheme.of(context);
      final indent = context.units(theme.spacing.large) * entry.depth;
      final actions =
          widget.actions?.call(node) ?? const <CarpenterActionDescriptor>[];
      final title =
          widget.itemBuilder?.call(context, node, state) ??
          CarpenterText.label(
            node.label,
            emphasis: state.selected || state.focused
                ? TypographyEmphasis.medium
                : TypographyEmphasis.regular,
          );
      final row = Padding(
        key: _rowKeys.putIfAbsent(node.id, GlobalKey.new),
        padding: EdgeInsetsDirectional.only(start: indent),
        child: CarpenterListTile(
          selected: state.selected,
          semanticLabel: node.effectiveSemanticLabel,
          onInvoke: () => _select(node),
          onDoubleInvoke: widget.onActivated == null ? null : () => _activate(node),
          leading: node.canExpand
              ? CarpenterIconButton(
                  icon: expanded
                      ? CarpenterIcons.sortDown
                      : CarpenterIcons.chevronRight,
                  semanticLabel: expanded
                      ? 'Collapse ${node.label}'
                      : 'Expand ${node.label}',
                  prominence: ActionProminence.ghost,
                  size: ControlSize.xsmall,
                  onPressed: () => _toggleExpansion(node),
                )
              : SizedBox(
                  width: context.units(theme.sizes.control(ControlSize.xsmall)),
                ),
          title: title,
          trailing: actions.isEmpty
              ? null
              : Wrap(
                  children: [
                    for (final action in actions)
                      if (action.icon != null)
                        CarpenterIconButton.fromAction(
                          action,
                          prominence: ActionProminence.ghost,
                          size: ControlSize.xsmall,
                        )
                      else
                        CarpenterButton.fromAction(
                          action,
                          prominence: ActionProminence.ghost,
                          size: ControlSize.xsmall,
                        ),
                  ],
                ),
        ),
      );
      if (widget.onDrop == null) return row;
      return CarpenterDraggable<CarpenterTreeNode<T>>(
        sourceId: node.id,
        activation: widget.dragActivation,
        payload: CarpenterDragPayload<CarpenterTreeNode<T>>(
          id: node.id,
          data: node,
        ),
        semanticLabel: 'Move ${node.effectiveSemanticLabel}',
        onDragStarted: () => setState(() => _draggingId = node.id),
        onDragCompleted: () {
          if (mounted) setState(() => _draggingId = null);
        },
        onDragCanceled: (_, __) {
          if (mounted) setState(() => _draggingId = null);
        },
        child: row,
      );
    }

    if (widget.onDrop == null) {
      return buildContent(
        CarpenterDropTargetState<CarpenterTreeNode<T>>(
          hovering: false,
          accepts: false,
        ),
      );
    }
    return CarpenterDropTarget<CarpenterTreeNode<T>>(
      targetId: node.id,
      axis: CarpenterDropAxis.vertical,
      acceptedOperations: const {CarpenterDragOperation.move},
      canAccept: (details) => _canDrop(node, details),
      onDrop: (details) => _drop(node, details),
      builder: (context, state) => buildContent(state),
    );
  }

  Widget _lazyState(BuildContext context, CarpenterTreeFlatNode<T> entry) {
    final theme = CarpenterTheme.of(context);
    final indent = context.units(theme.spacing.large) * (entry.depth + 1);
    final node = entry.node;
    final child = switch (node.loadState) {
      CarpenterTreeLoadState.loading => const CarpenterText.caption(
        'Loading…',
        colorRole: ContentColorRole.secondary,
      ),
      CarpenterTreeLoadState.failed => Row(
        children: [
          Expanded(
            child: CarpenterText.caption(
              node.errorText ?? 'Failed to load children',
              colorRole: ContentColorRole.secondary,
            ),
          ),
          if (widget.onRetryLoad != null)
            CarpenterIconButton(
              icon: CarpenterIcons.refresh,
              semanticLabel: 'Retry loading ${node.label}',
              prominence: ActionProminence.ghost,
              size: ControlSize.xsmall,
              onPressed: () => widget.onRetryLoad!(node),
            ),
        ],
      ),
      CarpenterTreeLoadState.ready => const SizedBox.shrink(),
    };
    return Padding(
      padding: EdgeInsetsDirectional.only(start: indent),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final flat = _flat;
    if (_pendingRevealId != null) _scheduleReveal(_pendingRevealId!);
    return CarpenterDragScope(
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in flat) ...[
                _row(context, entry),
                if (_visuallyExpanded(entry.node) &&
                    entry.node.children.isEmpty &&
                    entry.node.loadState != CarpenterTreeLoadState.ready)
                  _lazyState(context, entry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
