import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/theme.dart';
import 'conversation_components.dart';
import 'inline_media.dart';
import 'message_bubble.dart';
import 'message_cluster.dart';
import 'message_timeline_chrome.dart';
import 'messaging_models.dart';

typedef CarpenterMessageSelectionChanged =
    void Function(String messageId, bool selected);

typedef CarpenterMessageAvatarBuilder =
    Widget Function(BuildContext context, CarpenterMessageView message);
typedef CarpenterMessageMetadataBuilder =
    List<Widget> Function(BuildContext context, CarpenterMessageView message);

/// Controlled timeline presentation. Pagination and viewport anchoring belong
/// to the host-facing viewport component.
final class CarpenterMessageTimeline extends StatelessWidget {
  const CarpenterMessageTimeline({
    super.key,
    required this.messages,
    required this.selectedIds,
    required this.groupChat,
    this.onSelectionChanged,
    this.onReplyRequested,
    this.onRetryRequested,
    this.onReplyPreviewInvoked,
    this.avatarBuilder,
    this.loadingOlder = false,
    this.mediaPreviewBuilder,
    this.onMediaLoadRequested,
    this.onMediaPlayPauseRequested,
    this.onMediaSeekRequested,
    this.onMediaSpeedChanged,
    this.onMediaFocusChanged,
    this.metadataLeadingBuilder,
    this.metadataTrailingBuilder,
  });

  final List<CarpenterMessageView> messages;
  final Set<String> selectedIds;
  final bool groupChat;
  final CarpenterMessageSelectionChanged? onSelectionChanged;
  final ValueChanged<String>? onReplyRequested;
  final ValueChanged<String>? onRetryRequested;
  final ValueChanged<String>? onReplyPreviewInvoked;
  final CarpenterMessageAvatarBuilder? avatarBuilder;
  final bool loadingOlder;
  final CarpenterMediaPreviewBuilder? mediaPreviewBuilder;
  final ValueChanged<String>? onMediaLoadRequested;
  final ValueChanged<String>? onMediaPlayPauseRequested;
  final CarpenterMediaSeekRequested? onMediaSeekRequested;
  final CarpenterMediaSpeedChanged? onMediaSpeedChanged;
  final CarpenterMediaFocusChanged? onMediaFocusChanged;
  final CarpenterMessageMetadataBuilder? metadataLeadingBuilder;
  final CarpenterMessageMetadataBuilder? metadataTrailingBuilder;

  @override
  Widget build(BuildContext context) {
    final sections = _sections(context);
    return ListView.builder(
      padding: EdgeInsets.all(
        context.units(CarpenterTheme.of(context).spacing.small),
      ),
      itemCount: sections.length + (loadingOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (loadingOlder && index == 0) {
          return const CarpenterMessageHistoryLoading();
        }
        return sections[index - (loadingOlder ? 1 : 0)];
      },
    );
  }

  List<Widget> _sections(BuildContext context) {
    final result = <Widget>[];
    var index = 0;
    DateTime? previousDate;
    while (index < messages.length) {
      final message = messages[index];
      final localDate = message.sentAt.toLocal();
      if (!_sameDate(previousDate, localDate)) {
        result.add(
          CarpenterMessageDateDivider(
            key: ValueKey('message-date-${_dateLabel(localDate)}'),
            label: _dateLabel(localDate),
          ),
        );
      }
      previousDate = localDate;
      if (message.system) {
        result.add(
          CarpenterMessageSystemEvent(
            key: ValueKey('message-system-${message.id}'),
            text: message.body,
          ),
        );
        index++;
        continue;
      }

      final cluster = <CarpenterMessageView>[message];
      var next = index + 1;
      while (next < messages.length &&
          CarpenterMessageClusterPolicy.sameBlock(
            cluster.last,
            messages[next],
          )) {
        cluster.add(messages[next]);
        next++;
      }
      result.add(_cluster(context, cluster));
      index = next;
    }
    return result;
  }

  Widget _cluster(BuildContext context, List<CarpenterMessageView> cluster) {
    final first = cluster.first;
    return CarpenterMessageCluster(
      key: ValueKey('message-cluster-${first.id}'),
      own: first.own,
      avatar: groupChat && !first.own
          ? avatarBuilder?.call(context, first) ??
                CarpenterConversationAvatar(
                  name: first.authorLabel,
                  shape: CarpenterConversationAvatarShape.person,
                )
          : null,
      children: [
        for (var index = 0; index < cluster.length; index++)
          CarpenterMessageBubble(
            key: ValueKey(cluster[index].id),
            message: cluster[index],
            selected: selectedIds.contains(cluster[index].id),
            selectionMode: selectedIds.isNotEmpty,
            showAuthor: groupChat && index == 0,
            onSelectionChanged: onSelectionChanged == null
                ? null
                : (selected) =>
                      onSelectionChanged!(cluster[index].id, selected),
            onReplyRequested:
                onReplyRequested == null || !cluster[index].canReply
                ? null
                : () => onReplyRequested!(cluster[index].id),
            onRetryRequested:
                onRetryRequested == null || !cluster[index].canRetry
                ? null
                : () => onRetryRequested!(cluster[index].id),
            onReplyPreviewInvoked:
                onReplyPreviewInvoked == null ||
                    cluster[index].replyPreview == null
                ? null
                : () => onReplyPreviewInvoked!(cluster[index].id),
            mediaPreviewBuilder: mediaPreviewBuilder,
            onMediaLoadRequested: onMediaLoadRequested,
            onMediaPlayPauseRequested: onMediaPlayPauseRequested,
            onMediaSeekRequested: onMediaSeekRequested,
            onMediaSpeedChanged: onMediaSpeedChanged,
            onMediaFocusChanged: onMediaFocusChanged,
            metadataLeading:
                metadataLeadingBuilder?.call(context, cluster[index]) ??
                const [],
            metadataTrailing:
                metadataTrailingBuilder?.call(context, cluster[index]) ??
                const [],
          ),
      ],
    );
  }
}

bool _sameDate(DateTime? first, DateTime second) =>
    first != null &&
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _dateLabel(DateTime value) {
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(value.day)}.${two(value.month)}.${value.year}';
}
