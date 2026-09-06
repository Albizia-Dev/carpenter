import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import 'icon.dart';

/// A reference to one SVG from Carpenter's bundled Gravity icon set.
@immutable
final class GravityIconData extends CarpenterIconData {
  /// References a kebab-case name in the bundled Gravity SVG assets, without
  /// an .svg suffix. Construction does not validate that the asset exists.
  const GravityIconData(this.name);

  /// Kebab-case icon name without the `.svg` suffix.
  final String name;

  /// Asset path inside the Carpenter package.
  String get assetPath => 'assets/icons/gravity/$name.svg';

  /// Loads the SVG from the carpenter package at the requested logical-pixel
  /// width and height. Applies color with a source-in filter and forwards
  /// semanticLabel to the SVG renderer.
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

  /// Returns the stored asset name in a diagnostic GravityIconData
  /// representation; this is not an asset path.
  @override
  String toString() => 'GravityIconData($name)';
}

/// Compatibility wrapper around the generic [CarpenterIcon] renderer.
final class GravityIcon extends StatelessWidget {
  /// Renders one bundled SVG through CarpenterIcon, using semantic size and
  /// color roles rather than hard-coded dimensions or colors.
  const GravityIcon(
    this.icon, {
    super.key,
    this.size = IconSize.medium,
    this.colorRole = ContentColorRole.primary,
    this.semanticLabel,
  });

  /// Bundled SVG reference to render. Prefer constants from GravityIcons
  /// rather than constructing asset names that may not exist.
  final GravityIconData icon;

  /// Icon sizing role resolved by the surrounding Carpenter theme; defaults
  /// to medium.
  final IconSize size;

  /// Semantic content color resolved by CarpenterIcon; defaults to primary.
  final ContentColorRole colorRole;

  /// Accessible description of a meaningful icon. Null leaves the SVG without
  /// an explicit label; avoid repeating a visible parent label.
  final String? semanticLabel;

  /// Delegates to CarpenterIcon so SVG rendering uses the same theme roles
  /// and semantics as other Carpenter icon sources.
  @override
  Widget build(BuildContext context) => CarpenterIcon(
    icon,
    size: size,
    colorRole: colorRole,
    semanticLabel: semanticLabel,
  );
}
