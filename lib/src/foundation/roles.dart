import 'package:flutter/widgets.dart';

import 'icon_data.dart';

/// Semantic typography family chosen independently from emphasis and color.
enum TypographyRole {
  /// Largest editorial or hero text intended for rare, high-priority headings.
  display,

  /// Section, page, or component heading text.
  title,

  /// Default prose and control-supporting text.
  body,

  /// Compact text used for field labels, controls, and terse metadata.
  label,

  /// Small supporting or secondary annotation text.
  caption,
}

/// Semantic weight applied within a [TypographyRole].
enum TypographyEmphasis {
  /// Normal weight for the selected typography role.
  regular,

  /// Moderately emphasized text without becoming the strongest variant.
  medium,

  /// Strongest text weight exposed by the semantic typography system.
  strong,
}

/// Semantic foreground color for non-action content.
enum ContentColorRole {
  /// Primary readable foreground for normal content.
  primary,

  /// Secondary foreground for supporting content.
  secondary,

  /// De-emphasized foreground for tertiary metadata or hints.
  muted,

  /// Foreground intended for use on an inverse or strongly colored surface.
  inverse,

  /// Foreground communicating unavailable or disabled content.
  disabled,
}

/// Semantic color family for interactive actions.
enum ActionColorRole {
  /// Neutral action without product or status emphasis.
  neutral,

  /// Primary product action.
  primary,

  /// Utility or tooling action that is useful but not the main task.
  utility,

  /// Destructive or dangerous action.
  danger,

  /// Cautionary action whose consequences deserve warning emphasis.
  warning,

  /// Action associated with a successful or positive outcome.
  success,

  /// Informational action without success, warning, or danger semantics.
  info,
}

/// Visual emphasis of an action, independent from its semantic color role.
enum ActionProminence {
  /// Default action treatment for the owning component or theme.
  normal,

  /// Minimal chrome, typically preserving only content until interaction emphasis.
  ghost,

  /// Bordered action without a filled semantic background.
  outlined,

  /// Deliberately low-emphasis action.
  low,

  /// High-emphasis action intended to stand out among peers.
  high,

  /// Explicit filled treatment using the action color family.
  filled,
}

/// Theme slot resolved for an action color family and prominence.
enum ActionColorSlot {
  /// Action surface/background color.
  background,

  /// Text and general foreground color.
  foreground,

  /// Icon foreground color when it differs from text.
  icon,

  /// Border or outline color.
  border,
}

/// Semantic color family for passive feedback and status presentation.
enum FeedbackColorRole {
  /// Neutral status without success, warning, danger, or information emphasis.
  neutral,

  /// Successful or completed status.
  success,

  /// Warning or caution status.
  warning,

  /// Error, failure, or dangerous status.
  danger,

  /// Informational status.
  info,
}

/// Semantic size scale used by compact controls.
enum ControlSize {
  /// Extra-small control size.
  xsmall,

  /// Small control size.
  small,

  /// Default medium control size.
  medium,

  /// Large control size.
  large,

  /// Extra-large control size.
  xlarge,
}

/// Semantic size scale used by icons.
enum IconSize {
  /// Extra-small icon size.
  xsmall,

  /// Small icon size.
  small,

  /// Default medium icon size.
  medium,

  /// Large icon size.
  large,

  /// Extra-large icon size.
  xlarge,
}

/// Semantic size scale used by fields and field-like controls.
enum FieldSize {
  /// Extra-small field size.
  xsmall,

  /// Small field size.
  small,

  /// Default medium field size.
  medium,

  /// Large field size.
  large,

  /// Extra-large field size.
  xlarge,
}

/// Interaction availability of an input field.
enum FieldAvailability {
  /// Editable and interactive field.
  enabled,

  /// Readable and focusable field whose value cannot be edited.
  readOnly,

  /// Unavailable field excluded from normal interaction.
  disabled,
}

/// Tri-state checkbox value.
enum CheckboxValue {
  /// Explicitly not selected.
  unchecked,

  /// Explicitly selected.
  checked,

  /// Mixed or indeterminate selection, commonly representing differing children.
  mixed,
}

/// Semantic color family for selection indicators and selected surfaces.
enum SelectionColorRole {
  /// Neutral selection without product or status emphasis.
  neutral,

