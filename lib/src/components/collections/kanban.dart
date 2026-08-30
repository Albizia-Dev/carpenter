import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/card.dart';
import '../basic/text.dart';
import '../behaviour/drag_and_drop/drag_operation.dart';
import '../behaviour/drag_and_drop/drag_payload.dart';
import '../behaviour/drag_and_drop/drag_scope.dart';
import '../behaviour/drag_and_drop/draggable.dart';
import '../behaviour/drag_and_drop/drop_target.dart';

enum CarpenterKanbanLoadState { ready, loading, failed }

@immutable
final class CarpenterKanbanColumn<C, T> {
  const CarpenterKanbanColumn({
    required this.id,
    required this.value,
    required this.title,
    this.cards = const [],
    this.loadState = CarpenterKanbanLoadState.ready,
    this.hasMore = false,
    this.errorText,
    this.semanticLabel,
  });

  final Object id;
  final C value;
  final String title;
  final List<T> cards;
  final CarpenterKanbanLoadState loadState;
  final bool hasMore;
  final String? errorText;
  final String? semanticLabel;
}

@immutable
final class CarpenterKanbanMoveDetails<C, T> {
  const CarpenterKanbanMoveDetails({
    required this.card,
    required this.sourceColumn,
    required this.sourceIndex,
    required this.targetColumn,
    required this.targetIndex,
    required this.position,
    required this.operation,
  });

  final T card;
  final CarpenterKanbanColumn<C, T> sourceColumn;
  final int sourceIndex;
  final CarpenterKanbanColumn<C, T> targetColumn;
  final int targetIndex;
  final CarpenterDropPosition position;
  final CarpenterDragOperation operation;
}

@immutable
final class CarpenterKanbanCardState<C> {
  const CarpenterKanbanCardState({
    required this.column,
    required this.index,
    required this.dragging,
    required this.hovering,
    required this.acceptsDrop,
    this.dropPosition,
  });

  final C column;
  final int index;
  final bool dragging;
  final bool hovering;
  final bool acceptsDrop;
  final CarpenterDropPosition? dropPosition;
}

typedef CarpenterKanbanCardBuilder<C, T> =
    Widget Function(
      BuildContext context,
      T card,
      CarpenterKanbanCardState<C> state,
    );
typedef CarpenterKanbanMoveCallback<C, T> =
    void Function(CarpenterKanbanMoveDetails<C, T> details);
typedef CarpenterKanbanMoveAcceptance<C, T> =
    bool Function(CarpenterKanbanMoveDetails<C, T> details);
typedef CarpenterKanbanColumnCallback<C, T> =
    void Function(CarpenterKanbanColumn<C, T> column);

@immutable
final class _KanbanDragData<C, T> {
  const _KanbanDragData({
    required this.boardId,
    required this.sourceColumnId,
    required this.sourceIndex,
    required this.card,
  });

  final Object boardId;
  final Object sourceColumnId;
  final int sourceIndex;
  final T card;
}

/// Controlled multi-column board with cross-column and within-column DnD.
final class CarpenterKanban<C, T> extends StatefulWidget {
  const CarpenterKanban({
    super.key,
    required this.columns,
    required this.cardKey,
    required this.cardBuilder,
    this.onMove,
    this.canMove,
    this.onLoadMore,
    this.onRetry,
    this.dragActivation = CarpenterDragActivation.immediate,
    this.emptyLabel = 'No cards',
    this.semanticLabel = 'Kanban board',
  });

  final List<CarpenterKanbanColumn<C, T>> columns;
  final Object Function(T card) cardKey;
  final CarpenterKanbanCardBuilder<C, T> cardBuilder;
  final CarpenterKanbanMoveCallback<C, T>? onMove;
  final CarpenterKanbanMoveAcceptance<C, T>? canMove;
  final CarpenterKanbanColumnCallback<C, T>? onLoadMore;
  final CarpenterKanbanColumnCallback<C, T>? onRetry;
  final CarpenterDragActivation dragActivation;
  final String emptyLabel;
  final String semanticLabel;

  @override
  State<CarpenterKanban<C, T>> createState() => _CarpenterKanbanState<C, T>();
}

