import 'dart:math' as math;

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

/// Single-line hierarchical navigation with width-aware middle overflow.
///
/// The current item is always present. Earlier ancestors collapse into an
/// accessible menu before the first and current labels are ellipsized. Full
/// labels remain available to assistive technology. [maxVisibleItems] limits
/// labelled items, not the additional overflow button.
///
/// The preferred width is intrinsic-safe, including inside a page header. The
/// component never wraps or requires a caller-owned horizontal scroll view.
final class CarpenterBreadcrumbs extends StatefulWidget {
  /// Creates a single-line breadcrumb path from ordered [items].
  const CarpenterBreadcrumbs({
    super.key,
    required this.items,
    this.maxVisibleItems = 4,
    this.semanticLabel = 'Breadcrumbs',
    this.overflowLabel = 'More breadcrumb items',
  }) : assert(maxVisibleItems >= 2);

  final List<CarpenterBreadcrumb> items;
  final int maxVisibleItems;
  final String semanticLabel;

  /// Accessible label for the ancestor menu and its trigger.
  final String overflowLabel;

  @override
  State<CarpenterBreadcrumbs> createState() => _CarpenterBreadcrumbsState();
}

final class _CarpenterBreadcrumbsState extends State<CarpenterBreadcrumbs> {
  bool _overflowOpen = false;

  @override
  void didUpdateWidget(CarpenterBreadcrumbs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) _overflowOpen = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final theme = CarpenterTheme.of(context);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final regular = theme.typography.resolve(
      context,
      TypographyRole.body,
      TypographyEmphasis.regular,
    );
    final medium = theme.typography.resolve(
      context,
      TypographyRole.body,
      TypographyEmphasis.medium,
    );

    double measure(String text, TextStyle style) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: direction,
        textScaler: scaler,
        locale: Localizations.maybeLocaleOf(context),
        maxLines: 1,
      )..layout();
      final width = painter.width.ceilToDouble();
      painter.dispose();
      return width;
    }

    final widths = [
      for (final item in widget.items)
        math.max(measure(item.label, regular), measure(item.label, medium)),
    ];
    final gap = context.units(theme.spacing.small) / 2;
    final separatorWidth = measure('\u203a', regular);
    final overflowWidth = measure('\u2026', medium);
    final initial = <int>[for (var i = 0; i < widths.length; i++) i];
    while (initial.length > widget.maxVisibleItems) {
      initial.removeAt(1);
    }
    double requiredWidth(List<int> indices) {
      final hidden = indices.length < widths.length;
      final entries = indices.length + (hidden ? 1 : 0);
      return indices.fold<double>(0, (sum, i) => sum + widths[i]) +
          (hidden ? overflowWidth : 0) +
          math.max(0, entries - 1) * (separatorWidth + gap * 2);
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      explicitChildNodes: true,
      child: SizedBox(
        width: requiredWidth(initial),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final available = constraints.maxWidth;
            final visible = [...initial];
            while (visible.length > 2 && requiredWidth(visible) > available) {
              visible.removeAt(1);
            }
            if (visible.length > 1 &&
                available < overflowWidth + 2 * (separatorWidth + gap * 2)) {
              visible.removeAt(0);
            }
            final visibleSet = visible.toSet();
            final hidden = [
              for (var i = 0; i < widget.items.length; i++)
                if (!visibleSet.contains(i)) widget.items[i],
            ];
            final entries = <int?>[
              if (visible.first == 0) visible.first,
              if (hidden.isNotEmpty) null,
              ...visible.skip(visible.first == 0 ? 1 : 0),
            ];
            final count = entries.length;
            final naturalSeparator = separatorWidth + gap * 2;
            final separator = count > 1
                ? math.min(naturalSeparator, available / (count * 3))
                : 0.0;
            var budget = math.max(0.0, available - separator * (count - 1));
            final overflow = hidden.isEmpty
                ? 0.0
                : math.min(overflowWidth, budget / 2);
            budget -= overflow;
            final naturalLabels = visible.fold<double>(
              0,
              (sum, i) => sum + widths[i],
            );
            final labelWidths = <int, double>{};
            if (naturalLabels <= budget) {
              for (final index in visible) {
                labelWidths[index] = widths[index];
              }
            } else if (visible.length == 1) {
              labelWidths[visible.single] = budget;
            } else {
              final current = visible.last;
              final reserve = math.min(widths[current], budget * 2 / 3);
              final first = math.min(widths[visible.first], budget - reserve);
              labelWidths[visible.first] = first;
              labelWidths[current] = budget - first;
            }

            final children = <Widget>[];
            for (var position = 0; position < entries.length; position++) {
              if (position > 0) {
                children.add(
                  SizedBox(
                    width: separator,
                    child: const ExcludeSemantics(
                      child: CarpenterText.body(
                        '\u203a',
                        colorRole: ContentColorRole.muted,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }
              final index = entries[position];
              if (index == null) {
                children.add(
                  SizedBox(width: overflow, child: _overflow(hidden)),
                );
              } else {
                final item = widget.items[index];
                final current = index == widget.items.length - 1;
                children.add(
                  SizedBox(
                    key: ValueKey('breadcrumb.$index'),
                    width: labelWidths[index],
                    child: current || item.onInvoke == null
                        ? CarpenterText.body(
                            item.label,
                            semanticsLabel: item.semanticLabel ?? item.label,
                            emphasis: current
                                ? TypographyEmphasis.medium
                                : TypographyEmphasis.regular,
                            colorRole: current
                                ? ContentColorRole.primary
                                : ContentColorRole.secondary,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          )
                        : _BreadcrumbLink(
                            label: item.label,
                            semanticLabel: item.semanticLabel,
                            onInvoke: item.onInvoke!,
                          ),
                  ),
                );
              }
            }
            return Row(mainAxisSize: MainAxisSize.min, children: children);
          },
        ),
      ),
    );
  }

  Widget _overflow(List<CarpenterBreadcrumb> hidden) => AnchoredOverlayHost(
    open: _overflowOpen,
    onOpenChanged: (value) => setState(() => _overflowOpen = value),
    placement: OverlayPlacement.bottomStart,
    fallbackPlacements: const [OverlayPlacement.bottomEnd],
    anchor: _BreadcrumbLink(
      label: '\u2026',
      semanticLabel: widget.overflowLabel,
      onInvoke: () => setState(() => _overflowOpen = !_overflowOpen),
    ),
    overlayBuilder: (context) => CarpenterMenu(
      semanticLabel: widget.overflowLabel,
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
  );
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
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
