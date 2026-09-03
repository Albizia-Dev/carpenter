import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../master_detail.dart';
import '../page_header.dart';
import '../regions/adaptive_region_policy.dart';
import '../regions/primary_region.dart';
import '../regions/region_role.dart';
import 'header_actions.dart';

typedef CarpenterDetailBuilder<T> =
    Widget Function(BuildContext context, T value);

final class CarpenterMasterDetailPage<T> extends StatelessWidget {
  const CarpenterMasterDetailPage({
    super.key,
    required this.title,
    required this.master,
    required this.selectedValue,
    required this.detailBuilder,
    required this.onDetailClosed,
    this.subtitle,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.policy = CarpenterBreakpointRegionPolicy.masterDetail,
    this.splitPosition = 0.42,
    this.onSplitPositionChanged,
    this.masterFocusNode,
    this.detailFocusNode,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget master;
  final T? selectedValue;
  final CarpenterDetailBuilder<T> detailBuilder;
  final VoidCallback? onDetailClosed;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final CarpenterAdaptiveRegionPolicy policy;
  final double splitPosition;
  final ValueChanged<double>? onSplitPositionChanged;
  final FocusNode? masterFocusNode;
  final FocusNode? detailFocusNode;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final selected = selectedValue;
    final actions = CarpenterHeaderActions(
      primary: primaryActions,
      secondary: secondaryActions,
    );
    return CarpenterPageRegion(
      semanticLabel: semanticLabel ?? title,
      scrollOwnership: CarpenterRegionScrollOwnership.child,
      shortcutActions: actions.allActions,
      header: CarpenterPageHeader(
        title: title,
        subtitle: subtitle,
        actions: actions.allActions.isEmpty ? null : actions,
      ),
      body: CarpenterMasterDetail(
        master: master,
        detail: selected == null ? null : detailBuilder(context, selected),
        onDetailVisibilityChanged: (visible) {
          if (!visible) onDetailClosed?.call();
        },
        policy: policy,
        splitPosition: splitPosition,
        onSplitPositionChanged: onSplitPositionChanged,
        masterFocusNode: masterFocusNode,
        detailFocusNode: detailFocusNode,
      ),
    );
  }
}
