import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'field_shell.dart';
import 'interactive_region.dart';

final class SelectableField extends StatelessWidget {
  const SelectableField({
    super.key,
    required this.valueText,
    required this.availability,
    required this.size,
    required this.shape,
    required this.open,
    required this.onActivate,
    this.placeholder,
    this.label,
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.focusNode,
    this.autofocus = false,
  });

  final String? valueText;
  final String? placeholder;
  final String? label;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final bool open;
  final VoidCallback? onActivate;
  final FocusNode? focusNode;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final disabled = availability == FieldAvailability.disabled;
    final readOnly = availability == FieldAvailability.readOnly;
    final focusableAction = disabled ? null : (onActivate ?? () {});
    return Semantics(
      container: true,
      textField: true,
      enabled: !disabled,
      readOnly: readOnly,
      expanded: open,
      isRequired: required ? true : null,
      label: semanticLabel ?? label,
      value: valueText,
      hint: errorText ?? description ?? placeholder,
      onTap: readOnly || disabled ? null : onActivate,
      excludeSemantics: true,
      child: InteractiveRegion(
        onActivate: focusableAction,
        activationBlocked: readOnly || onActivate == null,
        focusNode: focusNode,
        autofocus: autofocus && !disabled,
        shortcutCallbacks: {
          if (!readOnly && onActivate != null)
            const SingleActivator(LogicalKeyboardKey.arrowDown): onActivate!,
        },
        builder: (context, states, showFocusHighlight) {
          final theme = CarpenterTheme.of(context);
          final fieldStates = <WidgetState>{
            ...states,
            if (errorText != null) WidgetState.error,
          };
          final style = theme.fields.resolve(
            availability: availability,
            states: fieldStates,
            hasError: errorText != null,
          );
          final hasValue = valueText != null && valueText!.isNotEmpty;
          return MouseRegion(
            cursor: readOnly || disabled
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            child: FieldShell(
              availability: availability,
              size: size,
              shape: shape,
              states: fieldStates,
              label: label,
              description: description,
              errorText: errorText,
              required: required,
              child: Text(
                hasValue ? valueText! : (placeholder ?? ''),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.typography
                    .fieldInput(context, size, TypographyEmphasis.regular)
                    .copyWith(
                      color: hasValue ? style.foreground : style.placeholder,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}
