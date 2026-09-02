import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../page_header.dart';
import '../regions/adaptive_region.dart';
import '../regions/adaptive_region_policy.dart';
import '../regions/primary_region.dart';
import '../regions/region_role.dart';
import '../regions/secondary_region.dart';
import 'header_actions.dart';

final class CarpenterObjectPage extends StatelessWidget {
  const CarpenterObjectPage({
    super.key,
    required this.title,
    required this.primaryContent,
    this.subtitle,
    this.status,
    this.breadcrumbs,
    this.metadata,
    this.secondaryRegion,
    this.secondaryVisible = true,
    this.onSecondaryVisibilityChanged,
    this.secondaryPolicy = CarpenterBreakpointRegionPolicy.secondary,
    this.splitPosition = 0.7,
    this.onSplitPositionChanged,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.destructiveActions = const [],
    this.headerBehavior = CarpenterPageHeaderBehavior.sticky,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final CarpenterPageStatus? status;
  final Widget? breadcrumbs;
  final Widget primaryContent;
  final Widget? metadata;
  final Widget? secondaryRegion;
  final bool secondaryVisible;
  final ValueChanged<bool>? onSecondaryVisibilityChanged;
  final CarpenterAdaptiveRegionPolicy secondaryPolicy;
  final double splitPosition;
  final ValueChanged<double>? onSplitPositionChanged;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final List<CarpenterActionDescriptor> destructiveActions;
  final CarpenterPageHeaderBehavior headerBehavior;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    final pageOwnsScroll = headerBehavior == CarpenterPageHeaderBehavior.scrolls;
    final primary = CarpenterPrimaryRegion(
      scrollOwnership: pageOwnsScroll
          ? CarpenterRegionScrollOwnership.child
          : CarpenterRegionScrollOwnership.region,
      semanticLabel: '$title primary content',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          primaryContent,
          if (metadata != null) ...[SizedBox(height: gap), metadata!],
        ],
      ),
    );
    final body = secondaryRegion == null
        ? primary
        : CarpenterAdaptiveRegion(
            primary: primary,
            region: CarpenterSecondaryRegion(
              semanticLabel: '$title secondary content',
              child: secondaryRegion!,
            ),
            role: CarpenterRegionRole.secondary,
            policy: secondaryPolicy,
            regionVisible: secondaryVisible,
            onRegionVisibilityChanged: onSecondaryVisibilityChanged,
            splitPosition: splitPosition,
            onSplitPositionChanged: onSplitPositionChanged,
          );
    final actions = CarpenterHeaderActions(
      primary: primaryActions,
      secondary: secondaryActions,
      destructive: destructiveActions,
    );
    final allActions = actions.allActions;
    return CarpenterPageRegion(
      semanticLabel: semanticLabel ?? title,
      scrollOwnership: pageOwnsScroll
          ? CarpenterRegionScrollOwnership.region
          : CarpenterRegionScrollOwnership.child,
      headerBehavior: headerBehavior,
      shortcutActions: allActions,
      header: CarpenterPageHeader(
        title: title,
        subtitle: subtitle,
        status: status,
        breadcrumbs: breadcrumbs,
        actions: allActions.isEmpty ? null : actions,
      ),
      body: body,
    );
  }
}
