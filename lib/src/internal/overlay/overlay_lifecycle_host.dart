import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef OverlayLifecycleBuilder = Widget Function(
  BuildContext context,
  OverlayChildLayoutInfo info,
  VoidCallback dismiss,
);

final class OverlayLifecycleHost extends StatefulWidget {
  const OverlayLifecycleHost({
    super.key,
    required this.open,
    required this.onOpenChanged,
    required this.child,
    required this.overlayBuilder,
    this.dismissOnOutside = true,
    this.dismissOnEscape = true,
    this.takeFocus = true,
    this.restoreFocus = true,
    this.modal = false,
    this.trapFocus = false,
    this.allowChildInteraction = false,
    this.initialFocusNode,
    this.scrimColor,
  });

  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final Widget child;
  final OverlayLifecycleBuilder overlayBuilder;
  final bool dismissOnOutside;
  final bool dismissOnEscape;
  final bool takeFocus;
  final bool restoreFocus;
  final bool modal;
  final bool trapFocus;
  final bool allowChildInteraction;
  final FocusNode? initialFocusNode;
  final Color? scrimColor;

  @override
  State<OverlayLifecycleHost> createState() => _OverlayLifecycleHostState();
}

final class _OverlayLifecycleHostState extends State<OverlayLifecycleHost> {
  final OverlayPortalController _controller = OverlayPortalController();
  final FocusScopeNode _overlayFocusScope = FocusScopeNode();
  FocusNode? _previousFocus;
  var _dismissRequested = false;

  @override
  void initState() {
    super.initState();
    _scheduleSync();
  }

  @override
  void didUpdateWidget(OverlayLifecycleHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.open != widget.open) {
      _dismissRequested = false;
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.open ? _show() : _hide();
    });
  }

  void _show() {
    if (_controller.isShowing) return;
    _previousFocus = FocusManager.instance.primaryFocus;
    _controller.show();
    if (!widget.takeFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.open) return;
      final initial = widget.initialFocusNode;
      if (initial?.canRequestFocus ?? false) {
        initial!.requestFocus();
      } else {
        _overlayFocusScope.requestFocus();
      }
    });
  }

  void _hide() {
    if (!_controller.isShowing) return;
    _controller.hide();
    if (widget.restoreFocus) {
      final previous = _previousFocus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (previous?.canRequestFocus ?? false) previous!.requestFocus();
      });
    }
    _previousFocus = null;
  }

  void _dismiss() {
    if (_dismissRequested || !widget.open) return;
    _dismissRequested = true;
    widget.onOpenChanged(false);
  }

  KeyEventResult _trapKey(FocusNode node, KeyEvent event) {
    if (!widget.trapFocus ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    final descendants = _overlayFocusScope.descendants
        .where((node) => node.canRequestFocus && !node.skipTraversal)
        .toList(growable: false);
    if (descendants.isEmpty) return KeyEventResult.handled;
    final current = FocusManager.instance.primaryFocus;
    final index = current == null ? -1 : descendants.indexOf(current);
    final backwards = HardwareKeyboard.instance.isShiftPressed;
    final next = index < 0
        ? (backwards ? descendants.length - 1 : 0)
        : backwards
        ? (index - 1 + descendants.length) % descendants.length
        : (index + 1) % descendants.length;
    descendants[next].requestFocus();
    return KeyEventResult.handled;
  }

  @override
  void dispose() {
    if (_controller.isShowing) {
      _controller.hide();
      if (widget.restoreFocus && (_previousFocus?.canRequestFocus ?? false)) {
        _previousFocus!.requestFocus();
      }
    }
    _overlayFocusScope.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.dismissOnEscape && widget.open
        ? CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
            },
            child: widget.child,
          )
        : widget.child;
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: _controller,
      child: child,
      overlayChildBuilder: (context, info) {
        final childRect = widget.allowChildInteraction
            ? MatrixUtils.transformRect(
                info.childPaintTransform,
                Offset.zero & info.childSize,
              )
            : null;
        Widget foreground = FocusScope(
          node: _overlayFocusScope,
          autofocus: widget.takeFocus,
          onKeyEvent: _trapKey,
          child: widget.overlayBuilder(context, info, _dismiss),
        );
        if (widget.dismissOnEscape) {
          foreground = CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): _dismiss,
            },
            child: foreground,
          );
        }
        return SizedBox.fromSize(
          size: info.overlaySize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.modal || widget.dismissOnOutside)
                Positioned.fill(
                  child: _OutsideDismissBarrier(
                    passthrough: childRect,
                    child: Semantics(
                      container: widget.modal,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: widget.dismissOnOutside
                            ? (_) => _dismiss()
                            : null,
                        child: widget.scrimColor == null
                            ? null
                            : ColoredBox(color: widget.scrimColor!),
                      ),
                    ),
                  ),
                ),
              foreground,
            ],
          ),
        );
      },
    );
  }
}

final class _OutsideDismissBarrier extends SingleChildRenderObjectWidget {
  const _OutsideDismissBarrier({required this.passthrough, super.child});

  final Rect? passthrough;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _OutsideDismissRenderBox(passthrough);

  @override
  void updateRenderObject(
    BuildContext context,
    _OutsideDismissRenderBox renderObject,
  ) {
    renderObject.passthrough = passthrough;
  }
}

final class _OutsideDismissRenderBox extends RenderProxyBox {
  _OutsideDismissRenderBox(this._passthrough);

  Rect? _passthrough;

  set passthrough(Rect? value) {
    if (_passthrough == value) return;
    _passthrough = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_passthrough?.contains(position) ?? false) return false;
    return super.hitTest(result, position: position);
  }
}