final class _CarpenterKanbanState<C, T> extends State<CarpenterKanban<C, T>> {
  final Object _boardId = Object();
  final CarpenterDragController _dragController = CarpenterDragController();
  final ScrollController _scrollController = ScrollController();
  Object? _draggingCardId;

  @override
  void dispose() {
    _dragController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  CarpenterKanbanColumn<C, T>? _columnById(Object id) {
    for (final column in widget.columns) {
      if (column.id == id) return column;
    }
    return null;
  }

  CarpenterDropPosition _effectivePosition(
    CarpenterDropDetails<_KanbanDragData<C, T>> details,
  ) {
    if (details.position != CarpenterDropPosition.inside) {
      return details.position;
    }
    if (details.targetSize.height == 0) return CarpenterDropPosition.after;
    return details.localOffset.dy < details.targetSize.height / 2
        ? CarpenterDropPosition.before
        : CarpenterDropPosition.after;
  }

  CarpenterKanbanMoveDetails<C, T>? _moveDetails(
    CarpenterKanbanColumn<C, T> targetColumn,
    int targetCardIndex,
    CarpenterDropDetails<_KanbanDragData<C, T>> details, {
    bool append = false,
  }) {
    final drag = details.payload.data;
    if (drag.boardId != _boardId) return null;
    final sourceColumn = _columnById(drag.sourceColumnId);
    if (sourceColumn == null) return null;
    final position = append
        ? CarpenterDropPosition.after
        : _effectivePosition(details);
    var insertion = append
        ? targetColumn.cards.length
        : targetCardIndex + (position == CarpenterDropPosition.after ? 1 : 0);
    if (sourceColumn.id == targetColumn.id && drag.sourceIndex < insertion) {
      insertion -= 1;
    }
    insertion = insertion.clamp(0, targetColumn.cards.length);
    return CarpenterKanbanMoveDetails<C, T>(
      card: drag.card,
      sourceColumn: sourceColumn,
      sourceIndex: drag.sourceIndex,
      targetColumn: targetColumn,
      targetIndex: insertion,
      position: position,
      operation: details.operation,
    );
  }

  bool _canAccept(CarpenterKanbanMoveDetails<C, T>? move) {
    if (move == null) return false;
    if (move.sourceColumn.id == move.targetColumn.id &&
        move.sourceIndex == move.targetIndex) {
      return false;
    }
    return widget.canMove?.call(move) ?? true;
  }

  void _emit(CarpenterKanbanMoveDetails<C, T>? move) {
    if (move == null || !_canAccept(move)) return;
    widget.onMove?.call(move);
  }

  void _autoScroll(Offset localPosition, double width) {
    if (!_dragController.isDragging || !_scrollController.hasClients) return;
    final context = this.context;
    final edge = context.units(3.rem);
    final delta = context.units(1.rem);
    var target = _scrollController.offset;
    if (localPosition.dx < edge) target -= delta;
    if (localPosition.dx > width - edge) target += delta;
    target = target.clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );
    if (target != _scrollController.offset) _scrollController.jumpTo(target);
  }

  Widget _card(
    BuildContext context,
    CarpenterKanbanColumn<C, T> column,
    T card,
    int index,
  ) {
    final cardId = widget.cardKey(card);
    Widget content(
      CarpenterDropTargetState<_KanbanDragData<C, T>> targetState,
    ) {
      final state = CarpenterKanbanCardState<C>(
        column: column.value,
        index: index,
        dragging: _draggingCardId == cardId,
        hovering: targetState.hovering,
        acceptsDrop: targetState.accepts,
        dropPosition: targetState.position,
      );
      final child = widget.cardBuilder(context, card, state);
      if (widget.onMove == null) return child;
      return CarpenterDraggable<_KanbanDragData<C, T>>(
        sourceId: cardId,
        activation: widget.dragActivation,
        payload: CarpenterDragPayload<_KanbanDragData<C, T>>(
          id: cardId,
          data: _KanbanDragData<C, T>(
            boardId: _boardId,
            sourceColumnId: column.id,
            sourceIndex: index,
            card: card,
          ),
        ),
        semanticLabel: 'Move card ${index + 1} in ${column.title}',
        onDragStarted: () => setState(() => _draggingCardId = cardId),
        onDragCompleted: () {
          if (mounted) setState(() => _draggingCardId = null);
        },
        onDragCanceled: (_, __) {
          if (mounted) setState(() => _draggingCardId = null);
        },
        child: child,
      );
    }

    if (widget.onMove == null) {
      return content(
        CarpenterDropTargetState<_KanbanDragData<C, T>>(
          hovering: false,
          accepts: false,
        ),
      );
    }
    return CarpenterDropTarget<_KanbanDragData<C, T>>(
      targetId: 'kanban.${column.id}.$cardId',
      axis: CarpenterDropAxis.vertical,
      edgeFraction: .35,
      acceptedOperations: const {CarpenterDragOperation.move},
      canAccept: (details) => _canAccept(_moveDetails(column, index, details)),
      onDrop: (details) => _emit(_moveDetails(column, index, details)),
      builder: (context, state) => content(state),
    );
  }

