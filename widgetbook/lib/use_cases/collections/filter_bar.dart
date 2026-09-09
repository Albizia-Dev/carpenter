import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final filterBarComponent = WidgetbookComponent(
  name: 'Filter bar',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(
      name: 'Edge cases · Alignment stress',
      builder: _alignmentStress,
    ),
    WidgetbookUseCase(
      name: 'States · Responsive states',
      builder: _responsiveStates,
    ),
  ],
);

Widget _playground(BuildContext context) {
  final activeFilters = context.knobs.int.slider(
    label: 'Data · Filters / Active count',
    initialValue: 2,
    min: 0,
    max: 8,
  );
  final filters = context.knobs.int.slider(
    label: 'Data · Filters / Controls',
    initialValue: 3,
    min: 0,
    max: 6,
  );
  final extraActions = context.knobs.boolean(
    label: 'Behavior · Actions / Extra actions',
    initialValue: true,
  );
  final labeledSearch = context.knobs.boolean(
    label: 'Data · Search / Show label',
    initialValue: true,
  );
  return preview(
    SizedBox(
      width: double.infinity,
      child: _FilterBarPreview(
        activeFilters: activeFilters,
        filterCount: filters,
        extraActions: extraActions,
        labeledSearch: labeledSearch,
      ),
    ),
  );
}

Widget _alignmentStress(BuildContext context) => preview(
  SizedBox(
    width: context.units(57.5.rem),
    child: _FilterBarPreview(
      activeFilters: 2,
      filterCount: 3,
      extraActions: true,
      labeledSearch: true,
    ),
  ),
);

Widget _responsiveStates(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(20.rem),
    child: _FilterBarPreview(
      activeFilters: 3,
      filterCount: 3,
      extraActions: true,
      labeledSearch: true,
    ),
  ),
  SizedBox(
    width: context.units(45.rem),
    child: _FilterBarPreview(
      activeFilters: 1,
      filterCount: 2,
      extraActions: true,
      labeledSearch: true,
    ),
  ),
  SizedBox(
    width: context.units(67.5.rem),
    child: _FilterBarPreview(
      activeFilters: 0,
      filterCount: 4,
      extraActions: false,
      labeledSearch: false,
    ),
  ),
]);

final class _FilterBarPreview extends StatefulWidget {
  const _FilterBarPreview({
    required this.activeFilters,
    required this.filterCount,
    required this.extraActions,
    required this.labeledSearch,
  });

  final int activeFilters;
  final int filterCount;
  final bool extraActions;
  final bool labeledSearch;

  @override
  State<_FilterBarPreview> createState() => _FilterBarPreviewState();
}

final class _FilterBarPreviewState extends State<_FilterBarPreview> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterFilterBar(
    searchController: _searchController,
    searchLabel: widget.labeledSearch ? 'Search' : '',
    searchPlaceholder: 'Number, customer or purpose',
    onSearchChanged: (_) => setState(() {}),
    activeFilterCount:
        widget.activeFilters + (_searchController.text.isEmpty ? 0 : 1),
    filterControls: [
      for (var index = 0; index < widget.filterCount; index++)
        CarpenterButton.outlined(
          label: index.isEven ? 'Status ${index + 1}' : 'Period ${index + 1}',
          size: ControlSize.medium,
          onPressed: () {},
        ),
    ],
    clearAction: CarpenterActionDescriptor(
      id: 'clear-filters',
      label: 'Clear',
      onInvoke: widget.activeFilters == 0 && _searchController.text.isEmpty
          ? null
          : () => setState(_searchController.clear),
    ),
    actions: widget.extraActions
        ? [
            CarpenterActionDescriptor(
              id: 'saved-filter',
              label: 'Saved filters',
              onInvoke: () {},
            ),
          ]
        : const [],
  );
}
