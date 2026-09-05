import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../behaviour/action_strip.dart';

enum CarpenterToolbarPriority { critical, normal, overflow }

enum CarpenterToolbarGroup { primary, secondary, overflow }

enum CarpenterToolbarPresentation { label, icon }

@immutable
final class CarpenterToolbarItem {
  const CarpenterToolbarItem({
    required this.action,
    this.group = CarpenterToolbarGroup.secondary,
    @Deprecated('Use group instead. Priority is retained for compatibility.')
    CarpenterToolbarPriority? priority,
    this.presentation = CarpenterToolbarPresentation.label,
    this.prominence = ActionProminence.ghost,
    this.size = ControlSize.medium,
    this.executionPhase = ActionExecutionPhase.idle,
  }) : _priority = priority;

  final CarpenterActionDescriptor action;
  final CarpenterToolbarGroup group;
  final CarpenterToolbarPriority? _priority;
  final CarpenterToolbarPresentation presentation;
  final ActionProminence prominence;
  final ControlSize size;
  final ActionExecutionPhase executionPhase;

  @Deprecated('Use group instead. Priority is retained for compatibility.')
  CarpenterToolbarPriority get priority =>
      _priority ??
      switch (group) {
        CarpenterToolbarGroup.primary => CarpenterToolbarPriority.critical,
        CarpenterToolbarGroup.secondary => CarpenterToolbarPriority.normal,
        CarpenterToolbarGroup.overflow => CarpenterToolbarPriority.overflow,
      };

  CarpenterToolbarGroup get effectiveGroup => switch (_priority) {
    CarpenterToolbarPriority.critical => CarpenterToolbarGroup.primary,
    CarpenterToolbarPriority.normal => CarpenterToolbarGroup.secondary,
    CarpenterToolbarPriority.overflow => CarpenterToolbarGroup.overflow,
    null => group,
  };
}

/// Semantic toolbar projection over the shared adaptive action-strip behaviour.
final class CarpenterToolbar extends StatelessWidget {
  const CarpenterToolbar({
    super.key,
    required this.items,
    this.alignment = AlignmentDirectional.centerEnd,
    this.overflowLabel = 'More actions',
    this.overflowSize = ControlSize.medium,
    this.semanticLabel = 'Toolbar',
  });

  final List<CarpenterToolbarItem> items;
  final AlignmentGeometry alignment;
  final String overflowLabel;
  final ControlSize overflowSize;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => CarpenterActionStrip(
    alignment: alignment,
    overflowLabel: overflowLabel,
    overflowSize: overflowSize,
    semanticLabel: semanticLabel,
    items: [
      for (final item in items)
        CarpenterActionStripItem(
          action: item.action,
          group: switch (item.effectiveGroup) {
            CarpenterToolbarGroup.primary => CarpenterActionStripGroup.primary,
            CarpenterToolbarGroup.secondary =>
              CarpenterActionStripGroup.secondary,
            CarpenterToolbarGroup.overflow => CarpenterActionStripGroup.overflow,
          },
          presentation: switch (item.presentation) {
            CarpenterToolbarPresentation.label =>
              CarpenterActionStripPresentation.label,
            CarpenterToolbarPresentation.icon =>
              CarpenterActionStripPresentation.icon,
          },
          prominence: item.prominence,
          size: item.size,
          executionPhase: item.executionPhase,
        ),
    ],
  );
}
