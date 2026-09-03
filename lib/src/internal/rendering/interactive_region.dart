import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef InteractiveRegionBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  bool showFocusHighlight,
);

final class InteractiveRegion extends StatefulWidget {
  const InteractiveRegion({
    super.key,
    required this.onActivate,
    required this.builder,
    this.onDoubleActivate,
    this.activationBlocked = false,
    this.handlesActivationShortcuts = true,
    this.includeFocusSemantics = true,
    this.shortcutCallbacks = const {},
    this.focusNode,
    this.autofocus = false,
  });

  final VoidCallback? onActivate;
  final VoidCallback? onDoubleActivate;
  final InteractiveRegionBuilder builder;
  final bool activationBlocked;
  final bool handlesActivationShortcuts;
  final bool includeFocusSemantics;
  final Map<ShortcutActivator, VoidCallback> shortcutCallbacks;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<InteractiveRegion> createState() => _InteractiveRegionState();
}

final class _InteractiveRegionState extends State<InteractiveRegion> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;
  bool _showFocusHighlight = false;

  bool get _enabled =>
      widget.onActivate != null || widget.onDoubleActivate != null;
  bool get _interactive => _enabled && !widget.activationBlocked;

  Set<WidgetState> get _states => <WidgetState>{
    if (_hovered && _interactive) WidgetState.hovered,
    if (_focused) WidgetState.focused,
    if (_pressed && _interactive) WidgetState.pressed,
    if (!_enabled) WidgetState.disabled,
  };

  void _setHover(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
  }

  void _setFocus(bool value) {
    if (_focused == value) return;
    setState(() => _focused = value);
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _activate() {
    if (_interactive) widget.onActivate?.call();
  }

  void _doubleActivate() {
    if (_interactive) widget.onDoubleActivate?.call();
  }

  @override
  void didUpdateWidget(InteractiveRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: _enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      includeFocusSemantics: widget.includeFocusSemantics,
      onFocusChange: _setFocus,
      onShowFocusHighlight: (value) {
        if (_showFocusHighlight == value) return;
        setState(() => _showFocusHighlight = value);
      },
      shortcuts:
          widget.handlesActivationShortcuts ||
              widget.shortcutCallbacks.isNotEmpty
          ? <ShortcutActivator, Intent>{
              if (widget.handlesActivationShortcuts) ...const {
                SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
                SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
              },
              for (final entry in widget.shortcutCallbacks.entries)
                entry.key: VoidCallbackIntent(entry.value),
            }
          : null,
      actions:
          widget.handlesActivationShortcuts ||
              widget.shortcutCallbacks.isNotEmpty
          ? <Type, Action<Intent>>{
              if (widget.handlesActivationShortcuts)
                ActivateIntent: CallbackAction<ActivateIntent>(
                  onInvoke: (_) {
                    _activate();
                    return null;
                  },
                ),
              if (widget.shortcutCallbacks.isNotEmpty)
                VoidCallbackIntent: VoidCallbackAction(),
            }
          : null,
      child: MouseRegion(
        cursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: _interactive ? (_) => _setHover(true) : null,
        onExit: _interactive ? (_) => _setHover(false) : null,
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _interactive ? (_) => _setPressed(true) : null,
          onPointerUp: _interactive ? (_) => _setPressed(false) : null,
          onPointerCancel: _interactive ? (_) => _setPressed(false) : null,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: _interactive && widget.onActivate != null ? _activate : null,
            onDoubleTap: _interactive && widget.onDoubleActivate != null
                ? _doubleActivate
                : null,
            child: widget.builder(context, _states, _showFocusHighlight),
          ),
        ),
      ),
    );
  }
}
