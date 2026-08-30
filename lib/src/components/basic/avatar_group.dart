import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import 'avatar.dart';

@immutable
final class CarpenterAvatarItem {
  const CarpenterAvatarItem({
    this.initials,
    this.foregroundImage,
    this.semanticLabel,
  }) : assert(initials != null || foregroundImage != null);

  final String? initials;
  final ImageProvider<Object>? foregroundImage;
  final String? semanticLabel;
}

/// Compact overlapping identity group with an automatic overflow avatar.
final class CarpenterAvatarGroup extends StatelessWidget {
  const CarpenterAvatarGroup({
    super.key,
    required this.items,
    this.maxVisible = 4,
    this.size = const Rem(2.5),
    this.semanticLabel = 'People',
  }) : assert(maxVisible > 0);

  final List<CarpenterAvatarItem> items;
  final int maxVisible;
  final LengthUnit size;
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
