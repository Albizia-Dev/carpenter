import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../internal/overlay/anchored_overlay_host.dart';
import '../../../internal/rendering/selectable_field.dart';
import '../../../internal/selection/menu_panel.dart';

typedef CarpenterValueEquality<T> = bool Function(T first, T second);

/// A controlled field for selecting exactly one value from typed options.
final class CarpenterSelect<T> extends StatelessWidget {
  const CarpenterSelect({
    super.key,
    required this.value,
    required this.onChanged,
    required this.open,
    required this.onOpenChanged,
    required this.options,
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
  });

  final T? value;
  final ValueChanged<T>? onChanged;
  final bool open;
  final ValueChanged<bool> onOpenChanged;
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

  bool _same(T first, T second) =>
      isSameValue?.call(first, second) ?? first == second;

  CarpenterOption<T>? get _selectedOption {
    final selected = value;
    if (selected == null) return null;
    for (final option in options) {
      if (_same(option.value, selected)) return option;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      options.map((option) => option.id).toSet().length == options.length,
      'CarpenterSelect option ids must be unique.',
    );
    final enabled =
        availability == FieldAvailability.enabled && onChanged != null;
    final selected = _selectedOption;
    void toggle() {
      if (enabled) onOpenChanged(!open);
    }

    return AnchoredOverlayHost(
      open: open && enabled,
      onOpenChanged: onOpenChanged,
      placement: placement,
      anchor: SelectableField(
        valueText: selected?.label,
        placeholder: placeholder,
        label: label,
        description: description,
        errorText: errorText,
        semanticLabel: semanticLabel,
        required: required,
        availability:
            availability == FieldAvailability.enabled && onChanged == null
            ? FieldAvailability.disabled
            : availability,
        size: size,
        shape: shape,
        open: open,
        onActivate: enabled ? toggle : null,
        focusNode: focusNode,
        autofocus: autofocus,
      ),
      overlayBuilder: (context) {
        if (options.isEmpty) {
          return MenuPanel(
            entries: [
              MenuPanelEntry(
                id: 'empty',
                label: emptyText,
                semanticLabel: emptyText,
                enabled: false,
                onActivate: null,
              ),
            ],
            onDismissRequested: () => onOpenChanged(false),
          );
        }
        return MenuPanel(
          semanticLabel: semanticLabel,
          onDismissRequested: () => onOpenChanged(false),
          entries: [
            for (final option in options)
              MenuPanelEntry(
                id: option.id,
                label: option.label,
                semanticLabel: option.effectiveSemanticLabel,
                enabled: option.enabled,
                selected: selected?.id == option.id,
                onActivate: option.enabled
                    ? () {
                        onChanged?.call(option.value);
                      }
                    : null,
              ),
          ],
        );
      },
    );
  }
}
