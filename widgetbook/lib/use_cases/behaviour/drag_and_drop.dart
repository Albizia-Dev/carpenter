import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final dragAndDropComponent = WidgetbookComponent(
  name: 'Drag & Drop',
  useCases: [
    WidgetbookUseCase(name: 'Kernel playground', builder: _dragAndDrop),
  ],
);

Widget _dragAndDrop(BuildContext context) {
  final operation = context.knobs.object.segmented(
    label: 'Drag · Operation',
    options: CarpenterDragOperation.values,
    initialOption: CarpenterDragOperation.move,
    labelBuilder: semanticValueLabel,
  );
  final axis = context.knobs.object.segmented(
    label: 'Target · Axis',
    options: CarpenterDropAxis.values,
    initialOption: CarpenterDropAxis.vertical,
    labelBuilder: semanticValueLabel,
  );
  final activation = context.knobs.object.segmented(
    label: 'Drag · Activation',
    options: CarpenterDragActivation.values,
    initialOption: CarpenterDragActivation.immediate,
    labelBuilder: semanticValueLabel,
  );

  return _DragDropPreview(
    operation: operation,
    axis: axis,
    activation: activation,
  );
}

final class _DragDropPreview extends StatefulWidget {
  const _DragDropPreview({
    required this.operation,
    required this.axis,
    required this.activation,
  });

  final CarpenterDragOperation operation;
  final CarpenterDropAxis axis;
  final CarpenterDragActivation activation;

  @override
  State<_DragDropPreview> createState() => _DragDropPreviewState();
}

final class _DragDropPreviewState extends State<_DragDropPreview> {
  String _session = 'Idle';
  String _lastDrop = 'Nothing dropped yet';

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterDragScope(
      onSessionChanged: (session) {
        if (!mounted) return;
        setState(() {
          _session = session == null
              ? 'Idle'
              : '${session.operation.name} · ${session.targetId ?? 'no target'} · ${session.dropPosition?.name ?? 'moving'}';
        });
      },
      child: Wrap(
        spacing: context.units(1.5.rem),
        runSpacing: context.units(1.5.rem),
        crossAxisAlignment: WrapCrossAlignment.start,
        children: [
          SizedBox(
            width: context.units(15.rem),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const CarpenterText.label(
                  'Source',
                  emphasis: TypographyEmphasis.strong,
                ),
                SizedBox(height: context.units(.5.rem)),
                CarpenterDraggable<String>(
                  sourceId: 'invoice-184',
                  operation: widget.operation,
                  activation: widget.activation,
                  payload: const CarpenterDragPayload<String>(
                    id: 'invoice-184',
                    data: 'Invoice #184',
                    allowedOperations: {
                      CarpenterDragOperation.move,
                      CarpenterDragOperation.copy,
                      CarpenterDragOperation.link,
                    },
                    metadata: {'kind': 'invoice'},
                  ),
                  feedback: SizedBox(
                    width: context.units(13.75.rem),
                    child: const CarpenterCard(
                      child: CarpenterText.label('Invoice #184'),
                    ),
                  ),
                  childWhenDragging: const Opacity(
                    opacity: .35,
                    child: CarpenterCard(
                      child: CarpenterText.label('Invoice #184'),
                    ),
                  ),
                  child: const CarpenterCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarpenterText.label(
                          'Invoice #184',
                          emphasis: TypographyEmphasis.strong,
                        ),
                        CarpenterText.caption(
                          'Drag me across target edges',
                          colorRole: ContentColorRole.secondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: context.units(20.rem),
            child: _Target(
              id: 'review',
              title: 'Review queue',
              axis: widget.axis,
              onDrop: _recordDrop,
            ),
          ),
          SizedBox(
            width: context.units(20.rem),
            child: _Target(
              id: 'archive',
              title: 'Archive',
              axis: widget.axis,
              rejectLinks: true,
              onDrop: _recordDrop,
            ),
          ),
        ],
      ),
    ),
    Wrap(
      spacing: context.units(.5.rem),
      runSpacing: context.units(.5.rem),
      children: [
        CarpenterStatusIndicator(
          label: _session,
          role: _session == 'Idle'
              ? FeedbackColorRole.neutral
              : FeedbackColorRole.info,
        ),
        CarpenterStatusIndicator(
          label: _lastDrop,
          role: FeedbackColorRole.success,
        ),
      ],
    ),
  ]);

  void _recordDrop(CarpenterDropDetails<String> details) {
    setState(() {
      _lastDrop =
          '${details.payload.data} → ${details.targetId} · ${details.operation.name} · ${details.position.name}';
    });
  }
}

final class _Target extends StatelessWidget {
  const _Target({
    required this.id,
    required this.title,
    required this.axis,
    required this.onDrop,
    this.rejectLinks = false,
  });

  final String id;
  final String title;
  final CarpenterDropAxis axis;
  final CarpenterDropCallback<String> onDrop;
  final bool rejectLinks;

  @override
  Widget build(BuildContext context) => CarpenterDropTarget<String>(
    targetId: id,
    axis: axis,
    canAccept: (details) =>
        !rejectLinks || details.operation != CarpenterDragOperation.link,
    onDrop: onDrop,
    builder: (context, state) {
      final role = !state.hovering
          ? FeedbackColorRole.neutral
          : state.accepts
          ? FeedbackColorRole.success
          : FeedbackColorRole.danger;
      final colors = CarpenterTheme.of(context).feedback.resolve(role);
      return CarpenterCard(
        borderColor: colors.foreground,
        backgroundColor: colors.background,
        child: SizedBox(
          height: context.units(8.rem),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CarpenterText.label(title, emphasis: TypographyEmphasis.strong),
              SizedBox(height: context.units(.5.rem)),
              CarpenterText.caption(
                state.hovering
                    ? '${state.accepts ? 'Accept' : 'Reject'} · ${state.operation?.name} · ${state.position?.name}'
                    : rejectLinks
                    ? 'move / copy only'
                    : 'move / copy / link',
                colorRole: ContentColorRole.secondary,
              ),
            ],
          ),
        ),
      );
    },
  );
}
