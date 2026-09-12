import 'package:flutter/widgets.dart';
import 'package:carpenter_units/carpenter_units.dart';
import '../../../../foundation/theme.dart';
import '../../../../foundation/roles.dart';
import '../../../basic/text.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';

/// Upload phase only; no value means that the chat message has been sent.
enum CarpenterMessengerUploadPhase {
  /// Waiting for a transport slot.
  queued,

  /// Bytes are being transferred.
  uploading,

  /// Transfer finished; the server has not yet confirmed a usable asset.
  verifying,

  /// Verified asset, ready for later attachment to a message.
  ready,

  /// Recoverable upload error, separate from message delivery.
  failed,

  /// Cancelled locally; remote object deletion is not implied.
  cancelled,
}

/// Display-only item. The host owns account/room filtering and file bytes.
class CarpenterAttachmentItem {
  /// [id] is stable through retry. [detail] contains safe size/error text.
  const CarpenterAttachmentItem({
    required this.id,
    required this.name,
    required this.phase,
    required this.detail,
    this.progress,
  });

  /// Opaque upload intent used in callbacks.
  final String id;

  /// Original display filename, never a local path or signed URL.
  final String name;

  /// Authoritative host upload state.
  final CarpenterMessengerUploadPhase phase;

  /// Human-readable size or safe error guidance.
  final String detail;

  /// Uploaded fraction; null shows indeterminate progress while uploading.
  final double? progress;
}

/// Controlled, scrollable attachment list for a bounded composer region.
/// Uses flat rows and keyboard-accessible Carpenter actions. Failed items can
/// retry independently; ready items never receive a send/retry action here.
class CarpenterAttachmentTray extends StatelessWidget {
  /// Empty [items] keeps only an optional add action. The host owns persistence,
  /// picker lifecycle and stale callback handling. Null callbacks hide actions.
  const CarpenterAttachmentTray({
    super.key,
    required this.items,
    this.onAdd,
    this.onRetry,
    this.onCancel,
    this.onRemove,
  });

  /// Only uploads belonging to the selected, authorized account and room.
  final List<CarpenterAttachmentItem> items;

  /// Opens a caller-owned picker; this component does not access the filesystem.
  final VoidCallback? onAdd;

  /// Retries a failed intent with its original immutable payload.
  final ValueChanged<String>? onRetry;

  /// Cancels queued/uploading/verifying items without claiming server deletion.
  final ValueChanged<String>? onCancel;

  /// Removes a ready, failed or cancelled local attachment. This never implies
  /// deleting its remote media object or an already submitted message.
  final ValueChanged<String>? onRemove;

  /// Builds a bounded lazy list; long names wrap and actions keep their labels.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    if (items.isEmpty && onAdd == null) return const SizedBox.shrink();
    return ColoredBox(
      color: theme.surface.base,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: gap),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (items.isNotEmpty)
                  CarpenterText.label('Вложения · ${items.length}'),
                if (onAdd != null)
                  CarpenterButton.text(
                    label: 'Добавить файлы',
                    onPressed: onAdd,
                  ),
              ],
            ),
          ),
          if (items.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight:
                    context.units(16.rem) *
                    MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                primary: false,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final status = switch (item.phase) {
                    CarpenterMessengerUploadPhase.queued => 'В очереди',
                    CarpenterMessengerUploadPhase.uploading => 'Загружается',
                    CarpenterMessengerUploadPhase.verifying => 'Проверяется',
                    CarpenterMessengerUploadPhase.ready => 'Файл загружен',
                    CarpenterMessengerUploadPhase.failed => 'Ошибка загрузки',
                    CarpenterMessengerUploadPhase.cancelled =>
                      'Загрузка отменена',
                  };
                  final cancellable =
                      item.phase == CarpenterMessengerUploadPhase.queued ||
                      item.phase == CarpenterMessengerUploadPhase.uploading ||
                      item.phase == CarpenterMessengerUploadPhase.verifying;
                  return Padding(
                    key: ValueKey(item.id),
                    padding: EdgeInsets.symmetric(
                      horizontal: gap,
                      vertical: gap / 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CarpenterText(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          semanticsLabel: item.name,
                        ),
                        if (item.phase == CarpenterMessengerUploadPhase.failed)
                          CarpenterText.feedback(
                            '$status · ${item.detail}',
                            feedbackRole: FeedbackColorRole.danger,
                          )
                        else
                          CarpenterText.caption('$status · ${item.detail}'),
                        if (item.phase ==
                                CarpenterMessengerUploadPhase.uploading ||
                            item.phase ==
                                CarpenterMessengerUploadPhase.verifying) ...[
                          SizedBox(height: gap / 2),
                          CarpenterProgress(
                            value:
                                item.phase ==
                                    CarpenterMessengerUploadPhase.verifying
                                ? null
                                : item.progress,
                            semanticLabel: '$status: ${item.name}',
                          ),
                        ],
                        Wrap(
                          spacing: gap,
                          children: [
                            if (item.phase ==
                                    CarpenterMessengerUploadPhase.failed &&
                                onRetry != null)
                              CarpenterButton.text(
                                label: 'Повторить',
                                semanticLabel:
                                    'Повторить загрузку: ${item.name}',
                                onPressed: () => onRetry!(item.id),
                              ),
                            if (cancellable && onCancel != null)
                              CarpenterButton.text(
                                label: 'Отменить',
                                semanticLabel:
                                    'Отменить загрузку: ${item.name}',
                                onPressed: () => onCancel!(item.id),
                              ),
                            if (!cancellable && onRemove != null)
                              CarpenterButton.text(
                                label: 'Убрать',
                                semanticLabel: 'Убрать вложение: ${item.name}',
                                onPressed: () => onRemove!(item.id),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
