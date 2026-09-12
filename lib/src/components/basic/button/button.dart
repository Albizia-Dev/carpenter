import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../../foundation/hotkey_formatter.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/action_control.dart';
import '../../../internal/rendering/icon_renderer.dart';

/// Semantic text action with optional icon, keyboard/focus handling, and
/// caller-controlled execution feedback.
///
/// Labels stay on one line and ellipsize within constrained widths, preserving
/// the semantic control height. The complete label remains in semantics.
///
/// Provide [onPressed] for new code; [onInvoke] is a compatibility alias and
/// must not be supplied together with it. The button does not await
/// asynchronous work or infer [executionPhase]. Use a command binding for
/// managed execution, or update the phase in application state.
final class CarpenterButton extends StatelessWidget {
  /// Creates a normally presented action unless [prominence] is specified.
  /// With neither callback supplied the action is disabled. Supplying both
  /// callback names is an assertion error.
  const CarpenterButton({
    super.key,
    required this.label,
    this.onPressed,
    this.onInvoke,
    this.icon,
    this.iconPosition = CarpenterActionIconPosition.leading,
    this.colorRole = ActionColorRole.primary,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.toggled,
    this.shortcut,
  }) : _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  /// Creates an action with [ActionProminence.filled]; all execution and
  /// callback rules match the default constructor.
  const CarpenterButton.filled({
    super.key,
    required this.label,
    this.onPressed,
    this.onInvoke,
    this.icon,
    this.iconPosition = CarpenterActionIconPosition.leading,
    this.colorRole = ActionColorRole.primary,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.toggled,
    this.shortcut,
  }) : prominence = ActionProminence.filled,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  /// Creates an action with [ActionProminence.outlined]; all execution and
  /// callback rules match the default constructor.
  const CarpenterButton.outlined({
    super.key,
    required this.label,
    this.onPressed,
    this.onInvoke,
    this.icon,
    this.iconPosition = CarpenterActionIconPosition.leading,
    this.colorRole = ActionColorRole.primary,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.toggled,
    this.shortcut,
  }) : prominence = ActionProminence.outlined,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  /// Creates a low-chrome action with [ActionProminence.ghost], not a plain
  /// unstyled Flutter text widget.
  const CarpenterButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.onInvoke,
    this.icon,
    this.iconPosition = CarpenterActionIconPosition.leading,
    this.colorRole = ActionColorRole.primary,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.toggled,
    this.shortcut,
  }) : prominence = ActionProminence.ghost,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

  /// Projects a reusable [action] into a button. Its visibility, label, icon,
  /// callback, color, and disabled reason are preserved; the descriptor does
  /// not own asynchronous execution state.
  CarpenterButton.fromAction(
    CarpenterActionDescriptor action, {
    super.key,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.executionPhase = ActionExecutionPhase.idle,
    this.iconPosition = CarpenterActionIconPosition.leading,
    this.focusNode,
    this.autofocus = false,
  }) : label = action.label,
       onPressed = action.onInvoke,
       onInvoke = null,
       icon = action.icon,
       semanticLabel = action.semanticLabel,
       colorRole = action.colorRole,
       toggled = action.toggled,
       shortcut = action.shortcut,
       _visible = action.visible,
       _semanticHint = action.disabledReason;

  /// Visible text naming the control or choice; keep it meaningful without
  /// relying on an icon.
  final String label;

  /// Optional shortcut badge; the caller owns shortcut registration.
  final ShortcutActivator? shortcut;

  /// Invoked when the enabled action is activated. Null disables the action
  /// unless the compatibility callback is supplied.
  final VoidCallback? onPressed;

  /// Compatibility alias for older Carpenter call sites.
  final VoidCallback? onInvoke;

  /// Optional icon rendered alongside the visible label using the action
  /// theme.
  final CarpenterIconSource? icon;

  /// Whether the icon precedes or follows the label in logical reading order.
  final CarpenterActionIconPosition iconPosition;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final ActionColorRole colorRole;

  /// Controlled switch state. Null keeps ordinary action semantics; false
  /// renders neutral and true renders [colorRole]. The callback owns updates.
  final bool? toggled;

  /// Visual emphasis of the action, independently of its semantic color role.
  final ActionProminence prominence;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Leading and trailing corner roles. Logical start/end follow text
  /// direction.
  final CarpenterShape shape;

  /// Application-supplied execution phase used by the action renderer.
  /// Changing it does not start an operation.
  final ActionExecutionPhase executionPhase;

  /// Optional caller-owned focus node. Dispose a supplied node in its owner,
  /// not in the widget.
  final FocusNode? focusNode;

  /// Whether the control requests focus when first attached. Defaults to
  /// false.
  final bool autofocus;

  /// Accessible name supplied to assistive technology. When omitted, the
  /// visible label is used.
  final String? semanticLabel;
  final bool _visible;
  final String? _semanticHint;

  VoidCallback? get _effectiveOnPressed => onPressed ?? onInvoke;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return ActionControl(
      semanticLabel: semanticLabel ?? label,
      semanticHint: _semanticHint,
      onInvoke: _effectiveOnPressed,
      colorRole: colorRole,
      toggled: toggled,
      prominence: prominence,
      size: size,
      shape: shape,
      executionPhase: executionPhase,
      iconOnly: false,
      focusNode: focusNode,
      autofocus: autofocus,
      childBuilder: (context, style, iconDimension) => _ButtonContent(
        label: label,
        shortcut: shortcut,
        icon: icon,
        iconPosition: iconPosition,
        style: style,
        iconDimension: iconDimension,
        size: size,
      ),
    );
  }
}

final class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.shortcut,
    required this.icon,
    required this.iconPosition,
    required this.style,
    required this.iconDimension,
    required this.size,
  });

  final String label;

  /// Optional shortcut badge; the caller owns shortcut registration.
  final ShortcutActivator? shortcut;
  final CarpenterIconSource? icon;
  final CarpenterActionIconPosition iconPosition;
  final CarpenterActionStyle style;
  final double iconDimension;
  final ControlSize size;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.actionGap(size));
    final textStyle = theme.typography
        .action(context, size, TypographyEmphasis.medium)
        .copyWith(color: style.foreground);

    final keys = shortcut == null
        ? null
        : CarpenterHotkeyFormatter(
            platform: defaultTargetPlatform,
          ).formatActivator(shortcut!);
    final glyph = icon == null
        ? null
        : IconRenderer(
            icon: icon!,
            size: MediaQuery.textScalerOf(context).scale(iconDimension),
            color: style.icon,
          );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (glyph != null &&
            iconPosition == CarpenterActionIconPosition.leading) ...[
          glyph,
          SizedBox(width: gap),
        ],
        Flexible(
          child: Text(
            label,
            style: textStyle,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        if (keys != null) ...[
          SizedBox(width: gap),
          DecoratedBox(
            decoration: BoxDecoration(
              color: style.foreground.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(
                context.units(theme.shapes.radius(ShapeRole.rounded)) / 2,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.units(theme.spacing.small) / 2,
                vertical: context.units(theme.spacing.small) / 4,
              ),
              child: Text(
                keys,
                style: theme.typography
                    .resolve(
                      context,
                      TypographyRole.caption,
                      TypographyEmphasis.regular,
                    )
                    .copyWith(color: style.foreground),
                maxLines: 1,
              ),
            ),
          ),
        ],
        if (glyph != null &&
            iconPosition == CarpenterActionIconPosition.trailing) ...[
          SizedBox(width: gap),
          glyph,
        ],
      ],
    );
  }
}