  /// Primary product selection.
  primary,

  /// Utility/tooling selection.
  utility,

  /// Dangerous or destructive selection state.
  danger,

  /// Warning selection state.
  warning,

  /// Successful or positive selection state.
  success,

  /// Informational selection state.
  info,
}

/// Preferred placement of anchored overlay content relative to its anchor.
enum OverlayPlacement {
  /// Centered above the anchor.
  top,

  /// Centered below the anchor.
  bottom,

  /// Centered to the left of the anchor.
  left,

  /// Centered to the right of the anchor.
  right,

  /// Above the anchor aligned to its directional start edge.
  topStart,

  /// Above the anchor aligned to its directional end edge.
  topEnd,

  /// Below the anchor aligned to its directional start edge.
  bottomStart,

  /// Below the anchor aligned to its directional end edge.
  bottomEnd,
}

/// Semantic delay before tooltip presentation.
enum TooltipDelay {
  /// Show without an intentional delay.
  immediate,

  /// Use the theme's short tooltip delay.
  short,

  /// Use the theme's long tooltip delay.
  long,
}

/// Loading state for option-producing controls such as selects and suggestions.
enum OptionsLoadState {
  /// Options are available and no request is currently pending.
  ready,

  /// Options are currently being loaded.
  loading,

  /// The most recent options request failed.
  failed,
}

/// Semantic lifetime of transient toast feedback.
enum ToastDuration {
  /// Remain visible until explicitly dismissed or replaced.
  persistent,

  /// Use the short transient duration configured by the theme/surface.
  short,

  /// Use the long transient duration configured by the theme/surface.
  long,
}

/// Policy controlling which implicit gestures may dismiss a dialog.
enum DialogDismissPolicy {
  /// Only an explicit application action may dismiss the dialog.
  explicitOnly,

  /// Escape may dismiss the dialog, but outside interaction may not.
  escapeOnly,

  /// Both outside interaction and Escape may dismiss the dialog.
  outsideAndEscape,
}

/// Semantic endpoint shape used by grouped surfaces and controls.
enum ShapeRole {
  /// No rounded endpoint treatment.
  none,

  /// Theme-standard rounded endpoint.
  rounded,

  /// Fully circular or pill-like endpoint.
  circular,
}

/// Directional start/end shape descriptor for controls that may join a group.
@immutable
final class CarpenterShape {
  /// Creates a directional shape from independent [start] and [end] roles.
  const CarpenterShape({required this.start, required this.end});

  /// Shape with square/unrounded start and end roles.
  static const none = CarpenterShape(
    start: ShapeRole.none,
    end: ShapeRole.none,
  );

  /// Shape with theme-standard rounded start and end roles.
  static const rounded = CarpenterShape(
    start: ShapeRole.rounded,
    end: ShapeRole.rounded,
  );

  /// Shape with circular start and end roles.
  static const circular = CarpenterShape(
    start: ShapeRole.circular,
    end: ShapeRole.circular,
  );

  /// Shape role applied to the directional start endpoint.
  final ShapeRole start;

  /// Shape role applied to the directional end endpoint.
  final ShapeRole end;
}

/// Requested contrast level for semantic Carpenter colors.
enum ContrastMode {
  /// Standard contrast palette.
  standard,

  /// High-contrast palette intended to increase visual separation/readability.
  high,
}

/// Global density preference used by semantic sizing and spacing resolution.
enum CarpenterDensity {
  /// Reduced spacing and control dimensions for dense interfaces.
  compact,

  /// Default spacing and control dimensions.
  normal,
}

/// Presentation phase of an asynchronous or externally tracked action.
enum ActionExecutionPhase {
  /// No operation is currently represented.
  idle,

  /// Operation is in progress.
  running,

  /// Most recent operation completed successfully.
  succeeded,

  /// Most recent operation failed.
  failed,
}

/// Position of an action icon relative to its label.
enum CarpenterActionIconPosition {
  /// Place the icon before the label in reading order.
  leading,

  /// Place the icon after the label in reading order.
  trailing,
}

