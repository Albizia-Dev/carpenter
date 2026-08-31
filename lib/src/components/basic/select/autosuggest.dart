import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/selection/suggestion_field.dart';

/// An editable controlled field offering optional suggestions for free text.
///
/// Query and suggestions remain caller-owned. Overlay visibility is
/// self-managed by default; pass both [open] and [onOpenChanged] to control it.
final class CarpenterAutosuggest<T> extends StatefulWidget {
  const CarpenterAutosuggest({
    super.key,
    required this.controller,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.suggestions,
    this.open,
    this.onOpenChanged,
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
    this.replaceQueryOnSelection = true,
    this.loadingText = 'Loading',
    this.emptyText = 'No suggestions',
    this.failedText = 'Unable to load suggestions',
  }) : assert(
         open == null || onOpenChanged != null,
         'Controlled CarpenterAutosuggest.open requires onOpenChanged.',
       );

  final TextEditingController controller;
  final ValueChanged<String>? onQueryChanged;
  final ValueChanged<CarpenterOption<T>>? onSuggestionSelected;

  /// Controlled overlay visibility. Omit to let Carpenter own this transient
  /// interaction state.
  final bool? open;

  /// Observes self-managed visibility changes or updates controlled [open].
  final ValueChanged<bool>? onOpenChanged;
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
  final bool replaceQueryOnSelection;
  final String loadingText;
  final String emptyText;
  final String failedText;

  @override
  State<CarpenterAutosuggest<T>> createState() =>
      _CarpenterAutosuggestState<T>();
}

final class _CarpenterAutosuggestState<T>
    extends State<CarpenterAutosuggest<T>> {
  bool _open = false;

  bool get _effectiveOpen => widget.open ?? _open;

  void _setOpen(bool value) {
    if (widget.open == null && _open != value) {
      setState(() => _open = value);
    }
    widget.onOpenChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) => SuggestionField<T>(
    controller: widget.controller,
    options: widget.suggestions,
    open: _effectiveOpen,
    onOpenChanged: _setOpen,
    onQueryChanged: widget.onQueryChanged,
    onSelected: widget.onSuggestionSelected,
    loadState: widget.loadState,
    loadingText: widget.loadingText,
    emptyText: widget.emptyText,
    failedText: widget.failedText,
    label: widget.label,
    placeholder: widget.placeholder,
    description: widget.description,
    errorText: widget.errorText,
    semanticLabel: widget.semanticLabel,
    required: widget.required,
    availability: widget.availability,
    size: widget.size,
    shape: widget.shape,
    placement: widget.placement,
    clearAction: widget.clearAction,
    focusNode: widget.focusNode,
    autofocus: widget.autofocus,
    replaceQueryOnSelection: widget.replaceQueryOnSelection,
  );
}
