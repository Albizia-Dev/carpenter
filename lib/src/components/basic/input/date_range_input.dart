import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/date/picker_host.dart';
import '../../../internal/date/calendar_model.dart';
import '../button/button.dart';
import '../calendar.dart';
import '../gravity_icons.g.dart';
import '../text.dart';

import 'date_input.dart';
import 'field_shell.dart';
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

/// Controlled inclusive date range field with numeric entry and a shared non-modal range calendar.
final class CarpenterDateRangeInput extends StatefulWidget {
  const CarpenterDateRangeInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.description,
    this.feedback,
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
  final CarpenterFieldFeedback? feedback;
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
  DateTime? _rangeAnchor;
  String? _validationError;
  late DateTime _start = _initialStart();
  late DateTime _end = _initialEnd(_start);

  bool get _interactive =>
      widget.enabled && widget.availability == FieldAvailability.enabled;

  DateTime _initialStart() => CalendarModel.clamp(
    widget.value?.start ?? DateTime.now(),
    widget.firstDate,
    widget.lastDate,
  );

  DateTime _initialEnd(DateTime start) {
    final candidate = CalendarModel.clamp(
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
    if (!_interactive) _open = false;
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
    if (value && !_interactive) return;
    if (value) {
      _rangeAnchor = null;
      _start = _initialStart();
      _end = _initialEnd(_start);
    }
    if (value) FocusManager.instance.primaryFocus?.unfocus();
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

  void _selectDate(DateTime value) {
    if (_rangeAnchor == null) {
      setState(() {
        _rangeAnchor = value;
        _start = value;
        _end = value;
      });
      return;
    }
    final anchor = _rangeAnchor!;
    _start = value.isBefore(anchor) ? value : anchor;
    _end = value.isBefore(anchor) ? anchor : value;
    _rangeAnchor = null;
    _applyDraft();
  }

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
    return PickerHost(
      open: _open && _interactive,
      onOpenChanged: _setOpen,
      picker: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CarpenterText.label(
                _rangeAnchor == null
                    ? 'Выберите начальную дату'
                    : 'Выберите конечную дату',
              ),
              SizedBox(height: context.units(.5.rem)),
              CarpenterCalendar(
                selected: _rangeAnchor == null ? widget.value?.start : _start,
                rangeStart: _rangeAnchor ?? widget.value?.start,
                rangeEnd: _rangeAnchor == null ? widget.value?.end : null,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                initialMonth: _start,
                onChanged: _selectDate,
              ),
            ],
          ),
          if (widget.allowClear) ...[
            SizedBox(height: context.units(.5.rem)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CarpenterButton(
                label: 'Очистить',
                size: ControlSize.small,
                prominence: ActionProminence.ghost,
                onInvoke: _clear,
              ),
            ),
          ],
        ],
      ),
      field: CarpenterMaskedInput(
        controller: _controller,
        mask: CarpenterInputMask.dateRange,
        label: widget.label,
        placeholder: widget.placeholder ?? 'ДД.ММ.ГГГГ – ДД.ММ.ГГГГ',
        description: widget.description,
        feedback: widget.feedback,
        errorText: widget.errorText ?? _validationError,
        semanticLabel: widget.semanticLabel,
        required: widget.required,
        availability: widget.enabled
            ? widget.availability
            : FieldAvailability.disabled,
        size: widget.size,
        shape: widget.shape,
        keyboardType: TextInputType.number,
        autofocus: widget.autofocus,
        trailingAction: CarpenterActionDescriptor(
          id: 'date-range.open-picker',
          label: 'Выбрать период',
          semanticLabel: 'Открыть выбор периода',
          icon: GravityIcons.calendar,
          onInvoke: _interactive ? () => _setOpen(!_open) : null,
        ),
        onChanged: _interactive ? _handleTextChanged : null,
      ),
    );
  }
}

String? _rangeError(
  CarpenterDateRange? value,
  DateTime? firstDate,
  DateTime? lastDate,
) {
  if (value == null) return 'Некорректный период';
  if (firstDate != null && value.start.isBefore(_dateOnly(firstDate))) {
    return 'Начальная дата раньше допустимой';
  }
  if (lastDate != null && value.end.isAfter(_dateOnly(lastDate))) {
    return 'Конечная дата позже допустимой';
  }
  return null;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
