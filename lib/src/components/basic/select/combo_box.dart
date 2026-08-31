import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/selection/suggestion_field.dart';
import 'select.dart';

/// An editable controlled field whose query may resolve to one selected option.
///
/// Value and query remain caller-owned. Overlay visibility is self-managed by
/// default; pass both [open] and [onOpenChanged] to control it explicitly.
final class CarpenterComboBox<T> extends StatefulWidget {
  const CarpenterComboBox({
    super.key,
    required this.controller,
    required this.value,
    required this.onChanged,
    required this.onQueryChanged,
    required this.options,
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
    this.isSameValue,
    this.clearAction,
    this.focusNode,
    this.autofocus = false,
    this.loadingText = 'Loading',
    this.emptyText = 'No options',
    this.failedText = 'Unable to load options',
  }) : assert(
         open == null || onOpenChanged != null,
         'Controlled CarpenterComboBox.open requires onOpenChanged.',
       );

  final TextEditingController controller;
  final T? value;
  final ValueChanged<T>? onChanged;
  final ValueChanged<String>? onQueryChanged;

  /// Controlled overlay visibility. Omit to let Carpenter own this transient
  /// interaction state.
  final bool? open;

  /// Observes self-managed visibility changes or updates controlled [open].
  final ValueChanged<bool>? onOpenChanged;
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

  @override
  State<CarpenterComboBox<T>> createState() => _CarpenterComboBoxState<T>();
}

final class _CarpenterComboBoxState<T> extends State<CarpenterComboBox<T>> {
  bool _open = false;

  bool get _effectiveOpen => widget.open ?? _open;

  Object? get _selectedId {
    final selected = widget.value;
    if (selected == null) return null;
    for (final option in widget.options) {
      if (widget.isSameValue?.call(option.value, selected) ??
          option.value == selected) {
        return option.id;
      }
    }
    return null;
  }

  void _setOpen(bool value) {
    if (widget.open == null && _open != value) {
      setState(() => _open = value);
    }
    widget.onOpenChanged?.call(value);
  }

  @override
  Widget build(BuildContext context) => SuggestionField<T>(
    controller: widget.controller,
    options: widget.options,
    open: _effectiveOpen,
    onOpenChanged: _setOpen,
    onQueryChanged: widget.onQueryChanged,
    onSelected: widget.onChanged == null
        ? null
        : (option) => widget.onChanged!.call(option.value),
    selectedOptionId: _selectedId,
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
    replaceQueryOnSelection: true,
  );
}
