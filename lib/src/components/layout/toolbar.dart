import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/button/icon_button.dart';
import '../basic/icons.dart';
import '../behaviour/menu/dropdown.dart';
import '../behaviour/menu/menu_entry.dart';
import 'action_overflow.dart';

enum CarpenterToolbarPriority { critical, normal, overflow }

enum CarpenterToolbarGroup { primary, secondary, overflow }

enum CarpenterToolbarPresentation { label, icon }

@immutable
final class CarpenterToolbarItem {
  const CarpenterToolbarItem({
    required this.action,
    this.group = CarpenterToolbarGroup.secondary,
    @Deprecated('Use group instead. Priority is retained for compatibility.')
    CarpenterToolbarPriority? priority,
    this.presentation = CarpenterToolbarPresentation.label,
    this.prominence = ActionProminence.ghost,
    this.size = ControlSize.medium,
    this.executionPhase = ActionExecutionPhase.idle,
  }) : _priority = priority;

  final CarpenterActionDescriptor action;
  final CarpenterToolbarGroup group;
  final CarpenterToolbarPriority? _priority;
  final CarpenterToolbarPresentation presentation;
  final ActionProminence prominence;
  final ControlSize size;
  final ActionExecutionPhase executionPhase;

  @Deprecated('Use group instead. Priority is retained for compatibility.')
  CarpenterToolbarPriority get priority =>
      _priority ??
      switch (group) {
        CarpenterToolbarGroup.primary => CarpenterToolbarPriority.critical,
        CarpenterToolbarGroup.secondary => CarpenterToolbarPriority.normal,
        CarpenterToolbarGroup.overflow => CarpenterToolbarPriority.overflow,
      };

  CarpenterToolbarGroup get effectiveGroup => switch (_priority) {
    CarpenterToolbarPriority.critical => CarpenterToolbarGroup.primary,
    CarpenterToolbarPriority.normal => CarpenterToolbarGroup.secondary,
    CarpenterToolbarPriority.overflow => CarpenterToolbarGroup.overflow,
    null => group,
  };
}

final class CarpenterToolbar extends StatefulWidget {
  const CarpenterToolbar({
    super.key,
    required this.items,
    this.alignment = AlignmentDirectional.centerEnd,
    this.overflowLabel = 'More actions',
    this.semanticLabel = 'Toolbar',
  });

  final List<CarpenterToolbarItem> items;
  final AlignmentGeometry alignment;
  final String overflowLabel;
  final String semanticLabel;

  @override
  State<CarpenterToolbar> createState() => _CarpenterToolbarState();
}

final class _CarpenterToolbarState extends State<CarpenterToolbar> {
  bool _overflowOpen = false;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = _layoutItems(context, constraints.maxWidth);
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: widget.semanticLabel,
        child: Align(
          alignment: widget.alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < layout.visible.length; index++) ...[
                if (index > 0) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: _ToolbarAction(
                    item: layout.visible[index],
                    forceIcon: layout.iconOnly,
                  ),
                ),
              ],
              if (layout.overflow.isNotEmpty) ...[
                if (layout.visible.isNotEmpty) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: CarpenterDropdown.icon(
                    open: _overflowOpen,
                    onOpenChanged: (value) =>
                        setState(() => _overflowOpen = value),
                    icon: CarpenterIcons.more,
                    label: widget.overflowLabel,
                    items: [
                      for (final item in layout.overflow)
                        CarpenterMenuItem(action: item.action),
                    ],
                    prominence: ActionProminence.ghost,
                    size: ControlSize.medium,
                    semanticLabel: widget.overflowLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _gap(BuildContext context) => SizedBox(
    width: context.units(CarpenterTheme.of(context).spacing.layoutToolbar),
  );

  _ToolbarLayout _layoutItems(BuildContext context, double availableWidth) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutToolbar);
    final overflowWidth = context.units(
      theme.sizes.actionHeight(ControlSize.medium),
    );
    final entries = [
      for (final item in widget.items)
        ActionOverflowEntry(
          value: item,
          group: switch (item.effectiveGroup) {
            CarpenterToolbarGroup.primary => ActionOverflowGroup.primary,
            CarpenterToolbarGroup.secondary => ActionOverflowGroup.secondary,
            CarpenterToolbarGroup.overflow => ActionOverflowGroup.overflow,
          },
          expandedWidth: _itemWidth(context, item),
          iconWidth: item.action.icon == null
              ? null
              : context.units(theme.sizes.actionHeight(item.size)),
        ),
    ];
    final resolution = const ActionOverflowResolver<CarpenterToolbarItem>()
        .resolve(
          entries: entries,
          availableWidth: availableWidth,
          gap: gap,
          overflowWidth: overflowWidth,
        );
    return _ToolbarLayout(
      visible: resolution.visible,
      overflow: resolution.overflow,
      iconOnly: resolution.iconOnly,
    );
  }

  double _itemWidth(BuildContext context, CarpenterToolbarItem item) =>
      item.presentation == CarpenterToolbarPresentation.icon
      ? context.units(CarpenterTheme.of(context).sizes.actionHeight(item.size))
      : _labelWidth(
          context,
          item.action.label,
          item.size,
          hasIcon: item.action.icon != null,
        );

  double _labelWidth(
    BuildContext context,
    String label,
    ControlSize size, {
    required bool hasIcon,
  }) {
    final theme = CarpenterTheme.of(context);
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: theme.typography.action(
          context,
          size,
          TypographyEmphasis.medium,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final horizontal = context.units(
      theme.spacing.actionHorizontalPadding(size),
    );
    final icon = hasIcon
        ? context.units(theme.sizes.actionIcon(size)) +
              context.units(theme.spacing.actionGap(size))
        : 0;
    return painter.width + horizontal * 2 + icon;
  }
}

final class _ToolbarAction extends StatelessWidget {
  const _ToolbarAction({required this.item, required this.forceIcon});

  final CarpenterToolbarItem item;
  final bool forceIcon;

  @override
  Widget build(BuildContext context) {
    final iconOnly =
        forceIcon || item.presentation == CarpenterToolbarPresentation.icon;
    if (iconOnly && item.action.icon != null) {
      return CarpenterIconButton.fromAction(
        item.action,
        prominence: item.prominence,
        size: item.size,
        executionPhase: item.executionPhase,
      );
    }
    return CarpenterButton.fromAction(
      item.action,
      prominence: item.prominence,
      size: item.size,
      executionPhase: item.executionPhase,
    );
  }
}

final class _ToolbarLayout {
  const _ToolbarLayout({
    required this.visible,
    required this.overflow,
    required this.iconOnly,
  });

  final List<CarpenterToolbarItem> visible;
  final List<CarpenterToolbarItem> overflow;
  final bool iconOnly;
}
