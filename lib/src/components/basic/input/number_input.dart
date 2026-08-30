import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import 'input.dart';

/// Controlled numeric field with locale-tolerant decimal parsing.
final class CarpenterNumberInput extends StatefulWidget {
  const CarpenterNumberInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.allowDecimal = true,
    this.allowNegative = true,
    this.min,
    this.max,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
  }) : assert(min == null || max == null || min <= max);

  final num? value;
  final ValueChanged<num?>? onChanged;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final bool allowDecimal;
  final bool allowNegative;
  final num? min;
  final num? max;
  final ValueChanged<num?>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<CarpenterNumberInput> createState() => _CarpenterNumberInputState();
}

final class _CarpenterNumberInputState extends State<CarpenterNumberInput> {
  late final TextEditingController _controller = TextEditingController(
    text: _format(widget.value),
  );
  String? _localError;

  @override
  void didUpdateWidget(CarpenterNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final next = _format(widget.value);
      if (_controller.text != next) {
        _controller.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      }
      _localError = null;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(num? value) => value?.toString() ?? '';

  num? _parse(String raw, {required bool reportError}) {
    final text = raw.trim();
    if (text.isEmpty) {
      _setLocalError(null, report: reportError);
      return null;
    }

    final parsed = num.tryParse(text.replaceAll(',', '.'));
    String? error;
    if (parsed == null) {
      error = 'Enter a valid number';
    } else if (!widget.allowNegative && parsed < 0) {
      error = 'Negative values are not allowed';
    } else if (!widget.allowDecimal && parsed != parsed.roundToDouble()) {
      error = 'Enter a whole number';
    } else if (widget.min != null && parsed < widget.min!) {
      error = 'Minimum is ${widget.min}';
    } else if (widget.max != null && parsed > widget.max!) {
      error = 'Maximum is ${widget.max}';
    }

    _setLocalError(error, report: reportError);
    return error == null ? parsed : null;
  }

  void _setLocalError(String? error, {required bool report}) {
    if (!report || error == _localError) return;
    setState(() {
      _localError = error;
    });
  }

  TextInputFormatter get _formatter =>
      FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'));

  @override
  Widget build(BuildContext context) => CarpenterInput(
    controller: _controller,
    label: widget.label,
    placeholder: widget.placeholder,
    description: widget.description,
    errorText: widget.errorText ?? _localError,
    semanticLabel: widget.semanticLabel,
    required: widget.required,
    availability: widget.availability,
    size: widget.size,
    shape: widget.shape,
    keyboardType: TextInputType.numberWithOptions(
      decimal: widget.allowDecimal,
      signed: widget.allowNegative,
    ),
    inputFormatters: [_formatter],
    textInputAction: TextInputAction.done,
    focusNode: widget.focusNode,
    autofocus: widget.autofocus,
    onChanged: _handleChanged,
    onSubmitted: _handleSubmitted,
  );

  void _handleChanged(String raw) {
    final parsed = _parse(raw, reportError: true);
    if (_localError == null) widget.onChanged?.call(parsed);
  }

  void _handleSubmitted(String raw) {
    final parsed = _parse(raw, reportError: true);
    if (_localError == null) widget.onSubmitted?.call(parsed);
  }
}
