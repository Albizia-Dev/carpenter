import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';

final rspRecoveryComponent = WidgetbookComponent(
  name: 'Незавершённые операции РСП',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: RspRecoveryScene(
          phase: context.knobs.object.dropdown(
            label: 'Состояние',
            options: CarpenterRspRecoveryPhase.values,
            initialOption: CarpenterRspRecoveryPhase.ready,
          ),
          empty: context.knobs.boolean(label: 'Пустой список'),
          preview: context.knobs.boolean(
            label: 'Демонстрационные данные',
            initialValue: true,
          ),
          enabled: context.knobs.boolean(
            label: 'Действия доступны',
            initialValue: true,
          ),
          label: context.knobs.string(
            label: 'Подпись поручения',
            initialValue: 'РСП №501',
          ),
          message: context.knobs.string(
            label: 'Ошибка чтения',
            initialValue: 'Не удалось прочитать сохранённые операции.',
          ),
        ),
      ),
    ),
  ],
);

/// Presentation-only navigation feedback; never simulates a successful commit.
class RspRecoveryScene extends StatefulWidget {
  const RspRecoveryScene({
    super.key,
    this.phase = CarpenterRspRecoveryPhase.ready,
    this.empty = false,
    this.preview = true,
    this.enabled = true,
    this.label = 'РСП №501',
    this.message,
  });
  final CarpenterRspRecoveryPhase phase;
  final bool empty, preview, enabled;
  final String label;
  final String? message;
  @override
  State<RspRecoveryScene> createState() => _SceneState();
}

class _SceneState extends State<RspRecoveryScene> {
  String? _opened;
  CarpenterRspRecoveryPhase? _phase;
  @override
  void didUpdateWidget(RspRecoveryScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    _opened = null;
    _phase = null;
  }

  @override
  Widget build(BuildContext context) => _opened == null
      ? CarpenterRspRecovery(
          phase: _phase ?? widget.phase,
          preview: widget.preview,
          message: widget.message,
          items: widget.empty
              ? const []
              : [
                  CarpenterRspRecoveryItem(
                    id: 'operation-1',
                    label: widget.label,
                  ),
                ],
          onRefresh: widget.enabled
              ? () => setState(() => _phase = CarpenterRspRecoveryPhase.ready)
              : null,
          onOpen: widget.enabled ? (id) => setState(() => _opened = id) : null,
        )
      : CarpenterRspDetail(
          phase: CarpenterRspDetailPhase.failure,
          reference: widget.label,
          preview: widget.preview,
          message:
              'Демонстрация перехода. Для проверки исхода требуется актуальное чтение поручения.',
          onRetry: () => setState(() => _opened = null),
        );
}
