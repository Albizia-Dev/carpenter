import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/selection/suggestion_field.dart';
import 'select.dart';

/// An editable controlled field whose query may resolve to one selected option.
final class CarpenterComboBox<T> extends StatelessWidget {
  const CarpenterComboBox({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onQueryChanged,
    required this.open,
    required this.onOpenChanged,
    required this.options,
    this.loadState = OptionsLoadState.ready,
    this.label,
    this.placeholder,
    this.description,
    this.errorText,
    this.semanticLabel,
    this.required = false,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.placement = OverlayPlacement.bottomStart,
    this.isSameValue,
    this.clearAction,
    this.focusNode,
    this.autofocus = false,
    this.loadingText = 'Loading',
    this.emptyText = 'No options',
    this.failedText = 'Unable to load options',
  });

  final TextEditingController controller;
  final T? value;
  final ValueChanged<T>? onChanged;
  final ValueChanged<String>? onQueryChanged;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final List<CarpenterOption<T>> options;
  final OptionsLoadState loadState;
  final String? label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final String? semanticLabel;
  final bool required;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final OverlayPlacement placement;
  final CarpenterValueEquality<T>? isSameValue;
  final CarpenterActionDescriptor? clearAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final String loadingText;
  final String emptyText;
  final String failedText;

  Object? get _selectedId {
    final selected = value;
    if (selected == null) return null;
    for (final option in options) {
      if (isSameValue?.call(option.value, selected) ??
          option.value == selected) {
        return option.id;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => SuggestionField<T>(
    controller: controller,
    options: options,
    open: open,
    onOpenChanged: onOpenChanged,
    onQueryChanged: onQueryChanged,
    onSelected: onChanged == null
        ? null
        : (option) => onChanged!.call(option.value),
    selectedOptionId: _selectedId,
    loadState: loadState,
    loadingText: loadingText,
    emptyText: emptyText,
    failedText: failedText,
    label: label,
    placeholder: placeholder,
    description: description,
    errorText: errorText,
    semanticLabel: semanticLabel,
    required: required,
    availability: availability,
    size: size,
    shape: shape,
    placement: placement,
    clearAction: clearAction,
    focusNode: focusNode,
    autofocus: autofocus,
    replaceQueryOnSelection: true,
  );
}
