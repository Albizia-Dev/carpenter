import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/theme.dart';

final class FocusRing extends StatelessWidget {
  const FocusRing({
    super.key,
    required this.visible,
    required this.borderRadius,
    required this.child,
  });

  final bool visible;
  final BorderRadiusGeometry borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.focus.gap);
    final width = context.units(theme.focus.width);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius.add(BorderRadius.circular(gap)),
        border: Border.all(
          color: visible ? theme.focus.color : theme.actions.transparent,
          width: width,
        ),
      ),
      child: Padding(padding: EdgeInsets.all(gap), child: child),
    );
  }
}
