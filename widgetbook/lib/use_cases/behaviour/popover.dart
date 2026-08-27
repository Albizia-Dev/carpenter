import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final popoverComponent = WidgetbookComponent(
  name: 'Popover',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Overlay edge cases', builder: _edgeCases),
  ],
);

Widget _playground(BuildContext context) {
  final initialOpen = context.knobs.boolean(
    label: 'State · Open',
    initialValue: true,
  );
  final placement = context.knobs.object.segmented(
    label: 'Position · Placement',
    options: OverlayPlacement.values,
    initialOption: OverlayPlacement.bottomStart,
    labelBuilder: semanticValueLabel,
  );
  final width = context.knobs.double.slider(
    label: 'Content · Width',
    initialValue: 240,
    min: 120,
    max: 480,
  );
  final height = context.knobs.double.slider(
    label: 'Content · Height',
    initialValue: 96,
    min: 48,
    max: 320,
  );
  final text = context.knobs.string(
    label: 'Content · Text',
    initialValue: 'Дополнительные параметры действия',
  );
  return preview(
    _ControlledPopover(
      requestedOpen: initialOpen,
      placement: placement,
      content: SizedBox(
        width: width,
        height: height,
        child: CarpenterText.body(text),
      ),
    ),
  );
}

Widget _edgeCases(BuildContext context) => preview(
  SizedBox(
    height: 520,
    child: SingleChildScrollView(
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Align(
          alignment: Alignment.topRight,
          child: _NestedPopoverPreview(),
        ),
      ),
    ),
  ),
);

final class _ControlledPopover extends StatefulWidget {
  const _ControlledPopover({
    required this.requestedOpen,
    required this.placement,
    required this.content,
  });

  final bool requestedOpen;
  final OverlayPlacement placement;
  final Widget content;

  @override
  State<_ControlledPopover> createState() => _ControlledPopoverState();
}

final class _ControlledPopoverState extends State<_ControlledPopover> {
  late bool _open = widget.requestedOpen;

  @override
  void didUpdateWidget(_ControlledPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedOpen != widget.requestedOpen) {
      _open = widget.requestedOpen;
    }
  }

  @override
  Widget build(BuildContext context) => CarpenterPopover(
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    placement: widget.placement,
    semanticLabel: 'Открыть popover',
    anchor: const CarpenterText.label('Параметры'),
    content: widget.content,
  );
}

final class _NestedPopoverPreview extends StatefulWidget {
  @override
  State<_NestedPopoverPreview> createState() => _NestedPopoverPreviewState();
}

final class _NestedPopoverPreviewState extends State<_NestedPopoverPreview> {
  var _outer = true;
  var _inner = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 280),
    child: CarpenterPopover(
      open: _outer,
      onOpenChanged: (value) => setState(() => _outer = value),
      placement: OverlayPlacement.topEnd,
      semanticLabel: 'Край viewport',
      anchor: const CarpenterText.label('Якорь у края'),
      content: CarpenterPopover(
        open: _inner,
        onOpenChanged: (value) => setState(() => _inner = value),
        placement: OverlayPlacement.left,
        semanticLabel: 'Вложенный popover',
        anchor: const CarpenterText.label('Открыть вложенный'),
        content: const SizedBox(
          width: 180,
          child: CarpenterText.body('Escape закрывает верхний overlay.'),
        ),
      ),
    ),
  );
}
