import 'attachment_tray.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

/// Compact, horizontally scrollable upload previews above the composer.
final class CarpenterAttachmentStrip extends StatelessWidget {
  const CarpenterAttachmentStrip({
    super.key,
    required this.items,
    this.onRetry,
    this.onCancel,
    this.onRemove,
  });

  final List<CarpenterAttachmentItem> items;
  final ValueChanged<String>? onRetry;
  final ValueChanged<String>? onCancel;
  final ValueChanged<String>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    return SizedBox(
      height: context.units(theme.sizes.tableColumn),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: gap),
        itemCount: items.length,
        separatorBuilder: (_, _) => SizedBox(width: gap),
        itemBuilder: (context, index) {
          final item = items[index];
          final cancellable =
              item.phase == CarpenterMessengerUploadPhase.queued ||
              item.phase == CarpenterMessengerUploadPhase.uploading ||
              item.phase == CarpenterMessengerUploadPhase.verifying;
          return SizedBox(
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
                    CarpenterText.label(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CarpenterText.caption(
                      item.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.progress != null)
                      CarpenterProgress(
                        value: item.progress,
                        semanticLabel: 'Загрузка ${item.name}',
                      ),
                    const Spacer(),
                    if (item.phase == CarpenterMessengerUploadPhase.failed &&
                        onRetry != null)
                      CarpenterButton.text(
                        label: 'Повторить',
                        onPressed: () => onRetry!(item.id),
                      )
                    else if (cancellable && onCancel != null)
                      CarpenterButton.text(
                        label: 'Отменить',
                        onPressed: () => onCancel!(item.id),
                      )
                    else if (onRemove != null)
                      CarpenterButton.text(
                        label: 'Убрать',
                        onPressed: () => onRemove!(item.id),
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
}
