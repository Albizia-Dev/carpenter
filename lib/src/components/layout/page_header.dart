import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/status_indicator.dart';
import '../basic/text.dart';
import 'action_overflow.dart';
import 'toolbar.dart';

@immutable
final class CarpenterPageStatus {
  const CarpenterPageStatus({required this.label, required this.role});

  final String label;
  final FeedbackColorRole role;
}

final class CarpenterPageHeader extends StatelessWidget {
  const CarpenterPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.status,
    this.breadcrumbs,
    this.actions,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.semanticLabel,
  }) : assert(
         actions == null ||
             (primaryActions.length == 0 && secondaryActions.length == 0),
         'Use either actions or descriptor action lists.',
       );

  final String title;
  final String? subtitle;
  final CarpenterPageStatus? status;
  final Widget? breadcrumbs;
  final Widget? actions;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final externalGap = context.units(theme.spacing.layoutHeader);
      final internalGap = context.units(theme.spacing.xsmall);
      final statusGap = context.units(theme.spacing.small);
      final viewport = const CarpenterViewportPolicy().resolve(
        context,
        constraints.maxWidth,
      );
      final actionWidget = actions ?? _descriptorActions();
      final titleBlock = IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (breadcrumbs != null) ...[
              breadcrumbs!,
              SizedBox(height: externalGap),
            ],
            CarpenterText.title(
              title,
              emphasis: TypographyEmphasis.strong,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null) ...[
              SizedBox(height: internalGap),
              CarpenterText.body(
                subtitle!,
                colorRole: ContentColorRole.secondary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (status case final CarpenterPageStatus value) ...[
              SizedBox(height: statusGap),
              CarpenterStatusIndicator(label: value.label, role: value.role),
            ],
          ],
        ),
      );
      final content = actionWidget == null
          ? titleBlock
          : viewport == CarpenterViewportClass.narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                titleBlock,
                SizedBox(height: externalGap),
                actionWidget,
              ],
            )
          : ActionOverflowLayout(
              content: titleBlock,
              actions: actionWidget,
              gap: externalGap,
              minimumInlineActionWidth: context.units(
                theme.sizes.actionHeight(ControlSize.medium),
              ),
            );
      return Semantics(
        container: true,
        explicitChildNodes: true,
        header: true,
        label: semanticLabel ?? title,
        child: content,
      );
    },
  );

  Widget? _descriptorActions() {
    if (primaryActions.isEmpty && secondaryActions.isEmpty) return null;
    return CarpenterToolbar(
      semanticLabel: '$title actions',
      items: [
        for (final action in primaryActions)
          CarpenterToolbarItem(
            action: action,
            group: CarpenterToolbarGroup.primary,
            prominence: ActionProminence.high,
          ),
        for (final action in secondaryActions)
          CarpenterToolbarItem(
            action: action,
            group: CarpenterToolbarGroup.secondary,
          ),
      ],
    );
  }
}
