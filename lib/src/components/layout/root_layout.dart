import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/theme.dart';
import 'sidebar.dart';
import '../../internal/overlay/overlay_lifecycle_host.dart';
import '../basic/button/icon_button.dart';
import '../basic/gravity_icons.g.dart';
import '../basic/text.dart';
import '../../foundation/roles.dart';

enum CarpenterRootLayoutPresentation { desktop, tablet, mobile }

@immutable
final class CarpenterRootLayoutContext {
  const CarpenterRootLayoutContext({
    required this.presentation,
    required this.sidebarExpanded,
    required this.sidebarOpen,
    required this.toggleSidebar,
    required this.toggleSidebarExpanded,
  });

  final CarpenterRootLayoutPresentation presentation;
  final bool sidebarExpanded;
  final bool sidebarOpen;
  final VoidCallback toggleSidebar;
  final VoidCallback toggleSidebarExpanded;

  bool get isDesktop => presentation == CarpenterRootLayoutPresentation.desktop;
  bool get isTablet => presentation == CarpenterRootLayoutPresentation.tablet;
  bool get isMobile => presentation == CarpenterRootLayoutPresentation.mobile;
}

typedef CarpenterRootHeaderBuilder =
    Widget Function(BuildContext context, CarpenterRootLayoutContext layout);

/// Root application composition: navigation + (header + page content).
///
/// Desktop uses a permanently docked sidebar. Tablet keeps an icon rail docked
/// while the expanded sidebar overlays content. Mobile reserves no navigation
/// width and uses the expanded sidebar as a drawer.
final class CarpenterRootLayout extends StatelessWidget {
  /// Composes the application navigation and content; navigation defaults are Russian.
  /// Creates an adaptive root; [sidebarVisible] only reserves docked space.
  /// The temporary drawer stays controlled by [sidebarOpen] on narrow hosts.
  const CarpenterRootLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.headerBuilder,
    this.sidebarExpanded = true,
    this.sidebarVisible = true,
    this.onSidebarExpandedChanged,
    this.sidebarOpen = false,
    this.onSidebarOpenChanged,
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.closeOverlayOnSelection = true,
    this.semanticLabel = 'Приложение',
  });

  final CarpenterSidebarData sidebar;
  final Widget body;
  final CarpenterRootHeaderBuilder? headerBuilder;

  /// Whether desktop reserves navigation space. Compact viewports still offer
  /// the caller-controlled drawer. This never unmounts [body].
  final bool sidebarVisible;
  final bool sidebarExpanded;
  final ValueChanged<bool>? onSidebarExpandedChanged;
  final bool sidebarOpen;
  final ValueChanged<bool>? onSidebarOpenChanged;
  final CarpenterViewportPolicy viewportPolicy;
  final bool closeOverlayOnSelection;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final viewport = viewportPolicy.resolve(context, constraints.maxWidth);
      final presentation = switch (viewport) {
        CarpenterViewportClass.wide => CarpenterRootLayoutPresentation.desktop,
        CarpenterViewportClass.medium => CarpenterRootLayoutPresentation.tablet,
        CarpenterViewportClass.narrow => CarpenterRootLayoutPresentation.mobile,
      };
      final overlayOpen =
          presentation != CarpenterRootLayoutPresentation.desktop &&
          sidebarOpen;
      final layoutContext = CarpenterRootLayoutContext(
        presentation: presentation,
        sidebarExpanded: sidebarExpanded,
        sidebarOpen: overlayOpen,
        toggleSidebar: () => onSidebarOpenChanged?.call(!overlayOpen),
        toggleSidebarExpanded: () =>
            onSidebarExpandedChanged?.call(!sidebarExpanded),
      );
      final rightRegion = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (headerBuilder case final CarpenterRootHeaderBuilder builder)
            builder(context, layoutContext),
          Expanded(child: body),
        ],
      );

      final docked =
          presentation != CarpenterRootLayoutPresentation.mobile &&
          sidebarVisible;
      final expanded =
          presentation == CarpenterRootLayoutPresentation.desktop &&
          sidebarExpanded;
      final base = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (docked)
            CarpenterSidebar(
              key: const ValueKey('docked-navigation'),
              data: _effectiveSidebar(closeOnSelection: false),
              expanded: expanded,
            ),
          Expanded(key: const ValueKey('primary-region'), child: rightRegion),
        ],
      );
      final layered = Overlay.wrap(
        child: OverlayLifecycleHost(
          open: overlayOpen,
          onOpenChanged: (open) => onSidebarOpenChanged?.call(open),
          modal: true,
          trapFocus: true,
          scrimColor: theme.overlay.scrim,
          overlayBuilder: (context, info, dismiss) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: context
                  .units(theme.sizes.layoutNavigationSide)
                  .clamp(0, info.overlaySize.width),
              height: info.overlaySize.height,
              child: Semantics(
                scopesRoute: true,
                explicitChildNodes: true,
                namesRoute: true,
                label: sidebar.semanticLabel,
                child: ColoredBox(
                  color: theme.surface.subtle,
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(
                          context.units(theme.spacing.small),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: CarpenterText.label(sidebar.semanticLabel),
                            ),
                            CarpenterIconButton(
                              icon: GravityIcons.xmark,
                              semanticLabel: 'Закрыть навигацию',
                              prominence: ActionProminence.ghost,
                              onPressed: dismiss,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: CarpenterSidebar(
                          data: _effectiveSidebar(
                            closeOnSelection: closeOverlayOnSelection,
                          ),
                          expanded: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: base,
        ),
      );

      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: ColoredBox(color: theme.surface.base, child: layered),
      );
    },
  );

  CarpenterSidebarData _effectiveSidebar({required bool closeOnSelection}) =>
      CarpenterSidebarData(
        sections: sidebar.sections,
        selectedId: sidebar.selectedId,
        header: sidebar.header,
        compactHeader: sidebar.compactHeader,
        footer: sidebar.footer,
        compactFooter: sidebar.compactFooter,
        semanticLabel: sidebar.semanticLabel,
        onSelected: (id) {
          sidebar.onSelected?.call(id);
          if (closeOnSelection) _closeOverlay();
        },
      );

  void _closeOverlay() => onSidebarOpenChanged?.call(false);
}
