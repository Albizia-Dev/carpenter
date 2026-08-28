import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/layout_viewport.dart';
import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

final sidebarComponent = WidgetbookComponent(
  name: 'Sidebar',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _sidebarPlayground),
    WidgetbookUseCase(name: 'Expanded / collapsed', builder: _sidebarMatrix),
  ],
);

final shellHeaderComponent = WidgetbookComponent(
  name: 'Header',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _headerPlayground)],
);

final rootLayoutComponent = WidgetbookComponent(
  name: 'Root Layout',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _rootPlayground),
    WidgetbookUseCase(name: 'Desktop', builder: _desktopRoot),
    WidgetbookUseCase(name: 'Tablet overlay', builder: _tabletRoot),
    WidgetbookUseCase(name: 'Mobile drawer', builder: _mobileRoot),
  ],
);

Widget _sidebarPlayground(BuildContext context) {
  final expanded = context.knobs.boolean(
    label: 'Sidebar · Expanded',
    initialValue: true,
  );
  final platform = context.knobs.object.segmented(
    label: 'Environment · Platform',
    options: [
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ],
    initialOption: TargetPlatform.macOS,
    labelBuilder: (value) => value.name,
  );
  final width = expanded ? 320.0 : 96.0;
  return preview(
    SizedBox(
      width: width,
      height: context.units(38.75.rem),
      child: _SidebarPreview(expanded: expanded, targetPlatform: platform),
    ),
  );
}

Widget _sidebarMatrix(BuildContext context) => preview(
  SizedBox(
    height: context.units(38.75.rem),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: const [
        _SidebarPreview(expanded: true),
        SizedBox(width: context.units(1.5.rem)),
        _SidebarPreview(expanded: false),
      ],
    ),
  ),
);

Widget _headerPlayground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Payments',
  );
  final subtitle = context.knobs.stringOrNull(
    label: 'Content · Subtitle',
    initialValue: 'Operational treasury workspace',
    defaultToNull: false,
  );
  final actionCount = context.knobs.int.slider(
    label: 'Actions · Count',
    initialValue: 2,
    min: 0,
    max: 4,
  );
  return preview(
    SizedBox(
      width: context.units(52.5.rem),
      child: CarpenterTopPanel(
        title: title,
        subtitle: subtitle,
        leading: CarpenterIconButton(
          icon: CarpenterIcons.list,
          semanticLabel: 'Open navigation',
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
          onPressed: () {},
        ),
        actions: [
          for (var index = 0; index < actionCount; index++)
            CarpenterButton(
              label: index == 0 ? 'Create' : 'Action ${index + 1}',
              size: ControlSize.small,
              prominence: index == 0
                  ? ActionProminence.high
                  : ActionProminence.ghost,
              onPressed: () {},
            ),
        ],
      ),
    ),
  );
}

Widget _rootPlayground(BuildContext context) => layoutViewportPreview(
  context,
  offHeight: const Px(720),
  child: const _RootPreview(),
);

Widget _desktopRoot(BuildContext context) => layoutViewportFrame(
  preset: LayoutViewportPreset.desktopSmall,
  child: const _RootPreview(),
);

Widget _tabletRoot(BuildContext context) => layoutViewportFrame(
  preset: LayoutViewportPreset.tabletPortrait,
  child: const _RootPreview(initialOpen: true),
);

Widget _mobileRoot(BuildContext context) => layoutViewportFrame(
  preset: LayoutViewportPreset.mobilePortrait,
  child: const _RootPreview(initialOpen: true),
);

final class _SidebarPreview extends StatefulWidget {
  const _SidebarPreview({this.expanded = true, this.targetPlatform});

  final bool expanded;
  final TargetPlatform? targetPlatform;

  @override
  State<_SidebarPreview> createState() => _SidebarPreviewState();
}

final class _SidebarPreviewState extends State<_SidebarPreview> {
  late final CarpenterCommandController<void> _searchCommand =
      CarpenterCommandController<void>(
        id: 'search',
        title: 'Search',
        shortcuts: const [
          SingleActivator(LogicalKeyboardKey.keyK, control: true),
        ],
      );
  late final CarpenterCommandController<void> _paymentsCommand =
      CarpenterCommandController<void>(
        id: 'payments',
        title: 'Payments',
        shortcuts: const [
          SingleActivator(LogicalKeyboardKey.keyP, control: true),
        ],
      );
  String _selected = 'overview';

  @override
  void dispose() {
    _searchCommand.dispose();
    _paymentsCommand.dispose();
    super.dispose();
  }

