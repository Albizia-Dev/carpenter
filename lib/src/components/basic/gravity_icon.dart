import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// A reference to one SVG from Carpenter's bundled Gravity icon set.
@immutable
final class GravityIconData {
  const GravityIconData(this.name);

  /// Kebab-case icon name without the `.svg` suffix.
  final String name;

  /// Asset path inside the Carpenter package.
  String get assetPath => 'assets/icons/gravity/$name.svg';

  @override
  String toString() => 'GravityIconData($name)';
}

/// Renders a bundled Gravity UI SVG using Carpenter's semantic icon sizing and
/// content colors.
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
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final resolvedSize = context.units(theme.sizes.icon(size));
    final color = theme.content.resolve(colorRole);

    return SvgPicture.asset(
      icon.assetPath,
      package: 'carpenter',
      width: resolvedSize,
      height: resolvedSize,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
    );
  }
}
