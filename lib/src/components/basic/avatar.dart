import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'text.dart';

/// Compact identity primitive for initials or arbitrary avatar content.
final class CarpenterAvatar extends StatelessWidget {
  const CarpenterAvatar({
    super.key,
    this.initials,
    this.child,
    this.size = 40,
    this.semanticLabel,
  }) : assert(initials != null || child != null);

  final String? initials;
  final Widget? child;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = theme.actions.resolve(
      ActionColorRole.primary,
      ActionProminence.high,
      const <WidgetState>{},
    );
    return Semantics(
      image: true,
      label: semanticLabel ?? initials,
      child: SizedBox.square(
        dimension: size,
        child: DecoratedBox(
          decoration: BoxDecoration(color: style.background, shape: BoxShape.circle),
          child: Center(
            child: child ??
                CarpenterText.label(
                  initials!,
                  emphasis: TypographyEmphasis.strong,
                  colorRole: ContentColorRole.inverse,
                ),
          ),
        ),
      ),
    );
  }
}
