import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import '../../../helpers/layout_viewport.dart';
import 'rsp_acceptance.dart';
import 'rsp_acceptance_fixture.g.dart';

final rspDetailComponent = WidgetbookComponent(
  name: 'Загрузка результата РСП',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => layoutViewportPreview(
        context,
        child: RspDetailScene(
          phase: context.knobs.object.dropdown(
            label: 'Состояние загрузки',
            options: CarpenterRspDetailPhase.values,
          ),
        ),
      ),
    ),
  ],
);

/// Presentation-only host: retry simulates a successful read, never a command.
class RspDetailScene extends StatefulWidget {
  const RspDetailScene({
    super.key,
    this.phase = CarpenterRspDetailPhase.initial,
  });
  final CarpenterRspDetailPhase phase;
  @override
  State<RspDetailScene> createState() => _SceneState();
}

class _SceneState extends State<RspDetailScene> {
  CarpenterRspDetailPhase? _override;
  @override
  void didUpdateWidget(RspDetailScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.phase != widget.phase) _override = null;
  }

  @override
  Widget build(BuildContext context) => CarpenterRspDetail(
    phase: _override ?? widget.phase,
    reference: (_override ?? widget.phase) == CarpenterRspDetailPhase.initial
        ? 'РСП'
        : rspAcceptanceReference,
    preview: true,
    onRetry: () => setState(() => _override = CarpenterRspDetailPhase.ready),
    content: const RspAcceptanceScene(),
  );
}
