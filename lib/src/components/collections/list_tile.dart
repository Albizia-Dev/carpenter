import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../foundation/roles.dart';
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
    this.contentPadding = true,
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
    this.contentPadding = true,
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

  /// Whether this tile owns edge padding around its content.
  ///
  /// Table-shaped parents can disable it when their individual cells already
  /// own the table padding contract.
  final bool contentPadding;

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
    final styledTitle = DefaultTextStyle(
      style: theme.typography
          .resolve(context, TypographyRole.body, TypographyEmphasis.medium)
          .copyWith(color: theme.content.resolve(ContentColorRole.primary)),
      child: title,
    );
    final styledSubtitle = subtitle == null
        ? null
        : DefaultTextStyle(
            style: theme.typography
                .resolve(
                  context,
                  TypographyRole.body,
                  TypographyEmphasis.regular,
                )
                .copyWith(
                  color: theme.content.resolve(ContentColorRole.secondary),
                ),
            child: subtitle!,
          );
    final styledTrailing = trailing == null
        ? null
        : DefaultTextStyle(style: styledTitle.style, child: trailing!);
    final row = LayoutBuilder(
      builder: (context, constraints) {
        // Rich list rows keep their primary text readable at narrow widths and
        // large text scales. Fixed-height table rows retain their column layout.
        final stacked =
            !tableRow &&
            subtitle != null &&
            trailing != null &&
            constraints.maxWidth <
                MediaQuery.textScalerOf(
                  context,
                ).scale(context.units(theme.sizes.layoutNarrowEnd));
        return Row(
          crossAxisAlignment: tableRow || subtitle == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (leading != null) ...[leading!, SizedBox(width: gap)],
            Expanded(
              child: tableRow && subtitle == null
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: styledTitle,
                    )
                  : Column(
                      mainAxisAlignment: tableRow
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        styledTitle,
                        if (styledSubtitle != null) ...[
                          SizedBox(height: gap / 2),
                          styledSubtitle,
                        ],
                        if (stacked) ...[
                          SizedBox(height: gap),
                          styledTrailing!,
                        ],
                      ],
                    ),
            ),
            if (trailing != null && !stacked) ...[
              SizedBox(width: gap),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: tableRow
                      ? double.infinity
                      : constraints.maxWidth * .4,
                ),
                child: styledTrailing!,
              ),
            ],
          ],
        );
      },
    );
    final content = contentPadding
        ? Padding(
            padding: tableRow
                ? EdgeInsetsDirectional.symmetric(
                    horizontal: gap,
                    vertical: metrics.verticalPadding,
                  )
                : EdgeInsets.symmetric(horizontal: gap, vertical: gap * .75),
            child: row,
          )
        : row;
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
            child: content,
          );
        },
      ),
    );
  }
}
