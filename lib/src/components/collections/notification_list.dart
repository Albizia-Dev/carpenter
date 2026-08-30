import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/badge.dart';
import '../basic/button/button.dart';
import '../basic/card.dart';
import '../basic/text.dart';

@immutable
final class CarpenterNotification {
  const CarpenterNotification({
    required this.id,
    required this.title,
    this.message,
    this.tone = FeedbackColorRole.info,
    this.timestamp,
    this.unread = false,
    this.action,
  });

  final Object id;
  final String title;
  final String? message;
  final FeedbackColorRole tone;
  final DateTime? timestamp;
  final bool unread;
  final CarpenterActionDescriptor? action;
}

/// Persistent notification surface. Items remain until caller state removes them.
final class CarpenterNotificationList extends StatelessWidget {
  const CarpenterNotificationList({
    super.key,
    required this.items,
    this.onDismiss,
    this.emptyMessage = 'No notifications',
    this.semanticLabel = 'Notifications',
  });

  final List<CarpenterNotification> items;
  final ValueChanged<Object>? onDismiss;
  final String emptyMessage;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: CarpenterText.body(
          emptyMessage,
          colorRole: ContentColorRole.secondary,
        ),
      );
    }

    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _NotificationCard(
              notification: items[index],
              onDismiss: onDismiss == null
                  ? null
                  : () => onDismiss!(items[index].id),
            ),
            if (index < items.length - 1) SizedBox(height: gap),
          ],
        ],
      ),
    );
  }
}

final class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, this.onDismiss});

  final CarpenterNotification notification;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final feedback = theme.feedback.resolve(notification.tone);
    final actions = <Widget>[
      if (notification.action != null)
        CarpenterButton.fromAction(
          notification.action!,
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
        ),
      if (onDismiss != null)
        CarpenterButton(
          label: 'Dismiss',
          size: ControlSize.small,
          prominence: ActionProminence.ghost,
          onInvoke: onDismiss,
        ),
    ];

    return CarpenterCard(
      semanticLabel: notification.title,
      borderColor: feedback.foreground.withValues(alpha: .35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CarpenterText.label(
                  notification.title,
                  emphasis: TypographyEmphasis.strong,
                ),
              ),
              if (notification.unread) ...[
                SizedBox(width: gap),
                const CarpenterBadge(
                  label: 'New',
                  role: FeedbackColorRole.info,
                ),
              ],
            ],
          ),
          if (notification.message != null) ...[
            SizedBox(height: gap),
            CarpenterText.body(
              notification.message!,
              colorRole: ContentColorRole.secondary,
            ),
          ],
          if (notification.timestamp != null || actions.isNotEmpty) ...[
            SizedBox(height: gap),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runAlignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: gap,
              runSpacing: gap,
              children: [
                if (notification.timestamp != null)
                  CarpenterText.caption(
                    notification.timestamp!.toLocal().toIso8601String(),
                    colorRole: ContentColorRole.muted,
                  ),
                if (actions.isNotEmpty)
                  Wrap(spacing: gap, runSpacing: gap, children: actions),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
