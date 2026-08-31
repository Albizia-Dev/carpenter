import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

final class PlanningPage extends StatefulWidget {
  const PlanningPage({super.key, required this.toaster});

  final CarpenterToasterController toaster;

  @override
  State<PlanningPage> createState() => _PlanningPageState();
}

final class _PlanningPageState extends State<PlanningPage> {
  final Map<String, List<_WorkItem>> _items = <String, List<_WorkItem>>{
    'backlog': <_WorkItem>[
      const _WorkItem(
        id: 'W-121',
        title: 'Import bank opening balances',
        owner: 'Treasury',
        priority: FeedbackColorRole.warning,
      ),
      const _WorkItem(
        id: 'W-122',
        title: 'Normalize counterparty accounts',
        owner: 'Master data',
        priority: FeedbackColorRole.neutral,
      ),
      const _WorkItem(
        id: 'W-123',
        title: 'Add approval audit trail',
        owner: 'Governance',
        priority: FeedbackColorRole.info,
      ),
    ],
    'progress': <_WorkItem>[
      const _WorkItem(
        id: 'W-118',
        title: 'Reconcile imported payments',
        owner: 'Treasury',
        priority: FeedbackColorRole.danger,
      ),
      const _WorkItem(
        id: 'W-119',
        title: 'Adaptive project header',
        owner: 'Client platform',
        priority: FeedbackColorRole.info,
      ),
    ],
    'done': <_WorkItem>[
      const _WorkItem(
        id: 'W-110',
        title: 'Trusted pub.dev publishing',
        owner: 'Platform',
        priority: FeedbackColorRole.success,
      ),
    ],
  };

  final List<String> _triage = <String>[
    'Review failed bank import',
    'Approve supplier contract',
    'Reconcile warehouse variance',
  ];

  List<CarpenterKanbanColumn<String, _WorkItem>> get _columns => [
    CarpenterKanbanColumn<String, _WorkItem>(
      id: 'backlog',
      value: 'backlog',
      title: 'Backlog',
      cards: List.unmodifiable(_items['backlog']!),
    ),
    CarpenterKanbanColumn<String, _WorkItem>(
      id: 'progress',
      value: 'progress',
      title: 'In progress',
      cards: List.unmodifiable(_items['progress']!),
    ),
    CarpenterKanbanColumn<String, _WorkItem>(
      id: 'done',
      value: 'done',
      title: 'Done',
      cards: List.unmodifiable(_items['done']!),
    ),
  ];

  void _move(CarpenterKanbanMoveDetails<String, _WorkItem> details) {
    final sourceId = details.sourceColumn.id as String;
    final targetId = details.targetColumn.id as String;
    final source = _items[sourceId]!;
    final target = _items[targetId]!;
    final sourceIndex = source.indexWhere((item) => item.id == details.card.id);
    if (sourceIndex < 0) return;

    setState(() {
      final item = source.removeAt(sourceIndex);
      final insertion = details.targetIndex.clamp(0, target.length);
      target.insert(insertion, item);
    });

    widget.toaster.show(
      CarpenterToastDescriptor(
        id: 'planning-${details.card.id}-$targetId',
        title: '${details.card.id} moved',
        message: 'Now in ${details.targetColumn.title}.',
        role: FeedbackColorRole.success,
      ),
    );
  }

  void _reorderTriage(CarpenterReorderDetails<String> details) {
    setState(() {
      final item = _triage.removeAt(details.oldIndex);
      _triage.insert(details.newIndex.clamp(0, _triage.length), item);
    });
  }

  @override
  Widget build(BuildContext context) => CarpenterPageBody(
    semanticLabel: 'Planning workspace',
    children: [
      CarpenterPageHeader(
        title: 'Delivery planning',
        subtitle:
            'Controlled Kanban and generic reorder surfaces using the same Carpenter drag-and-drop kernel.',
        status: CarpenterPageStatus(
          label: '${_items.values.fold<int>(0, (sum, list) => sum + list.length)} work items',
          role: FeedbackColorRole.info,
        ),
      ),
      const CarpenterNotice(
        title: 'This is application state, not a canned component demo',
        message:
            'The widgets only emit move details. This page owns the lists and applies every reorder, so the example mirrors production usage.',
        tone: CarpenterNoticeTone.info,
      ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('triage'),
        title: 'Triage order',
        description:
            'A presentation-neutral reorderable collection for arbitrary application content.',
        child: CarpenterReorderableCollection<String>(
          items: _triage,
          itemKey: (item) => item,
          onReorder: _reorderTriage,
          itemBuilder: (context, item, state) => Padding(
            padding: EdgeInsets.only(bottom: context.units(.5.rem)),
            child: CarpenterCard(
              semanticLabel: item,
              child: Row(
                children: [
                  Expanded(child: CarpenterText.body(item)),
                  CarpenterText.caption(
                    state.dragging ? 'Moving' : 'Drag to reorder',
                    colorRole: ContentColorRole.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      CarpenterPageSection(
        id: const CarpenterPageSectionId('kanban'),
        title: 'Delivery board',
        description:
            'Move cards within a column or across columns. Empty columns remain valid drop targets.',
        child: CarpenterKanban<String, _WorkItem>(
          columns: _columns,
          cardKey: (item) => item.id,
          onMove: _move,
          cardBuilder: (context, item, state) => CarpenterCard(
            semanticLabel: '${item.id} ${item.title}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CarpenterText.label(
                        item.title,
                        emphasis: TypographyEmphasis.strong,
                      ),
                    ),
                    CarpenterStatusIndicator(
                      label: item.id,
                      role: item.priority,
                    ),
                  ],
                ),
                SizedBox(height: context.units(.5.rem)),
                CarpenterText.caption(
                  item.owner,
                  colorRole: ContentColorRole.secondary,
                ),
                if (state.dragging || state.hovering) ...[
                  SizedBox(height: context.units(.5.rem)),
                  CarpenterText.caption(
                    state.dragging
                        ? 'Dragging'
                        : state.acceptsDrop
                        ? 'Drop here'
                        : 'Drop not accepted',
                    colorRole: ContentColorRole.secondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ],
  );
}

final class _WorkItem {
  const _WorkItem({
    required this.id,
    required this.title,
    required this.owner,
    required this.priority,
  });

  final String id;
  final String title;
  final String owner;
  final FeedbackColorRole priority;
}
