import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'icons.dart';
import 'text.dart';

/// Compact identity primitive for initials, images or arbitrary avatar content.
final class CarpenterAvatar extends StatelessWidget {
  const CarpenterAvatar({
    super.key,
    this.initials,
    this.child,
    this.foregroundImage,
    this.onForegroundImageError,
    this.size = 40,
    this.semanticLabel,
  }) : assert(initials != null || child != null || foregroundImage != null);

  final String? initials;
  final Widget? child;
  final ImageProvider<Object>? foregroundImage;
  final ImageErrorListener? onForegroundImageError;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final style = theme.actions.resolve(
      ActionColorRole.primary,
      ActionProminence.filled,
      const <WidgetState>{},
    );
    final fallback =
        child ??
        (initials != null
            ? CarpenterText.label(
                initials!,
                emphasis: TypographyEmphasis.strong,
                colorRole: ContentColorRole.inverse,
              )
            : Icon(
                CarpenterIcons.account,
                size: size * .52,
                color: style.foreground,
              ));

    final image = foregroundImage;
    final content = image == null
        ? Center(child: fallback)
        : Image(
            image: image,
            width: size,
            height: size,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) {
              onForegroundImageError?.call(error, stackTrace);
              return Center(child: fallback);
            },
          );

    return Semantics(
      image: true,
      label: semanticLabel ?? initials,
      child: SizedBox.square(
        dimension: size,
        child: ClipOval(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: style.background,
              shape: BoxShape.circle,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