  CarpenterSidebarData get _data => CarpenterSidebarData(
    selectedId: _selected,
    onSelected: (id) => setState(() => _selected = id),
    header: const CarpenterText.title('Carpenter'),
    compactHeader: const CarpenterIcon(CarpenterIcons.tree),
    footer: const CarpenterText.caption('v0.1 · workspace'),
    compactFooter: const CarpenterIcon(CarpenterIcons.info),
    sections: [
      CarpenterSidebarSection(
        label: 'Workspace',
        items: [
          CarpenterSidebarItem(
            id: 'overview',
            label: 'Overview',
            icon: CarpenterIcons.list,
            onInvoke: () {},
          ),
          CarpenterSidebarItem(
            id: 'payments',
            label: 'Payments',
            icon: CarpenterIcons.paymentCard,
            command: _paymentsCommand,
            onInvoke: () {},
          ),
          CarpenterSidebarItem(
            id: 'documents',
            label: 'Documents',
            icon: CarpenterIcons.file,
            onInvoke: () {},
          ),
        ],
      ),
      CarpenterSidebarSection(
        label: 'Actions',
        items: [
          CarpenterSidebarItem(
            id: 'search',
            label: 'Search',
            icon: CarpenterIcons.search,
            command: _searchCommand,
            onInvoke: () {},
            selectable: false,
          ),
          CarpenterSidebarItem(
            id: 'settings',
            label: 'Settings',
            icon: CarpenterIcons.edit,
            onInvoke: () {},
            selectable: false,
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => CarpenterSidebar(
    data: _data,
    expanded: widget.expanded,
    targetPlatform: widget.targetPlatform,
  );
}

final class _RootPreview extends StatefulWidget {
  const _RootPreview({this.initialOpen = false});

  final bool initialOpen;

  @override
  State<_RootPreview> createState() => _RootPreviewState();
}

final class _RootPreviewState extends State<_RootPreview> {
  late bool _open = widget.initialOpen;
  var _expanded = true;
  var _selected = 'overview';

  CarpenterSidebarData get _sidebar => CarpenterSidebarData(
    selectedId: _selected,
    onSelected: (id) => setState(() => _selected = id),
    header: const CarpenterText.title('Carpenter'),
    compactHeader: const CarpenterIcon(CarpenterIcons.tree),
    footer: const CarpenterText.caption('Albizia · workspace'),
    compactFooter: const CarpenterIcon(CarpenterIcons.info),
    sections: [
      CarpenterSidebarSection(
        label: 'Workspace',
        items: [
          CarpenterSidebarItem(
            id: 'overview',
            label: 'Overview',
            icon: CarpenterIcons.list,
            onInvoke: () {},
          ),
          CarpenterSidebarItem(
            id: 'payments',
            label: 'Payments',
            icon: CarpenterIcons.paymentCard,
            onInvoke: () {},
          ),
          CarpenterSidebarItem(
            id: 'documents',
            label: 'Documents',
            icon: CarpenterIcons.file,
            onInvoke: () {},
          ),
        ],
      ),
      CarpenterSidebarSection(
        label: 'System',
        items: [
          CarpenterSidebarItem(
            id: 'settings',
            label: 'Settings',
            icon: CarpenterIcons.edit,
            onInvoke: () {},
            selectable: false,
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => CarpenterRootLayout(
    sidebar: _sidebar,
    sidebarOpen: _open,
    onSidebarOpenChanged: (value) => setState(() => _open = value),
    sidebarExpanded: _expanded,
    onSidebarExpandedChanged: (value) => setState(() => _expanded = value),
    headerBuilder: (context, layout) => CarpenterTopPanel(
      title: 'Payments',
      subtitle: switch (layout.presentation) {
        CarpenterRootLayoutPresentation.desktop =>
          'Desktop · permanent navigation',
        CarpenterRootLayoutPresentation.tablet =>
          'Tablet · compact rail + overlay',
        CarpenterRootLayoutPresentation.mobile => 'Mobile · drawer',
      },
      leading: CarpenterIconButton(
        icon: layout.isDesktop
            ? (layout.sidebarExpanded
                  ? CarpenterIcons.chevronLeft
                  : CarpenterIcons.chevronRight)
            : CarpenterIcons.list,
        semanticLabel: layout.isDesktop
            ? 'Toggle compact navigation'
            : 'Open navigation',
        size: ControlSize.small,
        prominence: ActionProminence.ghost,
        onPressed: layout.isDesktop
            ? layout.toggleSidebarExpanded
            : layout.toggleSidebar,
      ),
      actions: [
        CarpenterButton(
          label: 'Create payment',
          size: ControlSize.small,
          prominence: ActionProminence.high,
          onPressed: () {},
        ),
      ],
    ),
    body: ColoredBox(
      color: CarpenterTheme.of(context).surface.base,
      child: Center(
        child: CarpenterCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarpenterText.title('Page content'),
              SizedBox(height: context.units(.5.rem)),
              CarpenterText.body('Selected: $_selected'),
            ],
          ),
        ),
      ),
    ),
  );
}
