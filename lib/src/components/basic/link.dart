import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/focus_ring.dart';
import '../../internal/rendering/icon_renderer.dart';
import '../../internal/rendering/interactive_region.dart';

/// Semantic presentation role for a [CarpenterLink].
///
/// Link role controls typography, default action color, and the automatic
/// underline policy. Status or destructive meaning remains owned by
/// [ActionColorRole] and can be overridden independently with `colorRole`.
enum CarpenterLinkRole {
  /// A hyperlink embedded in prose or other continuous text.
  inline,

  /// A normal application link such as an object name or navigation target.
  standalone,

  /// A lower-emphasis secondary or metadata link.
  subtle,

  /// A deliberately noticeable navigation link without button chrome.
  prominent,
}

/// Underline policy for a [CarpenterLink].
enum CarpenterLinkUnderline {
  /// Uses the semantic default defined by [CarpenterLinkRole].
  auto,

  /// Always renders an underline.
  always,

  /// Renders an underline while hovered or keyboard-focused.
  hover,

  /// Never renders an underline.
  none,
}

/// A semantic navigation action rendered as text with optional leading icon.
final class CarpenterLink extends StatelessWidget {
  /// Creates a semantic link.
  ///
  /// The default [role] is [CarpenterLinkRole.standalone], which uses a neutral
  /// action color without an underline in any state. Set [underline] to
  /// [CarpenterLinkUnderline.auto] to opt into role-based decoration, or
  /// [CarpenterLinkUnderline.always] for underlined prose links.
  const CarpenterLink({
    super.key,
    required this.label,
    this.onInvoke,
    this.semanticLabel,
    this.icon,
    this.role = CarpenterLinkRole.standalone,
    this.underline = CarpenterLinkUnderline.none,
    ActionColorRole? colorRole,
    this.focusNode,
    this.autofocus = false,
  }) : _colorRole = colorRole;

  /// Visible link label.
  final String label;

  /// Invoked when the link is activated. A null callback disables the link.
  final VoidCallback? onInvoke;

  /// Optional accessibility label replacing [label] for semantics.
  final String? semanticLabel;

  /// Optional leading icon rendered with the resolved link foreground.
  final CarpenterIconSource? icon;

  /// Semantic presentation role controlling default color, typography, and
  /// automatic underline behavior.
  final CarpenterLinkRole role;

  /// Underline policy. [CarpenterLinkUnderline.auto] derives behavior from
  /// [role].
  final CarpenterLinkUnderline underline;

  final ActionColorRole? _colorRole;

  /// Semantic action color used by this link.
  ///
  /// When no explicit color role is supplied, the value is derived from
  /// [role]: inline links use utility, standalone and subtle links use neutral,
  /// and prominent links use primary.
  ActionColorRole get colorRole =>
      _colorRole ??
      switch (role) {
        CarpenterLinkRole.inline => ActionColorRole.utility,
        CarpenterLinkRole.standalone => ActionColorRole.neutral,
        CarpenterLinkRole.subtle => ActionColorRole.neutral,
        CarpenterLinkRole.prominent => ActionColorRole.primary,
      };

  /// Focus node used by the interactive region.
  final FocusNode? focusNode;

  /// Whether the link requests focus when first built.
  final bool autofocus;

  TypographyEmphasis get _emphasis => switch (role) {
    CarpenterLinkRole.inline => TypographyEmphasis.medium,
    CarpenterLinkRole.standalone => TypographyEmphasis.medium,
    CarpenterLinkRole.subtle => TypographyEmphasis.regular,
    CarpenterLinkRole.prominent => TypographyEmphasis.strong,
  };

  bool _showUnderline(Set<WidgetState> states) => switch (underline) {
    CarpenterLinkUnderline.always => true,
    CarpenterLinkUnderline.hover =>
      states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused),
    CarpenterLinkUnderline.none => false,
    CarpenterLinkUnderline.auto => switch (role) {
      CarpenterLinkRole.inline => true,
      CarpenterLinkRole.standalone =>
        states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused),
      CarpenterLinkRole.subtle =>
        states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused),
      CarpenterLinkRole.prominent => false,
    },
  };

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
        final focusPadding = context.units(const Rem(.1875));
        final isUnderlined = _showUnderline(states);
        final content = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              IconRenderer(
                icon: icon!,
                size: context.units(theme.sizes.actionIcon(ControlSize.small)),
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
                    .resolve(context, TypographyRole.body, _emphasis)
                    .copyWith(
                      color: style.foreground,
                      decoration: isUnderlined
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: style.foreground,
                    ),
              ),
            ),
          ],
        );
        return FocusRing(
          visible: states.contains(WidgetState.focused) && showFocusHighlight,
          borderRadius: radius,
          child: Padding(padding: EdgeInsets.all(focusPadding), child: content),
        );
      },
    ),
  );
}
