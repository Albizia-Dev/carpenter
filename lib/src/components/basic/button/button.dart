import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/action_control.dart';
import '../../../internal/rendering/icon_renderer.dart';

final class CarpenterButton extends StatelessWidget {
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
  }) : _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

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
  }) : prominence = ActionProminence.filled,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

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
  }) : prominence = ActionProminence.outlined,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

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
  }) : prominence = ActionProminence.ghost,
       _visible = true,
       _semanticHint = null,
       assert(
         onPressed == null || onInvoke == null,
         'Use either onPressed or the compatibility onInvoke callback, not both.',
       );

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
       _visible = action.visible,
       _semanticHint = action.disabledReason;

  final String label;
  final VoidCallback? onPressed;

  /// Compatibility alias for older Carpenter call sites.
  final VoidCallback? onInvoke;
  final CarpenterIconSource? icon;
  final CarpenterActionIconPosition iconPosition;
  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ControlSize size;
  final CarpenterShape shape;
  final ActionExecutionPhase executionPhase;
  final FocusNode? focusNode;
  final bool autofocus;
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
      prominence: prominence,
      size: size,
      shape: shape,
      executionPhase: executionPhase,
      iconOnly: false,
      focusNode: focusNode,
      autofocus: autofocus,
      childBuilder: (context, style, iconDimension) => _ButtonContent(
        label: label,
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
    required this.icon,
    required this.iconPosition,
    required this.style,
    required this.iconDimension,
    required this.size,
  });

  final String label;
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

    final hasGlyph = icon != null;
    final glyph = icon == null
        ? null
        : WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox.square(
              dimension: iconDimension,
              child: IconRenderer(
                icon: icon!,
                size: iconDimension,
                color: style.icon,
              ),
            ),
          );
    final spacer = WidgetSpan(child: SizedBox(width: gap));
    final spans = <InlineSpan>[
      if (hasGlyph && iconPosition == CarpenterActionIconPosition.leading)
        glyph!,
      if (hasGlyph && iconPosition == CarpenterActionIconPosition.leading)
        spacer,
      TextSpan(text: label),
      if (hasGlyph && iconPosition == CarpenterActionIconPosition.trailing)
        spacer,
      if (hasGlyph && iconPosition == CarpenterActionIconPosition.trailing)
        glyph!,
    ];

    return Text.rich(
      TextSpan(style: textStyle, children: spans),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }
}
