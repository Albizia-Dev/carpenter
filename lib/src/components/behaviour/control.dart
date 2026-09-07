import 'package:flutter/widgets.dart';

import '../../internal/rendering/interactive_region.dart';

/// Public snapshot of the shared Carpenter interaction state.
final class CarpenterControlState {
  const CarpenterControlState({
    required this.enabled,
    required this.hovered,
    required this.focused,
    required this.pressed,
  });

  final bool enabled;
  final bool hovered;
  final bool focused;
  final bool pressed;
}

typedef CarpenterControlBuilder = Widget Function(
  BuildContext context,
  CarpenterControlState state,
);

/// Behaviour-only primitive for custom interactive Carpenter components.
///
/// It exposes the same pointer, focus and keyboard interaction machinery used
/// by built-in controls without forcing consumers to reimplement it.
final class CarpenterControl extends StatelessWidget {
  const CarpenterControl({
    super.key,
    required this.builder,
    this.onTap,
    this.enabled = true,
    this.semanticLabel,
    this.semanticButton = true,
    this.semanticChecked,
    this.semanticToggled,
    this.semanticSelected,
    this.semanticLink = false,
    this.focusNode,
    this.autofocus = false,
  });

  final CarpenterControlBuilder builder;
  final VoidCallback? onTap;
  final bool enabled;
  final String? semanticLabel;
  final bool semanticButton;
  final bool? semanticChecked;
  final bool? semanticToggled;
  final bool? semanticSelected;
  final bool semanticLink;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final interactive = enabled && onTap != null;
    return Semantics(
      button: semanticButton,
      checked: semanticChecked,
      toggled: semanticToggled,
      selected: semanticSelected,
      link: semanticLink,
      enabled: interactive,
      label: semanticLabel,
      onTap: interactive ? onTap : null,
      child: InteractiveRegion(
        onActivate: interactive ? onTap : null,
        focusNode: focusNode,
        autofocus: autofocus,
        builder: (context, states, _) => builder(
          context,
          CarpenterControlState(
            enabled: interactive,
            hovered: states.contains(WidgetState.hovered),
            focused: states.contains(WidgetState.focused),
            pressed: states.contains(WidgetState.pressed),
          ),
        ),
      ),
    );
  }
}
