import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';

final toastComponent = WidgetbookComponent(
  name: 'Toast',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final role = context.knobs.object.segmented(
    label: 'Feedback · Role',
    options: [
      FeedbackColorRole.info,
      FeedbackColorRole.success,
      FeedbackColorRole.warning,
      FeedbackColorRole.danger,
    ],
    labelBuilder: semanticValueLabel,
  );
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Изменения сохранены',
  );
  final message = context.knobs.string(
    label: 'Content · Message',
    initialValue: 'Документ успешно обновлён.',
  );
  final action = context.knobs.boolean(
    label: 'Content · Action',
    initialValue: true,
  );
  final duration = context.knobs.object.segmented(
    label: 'Motion · Duration',
    options: ToastDuration.values,
    labelBuilder: semanticValueLabel,
  );
  final placement = context.knobs.object.segmented(
    label: 'Stack · Placement',
    options: CarpenterToastPlacement.values,
    initialOption: CarpenterToastPlacement.topEnd,
    labelBuilder: (value) => value.name,
  );
  final maxVisible = context.knobs.int.slider(
    label: 'Stack · Max visible',
    initialValue: 3,
    min: 1,
    max: 8,
  );
  final burstSize = context.knobs.int.slider(
    label: 'Stack · Burst size',
    initialValue: 4,
    min: 1,
    max: 12,
  );
  final height = context.knobs.double.slider(
    label: 'Layout · Region height',
    initialValue: 520,
    min: 280,
    max: 800,
    divisions: 26,
  );
  return _ToastPreview(
    role: role,
    title: title,
    message: message,
    action: action,
    duration: duration,
    placement: placement,
    maxVisible: maxVisible,
    burstSize: burstSize,
    height: height,
  );
}

final class _ToastPreview extends StatefulWidget {
  const _ToastPreview({
    required this.role,
    required this.title,
    required this.message,
    required this.action,
    required this.duration,
    required this.placement,
    required this.maxVisible,
    required this.burstSize,
    required this.height,
  });
  final FeedbackColorRole role;
  final String title;
  final String message;
  final bool action;
  final ToastDuration duration;
  final CarpenterToastPlacement placement;
  final int maxVisible;
  final int burstSize;
  final double height;

  @override
  State<_ToastPreview> createState() => _ToastPreviewState();
}

final class _ToastPreviewState extends State<_ToastPreview> {
  final _controller = CarpenterToasterController();
  var _serial = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showOne() {
    final id = ++_serial;
    _controller.show(
      CarpenterToastDescriptor(
        id: id,
        title: '${widget.title} #$id',
        message: widget.message,
        role: widget.role,
        duration: widget.duration,
        action: widget.action
            ? CarpenterActionDescriptor(
                id: 'undo-$id',
                label: 'Отменить',
                onInvoke: () {},
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: widget.height,
    child: CarpenterToastRegion(
      controller: _controller,
      placement: widget.placement,
      maxVisible: widget.maxVisible,
      child: Align(
        alignment: Alignment.topLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CarpenterButton(label: 'Показать toast', onPressed: _showOne),
            CarpenterButton.outlined(
              label: 'Burst ×${widget.burstSize}',
              onPressed: () {
                for (var index = 0; index < widget.burstSize; index++) {
                  _showOne();
                }
              },
            ),
            CarpenterButton.text(
              label: 'Очистить',
              onPressed: _controller.dismissAll,
            ),
          ],
        ),
      ),
    ),
  );
}
