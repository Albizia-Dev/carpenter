import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/theme.dart';
import 'sidebar.dart';

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

typedef CarpenterRootHeaderBuilder = Widget Function(
  BuildContext context,
  CarpenterRootLayoutContext layout,
);

/// Root application composition: navigation + (header + page content).
///
/// Desktop uses a permanently docked sidebar. Tablet keeps an icon rail docked
/// while the expanded sidebar overlays content. Mobile reserves no navigation
/// width and uses the expanded sidebar as a drawer.
final class CarpenterRootLayout extends StatelessWidget {
  const CarpenterRootLayout({
    super.key,
    required this.sidebar,
    required this.body,
    this.headerBuilder,
    this.sidebarExpanded = true,
    this.onSidebarExpandedChanged,
    this.sidebarOpen = false,
    this.onSidebarOpenChanged,
    this.viewportPolicy = const CarpenterViewportPolicy(),
    this.closeOverlayOnSelection = true,
    this.semanticLabel = 'Application',
  });

  final CarpenterSidebarData sidebar;
  final Widget body;
  final CarpenterRootHeaderBuilder? headerBuilder;
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

      Widget base = switch (presentation) {
        CarpenterRootLayoutPresentation.desktop => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterSidebar(
              data: _effectiveSidebar(closeOnSelection: false),
              expanded: sidebarExpanded,
            ),
            Expanded(child: rightRegion),
          ],
        ),
        CarpenterRootLayoutPresentation.tablet => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterSidebar(
              data: _effectiveSidebar(closeOnSelection: false),
              expanded: false,
            ),
            Expanded(child: rightRegion),
          ],
        ),
        CarpenterRootLayoutPresentation.mobile => rightRegion,
      };

      if (overlayOpen) {
        base = CallbackShortcuts(
          bindings: <ShortcutActivator, VoidCallback>{
            const SingleActivator(LogicalKeyboardKey.escape): _closeOverlay,
          },
          child: Focus(
            autofocus: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                base,
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeOverlay,
                  child: ColoredBox(color: theme.overlay.scrim),
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
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
        );
      }

      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: ColoredBox(color: theme.surface.base, child: base),
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
