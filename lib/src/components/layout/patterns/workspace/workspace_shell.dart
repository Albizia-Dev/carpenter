import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/adaptive.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import '../../../behaviour/control.dart';
import '../../../collections/breadcrumbs.dart';
import '../../app_frame.dart';
import '../../root_layout.dart';
import '../../sidebar.dart';

/// Contextual application chrome: workspace navigation beside header and page.
///
/// The application supplies only the current workspace's [navigation]. It owns
/// routing, permissions, persistence, search, unread counts and all operations.
/// [onWorkspacePressed] opens an application-owned catalogue; [searchAction]
/// opens a palette without implying a business-data search backend.
///
/// Desktop can collapse or hide its navigation. Tablet keeps a rail and opens
/// a modal drawer; mobile keeps the entire page width. Drawer dismissal consumes
/// Escape and restores focus without unmounting [body]. Larger text influences
/// the default viewport policy. [actions] remain accessible on every width,
/// wrapping below the location when they cannot fit beside it.
///
/// This additive, experimental composition does not replace
/// `CarpenterApplicationShell` or change application routes.
final class CarpenterWorkspaceShell extends StatelessWidget {
  /// Creates a caller-controlled workspace. Labels default to Russian;
  /// optional slots are absent until the caller supplies real state.
  const CarpenterWorkspaceShell({
    super.key,
    required this.applicationLabel,
    required this.workspaceLabel,
    required this.navigation,
    required this.body,
    required this.onWorkspacePressed,
    this.workspaceCaption = 'Все разделы',
    this.workspaceIcon = GravityIcons.layoutCells,
    this.breadcrumbs = const [],
    this.searchAction,
    this.actions = const [],
    this.activity,
    this.notice,
    this.footer,
    this.nativeTitleBar,
    this.sidebarExpanded = true,
    this.onSidebarExpandedChanged,
    this.sidebarOpen = false,
    this.onSidebarOpenChanged,
    this.sidebarVisible = true,
    this.onSidebarVisibleChanged,
    this.viewportPolicy = const CarpenterViewportPolicy(
      accountForTextScale: true,
    ),
  });

  /// Product name in expanded navigation; does not navigate on activation.
  final String applicationLabel;

  /// Human-readable current workspace, independent from version and route IDs.
  final String workspaceLabel;

  /// Supporting text explaining the workspace switcher's action.
  final String workspaceCaption;

  /// Semantic icon for the current workspace; uses the standard icon facade.
  final Object workspaceIcon;

  /// Current workspace's items, selection, optional footer and pinned sections.
  /// Header slots are composed below the workspace switcher when supplied.
  final CarpenterSidebarData navigation;

  /// Stable page region. Loading and errors belong inside this caller-owned slot.
  final Widget body;

  /// Opens the caller's workspace catalogue; null disables the switcher.
  final VoidCallback? onWorkspacePressed;

  /// Hierarchical current location. Ancestor callbacks are application-owned.
  final List<CarpenterBreadcrumb> breadcrumbs;

  /// Shared search trigger, including its actual platform shortcut if supplied.
  /// This shell binds the shortcut to the same enabled action it renders.
  final CarpenterActionDescriptor? searchAction;

  /// Global actions such as inbox and profile. These wrap instead of disappearing.
  final List<Widget> actions;

  /// Ongoing activity, such as a call; remains outside the scrolling page.
  final Widget? activity;

  /// Current connection or update notice; no status is inferred by the shell.
  final Widget? notice;

  /// Optional page-wide status footer, separate from navigation's footer.
  final Widget? footer;

  /// Optional host-owned title bar above all regions. Web hosts omit this slot.
  final Widget? nativeTitleBar;

  /// Desktop expanded-versus-rail preference. Defaults to expanded.
  final bool sidebarExpanded;

  /// Proposes a new desktop preference; callers persist it when appropriate.
  final ValueChanged<bool>? onSidebarExpandedChanged;

  /// Controlled temporary drawer visibility on tablet and mobile.
  final bool sidebarOpen;

  /// Receives opening, dismissal and navigation-selection visibility requests.
  final ValueChanged<bool>? onSidebarOpenChanged;

  /// Whether desktop reserves navigation space. Mobile still has a menu button.
  final bool sidebarVisible;

  /// Restores navigation from concentration mode; callers own persistence.
  final ValueChanged<bool>? onSidebarVisibleChanged;

  /// Available-room policy, accounting for enlarged text by default.
  final CarpenterViewportPolicy viewportPolicy;

