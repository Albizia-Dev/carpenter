import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final avatarComponent = WidgetbookComponent(
  name: 'Avatar',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _avatarPlayground),
    WidgetbookUseCase(name: 'Sizes and content', builder: _avatarMatrix),
  ],
);

final activityComponent = WidgetbookComponent(
  name: 'Activity',
  useCases: [
    WidgetbookUseCase(name: 'Loader and progress', builder: _activity),
    WidgetbookUseCase(name: 'Reduced space', builder: _activityCompact),
  ],
);

final colorPickerComponent = WidgetbookComponent(
  name: 'Color Picker',
  useCases: [WidgetbookUseCase(name: 'Interactive', builder: (_) => const _ColorPickerPreview())],
);

final dateInputComponent = WidgetbookComponent(
  name: 'Date Input',
  useCases: [WidgetbookUseCase(name: 'Interactive', builder: (_) => const _DateInputPreview())],
);

Widget _avatarPlayground(BuildContext context) {
  final initials = context.knobs.string(label: 'Content · Initials', initialValue: 'NC');
  final size = context.knobs.double.slider(label: 'Size', initialValue: 40, min: 24, max: 96);
  return preview(CarpenterAvatar(initials: initials, size: size));
}

Widget _avatarMatrix(BuildContext context) => preview(
  const Wrap(
    spacing: 12,
    runSpacing: 12,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      CarpenterAvatar(initials: 'A', size: 24),
      CarpenterAvatar(initials: 'AB', size: 32),
      CarpenterAvatar(initials: 'CD', size: 40),
      CarpenterAvatar(initials: 'ERP', size: 64),
      CarpenterAvatar(child: Icon(CarpenterIcons.account), size: 48, semanticLabel: 'Account'),
    ],
  ),
);

Widget _activity(BuildContext context) {
  final value = context.knobs.double.slider(label: 'Progress · Value', initialValue: .64, min: 0, max: 1);
  return previewColumn([
    const CarpenterLoader(),
    SizedBox(width: 320, child: CarpenterProgress(value: value, semanticLabel: 'Upload progress')),
    CarpenterText.caption('${(value * 100).round()}% complete'),
  ]);
}

Widget _activityCompact(BuildContext context) => previewColumn([
  const SizedBox(width: 16, height: 16, child: CarpenterLoader(size: 16, strokeWidth: 2)),
  const SizedBox(width: 120, child: CarpenterProgress(value: .18, height: 3)),
]);

final class _ColorPickerPreview extends StatefulWidget {
  const _ColorPickerPreview();
  @override
  State<_ColorPickerPreview> createState() => _ColorPickerPreviewState();
}

final class _ColorPickerPreviewState extends State<_ColorPickerPreview> {
  Color _value = const Color(0xff2688d9);
  bool _enabled = true;

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 620,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterColorPicker(value: _value, enabled: _enabled, onChanged: (value) => setState(() => _value = value)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: CarpenterText.body('Current: ${carpenterFormatRgbHex(_value)}')),
            CarpenterButton(label: _enabled ? 'Disable' : 'Enable', prominence: ActionProminence.outlined, onInvoke: () => setState(() => _enabled = !_enabled)),
          ]),
        ],
      ),
    ),
  );
}

final class _DateInputPreview extends StatefulWidget {
  const _DateInputPreview();
  @override
  State<_DateInputPreview> createState() => _DateInputPreviewState();
}

final class _DateInputPreviewState extends State<_DateInputPreview> {
  DateTime? _value = DateTime(2026, 8, 28);

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 360,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CarpenterDateInput(
          value: _value,
          firstDate: DateTime(2025),
          lastDate: DateTime(2028, 12, 31),
          onChanged: (value) => setState(() => _value = value),
        ),
        const SizedBox(height: 12),
        CarpenterText.caption(_value == null ? 'No date selected' : 'Selected ${carpenterFormatDate(_value!)}'),
      ]),
    ),
  );
}
