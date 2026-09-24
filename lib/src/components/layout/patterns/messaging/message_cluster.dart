import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/theme.dart';
import 'messaging_models.dart';

/// Author/time policy for message blocks. Exactly twenty minutes starts a new
/// block; date and system boundaries always break one.
abstract final class CarpenterMessageClusterPolicy {
  static bool sameBlock(
    CarpenterMessageView previous,
    CarpenterMessageView current,
  ) {
    if (previous.system || current.system) return false;
    if (previous.authorId != current.authorId || previous.own != current.own) {
      return false;
    }
    final prior = previous.sentAt.toLocal();
    final next = current.sentAt.toLocal();
    if (prior.year != next.year ||
        prior.month != next.month ||
        prior.day != next.day) {
      return false;
    }
    final delta = next.difference(prior);
    return !delta.isNegative && delta < const Duration(minutes: 20);
  }
}

/// Keeps an optional group-chat avatar pinned to the bottom of its author
/// block and never outside the block's vertical bounds.
final class CarpenterMessageCluster extends StatelessWidget {
  const CarpenterMessageCluster({
    super.key,
    required this.own,
    required this.children,
    this.avatar,
  });

  final bool own;
  final Widget? avatar;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!own && avatar != null) ...[avatar!, SizedBox(width: gap)],
        Expanded(child: Column(children: children)),
      ],
    );
  }
}
