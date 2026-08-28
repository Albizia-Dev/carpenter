import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

enum _AvatarContent { initials, icon }

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
    WidgetbookUseCase(name: 'Playground', builder: _activityPlayground),
    WidgetbookUseCase(name: 'Sizes', builder: _activitySizes),
  ],
);

final colorPickerComponent = WidgetbookComponent(
  name: 'Color Picker',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _colorPicker)],
);

final dateInputComponent = WidgetbookComponent(
  name: 'Date Input',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _dateInput)],
);

final toggleButtonComponent = WidgetbookComponent(
  name: 'Toggle Button',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _toggleButton),
    WidgetbookUseCase(name: 'Roles and sizes', builder: _toggleMatrix),
  ],
);

Widget _avatarPlayground(BuildContext context) {
  final content = context.knobs.object.segmented(
    label: 'Content · Type',
    options: _AvatarContent.values,
    initialOption: _AvatarContent.initials,
    labelBuilder: (value) => value.name,
  );
  final initials = context.knobs.string(
    label: 'Content · Initials',
    initialValue: 'NC',
  );
  final size = context.knobs.double.slider(
    label: 'Appearance · Size',
    initialValue: 40,
    min: 20,
    max: 128,
    divisions: 27,
  );
  final semanticLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Nikolai Chupin',
    defaultToNull: true,
  );

  return preview(
    CarpenterAvatar(
      initials: content == _AvatarContent.initials ? initials : null,
      child: content == _AvatarContent.icon
          ? const Icon(CarpenterIcons.account)
          : null,
      size: size,
      semanticLabel: semanticLabel,
    ),
  );
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
      CarpenterAvatar(initials: 'XL', size: 96),
      CarpenterAvatar(
        size: 48,
        semanticLabel: 'Account',
        child: Icon(CarpenterIcons.account),
      ),
    ],
  ),
);

Widget _activityPlayground(BuildContext context) {
  final value = context.knobs.double.slider(
    label: 'Progress · Value',
    initialValue: .64,
    min: 0,
    max: 1,
    divisions: 100,
  );
  final width = context.knobs.double.slider(
    label: 'Progress · Width',
    initialValue: 320,
    min: 80,
    max: 720,
    divisions: 32,
  );
  final height = context.knobs.double.slider(
    label: 'Progress · Height',
    initialValue: 4,
    min: 2,
    max: 16,
    divisions: 14,
  );
  final showLoader = context.knobs.boolean(
    label: 'Loader · Visible',
    initialValue: true,
  );
  final loaderSize = context.knobs.double.slider(
    label: 'Loader · Size',
    initialValue: 24,
    min: 12,
    max: 64,
    divisions: 26,
  );
  final strokeWidth = context.knobs.double.slider(
    label: 'Loader · Stroke',
    initialValue: 2.5,
    min: 1,
    max: 8,
    divisions: 14,
  );
  final semanticLabel = context.knobs.string(
    label: 'Accessibility · Progress label',
    initialValue: 'Upload progress',
  );

  return previewColumn([
    if (showLoader) CarpenterLoader(size: loaderSize, strokeWidth: strokeWidth),
    SizedBox(
      width: width,
      child: CarpenterProgress(
        value: value,
        height: height,
        semanticLabel: semanticLabel,
      ),
    ),
    CarpenterText.caption('${(value * 100).round()}% complete'),
  ]);
}

Widget _activitySizes(BuildContext context) => previewColumn([
  const Wrap(
    spacing: 16,
    runSpacing: 16,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      CarpenterLoader(size: 12, strokeWidth: 1.5),
      CarpenterLoader(size: 16, strokeWidth: 2),
      CarpenterLoader(size: 24, strokeWidth: 2.5),
      CarpenterLoader(size: 32, strokeWidth: 3),
      CarpenterLoader(size: 48, strokeWidth: 4),
    ],
  ),
  const SizedBox(width: 120, child: CarpenterProgress(value: .18, height: 2)),
  const SizedBox(width: 240, child: CarpenterProgress(value: .50, height: 4)),
  const SizedBox(width: 480, child: CarpenterProgress(value: .82, height: 8)),
]);

Widget _colorPicker(BuildContext context) {
  final initialValue = context.knobs.color(
    label: 'Value · Initial color',
    initialValue: const Color(0xff2688d9),
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final paletteHeight = context.knobs.double.slider(
    label: 'Appearance · Palette height',
    initialValue: 160,
    min: 80,
    max: 320,
    divisions: 24,
  );
  final width = context.knobs.double.slider(
    label: 'Appearance · Width',
    initialValue: 620,
    min: 280,
    max: 900,
    divisions: 31,
  );

  return _ColorPickerPreview(
    initialValue: initialValue,
    enabled: enabled,
    paletteHeight: paletteHeight,
    width: width,
  );
}

final class _ColorPickerPreview extends StatefulWidget {
  const _ColorPickerPreview({
    required this.initialValue,
    required this.enabled,
    required this.paletteHeight,
    required this.width,
  });

  final Color initialValue;
  final bool enabled;
  final double paletteHeight;
  final double width;

  @override
  State<_ColorPickerPreview> createState() => _ColorPickerPreviewState();
}

final class _ColorPickerPreviewState extends State<_ColorPickerPreview> {
  late Color _value = widget.initialValue;

  @override
  void didUpdateWidget(_ColorPickerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterColorPicker(
            value: _value,
            enabled: widget.enabled,
            paletteHeight: widget.paletteHeight,
            onChanged: (value) => setState(() => _value = value),
          ),
          const SizedBox(height: 12),
          CarpenterText.caption('Current: ${carpenterFormatRgbHex(_value)}'),
        ],
      ),
    ),
  );
}