  Widget _tailDrop(BuildContext context, CarpenterKanbanColumn<C, T> column) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    if (widget.onMove == null) return SizedBox(height: gap);
    return CarpenterDropTarget<_KanbanDragData<C, T>>(
      targetId: 'kanban.${column.id}.tail',
      fixedPosition: CarpenterDropPosition.after,
      acceptedOperations: const {CarpenterDragOperation.move},
      canAccept: (details) => _canAccept(
        _moveDetails(column, column.cards.length, details, append: true),
      ),
      onDrop: (details) => _emit(
        _moveDetails(column, column.cards.length, details, append: true),
      ),
      builder: (context, state) => AnimatedContainer(
        duration: theme.motion.transitionDuration(context),
        height: state.hovering ? context.units(2.rem) : gap,
        decoration: BoxDecoration(
          color: state.hovering && state.accepts
              ? theme.feedback.resolve(FeedbackColorRole.info).background
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(context.units(.25.rem)),
        ),
      ),
    );
  }

  Widget _column(BuildContext context, CarpenterKanbanColumn<C, T> column) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return SizedBox(
      width: context.units(18.rem),
      child: CarpenterCard(
        semanticLabel: column.semanticLabel ?? column.title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CarpenterText.label(
                    column.title,
                    emphasis: TypographyEmphasis.strong,
                  ),
                ),
                CarpenterText.caption(
                  '${column.cards.length}',
                  colorRole: ContentColorRole.secondary,
                ),
              ],
            ),
            SizedBox(height: gap),
            if (column.cards.isEmpty &&
                column.loadState == CarpenterKanbanLoadState.ready)
              Padding(
                padding: EdgeInsets.symmetric(vertical: context.units(2.rem)),
                child: CarpenterText.caption(
                  widget.emptyLabel,
                  colorRole: ContentColorRole.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
            for (var index = 0; index < column.cards.length; index++) ...[
              if (index > 0) SizedBox(height: gap),
              _card(context, column, column.cards[index], index),
            ],
            _tailDrop(context, column),
            if (column.loadState == CarpenterKanbanLoadState.loading)
              const CarpenterText.caption(
                'Loading…',
                colorRole: ContentColorRole.secondary,
                textAlign: TextAlign.center,
              ),
            if (column.loadState == CarpenterKanbanLoadState.failed)
              GestureDetector(
                onTap: widget.onRetry == null
                    ? null
                    : () => widget.onRetry!(column),
                child: CarpenterText.caption(
                  column.errorText ?? 'Failed to load. Retry',
                  colorRole: ContentColorRole.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
            if (column.hasMore &&
                column.loadState == CarpenterKanbanLoadState.ready &&
                widget.onLoadMore != null)
              GestureDetector(
                onTap: () => widget.onLoadMore!(column),
                child: const CarpenterText.caption(
                  'Load more',
                  colorRole: ContentColorRole.secondary,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.large);
    return CarpenterDragScope(
      controller: _dragController,
      child: LayoutBuilder(
        builder: (context, constraints) => Listener(
          onPointerMove: (event) =>
              _autoScroll(event.localPosition, constraints.maxWidth),
          child: Semantics(
            container: true,
            label: widget.semanticLabel,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var index = 0;
                    index < widget.columns.length;
                    index++
                  ) ...[
                    if (index > 0) SizedBox(width: gap),
                    _column(context, widget.columns[index]),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
