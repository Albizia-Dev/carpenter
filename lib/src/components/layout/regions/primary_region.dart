import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/adaptive.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/layout/semantic_region.dart';
import 'region_role.dart';

final class CarpenterPrimaryRegion extends StatelessWidget {
  const CarpenterPrimaryRegion({
    super.key,
    required this.child,
    this.scrollOwnership = CarpenterRegionScrollOwnership.child,
    this.scrollController,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final Widget child;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final ScrollController? scrollController;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => SemanticRegion(
    role: CarpenterRegionRole.primary,
    scrollOwnership: scrollOwnership,
    scrollController: scrollController,
    focusNode: focusNode,
    autofocus: autofocus,
    semanticLabel: semanticLabel,
    child: child,
  );
}

/// Controls whether the page header participates in the page scroll flow.
enum CarpenterPageHeaderBehavior {
  /// Header stays at the top while the page body scrolls.
  sticky,

  /// Header is part of the document and scrolls away with the content.
  scrolls,
}

/// Owns page anatomy and optionally its single vertical scroll viewport.
///
/// Collection renderers such as [CarpenterTable] should normally use
/// [CarpenterRegionScrollOwnership.child]. Ordinary document or form content
/// can use [CarpenterRegionScrollOwnership.region].
final class CarpenterPageRegion extends StatelessWidget {
  const CarpenterPageRegion({
    super.key,
    required this.header,
    required this.body,
    this.toolbar,
    this.scrollOwnership = CarpenterRegionScrollOwnership.child,
    this.headerBehavior = CarpenterPageHeaderBehavior.sticky,
    this.scrollController,
    this.shortcutActions = const [],
    this.semanticLabel = 'Page',
  }) : assert(
         headerBehavior != CarpenterPageHeaderBehavior.scrolls ||
             scrollOwnership == CarpenterRegionScrollOwnership.region,
         'A scrolling page header requires the page region to own scrolling.',
       );

  final Widget header;
  final Widget body;
  final Widget? toolbar;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final CarpenterPageHeaderBehavior headerBehavior;
  final ScrollController? scrollController;
  final List<CarpenterActionDescriptor> shortcutActions;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final shortcuts = <ShortcutActivator, Intent>{};
    for (final action in shortcutActions) {
      final shortcut = action.shortcut;
      if (shortcut == null || !action.isEnabled) continue;
      shortcuts[shortcut] = VoidCallbackIntent(action.onInvoke!);
    }
    Widget result = _PageRegionLayout(
      header: header,
      toolbar: toolbar,
      body: body,
      scrollOwnership: scrollOwnership,
      headerBehavior: headerBehavior,
      scrollController: scrollController,
    );
    if (shortcuts.isNotEmpty) {
      result = Shortcuts(
        shortcuts: shortcuts,
        child: Actions(
          actions: <Type, Action<Intent>>{
            VoidCallbackIntent: VoidCallbackAction(),
          },
          child: result,
        ),
      );
    }
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: result,
    );
  }
}

final class _PageRegionLayout extends StatelessWidget {
  const _PageRegionLayout({
    required this.header,
    required this.toolbar,
    required this.body,
    required this.scrollOwnership,
    required this.headerBehavior,
    required this.scrollController,
  });

  final Widget header;
  final Widget? toolbar;
  final Widget body;
  final CarpenterRegionScrollOwnership scrollOwnership;
  final CarpenterPageHeaderBehavior headerBehavior;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, outerConstraints) {
      final theme = CarpenterTheme.of(context);
      final viewport = const CarpenterViewportPolicy().resolve(
        context,
        outerConstraints.maxWidth,
      );
      final inset = context.units(
        viewport == CarpenterViewportClass.narrow
            ? theme.spacing.layoutPageCompact
            : theme.spacing.layoutPage,
      );
      final gap = context.units(theme.spacing.layoutSection);

      Widget scrollingContent({required bool includeHeader}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (includeHeader) ...[header, SizedBox(height: gap)],
          if (toolbar != null) ...[toolbar!, SizedBox(height: gap)],
          body,
        ],
      );

      Widget childOwnedContent({required bool bounded}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          header,
          if (toolbar != null) ...[SizedBox(height: gap), toolbar!],
          SizedBox(height: gap),
          if (bounded) Expanded(child: body) else body,
        ],
      );

      return ColoredBox(
        color: theme.surface.base,
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Align(
            alignment: AlignmentDirectional.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.units(theme.sizes.layoutPageMaxWidth),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (scrollOwnership == CarpenterRegionScrollOwnership.child) {
                    return childOwnedContent(
                      bounded: constraints.maxHeight.isFinite,
                    );
                  }

                  if (headerBehavior == CarpenterPageHeaderBehavior.scrolls) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: scrollingContent(includeHeader: true),
                    );
                  }

                  final scrollView = SingleChildScrollView(
                    controller: scrollController,
                    child: scrollingContent(includeHeader: false),
                  );
                  if (!constraints.maxHeight.isFinite) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        header,
                        SizedBox(height: gap),
                        scrollView,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      header,
                      SizedBox(height: gap),
                      Expanded(child: scrollView),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );
}
