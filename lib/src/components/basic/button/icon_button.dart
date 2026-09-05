import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../internal/rendering/action_control.dart';
import '../../../internal/rendering/icon_renderer.dart';

final class CarpenterIconButton extends StatelessWidget {
  const CarpenterIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
    this.onInvoke,
    this.colorRole = ActionColorRole.neutral,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
  }) : _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  CarpenterIconButton.fromAction(
    CarpenterActionDescriptor action, {
    super.key,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
  }) : assert(action.icon != null, 'Icon action requires an icon.'),
       icon = action.icon!,
       semanticLabel = action.effectiveSemanticLabel,
       onPressed = action.onInvoke,
       onInvoke = null,
       colorRole = action.colorRole,
       _visible = action.visible,
       _semanticHint = action.disabledReason;

  final CarpenterIconSource icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Compatibility alias for older Carpenter call sites.
  final VoidCallback? onInvoke;
  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ControlSize size;
  final CarpenterShape shape;
  final ActionExecutionPhase executionPhase;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool _visible;
  final String? _semanticHint;

  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return ActionControl(
      semanticLabel: semanticLabel,
      semanticHint: _semanticHint,
      onInvoke: _effectiveOnPressed,
      colorRole: colorRole,
      prominence: prominence,
      size: size,
      shape: shape,
      executionPhase: executionPhase,
      iconOnly: true,
      focusNode: focusNode,
      autofocus: autofocus,
      childBuilder: (context, style, iconDimension) =>
          IconRenderer(icon: icon, size: iconDimension, color: style.icon),
    );
  }
}
