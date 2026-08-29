import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/icon_renderer.dart';

final class CarpenterIcon extends StatelessWidget {
  const CarpenterIcon(
    this.icon, {
    super.key,
    this.size = IconSize.medium,
    this.colorRole = ContentColorRole.primary,
    this.semanticLabel,
  });

  final CarpenterIconSource icon;
  final IconSize size;
  final ContentColorRole colorRole;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return IconRenderer(
      icon: icon,
      size: context.units(theme.sizes.icon(size)),
      color: theme.content.resolve(colorRole),
      semanticLabel: semanticLabel,
    );
  }
}
