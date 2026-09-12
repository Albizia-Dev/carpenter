import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/status_indicator.dart';
import '../basic/text.dart';
import '../behaviour/action_overflow.dart';
import 'toolbar.dart';

@immutable
final class CarpenterPageStatus {
  const CarpenterPageStatus({required this.label, required this.role});

  final String label;
  final FeedbackColorRole role;
}

final class CarpenterPageHeader extends StatelessWidget {
  /// Creates a responsive heading. [leading] hosts an optional identity visual;
  /// title, metadata and action contracts remain owned by the caller.
  const CarpenterPageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.status,
    this.breadcrumbs,
    this.actions,
    this.primaryActions = const [],
    this.secondaryActions = const [],
    this.overflowActions = const [],
    this.semanticLabel,
  }) : assert(
         actions == null ||
             (primaryActions.length == 0 &&
                 secondaryActions.length == 0 &&
                 overflowActions.length == 0),
         'Use either actions or descriptor action lists.',
       );

  final String title;
  final String? subtitle;

  /// Optional identity visual beside the title, such as an avatar.
  final Widget? leading;
  final CarpenterPageStatus? status;
  final Widget? breadcrumbs;
  final Widget? actions;
  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;

  /// Actions that always appear under the overflow button, even on wide screens.
  /// Nested action groups retain their hierarchy in that menu.
  final List<CarpenterActionDescriptor> overflowActions;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final externalGap = context.units(theme.spacing.layoutHeader);
      final internalGap = context.units(theme.spacing.small) / 2;
      final statusGap = context.units(theme.spacing.small);
      final actionWidget = actions ?? _descriptorActions();
      final titleContent = Column(
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
      );
      final titleBlock = leading == null
          ? titleContent
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                leading!,
                SizedBox(width: externalGap),
                Expanded(child: titleContent),
              ],
            );
      final content = actionWidget == null
          ? titleBlock
          : ActionOverflowLayout(
              keepInline: true,
              content: titleBlock,
              actions: actionWidget,
              gap: externalGap,
              minimumInlineActionWidth: theme.sizes.actionExtent(
                context,
                ControlSize.medium,
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
    if (primaryActions.isEmpty &&
        secondaryActions.isEmpty &&
        overflowActions.isEmpty) {
      return null;
    }
    return CarpenterToolbar(
      semanticLabel: '$title: действия',
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
        for (final action in overflowActions)
          CarpenterToolbarItem(
            action: action,
            group: CarpenterToolbarGroup.overflow,
          ),
      ],
    );
  }
}