  /// Composes theme-scaled navigation and chrome around the stable page slot.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    Widget heading(bool compact) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact) ...[
          CarpenterText.title(applicationLabel),
          SizedBox(height: gap),
          CarpenterControl(
            semanticLabel: '$workspaceLabel. $workspaceCaption',
            onTap: onWorkspacePressed,
            builder: (context, state) => DecoratedBox(
              decoration: BoxDecoration(
                color: state.hovered || state.focused
                    ? theme.overlay.hovered
                    : theme.surface.base,
                border: Border.all(
                  color: state.focused
                      ? theme.focus.color
                      : theme.overlay.border,
                  width: context.units(theme.focus.width),
                ),
                borderRadius: BorderRadius.circular(
                  context.units(theme.shapes.radius(ShapeRole.rounded)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: Row(
                  children: [
                    CarpenterIcon(workspaceIcon),
                    SizedBox(width: gap),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CarpenterText.label(workspaceLabel, maxLines: 2),
                          CarpenterText.caption(
                            workspaceCaption,
                            colorRole: ContentColorRole.secondary,
                          ),
                        ],
                      ),
                    ),
                    const CarpenterIcon(GravityIcons.chevronsExpandVertical),
                  ],
                ),
              ),
            ),
          ),
        ] else
          CarpenterIconButton(
            icon: workspaceIcon,
            semanticLabel: '$workspaceLabel. $workspaceCaption',
            onPressed: onWorkspacePressed,
            prominence: ActionProminence.ghost,
          ),
        if ((compact ? navigation.compactHeader : navigation.header)
            case final Widget header) ...[
          SizedBox(height: gap),
          header,
        ],
      ],
    );
    final sidebar = CarpenterSidebarData(
      sections: navigation.sections,
      selectedId: navigation.selectedId,
      onSelected: navigation.onSelected,
      semanticLabel: navigation.semanticLabel,
      header: heading(false),
      compactHeader: heading(true),
      footer: navigation.footer,
      compactFooter: navigation.compactFooter,
    );
    final root = CarpenterRootLayout(
      sidebar: sidebar,
      sidebarExpanded: sidebarExpanded,
      onSidebarExpandedChanged: onSidebarExpandedChanged,
      sidebarVisible: sidebarVisible,
      sidebarOpen: sidebarOpen,
      onSidebarOpenChanged: onSidebarOpenChanged,
      viewportPolicy: viewportPolicy,
      headerBuilder: _header,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?notice,
          ?activity,
          Expanded(key: const ValueKey('workspace-body'), child: body),
          ?footer,
        ],
      ),
    );
    return CallbackShortcuts(
      bindings: {
        if (searchAction?.shortcut != null && searchAction!.isEnabled)
          searchAction!.shortcut!: searchAction!.onInvoke!,
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?nativeTitleBar,
          Expanded(key: const ValueKey('workspace-root'), child: root),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, CarpenterRootLayoutContext layout) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final menu = CarpenterIconButton(
      icon: sidebarVisible && layout.isDesktop && sidebarExpanded
          ? GravityIcons.chevronLeft
          : GravityIcons.bars,
      semanticLabel: !layout.isDesktop
          ? 'Открыть навигацию'
          : !sidebarVisible
          ? 'Показать навигацию'
          : sidebarExpanded
          ? 'Свернуть навигацию'
          : 'Развернуть навигацию',
      prominence: ActionProminence.ghost,
      onPressed: !layout.isDesktop
          ? layout.toggleSidebar
          : !sidebarVisible
          ? () => onSidebarVisibleChanged?.call(true)
          : layout.toggleSidebarExpanded,
    );
    final location = layout.isMobile || breadcrumbs.isEmpty
        ? CarpenterText.label(
            workspaceLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : CarpenterBreadcrumbs(items: breadcrumbs);
    final controls = <Widget>[
      if (searchAction case final action?)
        layout.isDesktop
            ? CarpenterButton.fromAction(
                action,
                prominence: ActionProminence.outlined,
              )
            : CarpenterIconButton.fromAction(
                action,
                prominence: ActionProminence.ghost,
              ),
      ...actions,
    ];
    return CarpenterTopPanel(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final reserve =
              theme.sizes.actionExtent(context, ControlSize.medium) *
              (controls.length + 3);
          final stacked = constraints.maxWidth < reserve;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  menu,
                  SizedBox(width: gap),
                  Expanded(child: location),
                  if (!stacked) ...[SizedBox(width: gap), ...controls],
                ],
              ),
              if (stacked) ...[
                SizedBox(height: gap),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: gap,
                  runSpacing: gap,
                  children: controls,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
