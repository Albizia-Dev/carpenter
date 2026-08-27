import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/rendering/action_control.dart';

final class CarpenterIconButton extends StatelessWidget {
  const CarpenterIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onInvoke,
    this.colorRole = ActionColorRole.neutral,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.circular,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
  });

  CarpenterIconButton.fromAction(
    CarpenterActionDescriptor action, {
    super.key,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.circular,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
  }) : assert(action.icon != null, 'Icon action requires an icon.'),
       icon = action.icon!,
       semanticLabel = action.effectiveSemanticLabel,
       onInvoke = action.onInvoke,
       colorRole = action.colorRole;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onInvoke;
  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ControlSize size;
  final CarpenterShape shape;
  final ActionExecutionPhase executionPhase;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ActionControl(
      semanticLabel: semanticLabel,
      onInvoke: onInvoke,
      colorRole: colorRole,
      prominence: prominence,
      size: size,
      shape: shape,
      executionPhase: executionPhase,
      iconOnly: true,
      focusNode: focusNode,
      autofocus: autofocus,
      childBuilder: (context, style, iconDimension) =>
          Icon(icon, size: iconDimension, color: style.icon),
    );
  }
}
