import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final numberInputComponent = WidgetbookComponent(
  name: 'Number Input',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _numberInput),
    WidgetbookUseCase(name: 'States', builder: _numberStates),
  ],
);

final timeInputComponent = WidgetbookComponent(
  name: 'Time Input',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _timeInput)],
);

final dateRangeInputComponent = WidgetbookComponent(
  name: 'Date Range Input',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _dateRangeInput)],
);

final badgeComponent = WidgetbookComponent(
  name: 'Badge',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _badge),
    WidgetbookUseCase(name: 'Roles', builder: _badgeRoles),
  ],
);

final avatarGroupComponent = WidgetbookComponent(
  name: 'Avatar Group',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _avatarGroup)],
);

Widget _numberInput(BuildContext context) {
  final initial = context.knobs.double.slider(
    label: 'Value · Initial',
    initialValue: 1250.5,
    min: -10000,
    max: 10000,
    divisions: 200,
  );
  final allowDecimal = context.knobs.boolean(
    label: 'Behaviour · Decimal',
    initialValue: true,
  );
  final allowNegative = context.knobs.boolean(
    label: 'Behaviour · Negative',
    initialValue: true,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return _NumberPreview(
    initial: initial,
    allowDecimal: allowDecimal,
    allowNegative: allowNegative,
    enabled: enabled,
  );
}

final class _NumberPreview extends StatefulWidget {
  const _NumberPreview({
    required this.initial,
    required this.allowDecimal,
    required this.allowNegative,
    required this.enabled,
  });
  final double initial;
  final bool allowDecimal;
  final bool allowNegative;
  final bool enabled;
  @override
  State<_NumberPreview> createState() => _NumberPreviewState();
}

final class _NumberPreviewState extends State<_NumberPreview> {
  late num? _value = widget.initial;
  @override
  void didUpdateWidget(_NumberPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial) _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    SizedBox(
      width: context.units(22.rem),
      child: CarpenterNumberInput(
        value: _value,
        onChanged: widget.enabled
            ? (value) => setState(() => _value = value)
            : null,
        label: 'Amount',
        description: 'Typed num? value, commas accepted as decimal separators.',
        placeholder: '0.00',
        allowDecimal: widget.allowDecimal,
        allowNegative: widget.allowNegative,
        min: widget.allowNegative ? -10000 : 0,
        max: 10000,
        availability: widget.enabled
            ? FieldAvailability.enabled
            : FieldAvailability.disabled,
      ),
    ),
    CarpenterText.caption('Value: ${_value ?? 'null'}'),
  ]);
}

Widget _numberStates(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(18.rem),
    child: CarpenterNumberInput(value: 42, onChanged: (_) {}, label: 'Enabled'),
  ),
  SizedBox(
    width: context.units(18.rem),
    child: CarpenterNumberInput(
      value: 12,
      onChanged: (_) {},
      label: 'Bounded',
      min: 10,
      max: 20,
      description: '10…20',
    ),
  ),
  SizedBox(
    width: context.units(18.rem),
    child: CarpenterNumberInput(
      value: 7,
      onChanged: null,
      label: 'Disabled',
      availability: FieldAvailability.disabled,
    ),
  ),
]);

Widget _timeInput(BuildContext context) {
  final minuteStep = context.knobs.object.segmented(
    label: 'Behaviour · Minute step',
    options: const [1, 5, 10, 15, 30],
    initialOption: 5,
    labelBuilder: (value) => '$value min',
  );
  final allowClear = context.knobs.boolean(
    label: 'Behaviour · Allow clear',
    initialValue: true,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return _TimePreview(
    minuteStep: minuteStep,
    allowClear: allowClear,
    enabled: enabled,
  );
}

final class _TimePreview extends StatefulWidget {
  const _TimePreview({
    required this.minuteStep,
    required this.allowClear,
    required this.enabled,
  });
  final int minuteStep;
  final bool allowClear;
  final bool enabled;
  @override
  State<_TimePreview> createState() => _TimePreviewState();
}

final class _TimePreviewState extends State<_TimePreview> {
  CarpenterTime? _value = const CarpenterTime(hour: 14, minute: 30);
  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterTimeInput(
      value: _value,
      onChanged: (value) => setState(() => _value = value),
      minuteStep: widget.minuteStep,
      allowClear: widget.allowClear,
      enabled: widget.enabled,
    ),
    CarpenterText.caption(
      _value == null ? 'No time selected' : carpenterFormatTime(_value!),
    ),
  ]);
}

