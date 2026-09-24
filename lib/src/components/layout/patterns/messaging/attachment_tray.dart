import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/icon_data.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import 'messaging_models.dart';

/// Horizontal, fixed-size attachment previews owned by the composer.
final class CarpenterComposerAttachmentTray extends StatelessWidget {
  const CarpenterComposerAttachmentTray({
    super.key,
    required this.items,
    this.onRemoved,
  });

  final List<CarpenterMediaView> items;
  final ValueChanged<String>? onRemoved;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return SizedBox(
      height: context.units(theme.sizes.tableColumn),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (context, index) {
          final item = items[index];
          return SizedBox(
            key: ValueKey('composer-attachment-${item.id}'),
            width: context.units(theme.sizes.tableColumn),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surface.subtle,
                borderRadius: BorderRadius.circular(
                  context.units(theme.shapes.radius(ShapeRole.rounded)),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(gap),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CarpenterIcon(
                          _mediaIcon(item.kind),
                          semanticLabel: _mediaLabel(item.kind),
                          size: IconSize.small,
                        ),
                        SizedBox(width: gap),
                        Expanded(
                          child: CarpenterText.label(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CarpenterIconButton(
                          icon: GravityIcons.xmark,
                          semanticLabel: 'Убрать ${item.label}',
                          size: ControlSize.small,
                          prominence: ActionProminence.ghost,
                          onPressed: onRemoved == null
                              ? null
                              : () => onRemoved!(item.id),
                        ),
                      ],
                    ),
                    CarpenterText.caption(
                      _bytes(item.byteLength),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static CarpenterIconSource _mediaIcon(CarpenterMediaKind kind) =>
      switch (kind) {
        CarpenterMediaKind.image => GravityIcons.picture,
        CarpenterMediaKind.video ||
        CarpenterMediaKind.videoCircle => GravityIcons.video,
        CarpenterMediaKind.audio ||
        CarpenterMediaKind.voice => GravityIcons.musicNote,
        CarpenterMediaKind.file => GravityIcons.file,
      };

  static String _mediaLabel(CarpenterMediaKind kind) => switch (kind) {
    CarpenterMediaKind.image => 'Изображение',
    CarpenterMediaKind.video => 'Видео',
    CarpenterMediaKind.audio => 'Аудио',
    CarpenterMediaKind.voice => 'Голосовое',
    CarpenterMediaKind.videoCircle => 'Видеосообщение',
    CarpenterMediaKind.file => 'Файл',
  };

  static String _bytes(int value) {
    if (value >= 1024 * 1024) {
      return '${(value / (1024 * 1024)).toStringAsFixed(1)} МБ';
    }
    if (value >= 1024) return '${(value / 1024).toStringAsFixed(1)} КБ';
    return '$value Б';
  }
}
