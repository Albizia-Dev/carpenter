import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import 'button.dart';

/// Binary action button whose selected state is controlled by the caller.
final class CarpenterToggleButton extends StatelessWidget {
  /// Creates a caller-controlled binary action. Activation proposes the
  /// opposite [checked] value through [onChanged].
  const CarpenterToggleButton({
    super.key,
    required this.label,
    required this.checked,
    this.onChanged,
    this.icon,
    this.size = ControlSize.medium,
    this.colorRole = ActionColorRole.primary,
    this.shape = CarpenterShape.rounded,
    this.focusNode,
    this.semanticLabel,
  });

  /// Visible text naming the control or choice; keep it meaningful without
  /// relying on an icon.
  final String label;

  /// Current selected state; selected buttons use filled action prominence.
  final bool checked;

  /// Receives the proposed opposite state. Store it and rebuild to commit the
  /// change; null disables the button.
  final ValueChanged<bool>? onChanged;

  /// Optional icon rendered alongside the visible label using the action
  /// theme.
  final CarpenterIconSource? icon;

  /// Semantic control size, resolving coordinated height, spacing, icon, and
  /// typography metrics.
  final ControlSize size;

  /// Semantic action or selection color resolved from the current Carpenter
  /// theme.
  final ActionColorRole colorRole;

  /// Leading and trailing corner roles. Logical start/end follow text
  /// direction.
  final CarpenterShape shape;

  /// Optional caller-owned focus node. Dispose a supplied node in its owner,
  /// not in the widget.
  final FocusNode? focusNode;

  /// Accessible name supplied to assistive technology. When omitted, the
  /// visible label is used.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      toggled: checked,
      child: CarpenterButton(
        label: label,
        semanticLabel: semanticLabel ?? label,
        icon: icon,
        size: size,
        colorRole: colorRole,
        shape: shape,
        focusNode: focusNode,
        prominence: checked ? ActionProminence.filled : ActionProminence.normal,
        onPressed: onChanged == null ? null : () => onChanged!(!checked),
      ),
    ),
  );
}
