import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../application/command.dart';
import '../../application/hotkey.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/interactive_region.dart';
import '../basic/icon.dart';
import '../basic/text.dart';
import '../behaviour/tooltip.dart';

@immutable
final class CarpenterSidebarItem {
  const CarpenterSidebarItem({
    required this.id,
    required this.label,
    required this.icon,
    this.command,
    this.onInvoke,
    this.semanticLabel,
    this.selectable = true,
    this.showShortcut = true,
  });

  final String id;
  final String label;
  final IconData icon;
  final CarpenterCommand<void>? command;
  final VoidCallback? onInvoke;
  final String? semanticLabel;
  final bool selectable;
  final bool showShortcut;
}

@immutable
final class CarpenterSidebarSection {
  const CarpenterSidebarSection({this.label, required this.items});

  final String? label;
  final List<CarpenterSidebarItem> items;
}

@immutable
final class CarpenterSidebarData {
  const CarpenterSidebarData({
    required this.sections,
    this.selectedId,
    this.onSelected,
    this.header,
    this.footer,
    this.semanticLabel = 'Primary navigation',
  });

  final List<CarpenterSidebarSection> sections;
  final String? selectedId;
  final ValueChanged<String>? onSelected;
  final Widget? header;
  final Widget? footer;
  final String semanticLabel;
}

/// One visual navigation component used by desktop rails and overlay drawers.
///
/// The parent layout decides whether this instance is docked or overlaid. The
/// component itself only switches between its expanded and icon-only forms.
final class CarpenterSidebar extends StatelessWidget {
  const CarpenterSidebar({
    super.key,
    required this.data,
    this.expanded = true,
    this.targetPlatform,
  });

  final CarpenterSidebarData data;
  final bool expanded;
  final TargetPlatform? targetPlatform;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final width = context.units(
      expanded
          ? theme.sizes.layoutNavigationSide
          : theme.sizes.layoutNavigationCompact,
    );
    final padding = context.units(theme.spacing.small);
    final sectionGap = context.units(theme.spacing.medium);
    final borderWidth = context.units(theme.shapes.borderWidth);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: data.semanticLabel,
      child: SizedBox(
        width: width,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface.subtle,
            border: BorderDirectional(
              end: BorderSide(color: theme.overlay.border, width: borderWidth),
            ),
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.header != null)
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: data.header!,
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: EdgeInsets.all(padding),
                    itemCount: data.sections.length,
                    separatorBuilder: (_, _) => SizedBox(height: sectionGap),
                    itemBuilder: (context, index) => _SidebarSection(
                      section: data.sections[index],
                      selectedId: data.selectedId,
                      expanded: expanded,
                      onSelected: data.onSelected,
                      targetPlatform: targetPlatform ?? defaultTargetPlatform,
                    ),
                  ),
                ),
                if (data.footer != null)
                  Padding(
                    padding: EdgeInsets.all(padding),
                    child: data.footer!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.section,
    required this.selectedId,
    required this.expanded,
    required this.onSelected,
    required this.targetPlatform,
  });

  final CarpenterSidebarSection section;
  final String? selectedId;
  final bool expanded;
  final ValueChanged<String>? onSelected;
  final TargetPlatform targetPlatform;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (expanded && section.label != null) ...[
          Padding(
            padding: EdgeInsetsDirectional.only(start: gap, end: gap),
            child: CarpenterText.caption(
              section.label!,
              colorRole: ContentColorRole.secondary,
            ),
          ),
          SizedBox(height: gap),
        ],
        for (var index = 0; index < section.items.length; index++) ...[
          _SidebarTile(
            item: section.items[index],
            selected:
                section.items[index].selectable &&
                selectedId == section.items[index].id,
            expanded: expanded,
            onSelected: onSelected,
            targetPlatform: targetPlatform,
          ),
          if (index != section.items.length - 1) SizedBox(height: gap / 2),
        ],
      ],
    );
  }
}

