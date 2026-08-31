import 'package:carpenter/carpenter.dart';
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
              icon: GravityIcons.displayPulse,
              command: widget.commands.dashboard,
            ),
            CarpenterSidebarItem(
              id: 'projects',
              label: 'Projects',
              icon: GravityIcons.layoutList,
              command: widget.commands.projects,
            ),
            CarpenterSidebarItem(
              id: 'planning',
              label: 'Planning',
              icon: GravityIcons.clock,
              command: widget.commands.planning,
            ),
            CarpenterSidebarItem(
              id: 'explorer',
              label: 'Explorer',
              icon: GravityIcons.bars,
              command: widget.commands.explorer,
            ),
            CarpenterSidebarItem(
              id: 'operations',
              label: 'Operations',
              icon: GravityIcons.thunderbolt,
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
              icon: GravityIcons.gear,
              command: widget.commands.settings,
            ),
            CarpenterSidebarItem(
              id: 'notify',
              label: 'Notify',
              icon: GravityIcons.bell,
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
                        ? (_sidebarExpanded
                              ? GravityIcons.xmark
                              : GravityIcons.bars)
                        : GravityIcons.bars,
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
                      icon: GravityIcons.bell,
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
      const CarpenterAvatar(initials: 'C', size: Rem(2)),
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
      const CarpenterAvatar(initials: 'NC', size: Rem(2)),
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
