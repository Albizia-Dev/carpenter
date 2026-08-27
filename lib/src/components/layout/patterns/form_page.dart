import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../page_header.dart';
import '../regions/primary_region.dart';
import '../regions/region_role.dart';
import 'header_actions.dart';

final class CarpenterFormPage extends StatelessWidget {
  const CarpenterFormPage({
    super.key,
    required this.title,
    required this.formContent,
    required this.saveAction,
    required this.cancelAction,
    required this.dirty,
    this.subtitle,
    this.validationSummary,
    this.secondaryActions = const [],
    this.destructiveActions = const [],
    this.saveExecutionPhase = ActionExecutionPhase.idle,
    this.dirtyLabel = 'Unsaved changes',
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget formContent;
  final Widget? validationSummary;
  final CarpenterActionDescriptor saveAction;
  final CarpenterActionDescriptor cancelAction;
  final List<CarpenterActionDescriptor> secondaryActions;
  final List<CarpenterActionDescriptor> destructiveActions;
  final bool dirty;
  final ActionExecutionPhase saveExecutionPhase;
  final String dirtyLabel;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutSection);
    final actions = CarpenterHeaderActions(
      primary: [saveAction],
      secondary: [cancelAction, ...secondaryActions],
      destructive: destructiveActions,
      primaryExecutionPhase: saveExecutionPhase,
    );
    return CarpenterPageRegion(
      semanticLabel: semanticLabel ?? title,
      scrollOwnership: CarpenterRegionScrollOwnership.child,
      shortcutActions: actions.allActions,
      header: CarpenterPageHeader(
        title: title,
        subtitle: subtitle,
        status: dirty
            ? CarpenterPageStatus(
                label: dirtyLabel,
                role: FeedbackColorRole.warning,
              )
            : null,
        actions: actions,
      ),
      body: CarpenterPrimaryRegion(
        scrollOwnership: CarpenterRegionScrollOwnership.region,
        semanticLabel: '$title form',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (validationSummary != null) ...[
              validationSummary!,
              SizedBox(height: gap),
            ],
            formContent,
          ],
        ),
      ),
    );
  }
}
