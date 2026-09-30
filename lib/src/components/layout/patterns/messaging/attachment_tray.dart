import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/icon_data.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/progress.dart';
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
          final status = _transferStatus(item);
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
                    if (status == null)
                      CarpenterText.caption(
                        _bytes(item.byteLength),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    else ...[
                      CarpenterText.caption(
                        status.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        semanticsLabel: status.semanticLabel,
                      ),
                      if (status.active) ...[
                        SizedBox(height: context.units(theme.spacing.xsmall)),
                        CarpenterProgress(
                          value: status.progress,
                          semanticLabel: status.semanticLabel,
                        ),
                      ],
                    ],
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

  static ({String label, String semanticLabel, double? progress, bool active})?
  _transferStatus(CarpenterMediaView item) {
    final phase = item.transferPhase;
    if (phase == null) return null;
    final progress = _progress(item.transferProgress);
    return switch (phase) {
      CarpenterMediaTransferPhase.preparingUpload => (
        label: 'Готовим файл…',
        semanticLabel: 'Подготовка файла ${item.label}',
        progress: null,
        active: true,
      ),
      CarpenterMediaTransferPhase.uploading => (
        label: progress == null
            ? 'Отправляем…'
            : 'Отправляем · ${(progress * 100).round()}%',
        semanticLabel: 'Отправка файла ${item.label}',
        progress: progress,
        active: true,
      ),
      CarpenterMediaTransferPhase.verifyingUpload => (
        label: 'Проверяем файл…',
        semanticLabel: 'Проверка файла ${item.label}',
        progress: null,
        active: true,
      ),
      CarpenterMediaTransferPhase.uploadFailed => (
        label: 'Не удалось отправить',
        semanticLabel: 'Не удалось отправить файл ${item.label}',
        progress: null,
        active: false,
      ),
      CarpenterMediaTransferPhase.uploadCancelled => (
        label: 'Отправка отменена',
        semanticLabel: 'Отправка файла ${item.label} отменена',
        progress: null,
        active: false,
      ),
      CarpenterMediaTransferPhase.sourceRequired => (
        label: 'Выберите файл повторно',
        semanticLabel: 'Нужно повторно выбрать файл ${item.label}',
        progress: null,
        active: false,
      ),
      CarpenterMediaTransferPhase.downloading ||
      CarpenterMediaTransferPhase.downloadFailed => null,
    };
  }

  static double? _progress(double? value) => value == null || !value.isFinite
      ? null
      : value.clamp(0.0, 1.0).toDouble();
}
