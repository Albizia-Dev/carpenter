import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/selection/suggestion_field.dart';

/// An editable controlled field offering optional suggestions for free text.
final class CarpenterAutosuggest<T> extends StatelessWidget {
  const CarpenterAutosuggest({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.open,
    required this.onOpenChanged,
    required this.suggestions,
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
    this.clearAction,
    this.focusNode,
    this.autofocus = false,
    this.loadingText = 'Loading',
    this.emptyText = 'No suggestions',
    this.failedText = 'Unable to load suggestions',
  });

  final TextEditingController controller;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<CarpenterOption<T>>? onSuggestionSelected;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
  final List<CarpenterOption<T>> suggestions;
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
  final CarpenterActionDescriptor? clearAction;
  final FocusNode? focusNode;
  final bool autofocus;
  final String loadingText;
  final String emptyText;
  final String failedText;

  @override
  Widget build(BuildContext context) => SuggestionField<T>(
    controller: controller,
    options: suggestions,
    open: open,
    onOpenChanged: onOpenChanged,
    onQueryChanged: onQueryChanged,
    onSelected: onSuggestionSelected,
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
  );
}
