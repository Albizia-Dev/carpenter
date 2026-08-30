import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/icon.dart';
import '../../basic/icons.dart';
import '../../basic/link.dart';
import '../../basic/text.dart';
import '../../behaviour/menu/dropdown.dart';
import '../../behaviour/menu/menu_entry.dart';

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

/// Hierarchical navigation path with adaptive overflow for long locations.
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
      final rtl = Directionality.of(context) == TextDirection.rtl;
      children.add(
        ExcludeSemantics(
          child: CarpenterIcon(
            rtl ? CarpenterIcons.chevronLeft : CarpenterIcons.chevronRight,
            size: IconSize.xsmall,
            colorRole: ContentColorRole.muted,
          ),
        ),
      );
    }

    void appendItem(CarpenterBreadcrumb item, {required bool current}) {
      appendSeparator();
      if (current || item.onInvoke == null) {
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
        CarpenterLink(
          label: item.label,
          semanticLabel: item.semanticLabel,
          onInvoke: item.onInvoke,
        ),
      );
    }

    if (hasOverflow) {
      appendItem(widget.items.first, current: false);
      appendSeparator();
      final hidden = widget.items.sublist(1, tailStart);
      children.add(
        CarpenterDropdown.icon(
          open: _overflowOpen,
          onOpenChanged: (value) => setState(() => _overflowOpen = value),
          label: 'More path items',
          semanticLabel: 'More breadcrumb items',
          icon: CarpenterIcons.more,
          size: ControlSize.xsmall,
          prominence: ActionProminence.ghost,
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
