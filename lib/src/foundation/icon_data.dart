import 'package:flutter/widgets.dart';

/// Value accepted by Carpenter icon slots.
///
/// Carpenter accepts Flutter [IconData] directly and custom icon sources that
/// extend [CarpenterIconData]. Dart has no union types, so this alias keeps the
/// public API readable while the renderer validates the concrete value.
typedef CarpenterIconSource = Object;

/// Base contract for non-Flutter icon sources rendered by Carpenter.
@immutable
abstract class CarpenterIconData {
  const CarpenterIconData();

  /// Builds the icon at an already-resolved logical size and color.
  Widget buildIcon(
    BuildContext context, {
    required double size,
    required Color color,
    String? semanticLabel,
  });
}
