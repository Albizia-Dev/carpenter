import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/icon_renderer.dart';
import '../../../internal/rendering/text_editing_field.dart';
import '../button/icon_button.dart';

final class CarpenterInput extends StatelessWidget {
  const CarpenterInput({
    super.key,
    required this.controller,
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
    this.inputFormatters,
    this.focusNode,
    this.autofocus = false,
  });

  final TextEditingController controller;
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
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    assert(
      trailingAction == null || trailingAction!.icon != null,
      'A trailing field action requires an icon.',
    );
    final theme = CarpenterTheme.of(context);
    final fieldStyle = theme.fields.resolve(
      availability: availability,
      states: availability == FieldAvailability.disabled
          ? const <WidgetState>{WidgetState.disabled}
          : const <WidgetState>{},
      hasError: errorText != null,
    );
    final iconDimension = context.units(theme.sizes.fieldIcon(size));
    return TextEditingField(
      controller: controller,
      availability: availability,
      size: size,
      shape: shape,
      minLines: 1,
      maxLines: 1,
      label: label,
      placeholder: placeholder,
      description: description,
      errorText: errorText,
      semanticLabel: semanticLabel,
      required: required,
      leading: leadingIcon == null
          ? null
          : ExcludeSemantics(
              child: IconRenderer(
                icon: leadingIcon!,
                size: iconDimension,
                color: fieldStyle.icon,
              ),
            ),
      trailing: trailingAction == null
          ? null
          : CarpenterIconButton.fromAction(
              trailingAction!,
              prominence: ActionProminence.ghost,
              size: theme.sizes.controlForField(size),
            ),
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}
