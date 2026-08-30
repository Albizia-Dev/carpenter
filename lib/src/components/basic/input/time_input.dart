import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../icons.dart';
import 'adaptive_picker.dart';
import 'masked_input.dart';

@immutable
final class CarpenterTime {
  const CarpenterTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is CarpenterTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

String carpenterFormatTime(CarpenterTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

CarpenterTime? carpenterParseTime(String value) {
  final parts = value.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return CarpenterTime(hour: hour, minute: minute);
}

/// Controlled 24-hour field with masked manual entry and an adaptive picker action.
final class CarpenterTimeInput extends StatefulWidget {
  const CarpenterTimeInput({
    super.key,
    this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.minuteStep = 5,
    this.enabled = true,
    this.allowClear = true,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.semanticLabel,
    this.autofocus = false,
  }) : assert(minuteStep > 0 && minuteStep <= 30 && 60 % minuteStep == 0);

  final CarpenterTime? value;
  final ValueChanged<CarpenterTime?> onChanged;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final int minuteStep;
  final bool enabled;
  final bool allowClear;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final String? semanticLabel;
  final bool autofocus;

  @override
  State<CarpenterTimeInput> createState() => _CarpenterTimeInputState();
}

final class _CarpenterTimeInputState extends State<CarpenterTimeInput> {
  final TextEditingController _controller = TextEditingController();
  bool _open = false;
  String? _validationError;
  late CarpenterTime _draft = _initialDraft();

  bool get _interactive =>
      widget.enabled && widget.availability == FieldAvailability.enabled;

  CarpenterTime _initialDraft() {
    final current = widget.value;
    if (current != null) return current;
    final now = DateTime.now();
    return CarpenterTime(
      hour: now.hour,
      minute: (now.minute ~/ widget.minuteStep) * widget.minuteStep,
    );
  }

  @override
  void initState() {
    super.initState();
    _syncText();
  }

  @override
  void didUpdateWidget(CarpenterTimeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) _syncText();
  }

  void _syncText() {
    final text = widget.value == null ? '' : carpenterFormatTime(widget.value!);
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
    if (!CarpenterInputMask.time.isComplete(text)) {
      if (_validationError != null) setState(() => _validationError = null);
      return;
    }
    final parsed = carpenterParseTime(text);
    String? error;
    if (parsed == null) {
      error = 'Invalid time';
    } else if (parsed.minute % widget.minuteStep != 0) {
      error = 'Minute must match a ${widget.minuteStep}-minute step';
    }
    setState(() => _validationError = error);
    if (parsed != null && error == null) widget.onChanged(parsed);
  }

  void _applyDraft() {
    final text = carpenterFormatTime(_draft);
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
      title: 'Choose time',
      dismissPolicy: DialogDismissPolicy.outsideAndEscape,
      actions: [
        if (widget.allowClear)
          CarpenterActionDescriptor(
            id: 'time.clear',
            label: 'Clear',
            onInvoke: _clear,
          ),
        CarpenterActionDescriptor(
          id: 'time.cancel',
          label: 'Cancel',
          onInvoke: () => _setOpen(false),
        ),
        CarpenterActionDescriptor(
          id: 'time.apply',
          label: 'Apply',
          colorRole: ActionColorRole.primary,
          onInvoke: _applyDraft,
        ),
      ],
      content: wheel
          ? CarpenterTimeWheel(
              hour: _draft.hour,
              minute: _draft.minute,
              minuteStep: widget.minuteStep,
              onChanged: (hour, minute) => setState(
                () => _draft = CarpenterTime(hour: hour, minute: minute),
              ),
            )
          : CarpenterTimeSelect(
              hour: _draft.hour,
              minute: _draft.minute,
              minuteStep: widget.minuteStep,
              onChanged: (hour, minute) => setState(
                () => _draft = CarpenterTime(hour: hour, minute: minute),
              ),
            ),
      child: CarpenterMaskedInput(
        controller: _controller,
        mask: CarpenterInputMask.time,
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
          id: 'time.open-picker',
          label: 'Choose time',
          semanticLabel: 'Open time picker',
          icon: CarpenterIcons.clock,
          onInvoke: _interactive ? () => _setOpen(true) : null,
        ),
        onChanged: _interactive ? _handleTextChanged : null,
      ),
    );
  }
}
