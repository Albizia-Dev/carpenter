import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../button/button.dart';
import '../calendar.dart';
import '../icons.dart';
import 'adaptive_picker.dart';
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
  if (candidate.year != year || candidate.month != month || candidate.day != day) {
    return null;
  }
  return candidate;
}

/// Controlled date field with masked manual entry and an adaptive picker action.
final class CarpenterDateInput extends StatefulWidget {
  const CarpenterDateInput({
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

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
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
  State<CarpenterDateInput> createState() => _CarpenterDateInputState();
}

final class _CarpenterDateInputState extends State<CarpenterDateInput> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  String? _validationError;
  late DateTime _draft = _initialDraft();

  bool get _interactive =>
      widget.enabled && widget.availability == FieldAvailability.enabled;

  DateTime _initialDraft() => _clampDate(
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
    if (value) _draft = _initialDraft();
    setState(() => _open = value);
  }

  void _handleTextChanged(String text) {
    if (text.isEmpty) {
      setState(() => _validationError = null);
      if (widget.allowClear) widget.onChanged(null);
      return;
    }
    if (!CarpenterInputMask.date.isComplete(text)) {
      if (_validationError != null) setState(() => _validationError = null);
      return;
    }
    final parsed = carpenterParseDate(text);
    final error = _dateError(parsed, widget.firstDate, widget.lastDate);
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
    widget.onChanged(_draft);
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
      title: 'Choose date',
      dismissPolicy: DialogDismissPolicy.outsideAndEscape,
      actions: [
        if (widget.allowClear)
          CarpenterActionDescriptor(
            id: 'date.clear',
            label: 'Clear',
            onInvoke: _clear,
          ),
        CarpenterActionDescriptor(
          id: 'date.cancel',
          label: 'Cancel',
          onInvoke: () => _setOpen(false),
        ),
        CarpenterActionDescriptor(
          id: 'date.apply',
          label: 'Apply',
          colorRole: ActionColorRole.primary,
          onInvoke: _applyDraft,
        ),
      ],
      content: wheel
          ? CarpenterDateWheel(
              value: _draft,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              onChanged: (value) => setState(() => _draft = value),
            )
          : CarpenterCalendar(
              selected: _draft,
              firstDate: widget.firstDate,
              lastDate: widget.lastDate,
              initialMonth: _draft,
              onChanged: (value) => setState(() => _draft = value),
            ),
      child: CarpenterMaskedInput(
        controller: _controller,
        mask: CarpenterInputMask.date,
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
          id: 'date.open-picker',
          label: 'Choose date',
          semanticLabel: 'Open date picker',
          icon: CarpenterIcons.calendar,
          onInvoke: _interactive ? () => _setOpen(true) : null,
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

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

bool _sameNullableDate(DateTime? first, DateTime? second) {
  if (first == null || second == null) return first == second;
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
