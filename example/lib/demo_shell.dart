import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

import 'demo_commands.dart';

final class DemoShell extends StatefulWidget {
  const DemoShell({
    super.key,
    required this.selectedId,
    required this.title,
    required this.subtitle,
    required this.commands,
    required this.toaster,
    required this.child,
  });

  final String selectedId;
  final String title;
  final String subtitle;
  final DemoCommands commands;
  final CarpenterToasterController toaster;
  final Widget child;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

final class _DemoShellState extends State<DemoShell> {
  var _sidebarExpanded = true;
  var _sidebarOpen = false;

  @override
  Widget build(BuildContext context) {
    final sidebar = CarpenterSidebarData(
      selectedId: widget.selectedId,
      header: const _Brand(expanded: true),
      compactHeader: const _Brand(expanded: false),
      footer: const _Account(expanded: true),
      compactFooter: const _Account(expanded: false),
      sections: <CarpenterSidebarSection>[
        CarpenterSidebarSection(
          label: 'Workspace',
          items: <CarpenterSidebarItem>[
            CarpenterSidebarItem(
              id: 'dashboard',
              label: 'Overview',
              icon: Icons.dashboard_outlined,
              command: widget.commands.dashboard,
            ),
            CarpenterSidebarItem(
              id: 'projects',
              label: 'Projects',
              icon: Icons.view_list_outlined,
              command: widget.commands.projects,
            ),
            CarpenterSidebarItem(
              id: 'operations',
              label: 'Operations',
              icon: Icons.bolt_outlined,
              command: widget.commands.operations,
            ),
          ],
        ),
        CarpenterSidebarSection(
          label: 'Application',
          items: <CarpenterSidebarItem>[
            CarpenterSidebarItem(
              id: 'settings',
              label: 'Settings',
              icon: Icons.settings_outlined,
              command: widget.commands.settings,
            ),
            CarpenterSidebarItem(
              id: 'notify',
              label: 'Notify',
              icon: Icons.notifications_outlined,
              command: widget.commands.notify,
              selectable: false,
            ),
          ],
        ),
      ],
    );

    return CarpenterToastRegion(
      controller: widget.toaster,
      maxVisible: 3,
      placement: CarpenterToastPlacement.bottomEnd,
      child: LoadingBoundary(
        child: widget.child,
        builder: (context, loading, page) => CarpenterRootLayout(
          sidebar: sidebar,
          sidebarExpanded: _sidebarExpanded,
          onSidebarExpandedChanged: (value) =>
              setState(() => _sidebarExpanded = value),
          sidebarOpen: _sidebarOpen,
          onSidebarOpenChanged: (value) => setState(() => _sidebarOpen = value),
          headerBuilder: (context, layout) => SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CarpenterTopPanel(
                  title: widget.title,
                  subtitle: widget.subtitle,
                  leading: CarpenterIconButton(
                    icon: layout.isDesktop
                        ? (_sidebarExpanded ? Icons.menu_open : Icons.menu)
                        : Icons.menu,
                    semanticLabel: layout.isDesktop
                        ? 'Toggle compact sidebar'
                        : 'Open navigation',
                    onPressed: layout.isDesktop
                        ? layout.toggleSidebarExpanded
                        : layout.toggleSidebar,
                  ),
                  actions: <Widget>[
                    if (loading.isLoading)
                      CarpenterStatusIndicator(
                        label: '${loading.activeCount} active',
                        role: FeedbackColorRole.info,
                      ),
                    CarpenterIconButton(
                      icon: Icons.notifications_outlined,
                      semanticLabel: 'Show notification',
                      onPressed: () => widget.commands.notify.execute(null),
                    ),
                  ],
                ),
                if (loading.isLoading) const CarpenterProgress(value: .68),
              ],
            ),
          ),
          body: SafeArea(top: false, child: page),
        ),
      ),
    );
  }
}

final class _Brand extends StatelessWidget {
  const _Brand({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: expanded
        ? MainAxisAlignment.start
        : MainAxisAlignment.center,
    children: [
      const CarpenterAvatar(initials: 'C', size: 32),
      if (expanded) ...[
        SizedBox(width: context.units(.625.rem)),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterText.label(
                'Carpenter',
                emphasis: TypographyEmphasis.strong,
              ),
              CarpenterText.caption(
                'Example workspace',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
        ),
      ],
    ],
  );
}

final class _Account extends StatelessWidget {
  const _Account({required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: expanded
        ? MainAxisAlignment.start
        : MainAxisAlignment.center,
    children: [
      const CarpenterAvatar(initials: 'NC', size: 32),
      if (expanded) ...[
        SizedBox(width: context.units(.625.rem)),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarpenterText.label('Demo operator'),
              CarpenterText.caption(
                'Online',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
        ),
      ],
    ],
  );
}
