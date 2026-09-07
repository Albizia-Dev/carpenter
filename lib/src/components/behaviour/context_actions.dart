import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/anchored_overlay_positioner.dart';
import 'menu/menu.dart';
import 'menu/menu_entry.dart';

/// Input source that requested a contextual action surface.
enum CarpenterContextActionTrigger {
  /// A secondary pointer button requested contextual actions.
  pointerSecondary,

  /// A touch or pointer long-press requested contextual actions.
  longPress,
}

/// Makes one semantic action set available through platform-appropriate
/// alternative gestures.
///
/// A secondary pointer press and a touch long-press both open the same
/// [CarpenterMenu]. Callers provide semantic [CarpenterActionDescriptor]s and
/// do not need to branch on mouse versus touch input.
///
/// The region owns only the transient menu overlay. It does not own action
/// availability, selection, or command execution state. Disposing the region
/// dismisses any menu it opened.
final class CarpenterContextActionRegion extends StatefulWidget {
  const CarpenterContextActionRegion({
    super.key,
    required this.actions,
    required this.child,
    this.semanticLabel = 'Context actions',
    this.onOpen,
  });

  /// Semantic actions exposed by the contextual surface.
  ///
  /// Invisible descriptors are omitted and disabled descriptors retain their
  /// normal disabled presentation and invocation semantics.
  final List<CarpenterActionDescriptor> actions;

  /// Content that receives the secondary-press and long-press gestures.
  final Widget child;

  /// Accessibility label announced for the opened contextual menu.
  final String semanticLabel;

  /// Reports which input source opened the menu.
  ///
  /// This callback is informational. Invocation remains owned by the supplied
  /// [actions], and dismissing the overlay does not invoke this callback again.
  final ValueChanged<CarpenterContextActionTrigger>? onOpen;

  @override
  State<CarpenterContextActionRegion> createState() =>
      _CarpenterContextActionRegionState();
}

final class _CarpenterContextActionRegionState
    extends State<CarpenterContextActionRegion> {
  OverlayEntry? _entry;

  List<CarpenterActionDescriptor> get _visibleActions =>
      widget.actions.where((action) => action.visible).toList(growable: false);

  @override
  void didUpdateWidget(CarpenterContextActionRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_entry != null && oldWidget.actions != widget.actions) {
      _entry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  void _show(Offset globalPosition, CarpenterContextActionTrigger trigger) {
    if (_visibleActions.isEmpty) return;
    _close();

    final overlay = Overlay.of(context, rootOverlay: true);
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !overlayBox.hasSize) return;

    final point = overlayBox.globalToLocal(globalPosition);
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.overlayAnchorGap);
    final inset = context.units(theme.spacing.overlayViewportInset);
    final anchor = Rect.fromLTWH(point.dx, point.dy, 0, 0);

    _entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
            onSecondaryTap: _close,
            child: const SizedBox.expand(),
          ),
          CustomSingleChildLayout(
            delegate: _ContextActionMenuLayoutDelegate(
              anchor: anchor,
              gap: gap,
              viewportInset: inset,
              textDirection: Directionality.of(overlayContext),
            ),
            child: CarpenterMenu(
              items: [
                for (final action in _visibleActions)
                  CarpenterMenuItem(action: action),
              ],
              onDismissRequested: _close,
              semanticLabel: widget.semanticLabel,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    widget.onOpen?.call(trigger);
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
  }

  @override
  Widget build(BuildContext context) {
    if (_visibleActions.isEmpty) return widget.child;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onSecondaryTapDown: (details) => _show(
        details.globalPosition,
        CarpenterContextActionTrigger.pointerSecondary,
      ),
      onLongPressStart: (details) => _show(
        details.globalPosition,
        CarpenterContextActionTrigger.longPress,
      ),
      child: widget.child,
    );
  }
}

final class _ContextActionMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _ContextActionMenuLayoutDelegate({
    required this.anchor,
    required this.gap,
    required this.viewportInset,
    required this.textDirection,
  });

  final Rect anchor;
  final double gap;
  final double viewportInset;
  final TextDirection textDirection;

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
        preferred: OverlayPlacement.bottomStart,
        textDirection: textDirection,
        gap: gap,
        viewportInset: viewportInset,
        fallbacks: const [
          OverlayPlacement.topStart,
          OverlayPlacement.bottomEnd,
          OverlayPlacement.topEnd,
        ],
      ).offset;

  @override
  bool shouldRelayout(_ContextActionMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.gap != gap ||
      oldDelegate.viewportInset != viewportInset ||
      oldDelegate.textDirection != textDirection;
}
