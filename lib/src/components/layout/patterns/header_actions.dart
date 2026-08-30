import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../toolbar.dart';

final class CarpenterHeaderActions extends StatelessWidget {
  const CarpenterHeaderActions({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.destructive = const [],
    this.primaryExecutionPhase = ActionExecutionPhase.idle,
    this.overflowLabel = 'More actions',
    this.semanticLabel = 'Page actions',
  });

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;
  final List<CarpenterActionDescriptor> destructive;
  final ActionExecutionPhase primaryExecutionPhase;
  final String overflowLabel;
  final String semanticLabel;

  List<CarpenterActionDescriptor> get allActions => [
    ...primary,
    ...secondary,
    ...destructive,
  ];

  @override
  Widget build(BuildContext context) => CarpenterToolbar(
    overflowLabel: overflowLabel,
    semanticLabel: semanticLabel,
    items: [
      for (final action in primary)
        CarpenterToolbarItem(
          action: action,
          group: CarpenterToolbarGroup.primary,
          prominence: ActionProminence.high,
          executionPhase: primaryExecutionPhase,
        ),
      for (final action in secondary)
        CarpenterToolbarItem(
          action: action,
          group: CarpenterToolbarGroup.secondary,
        ),
      for (final action in destructive)
        CarpenterToolbarItem(
          action: action,
          group: CarpenterToolbarGroup.overflow,
          prominence: ActionProminence.outlined,
        ),
    ],
  );
}
