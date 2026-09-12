import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../../../foundation/hotkey_formatter.dart';
import '../../../internal/rendering/tooltip.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../internal/rendering/action_control.dart';
import '../../../internal/rendering/icon_renderer.dart';

/// Icon-only semantic action that requires an explicit accessible name.
///
/// Use it when the icon is recognizable in context and text would be
/// redundant. The caller owns execution state; callback aliases follow the
/// same mutually exclusive contract as [CarpenterButton].
final class CarpenterIconButton extends StatelessWidget {
  /// Creates an icon action with a required [semanticLabel]. Null callbacks
  /// disable it; supplying both [onPressed] and [onInvoke] is an assertion
  /// error.
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
    this.shortcut,
    this.toggled,
  }) : _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  /// Projects an icon-bearing [action], preserving its visibility and
  /// disabled reason. Asserts that the descriptor supplies an icon.
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
       toggled = action.toggled,
       shortcut = action.shortcut,
       _visible = action.visible,
       _semanticHint = action.disabledReason;

  /// Required Carpenter icon source; it is rendered at the themed action-icon
  /// size.
  final CarpenterIconSource icon;

  /// Required accessible action name. Describe the action rather than the
  /// icon shape.
  final String semanticLabel;

  /// Callback invoked by an enabled activation. Null disables the action
  /// unless the compatibility callback is supplied.
  final VoidCallback? onPressed;

  /// Compatibility alias for older Carpenter call sites.
  final VoidCallback? onInvoke;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final ActionColorRole colorRole;

  /// Controlled switch state. Null keeps ordinary action semantics; false
  /// renders neutral and true renders [colorRole]. The callback owns updates.
  final bool? toggled;

  /// Visual emphasis independently of the action's semantic color role.
  final ActionProminence prominence;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Leading and trailing corner roles. Logical start/end follow text
  /// direction.
  final CarpenterShape shape;

  /// Caller-owned operation phase shown by the action renderer; no work is
  /// started automatically.
  final ActionExecutionPhase executionPhase;

  /// Optional caller-owned focus node. Dispose a supplied node in its owner,
  /// not in the widget.
  final FocusNode? focusNode;

  /// Whether the control requests focus when first attached. Defaults to
  /// false.
  final bool autofocus;

  /// Shortcut metadata displayed on hover; binding remains with the caller.
  final ShortcutActivator? shortcut;
  final bool _visible;
  final String? _semanticHint;

  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    final control = ActionControl(
      semanticLabel: semanticLabel,
      semanticHint: _semanticHint,
      onInvoke: _effectiveOnPressed,
      colorRole: colorRole,
      toggled: toggled,
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
    final keys = shortcut == null
        ? null
        : CarpenterHotkeyFormatter(
            platform: defaultTargetPlatform,
          ).formatActivator(shortcut!);
    return MergeSemantics(
      child: ActionTooltip(
        text: keys == null ? semanticLabel : '$semanticLabel · $keys',
        child: control,
      ),
    );
  }
}
