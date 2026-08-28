import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';

/// Determinate linear progress indicator. Value is clamped to 0..1.
final class CarpenterProgress extends StatelessWidget {
  const CarpenterProgress({super.key, required this.value, this.height = 4, this.semanticLabel = 'Progress'});

  final double value;
  final double height;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final normalized = value.clamp(0.0, 1.0).toDouble();
    final accent = theme.actions.resolve(
      ActionColorRole.primary,
      ActionProminence.high,
      const <WidgetState>{},
    ).background;
    return Semantics(
      label: semanticLabel,
      value: '${(normalized * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: SizedBox(
          height: height,
          child: ColoredBox(
            color: theme.surface.subtle,
            child: FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: normalized,
              child: ColoredBox(color: accent),
            ),
          ),
        ),
      ),
    );
  }
}
