import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

final reorderableCollectionComponent = WidgetbookComponent(
  name: 'Reorderable collection',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (_) => const _ReorderPreview(),
    ),
    WidgetbookUseCase(
      name: 'Constrained',
      builder: (context) => SizedBox(
        width: context.units(16.rem),
        child: const _ReorderPreview(),
      ),
    ),
  ],
);

final treeViewComponent = WidgetbookComponent(
  name: 'Tree view',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: (_) => const _TreePreview()),
  ],
);

final treeTableComponent = WidgetbookComponent(
  name: 'Tree table',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (_) => const _TreeTablePreview(),
    ),
  ],
);

final kanbanComponent = WidgetbookComponent(
  name: 'Kanban',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (_) => const _KanbanPreview(),
    ),
  ],
);

final planningBoardComponent = WidgetbookComponent(
  name: 'Planning board',
  useCases: [
    WidgetbookUseCase(name: 'Lanes', builder: (_) => const _PlanningPreview()),
  ],
);

final class _ReorderPreview extends StatefulWidget {
  const _ReorderPreview();

  @override
  State<_ReorderPreview> createState() => _ReorderPreviewState();
}

final class _ReorderPreviewState extends State<_ReorderPreview> {
  List<String> _items = ['Discovery', 'Design', 'Build', 'Release'];

  @override
  Widget build(BuildContext context) => CarpenterReorderableCollection<String>(
    items: _items,
    itemKey: (item) => item,
    onReorder: (details) {
      setState(() {
        final next = [..._items];
        final item = next.removeAt(details.oldIndex);
        next.insert(details.newIndex, item);
        _items = next;
      });
    },
    itemBuilder: (context, item, state) => Padding(
      padding: EdgeInsets.only(bottom: context.units(.5.rem)),
      child: Opacity(
        opacity: state.dragging ? .45 : 1,
        child: CarpenterCard(
          borderColor: state.hovering && state.accepts
              ? CarpenterTheme.of(
                  context,
                ).feedback.resolve(FeedbackColorRole.info).foreground
              : null,
          child: CarpenterText.label(item),
        ),
      ),
    ),
  );
}

const _treeNodes = <CarpenterTreeNode<String>>[
  CarpenterTreeNode<String>(
    id: 'projects',
    value: 'projects',
    label: 'Projects',
    children: [
      CarpenterTreeNode<String>(
        id: 'alpha',
        value: 'alpha',
        label: 'Alpha',
        children: [
          CarpenterTreeNode<String>(
            id: 'alpha-spec',
            value: 'alpha-spec',
            label: 'Specification.md',
          ),
        ],
      ),
      CarpenterTreeNode<String>(
        id: 'beta',
        value: 'beta',
        label: 'Beta',
        hasChildren: true,
        loadState: CarpenterTreeLoadState.loading,
      ),
    ],
  ),
  CarpenterTreeNode<String>(id: 'archive', value: 'archive', label: 'Archive'),
];

final class _TreePreview extends StatefulWidget {
  const _TreePreview();

  @override
  State<_TreePreview> createState() => _TreePreviewState();
}

final class _TreePreviewState extends State<_TreePreview> {
  Set<Object> _expanded = {'projects'};
  Set<Object> _selected = {'alpha'};
  String _lastDrop = 'No move yet';

  @override
  Widget build(BuildContext context) => SizedBox(
    width: context.units(32.rem),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CarpenterTreeView<String>(
          nodes: _treeNodes,
          expandedIds: _expanded,
          selectedIds: _selected,
          selectionMode: CarpenterTreeSelectionMode.multiple,
          onExpansionChanged: (id, expanded) => setState(() {
            _expanded = expanded
                ? {..._expanded, id}
                : _expanded.difference({id});
          }),
          onSelectionChanged: (ids) => setState(() => _selected = ids),
          onDrop: (details) => setState(() {
            _lastDrop =
                '${details.dragged.label} → ${details.target.label} · ${details.position.name}';
          }),
        ),
        SizedBox(height: context.units(.5.rem)),
        CarpenterText.caption(_lastDrop, colorRole: ContentColorRole.secondary),
      ],
    ),
  );
}

final class _TreeTablePreview extends StatefulWidget {
  const _TreeTablePreview();

  @override
  State<_TreeTablePreview> createState() => _TreeTablePreviewState();
}

final class _TreeTablePreviewState extends State<_TreeTablePreview> {
  Set<Object> _expanded = {'projects', 'alpha'};
  Set<Object> _selected = const {};

