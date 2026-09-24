import 'package:flutter/widgets.dart';

import '../../../../foundation/adaptive.dart';
import '../../master_detail.dart';
import '../../regions/region_role.dart';

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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final viewport = const CarpenterViewportPolicy(accountForTextScale: true);
      final master = KeyedSubtree(
        key: const ValueKey('carpenter-messenger-directory'),
        child: directory,
      );
      final detail = KeyedSubtree(
        key: ValueKey(
          'carpenter-messenger-conversation-${selectedConversationId ?? 'none'}',
        ),
        child: conversation,
      );
      final empty = KeyedSubtree(
        key: const ValueKey('carpenter-messenger-empty'),
        child: emptyConversation,
      );
      if (viewport.resolve(context, constraints.maxWidth) ==
          CarpenterViewportClass.narrow) {
        return SizedBox.expand(
          child: selectedConversationId == null ? master : detail,
        );
      }
      return SizedBox.expand(
        child: CarpenterMasterDetail(
          viewportPolicy: viewport,
          detailScrollOwnership: CarpenterRegionScrollOwnership.child,
          masterSemanticLabel: 'Разговоры',
          detailSemanticLabel: 'Переписка',
          onDetailVisibilityChanged: null,
          master: master,
          detail: selectedConversationId == null ? empty : detail,
        ),
      );
    },
  );
}
