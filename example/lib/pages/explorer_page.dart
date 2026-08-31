import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

final class ExplorerPage extends StatefulWidget {
  const ExplorerPage({super.key, required this.toaster});

  final CarpenterToasterController toaster;

  @override
  State<ExplorerPage> createState() => _ExplorerPageState();
}

final class _ExplorerPageState extends State<ExplorerPage> {
  static const _nodes = <CarpenterTreeNode<_ExplorerEntry>>[
    CarpenterTreeNode<_ExplorerEntry>(
      id: 'finance',
      value: _ExplorerEntry('Finance', 'Domain', '4 resources'),
      label: 'Finance',
      children: [
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'treasury',
          value: _ExplorerEntry('Treasury', 'Module', 'Payments and balances'),
          label: 'Treasury',
          children: [
            CarpenterTreeNode<_ExplorerEntry>(
              id: 'bank-accounts',
              value: _ExplorerEntry(
                'Bank accounts',
                'Collection',
                '12 active accounts',
              ),
              label: 'Bank accounts',
            ),
            CarpenterTreeNode<_ExplorerEntry>(
              id: 'payments',
              value: _ExplorerEntry(
                'Payments',
                'Collection',
                '184 this month',
              ),
              label: 'Payments',
            ),
          ],
        ),
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'approvals',
          value: _ExplorerEntry(
            'Expense approvals',
            'Workflow',
            '7 waiting for review',
          ),
          label: 'Expense approvals',
        ),
      ],
    ),
    CarpenterTreeNode<_ExplorerEntry>(
      id: 'operations',
      value: _ExplorerEntry('Operations', 'Domain', '3 resources'),
      label: 'Operations',
      children: [
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'warehouse',
          value: _ExplorerEntry(
            'Warehouse',
            'Module',
            'Inventory and reconciliation',
          ),
          label: 'Warehouse',
        ),
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'projects',
          value: _ExplorerEntry('Projects', 'Module', '12 active projects'),
          label: 'Projects',
        ),
      ],
    ),
    CarpenterTreeNode<_ExplorerEntry>(
      id: 'platform',
      value: _ExplorerEntry('Platform', 'Domain', 'Shared infrastructure'),
      label: 'Platform',
      children: [
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'identity',
          value: _ExplorerEntry('Identity', 'Service', 'ORY-backed access'),
          label: 'Identity',
        ),
        CarpenterTreeNode<_ExplorerEntry>(
          id: 'files',
          value: _ExplorerEntry('Files', 'Service', 'Object storage gateway'),
          label: 'Files',
        ),
      ],
    ),
  ];

  Set<Object> _expanded = <Object>{'finance', 'treasury', 'operations'};
  Set<Object> _selected = <Object>{'bank-accounts'};

  CarpenterTreeNode<_ExplorerEntry>? get _selectedNode {
    if (_selected.isEmpty) return null;
    return findCarpenterTreeNode(_nodes, _selected.first);
  }

  void _setExpanded(Object id, bool expanded) {
    setState(() {
      _expanded = expanded
          ? <Object>{..._expanded, id}
          : _expanded.where((entry) => entry != id).toSet();
    });
  }

  void _inspect(CarpenterTreeNode<_ExplorerEntry> node) {
    widget.toaster.show(
      CarpenterToastDescriptor(
        id: 'explorer-${node.id}',
        title: node.label,
        message: '${node.value.kind}: ${node.value.description}',
        role: FeedbackColorRole.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedNode;
    final tree = CarpenterTreeView<_ExplorerEntry>(
      nodes: _nodes,
      expandedIds: _expanded,
      selectedIds: _selected,
      selectionMode: CarpenterTreeSelectionMode.single,
      onExpansionChanged: _setExpanded,
      onSelectionChanged: (value) => setState(() => _selected = value),
      actions: (node) => [
        CarpenterActionDescriptor(
          id: 'explorer.${node.id}.inspect',
          label: 'Inspect',
          onInvoke: () => _inspect(node),
        ),
      ],
      semanticLabel: 'Workspace resource tree',
    );

    final details = CarpenterCard(
      semanticLabel: 'Selected resource details',
      child: selected == null
          ? const CarpenterText.body(
              'Select a resource to inspect it.',
              colorRole: ContentColorRole.secondary,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarpenterText.title(
                  selected.value.title,
                  emphasis: TypographyEmphasis.strong,
                ),
                SizedBox(height: context.units(.75.rem)),
                CarpenterStatusIndicator(
                  label: selected.value.kind,
                  role: FeedbackColorRole.info,
                ),
                SizedBox(height: context.units(1.rem)),
                CarpenterText.body(selected.value.description),
                SizedBox(height: context.units(1.rem)),
                CarpenterButton.outlined(
                  label: 'Inspect resource',
                  onPressed: () => _inspect(selected),
                ),
              ],
            ),
    );

    return CarpenterPageBody(
      semanticLabel: 'Resource explorer',
      children: [
        CarpenterPageHeader(
          title: 'Resource explorer',
          subtitle:
              'Keyboard-friendly hierarchical navigation with caller-owned expansion and selection.',
          status: CarpenterPageStatus(
            label: '${flattenCarpenterTree(_nodes, _expanded).length} visible nodes',
            role: FeedbackColorRole.info,
          ),
        ),
        CarpenterCard(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < context.units(45.rem)) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    tree,
                    SizedBox(height: context.units(1.rem)),
                    details,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: tree),
                  SizedBox(width: context.units(1.rem)),
                  Expanded(flex: 2, child: details),
                ],
              );
            },
          ),
        ),
        const CarpenterNotice(
          title: 'Try the keyboard',
          message:
              'Arrow keys move through the tree, Left/Right collapse and expand, and Enter or Space selects the focused row.',
          tone: CarpenterNoticeTone.info,
        ),
      ],
    );
  }
}

final class _ExplorerEntry {
  const _ExplorerEntry(this.title, this.kind, this.description);

  final String title;
  final String kind;
  final String description;
}
