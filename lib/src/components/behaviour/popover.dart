import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/anchored_overlay_host.dart';
import '../../internal/overlay/overlay_surface.dart';
import '../../internal/rendering/focus_ring.dart';
import '../../internal/rendering/interactive_region.dart';
import 'menu/menu.dart';

/// Visual ownership for an anchored popover's content surface.
enum CarpenterPopoverPresentation { standard, bare }

/// A controlled, interactive container attached to an anchor.
final class CarpenterPopover extends StatelessWidget {
  const CarpenterPopover({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.anchor,
    required this.content,
    this.placement = OverlayPlacement.bottomStart,
    this.fallbackPlacements = const [],
    this.semanticLabel,
    this.anchorActivates = true,
    this.presentation = CarpenterPopoverPresentation.standard,
  });

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget anchor;
  final Widget content;
  final OverlayPlacement placement;
  final List<OverlayPlacement> fallbackPlacements;
  final String? semanticLabel;
  final bool anchorActivates;
  final CarpenterPopoverPresentation presentation;

  @override
  Widget build(BuildContext context) => AnchoredOverlayHost(
    open: open,
    onOpenChanged: onOpenChanged,
    placement: placement,
    fallbackPlacements: fallbackPlacements,
    anchor: Semantics(
      button: anchorActivates,
      expanded: open,
      label: semanticLabel,
      onTap: anchorActivates ? () => onOpenChanged(!open) : null,
      excludeSemantics: semanticLabel != null,
      child: InteractiveRegion(
        onActivate: anchorActivates ? () => onOpenChanged(!open) : null,
        builder: (context, states, showFocusHighlight) {
          final theme = CarpenterTheme.of(context);
          return FocusRing(
            visible: states.contains(WidgetState.focused) && showFocusHighlight,
            borderRadius: BorderRadius.circular(
              context.units(theme.shapes.popoverAnchorFocusRadius),
            ),
            child: anchor,
          );
        },
      ),
    ),
    overlayBuilder: (context) =>
        content is CarpenterMenu ||
            presentation == CarpenterPopoverPresentation.bare
        ? content
        : OverlaySurface(child: content),
  );
}
