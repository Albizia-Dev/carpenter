import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import 'avatar.dart';

/// Identity data for one entry in a [CarpenterAvatarGroup], using an image
/// and/or initials.
@immutable
final class CarpenterAvatarItem {
  /// Creates an avatar entry. At least initials or an image must be supplied.
  const CarpenterAvatarItem({
    this.initials,
    this.foregroundImage,
    this.semanticLabel,
  }) : assert(initials != null || foregroundImage != null);

  /// Fallback initials displayed without a usable image.
  final String? initials;

  /// Optional identity image provider.
  final ImageProvider<Object>? foregroundImage;

  /// Optional accessible identity name, passed to the rendered avatar.
  final String? semanticLabel;
}

/// Compact overlapping identity group with an automatic overflow avatar.
final class CarpenterAvatarGroup extends StatelessWidget {
  /// Creates an overlapping group with a positive [maxVisible] count. An
  /// empty item list renders no content.
  const CarpenterAvatarGroup({
    super.key,
    required this.items,
    this.maxVisible = 4,
    this.size = const Rem(2.5),
    this.semanticLabel = 'Люди',
  }) : assert(maxVisible > 0);

  /// Identities in logical display order; only the first [maxVisible] are
  /// shown individually.
  final List<CarpenterAvatarItem> items;

  /// Maximum number of individual avatars before an additional "+N" overflow
  /// avatar; must be positive.
  final int maxVisible;

  /// Diameter of each individual and overflow avatar, resolved in the current
  /// unit context.
  final LengthUnit size;

  /// Accessible group name; defaults to "People".
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final extent = context.units(size);
    final visibleCount = items.length.clamp(0, maxVisible).toInt();
    final hiddenCount = items.length - visibleCount;
    final renderedCount = visibleCount + (hiddenCount > 0 ? 1 : 0);
    final step = extent * .68;
    final width = extent + (renderedCount - 1) * step;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    final avatars = <Widget>[
      for (var index = 0; index < visibleCount; index++)
        CarpenterAvatar(
          initials: items[index].initials,
          foregroundImage: items[index].foregroundImage,
          semanticLabel: items[index].semanticLabel,
          size: size,
        ),
      if (hiddenCount > 0)
        CarpenterAvatar(
          initials: '+$hiddenCount',
          semanticLabel: '$hiddenCount more people',
          size: size,
        ),
    ];

    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: SizedBox(
        width: width,
        height: extent,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var index = 0; index < avatars.length; index++)
              Positioned(
                left: rtl ? null : index * step,
                right: rtl ? index * step : null,
                child: avatars[index],
              ),
          ],
        ),
      ),
    );
  }
}
