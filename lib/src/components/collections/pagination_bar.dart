import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/text.dart';

/// Compact offset/page navigation presentation retained from previous page blocks.
final class CarpenterPaginationBar extends StatelessWidget {
  const CarpenterPaginationBar({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    this.leading,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final label = CarpenterText.body('Page $page of $totalPages');
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CarpenterButton(
          label: '‹',
          semanticLabel: 'Previous page',
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
          onInvoke: page <= 1 ? null : () => onPageChanged(page - 1),
        ),
        SizedBox(width: gap),
        CarpenterButton(
          label: '›',
          semanticLabel: 'Next page',
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
          onInvoke: page >= totalPages ? null : () => onPageChanged(page + 1),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 420) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null) ...[leading!, SizedBox(height: gap)],
              Align(alignment: AlignmentDirectional.centerEnd, child: label),
              Align(alignment: AlignmentDirectional.centerEnd, child: buttons),
            ],
          );
        }
        return Row(
          children: [
            if (leading != null) Expanded(child: leading!),
            label,
            SizedBox(width: gap),
            buttons,
          ],
        );
      },
    );
  }
}
