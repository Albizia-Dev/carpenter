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
  return _ToastPreview(
    role: role,
    title: title,
    message: message,
    action: action,
    duration: duration,
  );
}

final class _ToastPreview extends StatefulWidget {
  const _ToastPreview({
    required this.role,
    required this.title,
    required this.message,
    required this.action,
    required this.duration,
  });
  final FeedbackColorRole role;
  final String title;
  final String message;
  final bool action;
  final ToastDuration duration;
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

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 520,
    child: CarpenterToastRegion(
      controller: _controller,
      child: Align(
        alignment: Alignment.topLeft,
        child: CarpenterButton(
          label: 'Показать toast',
          onInvoke: () {
            final id = ++_serial;
            _controller.show(
              CarpenterToastDescriptor(
                id: id,
                title: widget.title,
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
          },
        ),
      ),
    ),
  );
}
