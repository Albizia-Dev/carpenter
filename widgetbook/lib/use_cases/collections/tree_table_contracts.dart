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

  void _report(String action, CarpenterTreeNode<String> node) {
    setState(() => _lastActivated = '$action: ${node.label}');
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
                'Drag the visible header dividers to resize columns. '
                'Click selects, Ctrl/Cmd toggles, Shift selects a range. '
                'Double-click or Enter activates. Two primary row actions stay '
                'inline; extra primary and secondary actions stay behind the '
                'ellipsis without changing row geometry.',
            child: CarpenterTreeTable<String>(
              nodes: _projectNodes,
              controller: _treeController,
              treeHeader: 'Object',
              treeWidth: CarpenterTableColumnWidth.fixed(
                width: 20.rem,
                minimum: 12.rem,
                maximum: 34.rem,
              ),
              expandedIds: _expanded,
              selectedIds: _selected,
              selectionMode: CarpenterTreeSelectionMode.multiple,
              multipleSelectionBehavior:
                  CollectionMultiSelectionBehavior.desktop,
              iconBuilder: (node) =>
                  node.canExpand ? GravityIcons.folder : GravityIcons.file,
              filter: _filtered
                  ? (node) => node.label.toLowerCase().contains('specification')
                  : null,
              onExpansionChanged: (id, expanded) => setState(() {
                _expanded = expanded
                    ? {..._expanded, id}
                    : _expanded.difference({id});
              }),
              onSelectionChanged: (ids) => setState(() => _selected = ids),
              onActivated: (node) => _report('Activated', node),
              columns: [
                CarpenterTreeTableColumn<String>.text(
                  id: 'kind',
                  header: 'Kind',
                  value: (node) => node.canExpand ? 'Group' : 'File',
                  width: CarpenterTableColumnWidth.fixed(
                    width: 8.rem,
                    minimum: 6.rem,
                    maximum: 16.rem,
                  ),
                ),
                CarpenterTreeTableColumn<String>.status(
                  id: 'state',
                  header: 'State',
                  label: (node) => switch (node.loadState) {
                    CarpenterTreeLoadState.ready => 'Ready',
                    CarpenterTreeLoadState.loading => 'Loading',
                    CarpenterTreeLoadState.failed => 'Failed',
                  },
                  role: (node) => switch (node.loadState) {
                    CarpenterTreeLoadState.ready => FeedbackColorRole.success,
                    CarpenterTreeLoadState.loading => FeedbackColorRole.info,
                    CarpenterTreeLoadState.failed => FeedbackColorRole.danger,
                  },
                  alignment: CarpenterTableColumnAlignment.end,
                  width: CarpenterTableColumnWidth.fixed(
                    width: 8.rem,
                    minimum: 6.rem,
                    maximum: 16.rem,
                  ),
                ),
                CarpenterTreeTableColumn<String>.actions(
                  id: 'actions',
                  header: 'Actions',
                  actions: (node) => [
                    CarpenterActionDescriptor(
                      id: 'open-${node.id}',
                      label: 'Open',
                      icon: CarpenterIcons.openFile,
                      onInvoke: () => _report('Open', node),
                    ),
                    CarpenterActionDescriptor(
                      id: 'edit-${node.id}',
                      label: 'Edit',
                      icon: CarpenterIcons.edit,
                      onInvoke: () => _report('Edit', node),
                    ),
                    CarpenterActionDescriptor(
                      id: 'copy-${node.id}',
                      label: 'Duplicate',
                      icon: CarpenterIcons.copy,
                      onInvoke: () => _report('Duplicate', node),
                    ),
                  ],
                  secondaryActions: (node) => [
                    CarpenterActionDescriptor(
                      id: 'archive-${node.id}',
                      label: 'Archive',
                      icon: CarpenterIcons.archive,
                      onInvoke: () => _report('Archive', node),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
