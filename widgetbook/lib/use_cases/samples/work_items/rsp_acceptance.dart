import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';
import 'rsp_acceptance_fixture.g.dart';

final rspAcceptanceComponent = WidgetbookComponent(
  name: 'Подтверждение РСП',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: RspAcceptanceScene(
          phase: context.knobs.object.dropdown(
            label: 'Состояние команды',
            options: CarpenterRspAcceptancePhase.values,
          ),
          creator: context.knobs.boolean(
            label: 'Создатель поручения',
            initialValue: true,
          ),
        ),
      ),
    ),
  ],
);

/// Presentation-only fixture host. Every click below simulates a UI phase,
/// not a server commit. Actual command behavior is tested in Core/Desktop.
class RspAcceptanceScene extends StatefulWidget {
  const RspAcceptanceScene({
    super.key,
    this.phase = CarpenterRspAcceptancePhase.ready,
    this.creator = true,
  });
  final CarpenterRspAcceptancePhase phase;
  final bool creator;
  @override
  State<RspAcceptanceScene> createState() => _SceneState();
}

class _SceneState extends State<RspAcceptanceScene> {
  CarpenterRspAcceptancePhase? _override;
  @override
  void didUpdateWidget(RspAcceptanceScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase ||
        oldWidget.creator != widget.creator) {
      _override = null;
    }
  }

  @override
  Widget build(BuildContext context) => CarpenterRspAcceptance(
    reference: rspAcceptanceReference,
    executor: rspAcceptanceExecutor,
    preview: true,
    resultText: rspAcceptanceResultText,
    phase: _override ?? widget.phase,
    message:
        (_override ?? widget.phase) ==
            CarpenterRspAcceptancePhase.reviewRequired
        ? 'Прежнее подтверждение сохранено. Обновите текущий результат перед новым действием.'
        : null,
    onAccept: widget.creator
        ? () => setState(() => _override = CarpenterRspAcceptancePhase.accepted)
        : null,
    onRetry: () =>
        setState(() => _override = CarpenterRspAcceptancePhase.accepted),
    onReload: () =>
        setState(() => _override = CarpenterRspAcceptancePhase.ready),
  );
}