/// Immutable application action metadata used by Carpenter surfaces to project
/// consistent label, icon, availability, semantics, shortcut, and invocation.
@immutable
final class CarpenterActionDescriptor {
  /// Creates an action descriptor. A leaf with `null` [onInvoke] is unavailable.
  /// Nonempty [children] instead define a group, preserving the same identity
  /// and presentation metadata when it moves between toolbar and menu.
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
    this.toggled,
    this.children = const [],
  });

  /// Creates a nested action group. Activating it opens its visible children;
  /// it never executes a command. Empty groups, or groups with no available
  /// descendants, are disabled. IDs must be unique within each sibling level.
  const CarpenterActionDescriptor.group({
    required String id,
    required String label,
    required List<CarpenterActionDescriptor> children,
    CarpenterIconSource? icon,
    bool visible = true,
    String? semanticLabel,
  }) : this(
         id: id,
         label: label,
         onInvoke: null,
         children: children,
         icon: icon,
         visible: visible,
         semanticLabel: semanticLabel,
       );

  /// Nested actions, rendered as a submenu by menus and action strips.
  /// A nonempty list takes precedence over [onInvoke]. Callers own this tree
  /// and rebuild it when availability or controlled toggle values change.
  final List<CarpenterActionDescriptor> children;

  /// Creates a controlled switch action. Activation proposes the opposite
  /// [value]; callers commit it by rebuilding. Off uses the neutral role, on
  /// uses [colorRole], in buttons, icon buttons and overflow menus alike.
  factory CarpenterActionDescriptor.toggle({
    required String id,
    required String label,
    required bool value,
    required ValueChanged<bool>? onChanged,
    CarpenterIconSource? icon,
    String? semanticLabel,
    ActionColorRole colorRole = ActionColorRole.primary,
    ShortcutActivator? shortcut,
    bool visible = true,
    String? disabledReason,
  }) => CarpenterActionDescriptor(
    id: id,
    label: label,
    toggled: value,
    onInvoke: onChanged == null ? null : () => onChanged(!value),
    icon: icon,
    semanticLabel: semanticLabel,
    colorRole: colorRole,
    shortcut: shortcut,
    visible: visible,
    disabledReason: disabledReason,
  );

  /// Controlled switch state: null is an ordinary action, false uses neutral,
  /// and true uses [colorRole]. Activation remains owned by [onInvoke].
  final bool? toggled;

  /// Stable application-defined action identity.
  final String id;

  /// Visible human-readable action label.
  final String label;

  /// Optional icon rendered by surfaces that support action icons.
  final CarpenterIconSource? icon;

  /// Optional accessible action name when [label] is not the correct semantic name.
  final String? semanticLabel;

  /// Semantic action color family. It does not choose prominence or placement.
  final ActionColorRole colorRole;

  /// Optional keyboard shortcut metadata for surfaces that choose to expose or bind it.
  final ShortcutActivator? shortcut;

  /// Logical visibility independent of how a surface presents this action.
  final bool visible;

  /// Optional application reason for an unavailable action.
  ///
  /// Surfaces may expose this through accessibility or explanatory UI without
  /// treating it as presentation configuration on the descriptor itself.
  final String? disabledReason;

  /// Synchronous invocation callback; `null` means the action is unavailable.
  final VoidCallback? onInvoke;

  /// Whether a leaf can invoke, or a group has an available visible descendant.
  bool get isEnabled => children.isNotEmpty
      ? children.any((child) => child.visible && child.isEnabled)
      : onInvoke != null;

  /// Accessible action name, falling back to the visible [label].
  String get effectiveSemanticLabel => semanticLabel ?? label;
}

/// Immutable selectable option with stable identity, value, display text,
/// accessibility label, and availability.
@immutable
final class CarpenterOption<T> {
  /// Creates an option whose [id] remains stable independently from its display
  /// label and generic [value].
  const CarpenterOption({
    required this.id,
    required this.value,
    required this.label,
    this.semanticLabel,
    this.enabled = true,
  });

  /// Stable option identity used for comparison and controlled selection.
  final Object id;

  /// Application value represented by this option.
  final T value;

  /// Visible option label.
  final String label;

  /// Optional accessible option name when [label] is insufficient.
  final String? semanticLabel;

  /// Whether the option may be selected or activated.
  final bool enabled;

  /// Accessible option name, falling back to the visible [label].
  String get effectiveSemanticLabel => semanticLabel ?? label;
}
