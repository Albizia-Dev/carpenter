import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../calendar.dart';
import '../icons.dart';
import '../text.dart';
import 'adaptive_picker.dart';
import 'date_input.dart';
import 'masked_input.dart';

@immutable
final class CarpenterDateRange {
  CarpenterDateRange({required this.start, required this.end})
    : assert(!end.isBefore(start));

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is CarpenterDateRange &&
      _sameDate(other.start, start) &&
      _sameDate(other.end, end);

  @override
  int get hashCode => Object.hash(
    DateTime(start.year, start.month, start.day),
    DateTime(end.year, end.month, end.day),
  );
}

String carpenterFormatDateRange(CarpenterDateRange value) =>
    '${carpenterFormatDate(value.start)} – ${carpenterFormatDate(value.end)}';

CarpenterDateRange? carpenterParseDateRange(String value) {
  if (value.length < 23) return null;
  final start = carpenterParseDate(value.substring(0, 10));
  final end = carpenterParseDate(value.substring(value.length - 10));
  if (start == null || end == null || end.isBefore(start)) return null;
  return CarpenterDateRange(start: start, end: end);
}

/// Controlled inclusive date range field with a mask and adaptive picker action.
final class CarpenterDateRangeInput extends StatefulWidget {
  const CarpenterDateRangeInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.allowClear = true,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.semanticLabel,
    this.autofocus = false,
  });

  final CarpenterDateRange? value;
  final ValueChanged<CarpenterDateRange?> onChanged;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool allowClear;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final String? semanticLabel;
  final bool autofocus;

  @override
  State<CarpenterDateRangeInput> createState() =>
      _CarpenterDateRangeInputState();
}

