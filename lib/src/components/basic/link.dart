import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/focus_ring.dart';
import '../../internal/rendering/interactive_region.dart';

/// An inline semantic navigation action.
final class CarpenterLink extends StatelessWidget {
  const CarpenterLink({
    super.key,
    required this.label,
    this.onInvoke,
    this.semanticLabel,
    this.icon,
    this.colorRole = ActionColorRole.utility,
    this.focusNode,
    this.autofocus = false,
  });

  final String label;
  final VoidCallback? onInvoke;
  final String? semanticLabel;
  final IconData? icon;
  final ActionColorRole colorRole;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    link: true,
    enabled: onInvoke != null,
    label: semanticLabel ?? label,
    onTap: onInvoke,
    excludeSemantics: true,
    child: InteractiveRegion(
      onActivate: onInvoke,
      focusNode: focusNode,
      autofocus: autofocus,
      includeFocusSemantics: false,
      builder: (context, states, showFocusHighlight) {
        final theme = CarpenterTheme.of(context);
        final style = theme.actions.resolve(
          colorRole,
          ActionProminence.ghost,
          states,
        );
        final radius = BorderRadius.circular(
          context.units(theme.shapes.radius(ShapeRole.rounded)),
        );
        return FocusRing(
          visible: states.contains(WidgetState.focused) && showFocusHighlight,
          borderRadius: radius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.background,
              borderRadius: radius,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: context.units(
                      theme.sizes.actionIcon(ControlSize.small),
                    ),
                    color: style.icon,
                  ),
                  SizedBox(
                    width: context.units(
                      theme.spacing.actionGap(ControlSize.small),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: theme.typography
                        .resolve(
                          context,
                          TypographyRole.body,
                          TypographyEmphasis.medium,
                        )
                        .copyWith(
                          color: style.foreground,
                          decoration: TextDecoration.underline,
                          decorationColor: style.foreground,
                        ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
