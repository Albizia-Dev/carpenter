import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../internal/rendering/interactive_region.dart';
import 'table_metrics.dart';

enum CarpenterListTilePresentation { standard, tableRow }

/// Interactive semantic row used by collection and navigation patterns.
final class CarpenterListTile extends StatelessWidget {
  const CarpenterListTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onInvoke,
    this.onDoubleInvoke,
    this.selected = false,
    this.semanticLabel,
    this.presentation = CarpenterListTilePresentation.standard,
  });

  const CarpenterListTile.tableRow({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onInvoke,
    this.onDoubleInvoke,
    this.selected = false,
    this.semanticLabel,
  }) : presentation = CarpenterListTilePresentation.tableRow;

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onInvoke;
  final VoidCallback? onDoubleInvoke;
  final bool selected;
  final String? semanticLabel;
  final CarpenterListTilePresentation presentation;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final metrics = CarpenterTableMetrics.resolve(context);
    final tableRow = presentation == CarpenterListTilePresentation.tableRow;
    final gap = tableRow
        ? metrics.horizontalPadding
        : context.units(theme.spacing.medium);
    final radius = tableRow
        ? BorderRadius.zero
        : BorderRadius.circular(context.units(.5.rem));
    final rowHeight = metrics.rowHeight;
    return Semantics(
      container: true,
      selected: selected,
      label: semanticLabel,
      child: InteractiveRegion(
        onActivate: onInvoke,
        onDoubleActivate: onDoubleInvoke,
        builder: (context, states, showFocusHighlight) {
          final active =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          final background = selected
              ? theme.overlay.selected
              : active
              ? theme.overlay.hovered
              : tableRow
              ? theme.overlay.background
              : const Color(0x00000000);
          return TweenAnimationBuilder<Color?>(
            duration: theme.motion.transitionDuration(context),
            curve: theme.motion.stateCurve,
            tween: ColorTween(end: background),
            builder: (context, color, child) => Container(
              height: tableRow ? rowHeight : null,
              decoration: BoxDecoration(
                color: color,
                borderRadius: radius,
                border: tableRow
                    ? Border(
                        bottom: BorderSide(
                          color: theme.overlay.border,
                          width: metrics.borderWidth,
                        ),
                      )
                    : null,
              ),
              foregroundDecoration: showFocusHighlight
                  ? BoxDecoration(
                      border: Border.all(
                        color: theme.focus.color,
                        width: context.units(theme.focus.width),
                      ),
                      borderRadius: radius,
                    )
                  : null,
              child: child,
            ),
            child: Padding(
              padding: tableRow
                  ? EdgeInsetsDirectional.symmetric(
                      horizontal: gap,
                      vertical: metrics.verticalPadding,
                    )
                  : EdgeInsets.symmetric(horizontal: gap, vertical: gap * .75),
              child: Row(
                crossAxisAlignment: tableRow
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, SizedBox(width: gap)],
                  Expanded(
                    child: tableRow && subtitle == null
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: title,
                          )
                        : Column(
                            mainAxisAlignment: tableRow
                                ? MainAxisAlignment.center
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              title,
                              if (subtitle != null) ...[
                                SizedBox(height: gap / 2),
                                subtitle!,
                              ],
                            ],
                          ),
                  ),
                  if (trailing != null) ...[SizedBox(width: gap), trailing!],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