Widget _dateRangeInput(BuildContext context) {
  final start = context.knobs.dateTimeOrNull(
    label: 'Value · Start',
    initialValue: DateTime(2026, 9, 1),
    start: DateTime(2025),
    end: DateTime(2028, 12, 31),
  );
  final end = context.knobs.dateTimeOrNull(
    label: 'Value · End',
    initialValue: DateTime(2026, 9, 12),
    start: DateTime(2025),
    end: DateTime(2028, 12, 31),
  );
  return _DateRangePreview(start: start, end: end);
}

final class _DateRangePreview extends StatefulWidget {
  const _DateRangePreview({required this.start, required this.end});
  final DateTime? start;
  final DateTime? end;
  @override
  State<_DateRangePreview> createState() => _DateRangePreviewState();
}

final class _DateRangePreviewState extends State<_DateRangePreview> {
  CarpenterDateRange? _value;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_DateRangePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start || oldWidget.end != widget.end) _sync();
  }

  void _sync() {
    _value =
        widget.start != null &&
            widget.end != null &&
            !widget.end!.isBefore(widget.start!)
        ? CarpenterDateRange(start: widget.start!, end: widget.end!)
        : null;
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterDateRangeInput(
      value: _value,
      onChanged: (value) => setState(() => _value = value),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028, 12, 31),
    ),
    CarpenterText.caption(
      _value == null ? 'No range selected' : carpenterFormatDateRange(_value!),
    ),
  ]);
}

Widget _badge(BuildContext context) {
  final count = context.knobs.double
      .slider(
        label: 'Content · Count',
        initialValue: 7,
        min: 0,
        max: 150,
        divisions: 150,
      )
      .round();
  final role = context.knobs.object.segmented(
    label: 'Appearance · Role',
    options: FeedbackColorRole.values,
    initialOption: FeedbackColorRole.danger,
    labelBuilder: semanticValueLabel,
  );
  return preview(
    CarpenterBadge.count(
      count,
      role: role,
      semanticLabel: '$count notifications',
    ),
  );
}

Widget _badgeRoles(BuildContext context) => preview(
  Wrap(
    spacing: context.units(.75.rem),
    runSpacing: context.units(.75.rem),
    children: [
      for (final role in FeedbackColorRole.values)
        CarpenterBadge(label: semanticValueLabel(role), role: role),
    ],
  ),
);

Widget _avatarGroup(BuildContext context) {
  final people = context.knobs.double
      .slider(
        label: 'Content · People',
        initialValue: 7,
        min: 1,
        max: 12,
        divisions: 11,
      )
      .round();
  final maxVisible = context.knobs.double
      .slider(
        label: 'Behaviour · Visible',
        initialValue: 4,
        min: 1,
        max: 8,
        divisions: 7,
      )
      .round();
  final size = context.knobs.double.slider(
    label: 'Appearance · Size (rem)',
    initialValue: 2.5,
    min: 1.5,
    max: 5,
    divisions: 14,
  );
  const initials = [
    'NC',
    'AK',
    'IM',
    'DS',
    'EV',
    'AM',
    'MK',
    'VP',
    'TA',
    'RN',
    'AS',
    'OL',
  ];
  return preview(
    CarpenterAvatarGroup(
      items: [
        for (var index = 0; index < people; index++)
          CarpenterAvatarItem(
            initials: initials[index],
            semanticLabel: 'Person ${index + 1}',
          ),
      ],
      maxVisible: maxVisible,
      size: size.rem,
    ),
  );
}
