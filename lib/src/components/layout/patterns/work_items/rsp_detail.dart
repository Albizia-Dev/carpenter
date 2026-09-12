import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../behaviour/notice.dart';

enum CarpenterRspDetailPhase { initial, loading, ready, failure }

/// Controlled result-loading composition. [content] is mounted only in ready;
/// a stale acceptance panel is never left interactive behind a loading overlay.
/// Caller supplies the current execution label and owns retry/state transitions.
class CarpenterRspDetail extends StatelessWidget {
  const CarpenterRspDetail({
    super.key,
    required this.phase,
    required this.reference,
    this.preview = false,
    this.content,
    this.message,
    this.onRetry,
  }) : assert(phase != CarpenterRspDetailPhase.ready || content != null);
  final CarpenterRspDetailPhase phase;
  final String reference;
  final bool preview;
  final Widget? content;
  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (phase == CarpenterRspDetailPhase.ready && content != null) {
      return content!;
    }
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
            CarpenterText.title('Результат поручения'),
            if (preview) ...[
              SizedBox(height: gap),
              const CarpenterText(
                'Демонстрационные данные',
                colorRole: ContentColorRole.secondary,
              ),
            ],
            SizedBox(height: gap * 2),
            if (phase == CarpenterRspDetailPhase.initial)
              const CarpenterText(
                'Выберите поручение, чтобы проверить результат.',
              ),
            if (phase == CarpenterRspDetailPhase.loading) ...[
              const CarpenterProgress(
                semanticLabel: 'Загрузка результата поручения',
              ),
              SizedBox(height: gap),
              const CarpenterText('Загружаем актуальный результат…'),
            ],
            if (phase == CarpenterRspDetailPhase.failure) ...[
              CarpenterNotice(
                tone: CarpenterNoticeTone.warning,
                title: 'Результат не загрузился',
                message:
                    message ??
                    'Повторите загрузку. Подтверждение пока недоступно.',
              ),
              SizedBox(height: gap),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CarpenterButton(
                  label: 'Повторить загрузку',
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
