import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'anchored_overlay_positioner.dart';
import 'overlay_lifecycle_host.dart';

final class AnchoredOverlayHost extends StatelessWidget {
  const AnchoredOverlayHost({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.anchor,
    required this.overlayBuilder,
    this.placement = OverlayPlacement.bottomStart,
    this.fallbackPlacements = const [],
    this.dismissOnOutside = true,
    this.dismissOnEscape = true,
    this.takeFocus = true,
    this.restoreFocus = true,
    this.modal = false,
    this.allowAnchorInteraction = false,
  });

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget anchor;
  final WidgetBuilder overlayBuilder;
  final OverlayPlacement placement;
  final List<OverlayPlacement> fallbackPlacements;
  final bool dismissOnOutside;
  final bool dismissOnEscape;
  final bool takeFocus;
  final bool restoreFocus;
  final bool modal;
  final bool allowAnchorInteraction;

  @override
  Widget build(BuildContext context) => OverlayLifecycleHost(
    open: open,
    onOpenChanged: onOpenChanged,
    dismissOnOutside: dismissOnOutside,
    dismissOnEscape: dismissOnEscape,
    takeFocus: takeFocus,
    restoreFocus: restoreFocus,
    modal: modal,
    allowChildInteraction: allowAnchorInteraction,
    overlayBuilder: (context, info, dismiss) {
      final theme = CarpenterTheme.of(context);
      final anchorRect = MatrixUtils.transformRect(
        info.childPaintTransform,
        Offset.zero & info.childSize,
      );
      return CustomSingleChildLayout(
        delegate: _AnchoredOverlayLayoutDelegate(
          anchor: anchorRect,
          placement: placement,
          fallbackPlacements: fallbackPlacements,
          textDirection: Directionality.of(context),
          gap: context.units(theme.spacing.overlayAnchorGap),
          viewportInset: context.units(theme.spacing.overlayViewportInset),
        ),
        child: overlayBuilder(context),
      );
    },
    child: anchor,
  );
}

final class _AnchoredOverlayLayoutDelegate extends SingleChildLayoutDelegate {
  const _AnchoredOverlayLayoutDelegate({
    required this.anchor,
    required this.placement,
    required this.fallbackPlacements,
    required this.textDirection,
    required this.gap,
    required this.viewportInset,
  });

  final Rect anchor;
  final OverlayPlacement placement;
  final List<OverlayPlacement> fallbackPlacements;
  final TextDirection textDirection;
  final double gap;
  final double viewportInset;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          (constraints.maxWidth - viewportInset * 2)
              .clamp(0, constraints.maxWidth)
              .toDouble(),
          (constraints.maxHeight - viewportInset * 2)
              .clamp(0, constraints.maxHeight)
              .toDouble(),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      AnchoredOverlayPositioner.calculate(
        viewport: size,
        anchor: anchor,
        child: childSize,
        preferred: placement,
        fallbacks: fallbackPlacements,
        textDirection: textDirection,
        gap: gap,
        viewportInset: viewportInset,
      ).offset;

  @override
  bool shouldRelayout(_AnchoredOverlayLayoutDelegate oldDelegate) =>
      anchor != oldDelegate.anchor ||
      placement != oldDelegate.placement ||
      fallbackPlacements != oldDelegate.fallbackPlacements ||
      textDirection != oldDelegate.textDirection ||
      gap != oldDelegate.gap ||
      viewportInset != oldDelegate.viewportInset;
}
