import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'icon_data.dart';

enum ActionColorRole { neutral, primary, utility, danger, warning, success, info }

enum ActionProminence { ghost, normal, high, filled, outlined }

enum ControlSize { xsmall, small, medium, large, xlarge }

enum IconSize { xsmall, small, medium, large, xlarge }

enum FieldSize { xsmall, small, medium, large, xlarge }

enum FieldAvailability { enabled, readOnly, disabled }

enum ContentColorRole { primary, secondary, muted, inverse, disabled }

enum FeedbackColorRole { neutral, success, warning, danger, info }

enum SelectionColorRole { neutral, primary, utility, danger, warning, success, info }

enum TypographyRole { display, title, body, label, caption }

enum TypographyEmphasis { regular, medium, strong }

enum ShapeRole { none, roundedXsmall, roundedSmall, rounded, roundedLarge, roundedXlarge, circular }

@immutable
final class CarpenterShape {
  const CarpenterShape({required this.start, required this.end});

  const CarpenterShape.uniform(ShapeRole role) : start = role, end = role;

  static const none = CarpenterShape.uniform(ShapeRole.none);
  static const roundedXsmall = CarpenterShape.uniform(ShapeRole.roundedXsmall);
  static const roundedSmall = CarpenterShape.uniform(ShapeRole.roundedSmall);
  static const rounded = CarpenterShape.uniform(ShapeRole.rounded);
  static const roundedLarge = CarpenterShape.uniform(ShapeRole.roundedLarge);
  static const roundedXlarge = CarpenterShape.uniform(ShapeRole.roundedXlarge);
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
    this.visible = true,
    this.disabledReason,
  });

  final String id;
  final String label;
  final CarpenterIconSource? icon;
  final String? semanticLabel;
  final ActionColorRole colorRole;
  final ShortcutActivator? shortcut;

  /// Logical visibility independent of how a surface presents this action.
  final bool visible;

  /// Optional application reason for an unavailable action.
  ///
  /// Surfaces may expose this through accessibility or explanatory UI without
  /// treating it as presentation configuration on the descriptor itself.
  final String? disabledReason;

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
