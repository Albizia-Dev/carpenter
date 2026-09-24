import 'package:flutter/widgets.dart';

import 'conversation_split_view.dart';

/// Full-extent adaptive messenger shell with host-owned selection.
///
/// Narrow viewports show the selected conversation when one exists and the
/// directory otherwise. Wider viewports always retain the directory and show
/// either the selected conversation or [emptyConversation].
final class CarpenterMessengerLayout extends StatelessWidget {
  const CarpenterMessengerLayout({
    super.key,
    required this.selectedConversationId,
    required this.directory,
    required this.conversation,
    required this.emptyConversation,
  });

  final String? selectedConversationId;
  final Widget directory;
  final Widget conversation;
  final Widget emptyConversation;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: CarpenterConversationSplitView(
      selected: selectedConversationId != null,
      master: KeyedSubtree(
        key: const ValueKey('carpenter-messenger-directory'),
        child: directory,
      ),
      detail: KeyedSubtree(
        key: ValueKey(
          'carpenter-messenger-conversation-${selectedConversationId ?? 'none'}',
        ),
        child: conversation,
      ),
      emptyDetail: KeyedSubtree(
        key: const ValueKey('carpenter-messenger-empty'),
        child: emptyConversation,
      ),
    ),
  );
}
