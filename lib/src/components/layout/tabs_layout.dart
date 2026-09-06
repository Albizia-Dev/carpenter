import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../collections/tabs.dart';

enum CarpenterTabsOrientation { adaptive, horizontal, vertical }

final class CarpenterLayoutTab<T> {
  const CarpenterLayoutTab({
    required this.value,
    required this.label,
    required this.builder,
    this.badge,
    this.visible = true,
    this.enabled = true,
  });
  final T value;
  final String label;
  final WidgetBuilder builder;
  final String? badge;
  final bool visible;
  final bool enabled;
}

/// Tabs layout that switches between horizontal tabs and a vertical navigation rail.
final class CarpenterTabsLayout<T> extends StatelessWidget {
  const CarpenterTabsLayout({
    super.key,
    required this.value,
    required this.tabs,
    required this.onChanged,
    this.orientation = CarpenterTabsOrientation.adaptive,
    this.verticalBreakpoint = 720,
  });

  final T value;
  final List<CarpenterLayoutTab<T>> tabs;
  final ValueChanged<T> onChanged;
  final CarpenterTabsOrientation orientation;
  final double verticalBreakpoint;

  @override
  Widget build(BuildContext context) {
    final visible = tabs.where((tab) => tab.visible).toList(growable: false);
    final selected =
        visible.where((tab) => tab.value == value).firstOrNull ??
        (visible.isEmpty ? null : visible.first);
    if (selected == null) return const SizedBox.shrink();
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    return LayoutBuilder(
      builder: (context, constraints) {
        final vertical =
            orientation == CarpenterTabsOrientation.vertical ||
            (orientation == CarpenterTabsOrientation.adaptive &&
                constraints.maxWidth >= verticalBreakpoint);
        final content = selected.builder(context);
        if (!vertical) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarpenterTabs<T>(
                value: selected.value,
                tabs: [
                  for (final tab in visible)
                    CarpenterTab(
                      value: tab.value,
                      label: _label(tab),
                      enabled: tab.enabled,
                    ),
                ],
                onChanged: onChanged,
              ),
              SizedBox(height: gap),
              Expanded(child: content),
            ],
          );
        }
        final activeStyle = theme.actions.resolve(
          ActionColorRole.utility,
          ActionProminence.normal,
          const <WidgetState>{},
        );
        final indicatorWidth =
            context.units(theme.shapes.actionBorderWidth) * 2;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: context.units(15.rem),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    end: BorderSide(
                      color: theme.surface.subtle,
                      width: context.units(theme.shapes.actionBorderWidth),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final tab in visible)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: BorderDirectional(
                            start: BorderSide(
                              color: tab.value == selected.value
                                  ? activeStyle.foreground
                                  : theme.actions.transparent,
                              width: indicatorWidth,
                            ),
                          ),
                        ),
                        child: CarpenterButton(
                          label: _label(tab),
                          colorRole: ActionColorRole.utility,
                          prominence: tab.value == selected.value
                              ? ActionProminence.low
                              : ActionProminence.ghost,
                          shape: const CarpenterShape(
                            start: ShapeRole.none,
                            end: ShapeRole.none,
                          ),
                          onInvoke: tab.enabled
                              ? () => onChanged(tab.value)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: gap),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  String _label(CarpenterLayoutTab<T> tab) =>
      tab.badge == null ? tab.label : '${tab.label} · ${tab.badge}';
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}
