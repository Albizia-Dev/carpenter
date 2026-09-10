import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/date/picker_host.dart';
import '../../../internal/date/calendar_model.dart';
import '../button/button.dart';
import '../calendar.dart';
import '../gravity_icons.g.dart';

import 'field_shell.dart';
import 'masked_input.dart';

DateTime? carpenterParseDate(String value) {
  final parts = value.split('.');
  if (parts.length != 3) return null;
  final day = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final year = int.tryParse(parts[2]);
  if (day == null || month == null || year == null) return null;
  if (year < 1 || month < 1 || month > 12 || day < 1) return null;
  final candidate = DateTime(year, month, day);
  if (candidate.year != year ||
      candidate.month != month ||
      candidate.day != day) {
    return null;
  }
  return candidate;
}

/// Controlled date field with numeric keyboard entry and non-modal anchored/inline selection.
final class CarpenterDateInput extends StatefulWidget {
  /// Edits a controlled date using text entry or the shared calendar picker.
  /// The caller commits accepted dates through [onChanged]. Use
  /// [onInputValidityChanged] to prevent submitting an incomplete text draft.
  const CarpenterDateInput({
    super.key,
    this.value,
    required this.onChanged,
    this.onInputValidityChanged,
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

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  /// Reports whether each user edit can be submitted, before [onChanged].
  /// Incomplete, impossible and out-of-bounds dates report false without
  /// replacing [value]. Optional clearable empty input reports true. Calendar
  /// selection and the clear action also report validity. No event is emitted
  /// on initial build or external value replacement; callers own those values.
  /// Omit the callback when only accepted dates are needed.
  final ValueChanged<bool>? onInputValidityChanged;
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
  State<CarpenterDateInput> createState() => _CarpenterDateInputState();
}

final class _CarpenterDateInputState extends State<CarpenterDateInput> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  String? _validationError;
  late DateTime _draft = _initialDraft();

  bool get _interactive =>
      widget.enabled && widget.availability == FieldAvailability.enabled;

  DateTime _initialDraft() => CalendarModel.clamp(
    widget.value ?? DateTime.now(),
    widget.firstDate,
    widget.lastDate,
  );

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void didUpdateWidget(CarpenterDateInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _open = false;
    if (!_sameNullableDate(oldWidget.value, widget.value)) _syncText();
  }

  void _syncText() {
    final text = widget.value == null ? '' : carpenterFormatDate(widget.value!);
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _validationError = null;
  }

  void _setOpen(bool value) {
    if (value && !_interactive) return;
    if (value) _draft = _initialDraft();
    if (value) FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _open = value);
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      widget.onInputValidityChanged?.call(
        widget.allowClear && !widget.required,
      );
      setState(() => _validationError = null);
      if (widget.allowClear) widget.onChanged(null);
      return;
    }
    if (!CarpenterInputMask.date.isComplete(text)) {
      widget.onInputValidityChanged?.call(false);
      if (_validationError != null) setState(() => _validationError = null);
      return;
    }
    final parsed = carpenterParseDate(text);
    final error = _dateError(parsed, widget.firstDate, widget.lastDate);
    widget.onInputValidityChanged?.call(error == null);
    setState(() => _validationError = error);
    if (parsed != null && error == null) widget.onChanged(parsed);
  }

  void _applyDraft() {
    final text = carpenterFormatDate(_draft);
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {
      _validationError = null;
      _open = false;
    });
    widget.onInputValidityChanged?.call(true);
    widget.onChanged(_draft);
  }

  void _clear() {
    _controller.clear();
    setState(() {
      _validationError = null;
      _open = false;
    });
    widget.onInputValidityChanged?.call(!widget.required);
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
          CarpenterCalendar(
            selected: widget.value,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            initialMonth: _draft,
            onChanged: (value) {
              _draft = value;
              _applyDraft();
            },
          ),
          if (widget.allowClear) ...[
            SizedBox(height: context.units(.5.rem)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: CarpenterButton(
                label: 'Clear',
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
        mask: CarpenterInputMask.date,
        label: widget.label,
        placeholder: widget.placeholder ?? 'DD.MM.YYYY',
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
          id: 'date.open-picker',
          label: 'Choose date',
          semanticLabel: 'Open date picker',
          icon: GravityIcons.calendar,
          onInvoke: _interactive ? () => _setOpen(!_open) : null,
        ),
        onChanged: _interactive ? _handleTextChanged : null,
      ),
    );
  }
}

String? _dateError(DateTime? value, DateTime? firstDate, DateTime? lastDate) {
  if (value == null) return 'Invalid date';
  final date = DateTime(value.year, value.month, value.day);
  if (firstDate != null && date.isBefore(_dateOnly(firstDate))) {
    return 'Date is before the allowed range';
  }
  if (lastDate != null && date.isAfter(_dateOnly(lastDate))) {
    return 'Date is after the allowed range';
  }
  return null;
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _sameNullableDate(DateTime? first, DateTime? second) {
  if (first == null || second == null) return first == second;
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
