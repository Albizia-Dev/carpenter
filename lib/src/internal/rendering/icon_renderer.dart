import 'package:flutter/widgets.dart';

import '../../components/basic/gravity_icons.g.dart';
import '../../components/basic/icons.dart';
import '../../foundation/icon_data.dart';

/// Internal renderer for every Carpenter icon slot.
final class IconRenderer extends StatelessWidget {
  const IconRenderer({
    super.key,
    required this.icon,
    required this.size,
    required this.color,
    this.semanticLabel,
  });

  final CarpenterIconSource icon;
  final double size;
  final Color color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return switch (icon) {
      IconData data => _buildFrameworkIcon(context, data),
      CarpenterIconData data => data.buildIcon(
        context,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
      _ => throw ArgumentError.value(
        icon,
        'icon',
        'Expected IconData or CarpenterIconData.',
      ),
    };
  }

  Widget _buildFrameworkIcon(BuildContext context, IconData data) {
    final gravity = switch (data) {
      CarpenterIcons.back => GravityIcons.chevronLeft,
      CarpenterIcons.next => GravityIcons.chevronRight,
      CarpenterIcons.refresh => GravityIcons.arrowRotateRight,
      CarpenterIcons.restore => GravityIcons.arrowRotateLeft,
      CarpenterIcons.download => GravityIcons.arrowDown,
      CarpenterIcons.upload => GravityIcons.arrowUp,
      CarpenterIcons.arrowDownFilled => GravityIcons.arrowDown,
      CarpenterIcons.arrowUpRight => GravityIcons.arrowUpRight,
      CarpenterIcons.sortDown => GravityIcons.arrowDown,
      CarpenterIcons.sortUp => GravityIcons.arrowUp,
      CarpenterIcons.search => GravityIcons.magnifier,
      CarpenterIcons.clear => GravityIcons.xmark,
      CarpenterIcons.add => GravityIcons.plus,
      CarpenterIcons.edit => GravityIcons.pencil,
      CarpenterIcons.archive => GravityIcons.archive,
      CarpenterIcons.file => GravityIcons.file,
      CarpenterIcons.more => GravityIcons.ellipsis,
      _ => null,
    };
    if (gravity != null) {
      return gravity.buildIcon(
        context,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      );
    }
    return Icon(data, size: size, color: color, semanticLabel: semanticLabel);
  }
}
