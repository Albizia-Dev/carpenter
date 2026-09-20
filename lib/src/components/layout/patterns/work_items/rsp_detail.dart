import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/progress.dart';
import '../../../basic/text.dart';
import '../../../behaviour/notice.dart';

/// Host-owned phase for loading an RSP result detail.
enum CarpenterRspDetailPhase {
  /// No execution has been selected yet.
  initial,

  /// The current execution result is loading.
  loading,

  /// Fresh [CarpenterRspDetail.content] is available.
  ready,

  /// The result failed to load.
  failure,
}

/// Controlled result-loading composition. [content] is mounted only in ready;
/// a stale acceptance panel is never left interactive behind a loading overlay.
/// Caller supplies the current execution label and owns retry/state transitions.
class CarpenterRspDetail extends StatelessWidget {
  /// Creates a controlled result-detail loading surface.
  const CarpenterRspDetail({
    super.key,
    required this.phase,
    required this.reference,
    this.preview = false,
    this.content,
    this.message,
    this.onRetry,
  }) : assert(phase != CarpenterRspDetailPhase.ready || content != null);

  /// Current result-loading phase.
  final CarpenterRspDetailPhase phase;

  /// Formatted execution reference displayed above transient states.
  final String reference;

  /// Whether the surface displays demonstration rather than live data.
  final bool preview;

  /// Ready-state content owned by the host.
  final Widget? content;

  /// Optional host-provided failure explanation.
  final String? message;

  /// Requests another load after failure.
  final VoidCallback? onRetry;

  @override
  /// Builds ready content or the current loading/empty/failure state.
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
