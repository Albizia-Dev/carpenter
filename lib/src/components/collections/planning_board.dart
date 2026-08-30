import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
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
    required this.lane,
    required this.move,
  });

  final CarpenterPlanningLane<L, C, T> lane;
  final CarpenterKanbanMoveDetails<C, T> move;
}

typedef CarpenterPlanningMoveCallback<L, C, T> =
    void Function(CarpenterPlanningMoveDetails<L, C, T> details);
typedef CarpenterPlanningLaneExpansionChanged =
    void Function(Object laneId, bool expanded);

/// Multi-lane planning surface built from the same Kanban movement contracts.
/// Lane expansion is controlled; cards remain controlled by the caller.
final class CarpenterPlanningBoard<L, C, T> extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.large);
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < lanes.length; index++) ...[
            if (index > 0) SizedBox(height: gap),
            _PlanningLaneView<L, C, T>(
              lane: lanes[index],
              cardKey: cardKey,
              cardBuilder: cardBuilder,
              collapsed: collapsedLaneIds.contains(lanes[index].id),
              onExpansionChanged: onLaneExpansionChanged,
              onMove: onMove,
              onLoadMore: onLoadMore,
              onRetry: onRetry,
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
    required this.collapsed,
    this.onExpansionChanged,
    this.onMove,
    this.onLoadMore,
    this.onRetry,
  });

  final CarpenterPlanningLane<L, C, T> lane;
  final Object Function(T card) cardKey;
  final CarpenterKanbanCardBuilder<C, T> cardBuilder;
  final bool collapsed;
  final CarpenterPlanningLaneExpansionChanged? onExpansionChanged;
  final CarpenterPlanningMoveCallback<L, C, T>? onMove;
  final CarpenterKanbanColumnCallback<C, T>? onLoadMore;
  final CarpenterKanbanColumnCallback<C, T>? onRetry;

  int get _cardCount => lane.columns.fold<int>(
    0,
    (count, column) => count + column.cards.length,
  );

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
                onMove: onMove == null
                    ? null
                    : (move) => onMove!(
                        CarpenterPlanningMoveDetails<L, C, T>(
                          lane: lane,
                          move: move,
                        ),
                      ),
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
