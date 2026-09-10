import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/button/icon_button.dart';
import '../basic/gravity_icons.g.dart';
import '../basic/text.dart';

/// Adaptive page navigation with previous/next controls and a compact page window.
final class CarpenterPaginationBar extends StatelessWidget {
  const CarpenterPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.leading,
    this.siblingCount = 1,
    this.pageLabelBuilder,
    this.previousPageLabel = 'Previous page',
    this.nextPageLabel = 'Next page',
  }) : assert(page > 0),
       assert(totalPages > 0),
       assert(page <= totalPages),
       assert(siblingCount >= 0);

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Widget? leading;
  final int siblingCount;

  /// Localized visible page summary. Defaults to English when omitted.
  final String Function(int page, int totalPages)? pageLabelBuilder;

  /// Accessible labels for the previous/next navigation actions.
  final String previousPageLabel;
  final String nextPageLabel;

  List<int?> get _pageWindow {
    if (totalPages <= 7) {
      return [for (var value = 1; value <= totalPages; value++) value];
    }
    final values = <int>{1, totalPages};
    for (
      var value = page - siblingCount;
      value <= page + siblingCount;
      value++
    ) {
      if (value > 1 && value < totalPages) values.add(value);
    }
    if (page <= 2 + siblingCount) {
      for (var value = 2; value <= 3 + siblingCount; value++) {
        if (value < totalPages) values.add(value);
      }
    }
    if (page >= totalPages - 1 - siblingCount) {
      for (
        var value = totalPages - 2 - siblingCount;
        value < totalPages;
        value++
      ) {
        if (value > 1) values.add(value);
      }
    }
    final sorted = values.toList()..sort();
    final result = <int?>[];
    for (var index = 0; index < sorted.length; index++) {
      if (index > 0 && sorted[index] - sorted[index - 1] > 1) result.add(null);
      result.add(sorted[index]);
    }
    return result;
  }

  Widget _navigationButton({
    required bool previous,
    required String semanticLabel,
    required int target,
    required bool enabled,
    CarpenterShape shape = CarpenterShape.rounded,
  }) => CarpenterIconButton(
    icon: previous
        ? GravityIcons.chevronLeft
        : GravityIcons.chevronRight,
    semanticLabel: semanticLabel,
    size: ControlSize.small,
    colorRole: ActionColorRole.utility,
    prominence: ActionProminence.ghost,
    shape: shape,
    onPressed: enabled ? () => onPageChanged(target) : null,
  );

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final label = CarpenterText.body(
      pageLabelBuilder?.call(page, totalPages) ?? 'Page $page of $totalPages',
    );
    final previous = _navigationButton(
      previous: true,
      semanticLabel: previousPageLabel,
      target: page - 1,
      enabled: page > 1,
    );
    final next = _navigationButton(
      previous: false,
      semanticLabel: nextPageLabel,
      target: page + 1,
      enabled: page < totalPages,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <
            MediaQuery.textScalerOf(context).scale(context.units(30.rem))) {
          final navigation = Row(
            children: [
              previous,
              SizedBox(width: gap),
              Expanded(child: Center(child: label)),
              SizedBox(width: gap),
              next,
            ],
          );
          return leading == null
              ? navigation
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    leading!,
                    SizedBox(height: gap),
                    navigation,
                  ],
                );
        }

        const joinedShape = CarpenterShape(
          start: ShapeRole.none,
          end: ShapeRole.none,
        );
        final navigation = ClipRRect(
          borderRadius: BorderRadius.circular(
            context.units(
              theme.shapes.radiusForAction(
                ShapeRole.rounded,
                ControlSize.small,
              ),
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.surface.subtle,
                width: context.units(theme.shapes.actionBorderWidth),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _navigationButton(
                  previous: true,
                  semanticLabel: previousPageLabel,
                  target: page - 1,
                  enabled: page > 1,
                  shape: joinedShape,
                ),
                for (final item in _pageWindow)
                  if (item == null)
                    SizedBox(
                      width: context.units(
                        theme.sizes.actionHeight(ControlSize.small),
                      ),
                      child: const Center(child: CarpenterText.body('…')),
                    )
                  else
                    CarpenterButton(
                      label: '$item',
                      semanticLabel: item == page
                          ? 'Current page $item'
                          : 'Page $item',
                      size: ControlSize.small,
                      colorRole: ActionColorRole.utility,
                      prominence: item == page
                          ? ActionProminence.low
                          : ActionProminence.ghost,
                      shape: joinedShape,
                      onPressed: item == page
                          ? null
                          : () => onPageChanged(item),
                    ),
                _navigationButton(
                  previous: false,
                  semanticLabel: nextPageLabel,
                  target: page + 1,
                  enabled: page < totalPages,
                  shape: joinedShape,
                ),
              ],
            ),
          ),
        );

        return Row(
          children: [
            if (leading != null) Expanded(child: leading!),
            if (leading == null) const Spacer(),
            label,
            SizedBox(width: gap),
            navigation,
          ],
        );
      },
    );
  }
}
