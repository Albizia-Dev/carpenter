import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../behaviour/notice.dart';

/// Host-owned command phase. Uncertain means the write may already be saved;
/// retry must reconcile the original command, never create a second mutation.
enum CarpenterRspAcceptancePhase {
  ready,
  submitting,
  accepted,
  rejected,
  uncertain,
  reviewRequired,
}

/// A complete result acceptance composition for one RSP execution. The host
/// owns authorization, command lifecycle and formatted reference/author values.
/// [onAccept] is optional: absence leaves the result readable without an action.
/// [onRetry] must retry the original request. [onReload] reloads a definitively
/// rejected result for review, never silently retries its old command.
class CarpenterRspAcceptance extends StatelessWidget {
  const CarpenterRspAcceptance({
    super.key,
    required this.reference,
    required this.executor,
    required this.resultText,
    required this.phase,
    this.preview = false,
    this.message,
    this.onAccept,
    this.onRetry,
    this.onReload,
  });
  final String reference, executor, resultText;
  final CarpenterRspAcceptancePhase phase;
  final bool preview;
  final String? message;
  final VoidCallback? onAccept, onRetry, onReload;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return ColoredBox(
      color: theme.surface.base,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(gap * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CarpenterText.caption(
              reference,
              colorRole: ContentColorRole.secondary,
            ),
            SizedBox(height: gap),
            CarpenterText.title('Подтверждение результата'),
            if (preview) ...[
              SizedBox(height: gap),
              const CarpenterText(
                'Демонстрационные данные',
                colorRole: ContentColorRole.secondary,
              ),
            ],
            SizedBox(height: gap * 2),
            CarpenterText.label('Результат исполнителя · $executor'),
            SizedBox(height: gap),
            CarpenterText(resultText),
            SizedBox(height: gap * 2),
            if (phase == CarpenterRspAcceptancePhase.ready) ...[
              const CarpenterText(
                'Проверьте результат. Подтверждение завершает это исполнение поручения; другие исполнители группы не затрагиваются.',
              ),
              SizedBox(height: gap),
              if (onAccept != null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CarpenterButton(
                    label: 'Подтвердить результат',
                    onPressed: onAccept,
                  ),
                )
              else
                const CarpenterText(
                  'Подтверждение доступно создателю поручения.',
                  colorRole: ContentColorRole.secondary,
                ),
            ],
            if (phase == CarpenterRspAcceptancePhase.submitting) ...[
              const CarpenterProgress(
                semanticLabel: 'Подтверждение результата',
              ),
              SizedBox(height: gap),
              const CarpenterText('Сохраняем подтверждение…'),
            ],
            if (phase == CarpenterRspAcceptancePhase.accepted)
              const CarpenterText(
                'Результат подтверждён. Исполнение поручения завершено.',
              ),
            if (phase == CarpenterRspAcceptancePhase.rejected ||
                phase == CarpenterRspAcceptancePhase.uncertain ||
                phase == CarpenterRspAcceptancePhase.reviewRequired) ...[
              CarpenterNotice(
                tone: CarpenterNoticeTone.warning,
                title: phase == CarpenterRspAcceptancePhase.uncertain
                    ? 'Проверяем исход подтверждения'
                    : phase == CarpenterRspAcceptancePhase.reviewRequired
                    ? 'Обновите результат'
                    : 'Подтверждение не сохранено',
                message:
                    message ??
                    (phase == CarpenterRspAcceptancePhase.uncertain
                        ? 'Ответ не получен. Подтверждение могло сохраниться. Повторите проверку.'
                        : 'Обновите поручение и проверьте результат заново.'),
              ),
              SizedBox(height: gap),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CarpenterButton(
                  label: phase == CarpenterRspAcceptancePhase.uncertain
                      ? 'Повторить проверку'
                      : 'Обновить результат',
                  onPressed: phase == CarpenterRspAcceptancePhase.uncertain
                      ? onRetry
                      : onReload,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
