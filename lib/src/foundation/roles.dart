import 'package:flutter/widgets.dart';

import 'icon_data.dart';

enum TypographyRole { display, title, body, label, caption }

enum TypographyEmphasis { regular, medium, strong }

enum ContentColorRole { primary, secondary, muted, inverse, disabled }

enum ActionColorRole {
  neutral,
  primary,
  utility,
  danger,
  warning,
  success,
  info,
}

enum ActionProminence { normal, ghost, outlined, low, high, filled }

enum ActionColorSlot { background, foreground, icon, border }

enum FeedbackColorRole { neutral, success, warning, danger, info }

enum ControlSize { xsmall, small, medium, large, xlarge }

enum IconSize { xsmall, small, medium, large, xlarge }

enum FieldSize { xsmall, small, medium, large, xlarge }

enum FieldAvailability { enabled, readOnly, disabled }

enum CheckboxValue { unchecked, checked, mixed }

enum SelectionColorRole {
  neutral,
  primary,
  utility,
  danger,
  warning,
  success,
  info,
}

enum OverlayPlacement {
  top,
  bottom,
  left,
  right,
  topStart,
  topEnd,
  bottomStart,
  bottomEnd,
}

enum TooltipDelay { immediate, short, long }

enum OptionsLoadState { ready, loading, failed }

enum ToastDuration { persistent, short, long }

enum DialogDismissPolicy { explicitOnly, escapeOnly, outsideAndEscape }

enum ShapeRole { none, rounded, circular }

@immutable
final class CarpenterShape {
  const CarpenterShape({required this.start, required this.end});

  static const none = CarpenterShape(
    start: ShapeRole.none,
    end: ShapeRole.none,
  );
  static const rounded = CarpenterShape(
    start: ShapeRole.rounded,
    end: ShapeRole.rounded,
  );
  static const circular = CarpenterShape(
    start: ShapeRole.circular,
    end: ShapeRole.circular,
  );

  final ShapeRole start;
  final ShapeRole end;
}

enum ContrastMode { standard, high }

enum CarpenterDensity { compact, normal }

enum ActionExecutionPhase { idle, running, succeeded, failed }

enum CarpenterActionIconPosition { leading, trailing }

@immutable
final class CarpenterActionDescriptor {
  const CarpenterActionDescriptor({
    required this.id,
    required this.label,
    required this.onInvoke,
    this.icon,
    this.semanticLabel,
    this.colorRole = ActionColorRole.neutral,
    this.shortcut,
  });

  final String id;
  final String label;
  final CarpenterIconSource? icon;
  final String? semanticLabel;
  final ActionColorRole colorRole;
  final ShortcutActivator? shortcut;
  final VoidCallback? onInvoke;

  bool get isEnabled => onInvoke != null;

  String get effectiveSemanticLabel => semanticLabel ?? label;
}

@immutable
final class CarpenterOption<T> {
  const CarpenterOption({
    required this.id,
    required this.value,
    required this.label,
    this.semanticLabel,
    this.enabled = true,
  });

  final Object id;
  final T value;
  final String label;
  final String? semanticLabel;
  final bool enabled;

  String get effectiveSemanticLabel => semanticLabel ?? label;
}
