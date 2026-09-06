import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'icons.dart';
import 'text.dart';

/// Compact identity primitive for initials, images or arbitrary avatar content.
final class CarpenterAvatar extends StatelessWidget {
  /// Creates a circular identity preview. At least one of [initials],
  /// [child], or [foregroundImage] must be supplied.
  const CarpenterAvatar({
    super.key,
    this.initials,
    this.child,
    this.foregroundImage,
    this.onForegroundImageError,
    this.size = const Rem(2.5),
    this.semanticLabel,
  }) : assert(initials != null || child != null || foregroundImage != null);

  /// Text fallback when no custom child is supplied; also the default
  /// accessible name.
  final String? initials;

  /// Custom fallback content, preferred over initials when the image is
  /// absent or fails.
  final Widget? child;

  /// Optional image shown with cover fit. Image errors fall back to the
  /// child, initials, or account icon.
  final ImageProvider<Object>? foregroundImage;

  /// Receives image-loading errors before fallback content is rendered.
  final ImageErrorListener? onForegroundImageError;

  /// Avatar diameter resolved through the current unit context; defaults to
  /// 2.5 rem.
  final LengthUnit size;

  /// Accessible identity name; defaults to initials when supplied.
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
