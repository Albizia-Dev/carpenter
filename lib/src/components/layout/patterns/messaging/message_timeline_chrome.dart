import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/button.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/text.dart';

/// A centered boundary between local calendar days in a message timeline.
final class CarpenterMessageDateDivider extends StatelessWidget {
  const CarpenterMessageDateDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: CarpenterText.caption(
          label,
          colorRole: ContentColorRole.secondary,
        ),
      ),
    );
  }
}

/// Non-bubble event such as a room rename, invite, or pinned message.
final class CarpenterMessageSystemEvent extends StatelessWidget {
  const CarpenterMessageSystemEvent({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(gap),
        child: CarpenterText.caption(
          text,
          colorRole: ContentColorRole.secondary,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Controlled jump action shown above the timeline when newer items exist.
final class CarpenterJumpToLatest extends StatelessWidget {
  const CarpenterJumpToLatest({
    super.key,
    required this.onPressed,
    this.newerCount = 0,
  });

  final VoidCallback onPressed;
  final int newerCount;

  @override
  Widget build(BuildContext context) => CarpenterButton(
    label: newerCount > 0 ? 'К последним ($newerCount)' : 'К последним',
    onPressed: onPressed,
    prominence: ActionProminence.high,
  );
}

/// Selected-message count and actions, kept in a compact floating surface.
final class CarpenterMessageSelectionBar extends StatelessWidget {
  const CarpenterMessageSelectionBar({
    super.key,
    required this.count,
    required this.onClear,
    this.onActions,
  });

  final int count;
  final VoidCallback onClear;
  final VoidCallback? onActions;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.base,
        borderRadius: BorderRadius.circular(
          context.units(theme.shapes.radius(ShapeRole.rounded)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarpenterText.caption('Выбрано: $count'),
          CarpenterButton(
            label: 'Действия',
            onPressed: onActions,
            prominence: ActionProminence.ghost,
          ),
          CarpenterIconButton(
            icon: GravityIcons.xmark,
            semanticLabel: 'Снять выбор',
            onPressed: onClear,
            prominence: ActionProminence.ghost,
          ),
        ],
      ),
    );
  }
}
