import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/anchored_overlay_host.dart';
import '../basic/text.dart';
import '../behaviour/control.dart';
import '../behaviour/menu/menu.dart';
import '../behaviour/menu/menu_entry.dart';

@immutable
final class CarpenterBreadcrumb {
  const CarpenterBreadcrumb({
    required this.label,
    this.onInvoke,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback? onInvoke;
  final String? semanticLabel;
}

/// Hierarchical navigation path with compact text presentation and adaptive overflow.
final class CarpenterBreadcrumbs extends StatefulWidget {
  const CarpenterBreadcrumbs({
    super.key,
    required this.items,
    this.maxVisibleItems = 4,
    this.semanticLabel = 'Breadcrumbs',
  }) : assert(maxVisibleItems >= 2);

  final List<CarpenterBreadcrumb> items;
  final int maxVisibleItems;
  final String semanticLabel;

  @override
  State<CarpenterBreadcrumbs> createState() => _CarpenterBreadcrumbsState();
}

final class _CarpenterBreadcrumbsState extends State<CarpenterBreadcrumbs> {
  bool _overflowOpen = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small) / 2;
    final count = widget.items.length;
    final hasOverflow = count > widget.maxVisibleItems;
    final tailCount = hasOverflow ? widget.maxVisibleItems - 1 : count - 1;
    final tailStart = count - tailCount;
    final children = <Widget>[];

    void appendSeparator() {
      if (children.isEmpty) return;
      children.add(
        const ExcludeSemantics(
          child: CarpenterText.body('›', colorRole: ContentColorRole.muted),
        ),
      );
    }

    void appendItem(CarpenterBreadcrumb item, {required bool current}) {
      appendSeparator();
      final onInvoke = item.onInvoke;
      if (current || onInvoke == null) {
        children.add(
          CarpenterText.body(
            item.label,
            emphasis: current
                ? TypographyEmphasis.medium
                : TypographyEmphasis.regular,
            colorRole: current
                ? ContentColorRole.primary
                : ContentColorRole.secondary,
          ),
        );
        return;
      }
      children.add(
        _BreadcrumbLink(
          label: item.label,
          semanticLabel: item.semanticLabel,
          onInvoke: onInvoke,
        ),
      );
    }

    if (hasOverflow) {
      appendItem(widget.items.first, current: false);
      appendSeparator();
      final hidden = widget.items.sublist(1, tailStart);
      children.add(
        AnchoredOverlayHost(
          open: _overflowOpen,
          onOpenChanged: (value) => setState(() => _overflowOpen = value),
          placement: OverlayPlacement.bottomStart,
          fallbackPlacements: const [OverlayPlacement.bottomEnd],
          anchor: _BreadcrumbLink(
            label: '…',
            semanticLabel: 'More breadcrumb items',
            onInvoke: () => setState(() => _overflowOpen = !_overflowOpen),
          ),
          overlayBuilder: (context) => CarpenterMenu(
            semanticLabel: 'More breadcrumb items',
            onDismissRequested: () => setState(() => _overflowOpen = false),
            items: [
              for (var index = 0; index < hidden.length; index++)
                CarpenterMenuItem(
                  action: CarpenterActionDescriptor(
                    id: 'breadcrumb.overflow.$index',
                    label: hidden[index].label,
                    semanticLabel: hidden[index].semanticLabel,
                    onInvoke: hidden[index].onInvoke == null
                        ? null
                        : () {
                            setState(() => _overflowOpen = false);
                            hidden[index].onInvoke!();
                          },
                  ),
                ),
            ],
          ),
        ),
      );
    }

    for (var index = tailStart; index < count; index++) {
      appendItem(widget.items[index], current: index == count - 1);
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: Wrap(
        spacing: gap,
        runSpacing: gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: children,
      ),
    );
  }
}

final class _BreadcrumbLink extends StatelessWidget {
  const _BreadcrumbLink({
    required this.label,
    required this.onInvoke,
    this.semanticLabel,
  });

  final String label;
  final VoidCallback onInvoke;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: false,
    excludeSemantics: true,
    link: true,
    enabled: true,
    label: semanticLabel ?? label,
    onTap: onInvoke,
    child: CarpenterControl(
      onTap: onInvoke,
      semanticButton: false,
      builder: (context, state) => CarpenterText.body(
        label,
        emphasis: state.hovered || state.focused
            ? TypographyEmphasis.medium
            : TypographyEmphasis.regular,
        colorRole: state.hovered || state.focused
            ? ContentColorRole.primary
            : ContentColorRole.secondary,
      ),
    ),
  );
}
