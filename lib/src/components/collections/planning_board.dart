import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/icon_button.dart';
import '../basic/card.dart';
import '../basic/icons.dart';
import '../basic/text.dart';
import 'kanban.dart';

@immutable
final class CarpenterPlanningLane<L, C, T> {
  const CarpenterPlanningLane({
    required this.id,
    required this.value,
    required this.title,
    required this.columns,
    this.semanticLabel,
  });

  final Object id;
  final L value;
  final String title;
  final List<CarpenterKanbanColumn<C, T>> columns;
  final String? semanticLabel;
}

@immutable
final class CarpenterPlanningMoveDetails<L, C, T> {
  const CarpenterPlanningMoveDetails({
    required this.sourceLane,
    required this.targetLane,
    required this.move,
  });

  final CarpenterPlanningLane<L, C, T> sourceLane;
  final CarpenterPlanningLane<L, C, T> targetLane;
  final CarpenterKanbanMoveDetails<C, T> move;
}

typedef CarpenterPlanningMoveCallback<L, C, T> =
    void Function(CarpenterPlanningMoveDetails<L, C, T> details);
typedef CarpenterPlanningLaneExpansionChanged =
    void Function(Object laneId, bool expanded);

/// Multi-lane planning surface built from compatible Kanban drag surfaces.
/// Lane expansion and card collections remain controlled by the caller.
final class CarpenterPlanningBoard<L, C, T> extends StatefulWidget {
  const CarpenterPlanningBoard({
    super.key,
    required this.lanes,
    required this.cardKey,
    required this.cardBuilder,
    this.collapsedLaneIds = const {},
    this.onLaneExpansionChanged,
    this.onMove,
    this.onLoadMore,
    this.onRetry,
    this.semanticLabel = 'Planning board',
  });

  final List<CarpenterPlanningLane<L, C, T>> lanes;
  final Object Function(T card) cardKey;
  final CarpenterKanbanCardBuilder<C, T> cardBuilder;
  final Set<Object> collapsedLaneIds;
  final CarpenterPlanningLaneExpansionChanged? onLaneExpansionChanged;
  final CarpenterPlanningMoveCallback<L, C, T>? onMove;
  final CarpenterKanbanColumnCallback<C, T>? onLoadMore;
  final CarpenterKanbanColumnCallback<C, T>? onRetry;
  final String semanticLabel;

  @override
  State<CarpenterPlanningBoard<L, C, T>> createState() =>
      _CarpenterPlanningBoardState<L, C, T>();
}

final class _CarpenterPlanningBoardState<L, C, T>
    extends State<CarpenterPlanningBoard<L, C, T>> {
  final Object _dragGroupId = Object();

  CarpenterPlanningLane<L, C, T>? _laneForColumn(
    CarpenterKanbanColumn<C, T> sourceColumn,
  ) {
    for (final lane in widget.lanes) {
      for (final column in lane.columns) {
        if (identical(column, sourceColumn) || column.id == sourceColumn.id) {
          return lane;
        }
      }
    }
    return null;
  }

  void _emitMove(
    CarpenterPlanningLane<L, C, T> targetLane,
    CarpenterKanbanMoveDetails<C, T> move,
  ) {
    final sourceLane = _laneForColumn(move.sourceColumn);
    if (sourceLane == null) return;
    widget.onMove?.call(
      CarpenterPlanningMoveDetails<L, C, T>(
        sourceLane: sourceLane,
        targetLane: targetLane,
        move: move,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.large);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < widget.lanes.length; index++) ...[
            if (index > 0) SizedBox(height: gap),
            _PlanningLaneView<L, C, T>(
              lane: widget.lanes[index],
              cardKey: widget.cardKey,
              cardBuilder: widget.cardBuilder,
              dragGroupId: _dragGroupId,
              collapsed: widget.collapsedLaneIds.contains(
                widget.lanes[index].id,
              ),
              onExpansionChanged: widget.onLaneExpansionChanged,
              onMove: widget.onMove == null
                  ? null
                  : (move) => _emitMove(widget.lanes[index], move),
              onLoadMore: widget.onLoadMore,
              onRetry: widget.onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

final class _PlanningLaneView<L, C, T> extends StatelessWidget {
  const _PlanningLaneView({
    required this.lane,
    required this.cardKey,
    required this.cardBuilder,
    required this.dragGroupId,
    required this.collapsed,
    this.onExpansionChanged,
    this.onMove,
    this.onLoadMore,
    this.onRetry,
  });

  final CarpenterPlanningLane<L, C, T> lane;
  final Object Function(T card) cardKey;
  final CarpenterKanbanCardBuilder<C, T> cardBuilder;
  final Object dragGroupId;
  final bool collapsed;
  final CarpenterPlanningLaneExpansionChanged? onExpansionChanged;
  final CarpenterKanbanMoveCallback<C, T>? onMove;
  final CarpenterKanbanColumnCallback<C, T>? onLoadMore;
  final CarpenterKanbanColumnCallback<C, T>? onRetry;

  int get _cardCount =>
      lane.columns.fold<int>(0, (count, column) => count + column.cards.length);

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return CarpenterCard(
      padded: false,
      semanticLabel: lane.semanticLabel ?? lane.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.all(gap),
            child: Row(
              children: [
                if (onExpansionChanged != null)
                  CarpenterIconButton(
                    icon: collapsed
                        ? CarpenterIcons.chevronRight
                        : CarpenterIcons.sortDown,
                    semanticLabel: collapsed
                        ? 'Expand ${lane.title}'
                        : 'Collapse ${lane.title}',
                    prominence: ActionProminence.ghost,
                    size: ControlSize.xsmall,
                    onPressed: () => onExpansionChanged!(lane.id, collapsed),
                  ),
                if (onExpansionChanged != null) SizedBox(width: gap),
                Expanded(
                  child: CarpenterText.label(
                    lane.title,
                    emphasis: TypographyEmphasis.strong,
                  ),
                ),
                CarpenterText.caption(
                  '$_cardCount',
                  colorRole: ContentColorRole.secondary,
                ),
              ],
            ),
          ),
          if (!collapsed)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gap, 0, gap, gap),
              child: CarpenterKanban<C, T>(
                columns: lane.columns,
                cardKey: cardKey,
                cardBuilder: cardBuilder,
                dragGroupId: dragGroupId,
                onMove: onMove,
                onLoadMore: onLoadMore,
                onRetry: onRetry,
                semanticLabel: '${lane.title} board',
              ),
            ),
        ],
      ),
    );
  }
}
