import 'package:flutter/widgets.dart';

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
      IconData data => Icon(
        data,
        size: size,
        color: color,
        semanticLabel: semanticLabel,
      ),
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
}