Widget _dateInput(BuildContext context) {
  final initialValue = context.knobs.dateTimeOrNull(
    label: 'Value · Date',
    initialValue: DateTime(2026, 8, 28),
    start: DateTime(2025),
    end: DateTime(2028, 12, 31),
  );
  final placeholder = context.knobs.string(
    label: 'Content · Placeholder',
    initialValue: 'Choose date',
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final allowClear = context.knobs.boolean(
    label: 'Behaviour · Allow clear',
    initialValue: true,
  );

  return _DateInputPreview(
    initialValue: initialValue,
    placeholder: placeholder,
    enabled: enabled,
    allowClear: allowClear,
  );
}

final class _DateInputPreview extends StatefulWidget {
  const _DateInputPreview({
    required this.initialValue,
    required this.placeholder,
    required this.enabled,
    required this.allowClear,
  });

  final DateTime? initialValue;
  final String placeholder;
  final bool enabled;
  final bool allowClear;

  @override
  State<_DateInputPreview> createState() => _DateInputPreviewState();
}

final class _DateInputPreviewState extends State<_DateInputPreview> {
  late DateTime? _value = widget.initialValue;

  @override
  void didUpdateWidget(_DateInputPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _value = widget.initialValue;
    }
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: 360,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterDateInput(
            value: _value,
            placeholder: widget.placeholder,
            firstDate: DateTime(2025),
            lastDate: DateTime(2028, 12, 31),
            enabled: widget.enabled,
            allowClear: widget.allowClear,
            onChanged: (value) => setState(() => _value = value),
          ),
          const SizedBox(height: 12),
          CarpenterText.caption(
            _value == null
                ? 'No date selected'
                : 'Selected ${carpenterFormatDate(_value!)}',
          ),
        ],
      ),
    ),
  );
}

Widget _toggleButton(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Archived',
  );
  final showIcon = context.knobs.boolean(
    label: 'Content · Show icon',
    initialValue: true,
  );
  final initialChecked = context.knobs.boolean(
    label: 'State · Checked',
    initialValue: true,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final role = context.knobs.object.segmented(
    label: 'Appearance · Role',
    options: ActionColorRole.values,
    initialOption: ActionColorRole.primary,
    labelBuilder: semanticValueLabel,
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: ControlSize.values,
    initialOption: ControlSize.medium,
    labelBuilder: semanticValueLabel,
  );
  final semanticLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Toggle archived records',
    defaultToNull: true,
  );

  return _ToggleButtonPreview(
    label: label,
    showIcon: showIcon,
    initialChecked: initialChecked,
    enabled: enabled,
    role: role,
    size: size,
    semanticLabel: semanticLabel,
  );
}

final class _ToggleButtonPreview extends StatefulWidget {
  const _ToggleButtonPreview({
    required this.label,
    required this.showIcon,
    required this.initialChecked,
    required this.enabled,
    required this.role,
    required this.size,
    required this.semanticLabel,
  });

  final String label;
  final bool showIcon;
  final bool initialChecked;
  final bool enabled;
  final ActionColorRole role;
  final ControlSize size;
  final String? semanticLabel;

  @override
  State<_ToggleButtonPreview> createState() => _ToggleButtonPreviewState();
}

final class _ToggleButtonPreviewState extends State<_ToggleButtonPreview> {
  late bool _checked = widget.initialChecked;

  @override
  void didUpdateWidget(_ToggleButtonPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialChecked != widget.initialChecked) {
      _checked = widget.initialChecked;
    }
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterToggleButton(
      label: widget.label,
      checked: _checked,
      icon: widget.showIcon ? CarpenterIcons.archive : null,
      size: widget.size,
      colorRole: widget.role,
      semanticLabel: widget.semanticLabel,
      onChanged: widget.enabled
          ? (value) => setState(() => _checked = value)
          : null,
    ),
    CarpenterText.caption('checked=$_checked  enabled=${widget.enabled}'),
  ]);
}

Widget _toggleMatrix(BuildContext context) => preview(
  Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      for (final role in ActionColorRole.values)
        for (final checked in [false, true])
          CarpenterToggleButton(
            label: '${semanticValueLabel(role)} ${checked ? 'on' : 'off'}',
            checked: checked,
            colorRole: role,
            onChanged: (_) {},
          ),
    ],
  ),
);
