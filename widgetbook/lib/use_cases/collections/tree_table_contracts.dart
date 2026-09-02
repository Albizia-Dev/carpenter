import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

final treeTableContractsComponent = WidgetbookComponent(
  name: 'Tree table contracts',
  useCases: [
    WidgetbookUseCase(
      name: 'Project structure',
      builder: (_) => const _ProjectStructurePreview(),
    ),
  ],
);

const _projectNodes = <CarpenterTreeNode<String>>[
  CarpenterTreeNode<String>(
    id: 'project',
    value: 'project',
    label: 'Project #2417',
    children: [
      CarpenterTreeNode<String>(
        id: 'documents',
        value: 'documents',
        label: 'Documents',
        children: [
          CarpenterTreeNode<String>(
            id: 'specification',
            value: 'specification',
            label: 'Specification.md',
          ),
          CarpenterTreeNode<String>(
            id: 'budget',
            value: 'budget',
            label: 'Budget.xlsx',
          ),
        ],
      ),
      CarpenterTreeNode<String>(
        id: 'correspondence',
        value: 'correspondence',
        label: 'Correspondence',
        children: [
          CarpenterTreeNode<String>(
            id: 'incoming',
            value: 'incoming',
            label: 'Incoming #128',
          ),
        ],
      ),
    ],
  ),
];

final class _ProjectStructurePreview extends StatefulWidget {
  const _ProjectStructurePreview();

  @override
  State<_ProjectStructurePreview> createState() =>
      _ProjectStructurePreviewState();
}

final class _ProjectStructurePreviewState
    extends State<_ProjectStructurePreview> {
  final CarpenterTreeController _treeController = CarpenterTreeController();
  Set<Object> _expanded = {'project'};
  Set<Object> _selected = const {};
  bool _filtered = false;
  String _lastActivated = 'Nothing activated';

  @override
  void dispose() {
    _treeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: context.units(42.rem),
    child: CarpenterPage(
      descriptor: const CarpenterPageDescriptor(
        id: CarpenterPageId('widgetbook.project-structure'),
        title: 'Project #2417',
        kind: CarpenterPageKind.record,
      ),
      header: const CarpenterPageHeader(
        title: 'Project #2417',
        subtitle: 'Single page viewport with a flow-native tree table',
      ),
      body: CarpenterPageBody(
        children: [
          Wrap(
            spacing: context.units(.5.rem),
            runSpacing: context.units(.5.rem),
            children: [
              CarpenterButton(
                label: _filtered ? 'Show all' : 'Filter specification',
                prominence: ActionProminence.outlined,
                onInvoke: () => setState(() => _filtered = !_filtered),
              ),
              CarpenterButton(
                label: 'Reveal budget',
                prominence: ActionProminence.outlined,
                onInvoke: () => _treeController.reveal('budget'),
              ),
            ],
          ),
          CarpenterText.caption(
            _lastActivated,
            colorRole: ContentColorRole.secondary,
          ),
          CarpenterPageSection(
            id: const CarpenterPageSectionId('structure'),
            title: 'Structure',
            description:
                'Click or Space selects. Double-click or Enter activates.',
            child: CarpenterTreeTable<String>(
              nodes: _projectNodes,
              controller: _treeController,
              treeHeader: 'Object',
              treeWidth: CarpenterTableColumnWidth.flexible(
                flex: 3,
                minimum: 12.rem,
                maximum: 28.rem,
              ),
              expandedIds: _expanded,
              selectedIds: _selected,
              filter: _filtered
                  ? (node) => node.label.toLowerCase().contains('specification')
                  : null,
              onExpansionChanged: (id, expanded) => setState(() {
                _expanded = expanded
                    ? {..._expanded, id}
                    : _expanded.difference({id});
              }),
              onSelectionChanged: (ids) => setState(() => _selected = ids),
              onActivated: (node) => setState(() {
                _lastActivated = 'Activated: ${node.label}';
              }),
              columns: [
                CarpenterTreeTableColumn<String>(
                  id: 'kind',
                  header: 'Kind',
                  width: CarpenterTableColumnWidth.fixed(width: 7.rem),
                  cellBuilder: (context, node) => CarpenterText.caption(
                    node.canExpand ? 'Group' : 'File',
                    colorRole: ContentColorRole.secondary,
                  ),
                ),
                CarpenterTreeTableColumn<String>(
                  id: 'state',
                  header: 'State',
                  alignment: CarpenterTableColumnAlignment.end,
                  width: CarpenterTableColumnWidth.fixed(width: 6.rem),
                  cellBuilder: (context, node) => CarpenterText.caption(
                    node.loadState.name,
                    textAlign: TextAlign.end,
                    colorRole: ContentColorRole.secondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
