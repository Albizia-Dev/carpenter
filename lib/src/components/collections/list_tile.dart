import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';
import '../../internal/rendering/interactive_region.dart';

/// Interactive semantic row used by collection and navigation patterns.
final class CarpenterListTile extends StatelessWidget {
  const CarpenterListTile({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onInvoke,
    this.selected = false,
    this.semanticLabel,
  });

  final Widget title;
  final Widget? leading;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onInvoke;
  final bool selected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final radius = BorderRadius.circular(context.units(.5.rem));
    return Semantics(
      container: true,
      selected: selected,
      label: semanticLabel,
      child: InteractiveRegion(
        onActivate: onInvoke,
        builder: (context, states, showFocusHighlight) {
          final active =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.focused);
          final background = selected
              ? theme.overlay.selected
              : active
              ? theme.overlay.hovered
              : const Color(0x00000000);
          return TweenAnimationBuilder<Color?>(
            duration: theme.motion.transitionDuration(context),
            curve: theme.motion.stateCurve,
            tween: ColorTween(end: background),
            builder: (context, color, child) => DecoratedBox(
              decoration: BoxDecoration(color: color, borderRadius: radius),
              child: child,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: gap,
                vertical: gap * .75,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[leading!, SizedBox(width: gap)],
                  Expanded(
                    child: Column(
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