final class _CarpenterDateRangeInputState
    extends State<CarpenterDateRangeInput> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  String? _validationError;
  late DateTime _start = _initialStart();
  late DateTime _end = _initialEnd(_start);

  bool get _interactive =>
      widget.enabled && widget.availability == FieldAvailability.enabled;

  DateTime _initialStart() => _clampDate(
    widget.value?.start ?? DateTime.now(),
    widget.firstDate,
    widget.lastDate,
  );

  DateTime _initialEnd(DateTime start) {
    final candidate = _clampDate(
      widget.value?.end ?? start,
      start,
      widget.lastDate,
    );
    return candidate.isBefore(start) ? start : candidate;
  }

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void didUpdateWidget(CarpenterDateRangeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncText();
  }

  void _syncText() {
    final text = widget.value == null
        ? ''
        : carpenterFormatDateRange(widget.value!);
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _validationError = null;
  }

  void _setOpen(bool value) {
    if (value) {
      _start = _initialStart();
      _end = _initialEnd(_start);
    }
    setState(() => _open = value);
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      setState(() => _validationError = null);
      if (widget.allowClear) widget.onChanged(null);
      return;
    }
    if (!CarpenterInputMask.dateRange.isComplete(text)) {
      if (_validationError != null) setState(() => _validationError = null);
      return;
    }
    final range = carpenterParseDateRange(text);
    final error = _rangeError(range, widget.firstDate, widget.lastDate);
    setState(() => _validationError = error);
    if (range != null && error == null) widget.onChanged(range);
  }

  void _changeStart(DateTime value) {
    setState(() {
      _start = value;
      if (_end.isBefore(value)) _end = value;
    });
  }

  void _changeEnd(DateTime value) => setState(() => _end = value);

  void _applyDraft() {
    final range = CarpenterDateRange(start: _start, end: _end);
    final text = carpenterFormatDateRange(range);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _validationError = null;
      _open = false;
    });
    widget.onChanged(range);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _validationError = null;
      _open = false;
    });
    widget.onChanged(null);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wheel = carpenterUsesWheelPicker(context);
    return CarpenterDialog(
      open: _open,
      onOpenChanged: _setOpen,
      title: 'Choose date range',
      dismissPolicy: DialogDismissPolicy.outsideAndEscape,
      actions: [
        if (widget.allowClear)
          CarpenterActionDescriptor(
            id: 'date-range.clear',
            label: 'Clear',
            onInvoke: _clear,
          ),
        CarpenterActionDescriptor(
          id: 'date-range.cancel',
          label: 'Cancel',
          onInvoke: () => _setOpen(false),
        ),
        CarpenterActionDescriptor(
          id: 'date-range.apply',
          label: 'Apply',
          colorRole: ActionColorRole.primary,
          onInvoke: _applyDraft,
        ),
      ],
      content: LayoutBuilder(
        builder: (context, constraints) {
          final gap = context.units(.75.rem);
          final compact = constraints.maxWidth < context.units(40.rem);
          final startPicker = _RangePicker(
            label: 'Start date',
            wheel: wheel,
            selected: _start,
            firstDate: widget.firstDate,
            lastDate: _end,
            onChanged: _changeStart,
          );
          final endPicker = _RangePicker(
            label: 'End date',
            wheel: wheel,
            selected: _end,
            firstDate: _start,
            lastDate: widget.lastDate,
            onChanged: _changeEnd,
          );
          return SizedBox(
            width: compact ? constraints.maxWidth : context.units(42.rem),
            child: compact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      startPicker,
                      SizedBox(height: gap),
                      endPicker,
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: startPicker),
                      SizedBox(width: gap),
                      Expanded(child: endPicker),
                    ],
                  ),
          );
        },
      ),
      child: CarpenterMaskedInput(
        controller: _controller,
        mask: CarpenterInputMask.dateRange,
        label: widget.label,
        placeholder: widget.placeholder,
        description: widget.description,
        errorText: widget.errorText ?? _validationError,
        semanticLabel: widget.semanticLabel,
        required: widget.required,
        availability: widget.enabled
            ? widget.availability
            : FieldAvailability.disabled,
        size: widget.size,
        shape: widget.shape,
        keyboardType: TextInputType.datetime,
        autofocus: widget.autofocus,
        trailingAction: CarpenterActionDescriptor(
          id: 'date-range.open-picker',
          label: 'Choose date range',
          semanticLabel: 'Open date range picker',
          icon: CarpenterIcons.calendar,
          onInvoke: _interactive ? () => _setOpen(true) : null,
        ),
        onChanged: _interactive ? _handleTextChanged : null,
      ),
    );
  }
}

final class _RangePicker extends StatelessWidget {
  const _RangePicker({
    required this.label,
    required this.wheel,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final bool wheel;
  final DateTime selected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CarpenterText.label(label, emphasis: TypographyEmphasis.strong),
      SizedBox(height: context.units(.5.rem)),
      if (wheel)
        CarpenterDateWheel(
          value: selected,
          firstDate: firstDate,
          lastDate: lastDate,
          semanticLabel: label,
          onChanged: onChanged,
        )
      else
        CarpenterCalendar(
          selected: selected,
          firstDate: firstDate,
          lastDate: lastDate,
          initialMonth: selected,
          onChanged: onChanged,
        ),
    ],
  );
}

String? _rangeError(
  CarpenterDateRange? value,
  DateTime? firstDate,
  DateTime? lastDate,
) {
  if (value == null) return 'Invalid date range';
  if (firstDate != null && value.start.isBefore(_dateOnly(firstDate))) {
    return 'Start date is before the allowed range';
  }
  if (lastDate != null && value.end.isAfter(_dateOnly(lastDate))) {
    return 'End date is after the allowed range';
  }
  return null;
}

DateTime _clampDate(DateTime value, DateTime? firstDate, DateTime? lastDate) {
  final date = _dateOnly(value);
  if (firstDate != null && date.isBefore(_dateOnly(firstDate))) {
    return _dateOnly(firstDate);
  }
  if (lastDate != null && date.isAfter(_dateOnly(lastDate))) {
    return _dateOnly(lastDate);
  }
  return date;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
