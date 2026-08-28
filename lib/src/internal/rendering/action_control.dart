import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'focus_ring.dart';
import 'interactive_region.dart';
import 'loading_background.dart';

typedef ActionControlChildBuilder =
    Widget Function(
      BuildContext context,
      CarpenterActionStyle style,
      double iconDimension,
    );

final class ActionControl extends StatelessWidget {
  const ActionControl({
    super.key,
    required this.semanticLabel,
    required this.onInvoke,
    required this.colorRole,
    required this.prominence,
    required this.size,
    required this.executionPhase,
    required this.shape,
    required this.iconOnly,
    required this.childBuilder,
    this.focusNode,
    this.autofocus = false,
  });

  final String semanticLabel;
  final VoidCallback? onInvoke;
  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ControlSize size;
  final ActionExecutionPhase executionPhase;
  final CarpenterShape shape;
  final bool iconOnly;
  final ActionControlChildBuilder childBuilder;
  final FocusNode? focusNode;
  final bool autofocus;

  bool get _running => executionPhase == ActionExecutionPhase.running;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final controlDimension = theme.sizes.actionExtent(context, size);
    final minimumTarget = context.units(theme.sizes.minimumTarget);
    final horizontalPadding = context.units(
      theme.spacing.actionHorizontalPadding(size),
    );
    final verticalPadding = context.units(
      theme.spacing.actionVerticalPadding(size),
    );
    final iconDimension = context.units(theme.sizes.actionIcon(size));
    final zero = context.units(theme.sizes.zero);

    Radius radiusFor(ShapeRole role) => Radius.circular(
      role == ShapeRole.circular
          ? controlDimension / 2
          : context.units(theme.shapes.radiusForAction(role, size)),
    );

    final startRadius = radiusFor(shape.start);
    final endRadius = radiusFor(shape.end);
    final borderRadius = BorderRadiusDirectional.only(
      topStart: startRadius,
      bottomStart: startRadius,
      topEnd: endRadius,
      bottomEnd: endRadius,
    ).resolve(Directionality.of(context));

    return LayoutBuilder(
      builder: (context, constraints) {
        final fillTightParent = !iconOnly && constraints.hasTightWidth;
        return Semantics(
          container: true,
          button: true,
          enabled: onInvoke != null,
          label: semanticLabel,
          value: _running ? 'running' : null,
          liveRegion: _running,
          onTap: _running ? null : onInvoke,
          excludeSemantics: true,
          child: InteractiveRegion(
            onActivate: onInvoke,
            activationBlocked: _running,
            focusNode: focusNode,
            autofocus: autofocus,
            builder: (context, states, showFocusHighlight) {
              final visualStates =
                  _running && states.contains(WidgetState.disabled)
                  ? ({...states}..remove(WidgetState.disabled))
                  : states;
              final style = theme.actions.resolve(
                colorRole,
                prominence,
                visualStates,
              );
              final content = ExcludeSemantics(
                child: childBuilder(context, style, iconDimension),
              );
              final visual = FocusRing(
                visible:
                    states.contains(WidgetState.focused) && showFocusHighlight,
                borderRadius: borderRadius,
                child: AnimatedContainer(
                  duration: theme.motion.transitionDuration(context),
                  curve: theme.motion.stateCurve,
                  width: fillTightParent ? double.infinity : null,
                  constraints: BoxConstraints(
                    minWidth: iconOnly ? controlDimension : zero,
                  ),
                  height: controlDimension,
                  decoration: BoxDecoration(
                    color: style.background,
                    borderRadius: borderRadius,
                    border: Border.all(
                      color: style.border,
                      width: context.units(theme.shapes.actionBorderWidth),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: borderRadius,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        if (_running)
                          Positioned.fill(
                            child: LoadingBackground(
                              color: style.loadingAccent,
                            ),
                          ),
                        Padding(
                          padding: iconOnly
                              ? EdgeInsets.all(zero)
                              : EdgeInsets.symmetric(
                                  horizontal: horizontalPadding,
                                  vertical: verticalPadding,
                                ),
                          child: Align(
                            widthFactor: fillTightParent ? null : 1,
                            heightFactor: 1,
                            child: content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: iconOnly ? minimumTarget : zero,
                  minHeight: minimumTarget,
                ),
                child: Align(
                  widthFactor: fillTightParent ? null : 1,
                  heightFactor: 1,
                  child: visual,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
