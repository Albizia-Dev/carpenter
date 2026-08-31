import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/overlay/anchored_overlay_host.dart';
import '../../../internal/rendering/selectable_field.dart';
import '../../../internal/selection/menu_panel.dart';

typedef CarpenterValueEquality<T> = bool Function(T first, T second);

/// A controlled field for selecting exactly one value from typed options.
///
/// Selection remains controlled by [value] and [onChanged]. Overlay visibility
/// is self-managed by default because it is ephemeral interaction state. Pass
/// both [open] and [onOpenChanged] when an application needs to control it.
final class CarpenterSelect<T> extends StatefulWidget {
  const CarpenterSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.options,
    this.open,
    this.onOpenChanged,
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
    this.focusNode,
    this.autofocus = false,
    this.emptyText = 'No options',
  }) : assert(
         open == null || onOpenChanged != null,
         'Controlled CarpenterSelect.open requires onOpenChanged.',
       );

  final T? value;
  final ValueChanged<T>? onChanged;

  /// Controlled overlay visibility. Omit to let Carpenter own this transient
  /// interaction state.
  final bool? open;

  /// Observes self-managed visibility changes or updates controlled [open].
  final ValueChanged<bool>? onOpenChanged;
  final List<CarpenterOption<T>> options;
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
  final FocusNode? focusNode;
  final bool autofocus;
  final String emptyText;

  @override
  State<CarpenterSelect<T>> createState() => _CarpenterSelectState<T>();
}

final class _CarpenterSelectState<T> extends State<CarpenterSelect<T>> {
  bool _open = false;

  bool get _effectiveOpen => widget.open ?? _open;

  bool _same(T first, T second) =>
      widget.isSameValue?.call(first, second) ?? first == second;

  CarpenterOption<T>? get _selectedOption {
    final selected = widget.value;
    if (selected == null) return null;
    for (final option in widget.options) {
      if (_same(option.value, selected)) return option;
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
  Widget build(BuildContext context) {
    assert(
      widget.options.map((option) => option.id).toSet().length ==
          widget.options.length,
      'CarpenterSelect option ids must be unique.',
    );
    final enabled =
        widget.availability == FieldAvailability.enabled &&
        widget.onChanged != null;
    final selected = _selectedOption;
    void toggle() {
      if (enabled) _setOpen(!_effectiveOpen);
    }

    return AnchoredOverlayHost(
      open: _effectiveOpen && enabled,
      onOpenChanged: _setOpen,
      placement: widget.placement,
      anchor: SelectableField(
        valueText: selected?.label,
        placeholder: widget.placeholder,
        label: widget.label,
        description: widget.description,
        errorText: widget.errorText,
        semanticLabel: widget.semanticLabel,
        required: widget.required,
        availability:
            widget.availability == FieldAvailability.enabled &&
                widget.onChanged == null
            ? FieldAvailability.disabled
            : widget.availability,
        size: widget.size,
        shape: widget.shape,
        open: _effectiveOpen,
        onActivate: enabled ? toggle : null,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
      ),
      overlayBuilder: (context) {
        if (widget.options.isEmpty) {
          return MenuPanel(
            entries: [
              MenuPanelEntry(
                id: 'empty',
                label: widget.emptyText,
                semanticLabel: widget.emptyText,
                enabled: false,
                onActivate: null,
              ),
            ],
            onDismissRequested: () => _setOpen(false),
          );
        }
        return MenuPanel(
          semanticLabel: widget.semanticLabel,
          onDismissRequested: () => _setOpen(false),
          entries: [
            for (final option in widget.options)
              MenuPanelEntry(
                id: option.id,
                label: option.label,
                semanticLabel: option.effectiveSemanticLabel,
                enabled: option.enabled,
                selected: selected?.id == option.id,
                onActivate: option.enabled
                    ? () {
                        widget.onChanged?.call(option.value);
                      }
                    : null,
              ),
          ],
        );
      },
    );
  }
}
