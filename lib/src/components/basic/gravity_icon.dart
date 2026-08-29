import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import 'icon.dart';

/// A reference to one SVG from Carpenter's bundled Gravity icon set.
@immutable
final class GravityIconData extends CarpenterIconData {
  const GravityIconData(this.name);

  /// Kebab-case icon name without the `.svg` suffix.
  final String name;

  /// Asset path inside the Carpenter package.
  String get assetPath => 'assets/icons/gravity/$name.svg';

  @override
  Widget buildIcon(
    BuildContext context, {
    required double size,
    required Color color,
    String? semanticLabel,
  }) {
    return SvgPicture.asset(
      assetPath,
      package: 'carpenter',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }

  @override
  String toString() => 'GravityIconData($name)';
}

/// Compatibility wrapper around the generic [CarpenterIcon] renderer.
final class GravityIcon extends StatelessWidget {
  const GravityIcon(
    this.icon, {
    super.key,
    this.size = IconSize.medium,
    this.colorRole = ContentColorRole.primary,
    this.semanticLabel,
  });

  final GravityIconData icon;
  final IconSize size;
  final ContentColorRole colorRole;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => CarpenterIcon(
    icon,
    size: size,
    colorRole: colorRole,
    semanticLabel: semanticLabel,
  );
}
