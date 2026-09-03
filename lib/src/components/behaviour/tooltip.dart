import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/anchored_overlay_host.dart';
import '../../internal/overlay/overlay_surface.dart';

/// Short, non-interactive supplemental text for an anchored control.
final class CarpenterTooltip extends StatefulWidget {
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
  final FocusNode _focusNode = FocusNode(canRequestFocus: false);
  Timer? _timer;
  var _visible = false;
  var _hovered = false;
  var _focused = false;
  var _longPressed = false;

  bool get _shouldShow => _hovered || _focused || _longPressed;

  void _schedule(bool visible, TooltipDelay delay) {
    _timer?.cancel();
    final duration = CarpenterTheme.of(
      context,
    ).motion.tooltipDelay(delay).toDuration();
    if (duration == Duration.zero) {
      _setVisible(visible);
    } else {
      _timer = Timer(duration, () {
        if (mounted && (visible ? _shouldShow : !_shouldShow)) {
          _setVisible(visible);
        }
      });
    }
  }

  void _setVisible(bool value) {
    _timer?.cancel();
    if (_visible == value) return;
    setState(() => _visible = value);
  }

  void _interestChanged() =>
      _schedule(_shouldShow, _shouldShow ? widget.showDelay : widget.hideDelay);

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnchoredOverlayHost(
    open: _visible,
    onOpenChanged: (open) {
      if (!open) _setVisible(false);
    },
    placement: widget.placement,
    dismissOnOutside: false,
    takeFocus: false,
    restoreFocus: false,
    anchor: Semantics(
      tooltip: widget.text,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) {
          _focused = focused;
          _interestChanged();
        },
        child: MouseRegion(
          onEnter: (_) {
            _hovered = true;
            _interestChanged();
          },
          onExit: (_) {
            _hovered = false;
            _interestChanged();
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: () {
              _longPressed = true;
              _schedule(true, TooltipDelay.immediate);
            },
            onLongPressUp: () {
              _longPressed = false;
              _interestChanged();
            },
            child: widget.child,
          ),
        ),
      ),
    ),
    overlayBuilder: (context) {
      final theme = CarpenterTheme.of(context);
      return IgnorePointer(
        child: Semantics(
          container: true,
          label: widget.text,
          liveRegion: true,
          child: OverlaySurface(
            kind: OverlaySurfaceKind.tooltip,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.units(theme.sizes.overlayTooltipMaxWidth),
              ),
              child: Text(
                widget.text,
                style: theme.typography
                    .tooltip(context, TypographyEmphasis.regular)
                    .copyWith(color: theme.overlay.tooltipForeground),
              ),
            ),
          ),
        ),
      );
    },
  );
}