final class _SidebarTile extends StatelessWidget {
  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.expanded,
    required this.onSelected,
    required this.targetPlatform,
  });

  final CarpenterSidebarItem item;
  final bool selected;
  final bool expanded;
  final ValueChanged<String>? onSelected;
  final TargetPlatform targetPlatform;

  @override
  Widget build(BuildContext context) {
    final command = item.command;
    if (command == null) {
      return _buildTile(context, commandState: null);
    }
    return ValueListenableBuilder<CarpenterCommandState>(
      valueListenable: command.state,
      builder: (context, state, _) {
        if (state.visibility == CarpenterCommandVisibility.hidden) {
          return const SizedBox.shrink();
        }
        return _buildTile(context, commandState: state);
      },
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required CarpenterCommandState? commandState,
  }) {
    final theme = CarpenterTheme.of(context);
    final formatter = CarpenterHotkeyFormatter(platform: targetPlatform);
    final shortcuts = item.command?.shortcutsFor(targetPlatform) ?? const [];
    final shortcut = item.showShortcut && shortcuts.isNotEmpty
        ? formatter.formatActivator(shortcuts.first)
        : null;
    final enabled =
        (item.onInvoke != null || item.command != null || onSelected != null) &&
        (commandState?.enabled ?? true);
    final semanticLabel = item.semanticLabel ?? item.label;
    final tooltip = shortcut == null ? item.label : '${item.label}  $shortcut';
    final radius = BorderRadius.circular(
      context.units(theme.shapes.radius(ShapeRole.rounded)),
    );
    final horizontal = context.units(theme.spacing.small);
    final gap = context.units(theme.spacing.small);
    final height = theme.sizes.actionExtent(context, ControlSize.medium);
    final focusWidth = context.units(theme.focus.width);

    Widget tile = Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel,
      child: InteractiveRegion(
        onActivate: enabled ? () => _activate() : null,
        builder: (context, states, showFocusHighlight) {
          var background = selected
              ? theme.overlay.selected
              : theme.actions.transparent;
          if (states.contains(WidgetState.hovered)) {
            background = Color.alphaBlend(theme.overlay.hovered, background);
          }
          if (states.contains(WidgetState.pressed)) {
            background = Color.alphaBlend(theme.overlay.selected, background);
          }
          final disabled = states.contains(WidgetState.disabled);
          final contentRole = disabled
              ? ContentColorRole.disabled
              : ContentColorRole.primary;

          return AnimatedContainer(
            duration: theme.motion.transitionDuration(context),
            curve: theme.motion.stateCurve,
            height: height,
            padding: EdgeInsetsDirectional.symmetric(horizontal: horizontal),
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
              border: Border.all(
                color:
                    states.contains(WidgetState.focused) && showFocusHighlight
                    ? theme.focus.color
                    : theme.actions.transparent,
                width: focusWidth,
              ),
            ),
            child: Row(
              mainAxisAlignment: expanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                CarpenterIcon(
                  item.icon,
                  size: IconSize.medium,
                  colorRole: contentRole,
                ),
                if (expanded) ...[
                  SizedBox(width: gap),
                  Expanded(
                    child: CarpenterText.label(
                      item.label,
                      emphasis: selected
                          ? TypographyEmphasis.strong
                          : TypographyEmphasis.medium,
                      colorRole: contentRole,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (shortcut != null) ...[
                    SizedBox(width: gap),
                    CarpenterText.caption(
                      shortcut,
                      colorRole: disabled
                          ? ContentColorRole.disabled
                          : ContentColorRole.secondary,
                    ),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );

    if (!expanded) {
      tile = CarpenterTooltip(
        text: tooltip,
        placement: OverlayPlacement.right,
        child: tile,
      );
    }
    return tile;
  }

  void _activate() {
    if (item.selectable) onSelected?.call(item.id);
    if (item.onInvoke != null) {
      item.onInvoke!();
      return;
    }
    final command = item.command;
    if (command != null) unawaited(command.execute(null));
  }
}
