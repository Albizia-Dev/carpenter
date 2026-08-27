import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/button/icon_button.dart';
import '../behaviour/menu/dropdown.dart';
import '../behaviour/menu/menu_entry.dart';

enum CarpenterToolbarPriority { critical, normal, overflow }

enum CarpenterToolbarPresentation { label, icon }

@immutable
final class CarpenterToolbarItem {
  const CarpenterToolbarItem({
    required this.action,
    this.priority = CarpenterToolbarPriority.normal,
    this.presentation = CarpenterToolbarPresentation.label,
    this.prominence = ActionProminence.ghost,
    this.size = ControlSize.medium,
    this.executionPhase = ActionExecutionPhase.idle,
  });

  final CarpenterActionDescriptor action;
  final CarpenterToolbarPriority priority;
  final CarpenterToolbarPresentation presentation;
  final ActionProminence prominence;
  final ControlSize size;
  final ActionExecutionPhase executionPhase;
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
            mainAxisSize: MainAxisSize.max,
            children: [
              for (var index = 0; index < layout.visible.length; index++) ...[
                if (index > 0) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: _ToolbarAction(item: layout.visible[index]),
                ),
              ],
              if (layout.overflow.isNotEmpty) ...[
                if (layout.visible.isNotEmpty) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: CarpenterDropdown(
                    open: _overflowOpen,
                    onOpenChanged: (value) =>
                        setState(() => _overflowOpen = value),
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
    if (!availableWidth.isFinite) {
      return _ToolbarLayout(
        visible: widget.items
            .where((item) => item.priority != CarpenterToolbarPriority.overflow)
            .toList(),
        overflow: widget.items
            .where((item) => item.priority == CarpenterToolbarPriority.overflow)
            .toList(),
      );
    }
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutToolbar);
    final forcedOverflow = widget.items
        .where((item) => item.priority == CarpenterToolbarPriority.overflow)
        .toList();
    final candidates = widget.items
        .where((item) => item.priority != CarpenterToolbarPriority.overflow)
        .toList();
    final widths = {
      for (final item in candidates) item: _itemWidth(context, item),
    };
    final allWidth =
        widths.values.fold(0.0, (sum, width) => sum + width) +
        _mathMax(0, candidates.length - 1) * gap;
    if (forcedOverflow.isEmpty && allWidth <= availableWidth) {
      return _ToolbarLayout(visible: candidates, overflow: const []);
    }
    final overflowWidth = _labelWidth(
      context,
      widget.overflowLabel,
      ControlSize.medium,
      hasIcon: false,
    );
    final remaining = availableWidth - overflowWidth - gap;
    final ranked = [...candidates]
      ..sort((a, b) => a.priority.index.compareTo(b.priority.index));
    final visible = <CarpenterToolbarItem>[];
    var used = 0.0;
    for (final item in ranked) {
      final next = widths[item]! + (visible.isEmpty ? 0 : gap);
      if (used + next <= remaining) {
        visible.add(item);
        used += next;
      }
    }
    visible.sort(
      (a, b) => widget.items.indexOf(a).compareTo(widget.items.indexOf(b)),
    );
    final overflow = [
      for (final item in widget.items)
        if (!visible.contains(item)) item,
    ];
    return _ToolbarLayout(visible: visible, overflow: overflow);
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
  const _ToolbarAction({required this.item});
  final CarpenterToolbarItem item;

  @override
  Widget build(BuildContext context) =>
      item.presentation == CarpenterToolbarPresentation.icon
      ? CarpenterIconButton.fromAction(
          item.action,
          prominence: item.prominence,
          size: item.size,
          executionPhase: item.executionPhase,
        )
      : CarpenterButton.fromAction(
          item.action,
          prominence: item.prominence,
          size: item.size,
          executionPhase: item.executionPhase,
        );
}

final class _ToolbarLayout {
  const _ToolbarLayout({required this.visible, required this.overflow});
  final List<CarpenterToolbarItem> visible;
  final List<CarpenterToolbarItem> overflow;
}

int _mathMax(int a, int b) => a > b ? a : b;
