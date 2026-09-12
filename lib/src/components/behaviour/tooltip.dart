import 'package:flutter/widgets.dart';
import '../../foundation/roles.dart';
import '../../internal/rendering/tooltip.dart';

/// Short, non-interactive supplemental text for an anchored control.
final class CarpenterTooltip extends StatefulWidget {
  /// Uses the shared pointer/focus lifecycle and overlay placement. Tooltip
  /// content supplements, rather than replaces, the child's accessible name.
  const CarpenterTooltip({
    super.key,
    required this.text,
    required this.child,
    this.placement = OverlayPlacement.top,
    this.showDelay = TooltipDelay.long,
    this.hideDelay = TooltipDelay.short,
  });
  final String text;
  final Widget child;
  final OverlayPlacement placement;
  final TooltipDelay showDelay;
  final TooltipDelay hideDelay;
  @override
  State<CarpenterTooltip> createState() => _CarpenterTooltipState();
}

final class _CarpenterTooltipState extends State<CarpenterTooltip> {
  @override
  Widget build(BuildContext context) => ActionTooltip(
    text: widget.text,
    child: widget.child,
    placement: widget.placement,
    showDelay: widget.showDelay,
    hideDelay: widget.hideDelay,
  );
}
