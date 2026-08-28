import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/text.dart';

/// Adaptive page navigation with first/last controls and a compact page window.
final class CarpenterPaginationBar extends StatelessWidget {
  const CarpenterPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.leading,
    this.siblingCount = 1,
  }) : assert(page > 0),
       assert(totalPages > 0),
       assert(page <= totalPages),
       assert(siblingCount >= 0);

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Widget? leading;
  final int siblingCount;

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
    required String label,
    required String semanticLabel,
    required int target,
    required bool enabled,
  }) => CarpenterButton.text(
    label: label,
    semanticLabel: semanticLabel,
    size: ControlSize.small,
    onPressed: enabled ? () => onPageChanged(target) : null,
  );

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final label = CarpenterText.body('Page $page of $totalPages');
    final previous = _navigationButton(
      label: '‹',
      semanticLabel: 'Previous page',
      target: page - 1,
      enabled: page > 1,
    );
    final next = _navigationButton(
      label: '›',
      semanticLabel: 'Next page',
      target: page + 1,
      enabled: page < totalPages,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 480) {
          return Row(
            children: [
              previous,
              SizedBox(width: gap),
              Expanded(child: Center(child: label)),
              SizedBox(width: gap),
              next,
            ],
          );
        }

        final navigation = Wrap(
          spacing: gap / 2,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _navigationButton(
              label: '«',
              semanticLabel: 'First page',
              target: 1,
              enabled: page > 1,
            ),
            previous,
            for (final item in _pageWindow)
              if (item == null)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: CarpenterText.body('…'),
                )
              else
                CarpenterButton(
                  label: '$item',
                  semanticLabel: item == page ? 'Current page $item' : 'Page $item',
                  size: ControlSize.small,
                  prominence: item == page
                      ? ActionProminence.filled
                      : ActionProminence.ghost,
                  onPressed: () => onPageChanged(item),
                ),
            next,
            _navigationButton(
              label: '»',
              semanticLabel: 'Last page',
              target: totalPages,
              enabled: page < totalPages,
            ),
          ],
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
