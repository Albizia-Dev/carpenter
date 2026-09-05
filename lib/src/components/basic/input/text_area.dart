import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/icon_data.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/rendering/icon_renderer.dart';
import '../../../internal/rendering/text_editing_field.dart';
import '../button/icon_button.dart';
import 'field_shell.dart';

final class CarpenterTextArea extends StatelessWidget {
  const CarpenterTextArea({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.description,
    this.feedback,
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
    this.keyboardType = TextInputType.multiline,
    this.textInputAction = TextInputAction.newline,
    this.focusNode,
    this.autofocus = false,
    this.minLines = 3,
    this.maxLines = 6,
  }) : assert(minLines > 0),
       assert(maxLines == null || maxLines >= minLines);

  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final String? description;
  final CarpenterFieldFeedback? feedback;
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
  final int minLines;
  final int? maxLines;

  CarpenterFieldFeedback? get _effectiveFeedback =>
      errorText != null ? CarpenterFieldFeedback.danger(errorText!) : feedback;

  @override
  Widget build(BuildContext context) {
    assert(
      trailingAction == null || trailingAction!.icon != null,
      'A trailing field action requires an icon.',
    );
    final theme = CarpenterTheme.of(context);
    final effectiveFeedback = _effectiveFeedback;
    final fieldStyle = theme.fields.resolve(
      availability: availability,
      states: availability == FieldAvailability.disabled
          ? const <WidgetState>{WidgetState.disabled}
          : effectiveFeedback?.isError ?? false
          ? const <WidgetState>{WidgetState.error}
          : const <WidgetState>{},
      hasError: effectiveFeedback?.isError ?? false,
    );
    final iconDimension = context.units(theme.sizes.fieldIcon(size));
    return TextEditingField(
      controller: controller,
      availability: availability,
      size: size,
      shape: shape,
      minLines: minLines,
      maxLines: maxLines,
      label: label,
      placeholder: placeholder,
      description: description,
      feedback: feedback,
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
      focusNode: focusNode,
      autofocus: autofocus,
    );
  }
}
