import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../internal/overlay/anchored_overlay_host.dart';
import '../../basic/button/button.dart';
import '../../basic/button/icon_button.dart';
import 'menu.dart';
import 'menu_entry.dart';

/// A controlled action-menu trigger.
final class CarpenterDropdown extends StatelessWidget {
  const CarpenterDropdown({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.label,
    required this.items,
    this.icon,
    this.colorRole = ActionColorRole.neutral,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.placement = OverlayPlacement.bottomStart,
    this.fallbackPlacements = const [],
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : _iconOnly = false;

  const CarpenterDropdown.icon({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.label,
    required this.items,
    required CarpenterIconSource icon,
    this.colorRole = ActionColorRole.neutral,
    this.prominence = ActionProminence.normal,
    this.size = ControlSize.medium,
    this.shape = CarpenterShape.rounded,
    this.placement = OverlayPlacement.bottomStart,
    this.fallbackPlacements = const [],
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  }) : icon = icon,
       _iconOnly = true;

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final String label;
  final List<CarpenterMenuItem> items;
  final CarpenterIconSource? icon;
  final ActionColorRole colorRole;
  final ActionProminence prominence;
  final ControlSize size;
  final CarpenterShape shape;
  final OverlayPlacement placement;
  final List<OverlayPlacement> fallbackPlacements;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final bool _iconOnly;

  @override
  Widget build(BuildContext context) => AnchoredOverlayHost(
    open: open,
    onOpenChanged: onOpenChanged,
    placement: placement,
    fallbackPlacements: fallbackPlacements,
    anchor: _iconOnly
        ? CarpenterIconButton(
            icon: icon!,
            semanticLabel: semanticLabel ?? label,
            colorRole: colorRole,
            prominence: prominence,
            size: size,
            shape: shape,
            focusNode: focusNode,
            autofocus: autofocus,
            onInvoke: () => onOpenChanged(!open),
          )
        : CarpenterButton(
            label: label,
            icon: icon,
            colorRole: colorRole,
            prominence: prominence,
            size: size,
            shape: shape,
            focusNode: focusNode,
            autofocus: autofocus,
            semanticLabel: semanticLabel,
            onInvoke: () => onOpenChanged(!open),
          ),
    overlayBuilder: (context) => CarpenterMenu(
      items: items,
      onDismissRequested: () => onOpenChanged(false),
      semanticLabel: semanticLabel == null ? null : '$semanticLabel menu',
    ),
  );
}
