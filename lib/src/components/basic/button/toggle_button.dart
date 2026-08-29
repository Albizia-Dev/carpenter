import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import 'button.dart';

/// Binary action button whose selected state is controlled by the caller.
final class CarpenterToggleButton extends StatelessWidget {
  const CarpenterToggleButton({
    super.key,
    required this.label,
    required this.checked,
    this.onChanged,
    this.icon,
    this.size = ControlSize.medium,
    this.colorRole = ActionColorRole.primary,
    this.semanticLabel,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool>? onChanged;
  final CarpenterIconSource? icon;
  final ControlSize size;
  final ActionColorRole colorRole;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    toggled: checked,
    child: CarpenterButton(
      label: label,
      semanticLabel: semanticLabel ?? label,
      icon: icon,
      size: size,
      colorRole: colorRole,
      prominence: checked ? ActionProminence.filled : ActionProminence.normal,
      onPressed: onChanged == null ? null : () => onChanged!(!checked),
    ),
  );
}
