import 'package:carpenter_units/carpenter_units.dart';
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
    this.size = const Rem(2.5),
    this.semanticLabel,
  }) : assert(initials != null || child != null || foregroundImage != null);

  final String? initials;
  final Widget? child;
  final ImageProvider<Object>? foregroundImage;
  final ImageErrorListener? onForegroundImageError;
  final LengthUnit size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extent = context.units(size);
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
                size: extent * .52,
                color: style.foreground,
              ));

    final image = foregroundImage;
    final content = image == null
        ? Center(child: fallback)
        : Image(
            image: image,
            width: extent,
            height: extent,
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
        dimension: extent,
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
