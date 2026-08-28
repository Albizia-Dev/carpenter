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
        label: searchLabel,
        placeholder: searchPlaceholder,
        availability: searchAvailability,
        onChanged: onSearchChanged,
        semanticLabel: searchLabel,
      );
      final supporting = <Widget>[
        if (activeFilterCount > 0)
          CarpenterStatusIndicator(
            label: '$activeFilterCount active filters',
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
      return Semantics(
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
    },
  );
}
