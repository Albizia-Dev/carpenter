import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import 'package:carpenter/gravity_icons.dart';
import '../../../internal/selection/suggestion_field.dart';
import '../button/button.dart';

/// Searchable selection of multiple entities, identified by option id.
///
/// The caller owns selected values, search results and loading state. Results
/// may come from a local index or a remote query; this control never loads an
/// entire directory. Selected options remain visible when results change.
/// Arrow keys and Enter choose a result, Escape closes results, and each value
/// has a keyboard-accessible removal action. Free text is only a query.
final class CarpenterMultiSelect<T> extends StatefulWidget {
  const CarpenterMultiSelect({
    super.key,
    required this.values,
    required this.suggestions,
    required this.onChanged,
    required this.onQueryChanged,
    this.label,
    this.placeholder = 'Поиск',
    this.semanticLabel,
    this.availability = FieldAvailability.enabled,
    this.loadState = OptionsLoadState.ready,
    this.maximumSuggestions = 20,
    this.loadingText = 'Загрузка…',
    this.emptyText = 'Ничего не найдено',
    this.failedText = 'Не удалось загрузить результаты',
    this.removeLabel = 'Удалить',
  }) : assert(maximumSuggestions > 0);

  /// Selected options, independent of the current result page. Ids are unique.
  final List<CarpenterOption<T>> values;

  /// Current search results; already selected ids are omitted from the menu.
  final List<CarpenterOption<T>> suggestions;

  /// Receives an immutable replacement selection after adding or removing.
  final ValueChanged<List<CarpenterOption<T>>>? onChanged;

  /// Receives query edits and an empty query after selection. Remote sources
  /// own debounce, cancellation and protection against stale responses.
  final ValueChanged<String> onQueryChanged;
  final String? label;
  final String? semanticLabel;
  final String placeholder;
  final FieldAvailability availability;
  final OptionsLoadState loadState;

  /// Upper bound on rendered results. Ask users to refine broad searches.
  final int maximumSuggestions;
  final String loadingText;
  final String emptyText;
  final String failedText;

  /// Localized removal verb, combined with the selected option label.
  final String removeLabel;

  @override
  State<CarpenterMultiSelect<T>> createState() => _MultiSelectState<T>();
}

final class _MultiSelectState<T> extends State<CarpenterMultiSelect<T>> {
  final _query = TextEditingController();
  bool _open = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = widget.values.map((option) => option.id).toSet();
    assert(
      selectedIds.length == widget.values.length,
      'Selected ids must be unique.',
    );
    final enabled =
        widget.availability == FieldAvailability.enabled &&
        widget.onChanged != null;
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return SuggestionField<T>(
      controller: _query,
      options: widget.loadState != OptionsLoadState.ready
          ? []
          : widget.suggestions
                .where((option) => !selectedIds.contains(option.id))
                .take(widget.maximumSuggestions)
                .toList(),
      open: _open,
      onOpenChanged: (open) => setState(() => _open = open),
      onQueryChanged: enabled ? widget.onQueryChanged : null,
      onSelected: (option) {
        if (!enabled || selectedIds.contains(option.id)) return;
        widget.onChanged!(List.unmodifiable([...widget.values, option]));
        _query.clear();
        widget.onQueryChanged('');
      },
      label: widget.label,
      semanticLabel: widget.semanticLabel,
      placeholder: widget.placeholder,
      availability: widget.availability,
      loadState: widget.loadState,
      loadingText: widget.loadingText,
      emptyText: widget.emptyText,
      failedText: widget.failedText,
      selectedValues: widget.values.isEmpty
          ? null
          : Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final option in widget.values)
                  CarpenterButton(
                    key: ValueKey(option.id),
                    label: option.label,
                    semanticLabel: '${widget.removeLabel} ${option.label}',
                    icon: enabled ? GravityIcons.xmark : null,
                    iconPosition: CarpenterActionIconPosition.trailing,
                    size: ControlSize.small,
                    onInvoke: enabled
                        ? () => widget.onChanged!(
                            List.unmodifiable(
                              widget.values.where(
                                (value) => value.id != option.id,
                              ),
                            ),
                          )
                        : null,
                  ),
              ],
            ),
    );
  }
}