  @override
  Widget build(BuildContext context) => SizedBox(
    width: context.units(46.rem),
    child: CarpenterTreeTable<String>(
      nodes: _treeNodes,
      iconBuilder: (node) =>
          node.canExpand ? GravityIcons.folder : GravityIcons.file,
      expandedIds: _expanded,
      selectedIds: _selected,
      onExpansionChanged: (id, expanded) => setState(() {
        _expanded = expanded ? {..._expanded, id} : _expanded.difference({id});
      }),
      onSelectionChanged: (ids) => setState(() => _selected = ids),
      columns: [
        CarpenterTreeTableColumn<String>(
          id: 'kind',
          header: 'Kind',
          cellBuilder: (context, node) => CarpenterText.caption(
            node.canExpand ? 'Folder' : 'File',
            colorRole: ContentColorRole.secondary,
          ),
        ),
        CarpenterTreeTableColumn<String>(
          id: 'state',
          header: 'State',
          cellBuilder: (context, node) => CarpenterText.caption(
            node.loadState.name,
            colorRole: ContentColorRole.secondary,
          ),
        ),
      ],
    ),
  );
}

final class _KanbanPreview extends StatefulWidget {
  const _KanbanPreview();

  @override
  State<_KanbanPreview> createState() => _KanbanPreviewState();
}

final class _KanbanPreviewState extends State<_KanbanPreview> {
  List<CarpenterKanbanColumn<String, String>> _columns = const [
    CarpenterKanbanColumn<String, String>(
      id: 'todo',
      value: 'todo',
      title: 'To do',
      cards: ['Investigate', 'Write spec'],
    ),
    CarpenterKanbanColumn<String, String>(
      id: 'doing',
      value: 'doing',
      title: 'Doing',
      cards: ['Build prototype'],
    ),
    CarpenterKanbanColumn<String, String>(
      id: 'done',
      value: 'done',
      title: 'Done',
      cards: [],
    ),
  ];

  void _move(CarpenterKanbanMoveDetails<String, String> details) {
    setState(() {
      final cards = <Object, List<String>>{
        for (final column in _columns) column.id: [...column.cards],
      };
      final moved = cards[details.sourceColumn.id]!.removeAt(
        details.sourceIndex,
      );
      cards[details.targetColumn.id]!.insert(details.targetIndex, moved);
      _columns = [
        for (final column in _columns)
          CarpenterKanbanColumn<String, String>(
            id: column.id,
            value: column.value,
            title: column.title,
            cards: cards[column.id]!,
          ),
      ];
    });
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.units(24.rem),
    child: CarpenterKanban<String, String>(
      columns: _columns,
      cardKey: (card) => card,
      onMove: _move,
      cardBuilder: (context, card, state) => Opacity(
        opacity: state.dragging ? .45 : 1,
        child: CarpenterCard(
          borderColor: state.hovering && state.acceptsDrop
              ? CarpenterTheme.of(
                  context,
                ).feedback.resolve(FeedbackColorRole.info).foreground
              : null,
          child: CarpenterText.label(card),
        ),
      ),
    ),
  );
}

final class _PlanningPreview extends StatefulWidget {
  const _PlanningPreview();

  @override
  State<_PlanningPreview> createState() => _PlanningPreviewState();
}

final class _PlanningPreviewState extends State<_PlanningPreview> {
  Set<Object> _collapsed = {'later'};

  static const _lanes = <CarpenterPlanningLane<String, String, String>>[
    CarpenterPlanningLane<String, String, String>(
      id: 'now',
      value: 'now',
      title: 'Current sprint',
      columns: [
        CarpenterKanbanColumn<String, String>(
          id: 'now-todo',
          value: 'todo',
          title: 'Queue',
          cards: ['Tree keyboard nav', 'File adapter'],
        ),
        CarpenterKanbanColumn<String, String>(
          id: 'now-doing',
          value: 'doing',
          title: 'Active',
          cards: ['Kanban DnD'],
        ),
      ],
    ),
    CarpenterPlanningLane<String, String, String>(
      id: 'later',
      value: 'later',
      title: 'Later',
      columns: [
        CarpenterKanbanColumn<String, String>(
          id: 'later-backlog',
          value: 'backlog',
          title: 'Backlog',
          cards: ['Virtualization'],
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) =>
      CarpenterPlanningBoard<String, String, String>(
        lanes: _lanes,
        collapsedLaneIds: _collapsed,
        cardKey: (card) => card,
        onLaneExpansionChanged: (id, expanded) => setState(() {
          _collapsed = expanded
              ? _collapsed.difference({id})
              : {..._collapsed, id};
        }),
        cardBuilder: (context, card, state) =>
            CarpenterCard(child: CarpenterText.label(card)),
        onMove: (_) {},
      );
}
