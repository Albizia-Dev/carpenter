import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';

final dialogComponent = WidgetbookComponent(
  name: 'Dialog',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Scenario · Nested overlay', builder: _nested),
    WidgetbookUseCase(name: 'States · Hosted form', builder: _statefulForm),
  ],
);

Widget _playground(BuildContext context) {
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Подтверждение действия',
  );
  final content = context.knobs.string(
    label: 'Content · Message',
    initialValue: 'Продолжить выполнение операции?',
  );
  final height = context.knobs.double.slider(
    label: 'Content · Height',
    initialValue: 120,
    min: 48,
    max: 600,
  );
  final policy = context.knobs.object.segmented(
    label: 'Behavior · Dismiss / Policy',
    options: DialogDismissPolicy.values,
    labelBuilder: semanticValueLabel,
  );
  final actions = context.knobs.boolean(
    label: 'Content · Actions',
    initialValue: true,
  );
  return _DialogPreview(
    presentation: context.knobs.object.segmented(
      label: 'Layout · Presentation',
      options: CarpenterDialogPresentation.values,
      labelBuilder: (value) => value == CarpenterDialogPresentation.editor
          ? 'Editor panel / page'
          : 'Centered',
    ),
    title: title,
    content: content,
    height: height,
    policy: policy,
    actions: actions,
    loading: context.knobs.boolean(label: 'Behavior · Confirm loading'),
  );
}

Widget _nested(BuildContext context) => const _NestedDialogPreview();

final class _DialogPreview extends StatefulWidget {
  const _DialogPreview({
    required this.title,
    required this.presentation,
    required this.content,
    required this.height,
    required this.policy,
    required this.actions,
    required this.loading,
  });
  final CarpenterDialogPresentation presentation;
  final String title;
  final String content;
  final double height;
  final DialogDismissPolicy policy;
  final bool actions;
  final bool loading;
  @override
  State<_DialogPreview> createState() => _DialogPreviewState();
}

final class _DialogPreviewState extends State<_DialogPreview> {
  var _open = false;
  @override
  Widget build(BuildContext context) => CarpenterDialog(
    presentation: widget.presentation,
    actionExecutionPhases: {
      'confirm': widget.loading
          ? ActionExecutionPhase.running
          : ActionExecutionPhase.idle,
    },
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    title: widget.title,
    dismissPolicy: widget.policy,
    content: SizedBox(
      height: widget.height,
      child: CarpenterText.body(widget.content),
    ),
    actions: widget.actions
        ? [
            CarpenterActionDescriptor(
              id: 'cancel',
              label: 'Отмена',
              onInvoke: () => setState(() => _open = false),
            ),
            CarpenterActionDescriptor(
              id: 'confirm',
              label: 'Продолжить',
              colorRole: ActionColorRole.primary,
              onInvoke: () => setState(() => _open = false),
            ),
          ]
        : const [],
    child: CarpenterButton(
      label: 'Открыть dialog',
      onInvoke: () => setState(() => _open = true),
    ),
  );
}

final class _NestedDialogPreview extends StatefulWidget {
  const _NestedDialogPreview();
  @override
  State<_NestedDialogPreview> createState() => _NestedDialogPreviewState();
}

final class _NestedDialogPreviewState extends State<_NestedDialogPreview> {
  var _dialog = false;
  var _popover = true;
  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: _dialog,
    onOpenChanged: (value) => setState(() => _dialog = value),
    title: 'Dialog поверх transient UI',
    content: CarpenterPopover(
      open: _popover,
      onOpenChanged: (value) => setState(() => _popover = value),
      anchor: const CarpenterText.label('Вложенный popover'),
      content: const CarpenterText.body('Escape закрывает верхний слой.'),
    ),
    child: CarpenterButton(
      label: 'Открыть nested case',
      onInvoke: () => setState(() {
        _dialog = true;
        _popover = true;
      }),
    ),
  );
}

Widget _statefulForm(BuildContext context) => Center(
  child: CarpenterButton(
    label: 'Открыть форму',
    onPressed: () => showCarpenterDialog<String>(
      context: context,
      builder: (_) => const _DialogForm(),
    ),
  ),
);

class _DialogForm extends StatefulWidget {
  const _DialogForm();
  @override
  State<_DialogForm> createState() => _DialogFormState();
}

class _DialogFormState extends State<_DialogForm> {
  final _name = TextEditingController();
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: true,
    onOpenChanged: (open) {
      if (!open) Navigator.of(context).pop();
    },
    child: const SizedBox.shrink(),
    title: 'Название',
    content: CarpenterInput(
      controller: _name,
      label: 'Название',
      autofocus: true,
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      CarpenterActionDescriptor(
        id: 'cancel',
        label: 'Отмена',
        onInvoke: () => Navigator.of(context).pop(),
      ),
      CarpenterActionDescriptor(
        id: 'save',
        label: 'Сохранить',
        onInvoke: _name.text.trim().isEmpty
            ? null
            : () => Navigator.of(context).pop(_name.text.trim()),
      ),
    ],
  );
}
