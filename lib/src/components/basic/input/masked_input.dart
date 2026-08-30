import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import 'input.dart';

@immutable
final class CarpenterInputMask {
  const CarpenterInputMask(
    this.pattern, {
    this.placeholderCharacter = '_',
  }) : assert(pattern.length > 0),
       assert(placeholderCharacter.length == 1);

  static const date = CarpenterInputMask('##.##.####');
  static const time = CarpenterInputMask('##:##');
  static const dateRange = CarpenterInputMask('##.##.#### – ##.##.####');

  final String pattern;
  final String placeholderCharacter;

  String get placeholder {
    final buffer = StringBuffer();
    for (final part in _parts) {
      buffer.write(part.slot == null ? part.literal : placeholderCharacter);
    }
    return buffer.toString();
  }

  int get slotCount => _parts.where((part) => part.slot != null).length;

  bool isComplete(String value) => unmask(value).length == slotCount;

  String unmask(String value) {
    final slots = _parts.where((part) => part.slot != null).toList();
    final buffer = StringBuffer();
    var slotIndex = 0;
    for (final codePoint in value.runes) {
      if (slotIndex >= slots.length) break;
      final character = String.fromCharCode(codePoint);
      final slot = slots[slotIndex].slot!;
      if (_accepts(slot, character)) {
        buffer.write(character);
        slotIndex++;
      }
    }
    return buffer.toString();
  }

  String format(String value) => _formatRaw(unmask(value));

  List<_MaskPart> get _parts {
    final result = <_MaskPart>[];
    var escaped = false;
    for (final codePoint in pattern.runes) {
      final character = String.fromCharCode(codePoint);
      if (escaped) {
        result.add(_MaskPart.literal(character));
        escaped = false;
        continue;
      }
      if (character == r'\') {
        escaped = true;
        continue;
      }
      final slot = switch (character) {
        '#' => _MaskSlot.digit,
        'A' => _MaskSlot.letter,
        '*' => _MaskSlot.alphaNumeric,
        _ => null,
      };
      result.add(slot == null ? _MaskPart.literal(character) : _MaskPart.slot(slot));
    }
    if (escaped) result.add(const _MaskPart.literal(r'\'));
    return result;
  }

  String _formatRaw(String raw) {
    final buffer = StringBuffer();
    var rawIndex = 0;
    var consumedSlot = false;
    for (final part in _parts) {
      final slot = part.slot;
      if (slot != null) {
        if (rawIndex >= raw.length) break;
        final character = raw[rawIndex];
        if (!_accepts(slot, character)) break;
        buffer.write(character);
        rawIndex++;
        consumedSlot = true;
        continue;
      }
      if (consumedSlot) buffer.write(part.literal);
    }
    return buffer.toString();
  }

  bool _accepts(_MaskSlot slot, String value) => switch (slot) {
    _MaskSlot.digit => RegExp(r'^\d$').hasMatch(value),
    _MaskSlot.letter => RegExp(r'^[A-Za-zА-Яа-яЁё]$').hasMatch(value),
    _MaskSlot.alphaNumeric => RegExp(r'^[0-9A-Za-zА-Яа-яЁё]$').hasMatch(value),
  };
}

enum _MaskSlot { digit, letter, alphaNumeric }

final class _MaskPart {
  const _MaskPart.slot(this.slot) : literal = null;
  const _MaskPart.literal(this.literal) : slot = null;

  final _MaskSlot? slot;
  final String? literal;
}

final class _CarpenterMaskFormatter extends TextInputFormatter {
  const _CarpenterMaskFormatter(this.mask);

  final CarpenterInputMask mask;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = mask.unmask(newValue.text);
    final oldRaw = mask.unmask(oldValue.text);

    if (newValue.text.length < oldValue.text.length && raw == oldRaw && raw.isNotEmpty) {
      final rawCursor = mask.unmask(
        oldValue.text.substring(0, oldValue.selection.baseOffset.clamp(0, oldValue.text.length)),
      ).length;
      final removeAt = (rawCursor - 1).clamp(0, raw.length - 1);
      raw = raw.substring(0, removeAt) + raw.substring(removeAt + 1);
    }

    final formatted = mask._formatRaw(raw);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

/// Text input that applies a semantic mask while reusing the standard Carpenter field pipeline.
///
/// Mask tokens are `#` for digits, `A` for letters and `*` for alphanumeric
/// characters. Prefix a token with `\\` to render it literally.
final class CarpenterMaskedInput extends StatelessWidget {
  const CarpenterMaskedInput({
    super.key,
    required this.controller,
    required this.mask,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.leadingIcon,
    this.trailingAction,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final CarpenterInputMask mask;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final CarpenterIconSource? leadingIcon;
  final CarpenterActionDescriptor? trailingAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool autofocus;

  String unmask(String value) => mask.unmask(value);

  @override
  Widget build(BuildContext context) => CarpenterInput(
    controller: controller,
    label: label,
    placeholder: placeholder ?? mask.placeholder,
    description: description,
    errorText: errorText,
    semanticLabel: semanticLabel,
    required: required,
    availability: availability,
    size: size,
    shape: shape,
    leadingIcon: leadingIcon,
    trailingAction: trailingAction,
    onChanged: onChanged,
    onSubmitted: onSubmitted,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    inputFormatters: [_CarpenterMaskFormatter(mask)],
    focusNode: focusNode,
    autofocus: autofocus,
  );
}
