import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../behaviour/notice.dart';
import '../../../collections/list_tile.dart';

/// Discovery states; unavailable must never be rendered as an empty result.
enum CarpenterRspRecoveryPhase {
  /// No rows are interactive while the caller reads the journal.
  loading,

  /// The complete list is available, including a verified empty result.
  ready,

  /// Discovery failed; retry is offered without exposing stale rows.
  failure,

  /// The adapter has no discovery capability; refresh is disabled.
  unavailable,
}

/// Presentation identity only. Labels come from the caller; no journal or
/// authorization model crosses the Carpenter boundary.
@immutable
final class CarpenterRspRecoveryItem {
  /// Creates a display row with a stable unique identity for activation.
  const CarpenterRspRecoveryItem({required this.id, required this.label});

  /// Stable identity echoed by the open callback, never interpreted here.
  final String id;

  /// Human-readable reference; may wrap on narrow viewports.
  final String label;
}

/// Controlled discovery page. Opening a row requests navigation to a result;
/// it never confirms an operation. Only ready exposes rows. Refresh is disabled
/// during loading and for adapters without discovery. Caller owns all effects.
class CarpenterRspRecovery extends StatelessWidget {
  /// Creates the page; absent callbacks render the respective action disabled.
  const CarpenterRspRecovery({
    super.key,
    required this.phase,
    this.items = const [],
    this.preview = false,
    this.message,
    this.onRefresh,
    this.onOpen,
  });

  /// Caller-owned discovery state.
  final CarpenterRspRecoveryPhase phase;

  /// Complete ready-state rows, with unique IDs; ignored in other phases.
  final List<CarpenterRspRecoveryItem> items;

  /// Shows explicit demonstration provenance when true.
  final bool preview;

  /// Safe failure explanation; null uses the standard retry guidance.
  final String? message;

  /// Requests another read; never called while loading or unavailable.
  final VoidCallback? onRefresh;

  /// Requests navigation by row identity, not an acceptance mutation.
  final ValueChanged<String>? onOpen;

  /// Renders semantic states with theme spacing and keyboard-capable rows.
  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return ColoredBox(
      color: theme.surface.base,
      child: ListView(
        padding: EdgeInsets.all(gap * 2),
        children: [
          CarpenterText.title('Незавершённые операции'),
          SizedBox(height: gap),
          const CarpenterText(
            'Проверьте исход подтверждения, если ответ не пришёл. Поручение может уже отсутствовать в очереди.',
            colorRole: ContentColorRole.secondary,
          ),
          if (preview) ...[
            SizedBox(height: gap),
            const CarpenterText.caption('Демонстрационные данные'),
          ],
          SizedBox(height: gap),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CarpenterButton(
              label: 'Обновить список',
              onPressed:
                  phase == CarpenterRspRecoveryPhase.loading ||
                      phase == CarpenterRspRecoveryPhase.unavailable
                  ? null
                  : onRefresh,
            ),
          ),
          SizedBox(height: gap * 2),
          if (phase == CarpenterRspRecoveryPhase.loading) ...[
            const CarpenterProgress(
              semanticLabel: 'Загрузка незавершённых операций',
            ),
            SizedBox(height: gap),
            const CarpenterText('Читаем сохранённые операции…'),
          ],
          if (phase == CarpenterRspRecoveryPhase.failure)
            CarpenterNotice(
              tone: CarpenterNoticeTone.warning,
              title: 'Список не загрузился',
              message:
                  message ??
                  'Не удалось прочитать операции. Повторите загрузку.',
            ),
          if (phase == CarpenterRspRecoveryPhase.unavailable)
            const CarpenterNotice(
              tone: CarpenterNoticeTone.warning,
              title: 'Список операций недоступен',
              message:
                  'Текущее хранилище не поддерживает поиск незавершённых операций. Это не означает, что их нет.',
            ),
          if (phase == CarpenterRspRecoveryPhase.ready && items.isEmpty)
            const CarpenterText('Незавершённых операций нет.'),
          if (phase == CarpenterRspRecoveryPhase.ready)
            for (final item in items)
              CarpenterListTile(
                key: ValueKey(item.id),
                presentation: CarpenterListTilePresentation.collectionRow,
                semanticLabel: '${item.label}. Открыть для проверки исхода',
                title: CarpenterText(item.label),
                subtitle: const CarpenterText(
                  'Исход подтверждения неизвестен · Открыть для проверки',
                  colorRole: ContentColorRole.secondary,
                ),
                onInvoke: onOpen == null ? null : () => onOpen!(item.id),
              ),
        ],
      ),
    );
  }
}
