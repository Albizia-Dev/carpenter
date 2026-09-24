import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/input/input.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu_entry.dart';
import 'conversation_components.dart';
import 'messaging_models.dart';

typedef CarpenterConversationActionsBuilder =
    List<CarpenterMenuItem> Function(CarpenterConversationView conversation);

typedef CarpenterConversationAvatarBuilder =
    Widget Function(
      BuildContext context,
      CarpenterConversationView conversation,
    );

/// Controlled conversation directory with search, creation and resilient data
/// states. Pinning and chronology are supplied in the host-owned list order.
final class CarpenterConversationDirectory extends StatelessWidget {
  const CarpenterConversationDirectory({
    super.key,
    required this.searchController,
    required this.conversations,
    required this.selectedId,
    required this.onConversationSelected,
    required this.onSearchChanged,
    required this.onCreateConversation,
    this.initialLoading = false,
    this.failureLabel,
    this.emptyLabel = 'Нет чатов',
    this.actionsBuilder,
    this.avatarBuilder,
  });

  final TextEditingController searchController;
  final List<CarpenterConversationView> conversations;
  final String? selectedId;
  final ValueChanged<String> onConversationSelected;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onCreateConversation;
  final bool initialLoading;
  final String? failureLabel;
  final String emptyLabel;
  final CarpenterConversationActionsBuilder? actionsBuilder;
  final CarpenterConversationAvatarBuilder? avatarBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return ColoredBox(
      color: theme.surface.base,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(gap),
            child: Row(
              children: [
                Expanded(
                  child: CarpenterInput(
                    controller: searchController,
                    placeholder: 'Поиск',
                    semanticLabel: 'Поиск чатов',
                    leadingIcon: GravityIcons.magnifier,
                    onChanged: onSearchChanged,
                  ),
                ),
                SizedBox(width: gap),
                CarpenterIconButton(
                  icon: GravityIcons.commentPlus,
                  semanticLabel: 'Создать чат',
                  onPressed: onCreateConversation,
                  colorRole: ActionColorRole.primary,
                ),
              ],
            ),
          ),
          if (failureLabel case final label?)
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(gap, 0, gap, gap),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: CarpenterText.feedback(
                  label,
                  feedbackRole: FeedbackColorRole.danger,
                  role: TypographyRole.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          Expanded(child: _content(context)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (initialLoading && conversations.isEmpty) {
      return ListView.builder(
        itemCount: CarpenterConversationSkeleton.initialCount,
        itemBuilder: (_, index) => CarpenterConversationSkeleton(
          key: ValueKey('conversation-skeleton-$index'),
        ),
      );
    }
    if (conversations.isEmpty) {
      return Center(
        child: CarpenterText.body(
          emptyLabel,
          colorRole: ContentColorRole.secondary,
        ),
      );
    }
    return ListView.builder(
      itemCount: conversations.length,
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        return CarpenterConversationTile(
          key: ValueKey('conversation-${conversation.id}'),
          title: conversation.title,
          preview: conversation.preview,
          previewContent: _preview(conversation),
          avatar:
              avatarBuilder?.call(context, conversation) ??
              CarpenterConversationAvatar(
                name: conversation.title,
                shape: conversation.avatarShape,
                muted: conversation.muted,
                colorRole: _stableAvatarRole(conversation.id),
              ),
          selected: selectedId == conversation.id,
          onSelected: () => onConversationSelected(conversation.id),
          unreadCount: conversation.unreadCount,
          previewDelivery: conversation.effectivePreviewDelivery,
          actions: actionsBuilder?.call(conversation) ?? const [],
        );
      },
    );
  }

  Widget _preview(CarpenterConversationView conversation) {
    final draft = conversation.draft;
    if (draft != null && draft.isNotEmpty) {
      return Row(
        children: [
          const CarpenterText.feedback(
            'Черновик',
            feedbackRole: FeedbackColorRole.danger,
            role: TypographyRole.caption,
            maxLines: 1,
          ),
          const CarpenterText.caption(': ', maxLines: 1),
          Expanded(
            child: CarpenterText.caption(
              draft,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              colorRole: ContentColorRole.secondary,
            ),
          ),
        ],
      );
    }
    final author = conversation.previewAuthor;
    return Row(
      children: [
        if (author != null && author.isNotEmpty)
          CarpenterText.caption(
            '$author: ',
            maxLines: 1,
            emphasis: TypographyEmphasis.strong,
            colorRole: ContentColorRole.secondary,
          ),
        Expanded(
          child: CarpenterText.caption(
            conversation.preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            colorRole: ContentColorRole.secondary,
          ),
        ),
      ],
    );
  }

  ActionColorRole _stableAvatarRole(String id) {
    var value = 0;
    for (final unit in id.codeUnits) {
      value = (value * 31 + unit) & 0x7fffffff;
    }
    const roles = [
      ActionColorRole.primary,
      ActionColorRole.utility,
      ActionColorRole.info,
      ActionColorRole.success,
      ActionColorRole.warning,
    ];
    return roles[value % roles.length];
  }
}
