import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/adaptive.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/button/button.dart';
import '../../basic/input/input.dart';
import '../../basic/status_indicator.dart';

final class CarpenterFilterBar extends StatelessWidget {
  const CarpenterFilterBar({
    super.key,
    required this.searchController,
    this.onSearchChanged,
    this.searchLabel = 'Search',
    this.searchPlaceholder,
    this.searchAvailability = FieldAvailability.enabled,
    this.filterControls = const [],
    this.activeFilterCount = 0,
    this.advancedFilters,
    this.filtersExpanded = false,
    this.onFiltersExpandedChanged,
    this.filterToggleLabel = 'Filters',
    this.activeFilterSummary = const [],
    this.activeFilterLabelBuilder,
    this.clearAction,
    this.actions = const [],
    this.semanticLabel = 'Filters',
  }) : assert(activeFilterCount >= 0);

  final TextEditingController searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchLabel;
  final String? searchPlaceholder;
  final FieldAvailability searchAvailability;
  final List<Widget> filterControls;
  final int activeFilterCount;

  /// Additional controls revealed below the toolbar, without an overlay.
  /// Values and validation remain owned by the caller when collapsed.
  final Widget? advancedFilters;

  /// Controlled disclosure state; changing viewport width does not reset it.
  final bool filtersExpanded;

  /// Requests disclosure changes. A null callback disables the toggle.
  final ValueChanged<bool>? onFiltersExpandedChanged;

  /// Localized toggle label; the active count is appended when nonzero.
  final String filterToggleLabel;

  /// Persistent summaries, typically removable condition chips. These remain
  /// visible when additional controls are collapsed. The caller owns removal.
  final List<Widget> activeFilterSummary;

  /// Localizes the active count when no disclosure toggle is present.
  final String Function(int count)? activeFilterLabelBuilder;
  final CarpenterActionDescriptor? clearAction;
  final List<CarpenterActionDescriptor> actions;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final gap = context.units(theme.spacing.layoutToolbar);
      final viewport = const CarpenterViewportPolicy().resolve(
        context,
        constraints.maxWidth,
      );
      final search = CarpenterInput(
        controller: searchController,
        label: searchLabel.isEmpty ? null : searchLabel,
        placeholder: searchPlaceholder,
        availability: searchAvailability,
        onChanged: onSearchChanged,
        semanticLabel: searchLabel.isEmpty ? searchPlaceholder : searchLabel,
      );
      final supporting = <Widget>[
        if (advancedFilters != null)
          Semantics(
            expanded: filtersExpanded,
            child: CarpenterButton.outlined(
              label: activeFilterCount == 0
                  ? filterToggleLabel
                  : '$filterToggleLabel ($activeFilterCount)',
              onInvoke: onFiltersExpandedChanged == null
                  ? null
                  : () => onFiltersExpandedChanged!(!filtersExpanded),
            ),
          ),
        if (activeFilterCount > 0 && advancedFilters == null)
          CarpenterStatusIndicator(
            label:
                activeFilterLabelBuilder?.call(activeFilterCount) ??
                '$activeFilterCount active filters',
            role: FeedbackColorRole.info,
          ),
        if (clearAction != null && activeFilterCount > 0)
          CarpenterButton.fromAction(
            clearAction!,
            prominence: ActionProminence.ghost,
            size: ControlSize.small,
          ),
        if (actions.isNotEmpty)
          for (final action in actions)
            CarpenterButton.fromAction(
              action,
              prominence: ActionProminence.ghost,
              size: ControlSize.small,
            ),
      ];
      final toolbar = Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: viewport == CarpenterViewportClass.narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  search,
                  if (filterControls.isNotEmpty) ...[
                    SizedBox(height: gap),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: filterControls,
                    ),
                  ],
                  if (supporting.isNotEmpty) ...[
                    SizedBox(height: gap),
                    Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: supporting,
                    ),
                  ],
                ],
              )
            : Wrap(
                spacing: gap,
                runSpacing: gap,
                crossAxisAlignment: WrapCrossAlignment.end,
                children: [
                  SizedBox(
                    width: context.units(theme.sizes.layoutFilterSearch),
                    child: search,
                  ),
                  ...filterControls,
                  ...supporting,
                ],
              ),
      );
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          toolbar,
          if (activeFilterSummary.isNotEmpty) ...[
            SizedBox(height: gap),
            Wrap(spacing: gap, runSpacing: gap, children: activeFilterSummary),
          ],
          if (advancedFilters != null && filtersExpanded) ...[
            SizedBox(height: gap),
            advancedFilters!,
          ],
        ],
      );
    },
  );
}
