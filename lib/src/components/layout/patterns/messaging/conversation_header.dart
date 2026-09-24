import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import '../../../collections/list_tile.dart';
import 'messaging_models.dart';

/// Compact selectable preview of the host-provided pinned messages.
final class CarpenterPinnedMessages extends StatelessWidget {
  const CarpenterPinnedMessages({
    super.key,
    required this.previews,
    required this.currentIndex,
    required this.onSelected,
  }) : assert(previews.length > 0),
       assert(currentIndex >= 0 && currentIndex < previews.length);

  final List<String> previews;
  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => CarpenterListTile(
    presentation: CarpenterListTilePresentation.collectionRow,
    onInvoke: () => onSelected(currentIndex),
    semanticLabel:
        'Закреплённое сообщение ${currentIndex + 1} из ${previews.length}',
    leading: const CarpenterIcon(
      GravityIcons.pinFill,
      size: IconSize.small,
      semanticLabel: 'Закреплено',
    ),
    title: CarpenterText.caption(
      previews[currentIndex],
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      emphasis: TypographyEmphasis.medium,
    ),
    trailing: CarpenterText.caption(
      '${currentIndex + 1}/${previews.length}',
      colorRole: ContentColorRole.secondary,
    ),
  );
}

/// Compact conversation header with truthful optional presence and actions.
final class CarpenterConversationHeader extends StatelessWidget {
  const CarpenterConversationHeader({
    super.key,
    required this.title,
    required this.avatar,
    this.presence,
    this.status,
    this.onBack,
    this.onCall,
    this.onActions,
    this.actions,
    this.pinnedMessages,
  });

  final String title;
  final Widget avatar;
  final CarpenterPresenceKind? presence;

  /// Compatibility override for host-specific presence text.
  final String? status;
  final VoidCallback? onBack;
  final VoidCallback? onCall;
  final VoidCallback? onActions;

  /// Compatibility slot for an existing action group.
  final Widget? actions;
  final CarpenterPinnedMessages? pinnedMessages;

  String? get _presenceLabel =>
      status ??
      switch (presence) {
        CarpenterPresenceKind.online => 'онлайн',
        CarpenterPresenceKind.offline => 'офлайн',
        CarpenterPresenceKind.typing => 'печатает…',
        CarpenterPresenceKind.recordingVoice => 'записывает голосовое…',
        CarpenterPresenceKind.recordingVideo => 'записывает видео…',
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final presenceLabel = _presenceLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface.base,
        border: Border(
          bottom: BorderSide(
            color: theme.overlay.border,
            width: context.units(theme.shapes.adaptiveRegionBorderWidth),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(gap),
            child: Row(
              children: [
                if (onBack != null) ...[
                  CarpenterIconButton(
                    icon: GravityIcons.arrowLeft,
                    semanticLabel: 'К разговорам',
                    onPressed: onBack,
                    prominence: ActionProminence.ghost,
                  ),
                  SizedBox(width: gap),
                ],
                avatar,
                SizedBox(width: gap),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CarpenterText.label(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        emphasis: TypographyEmphasis.strong,
                      ),
                      if (presenceLabel != null && presenceLabel.isNotEmpty)
                        CarpenterText.caption(
                          presenceLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          colorRole: ContentColorRole.secondary,
                        ),
                    ],
                  ),
                ),
                if (onCall != null)
                  CarpenterIconButton(
                    icon: GravityIcons.handset,
                    semanticLabel: 'Позвонить',
                    onPressed: onCall,
                    prominence: ActionProminence.ghost,
                  ),
                if (onActions != null)
                  CarpenterIconButton(
                    icon: GravityIcons.ellipsis,
                    semanticLabel: 'Действия с чатом',
                    onPressed: onActions,
                    prominence: ActionProminence.ghost,
                  ),
                ?actions,
              ],
            ),
          ),
          ?pinnedMessages,
        ],
      ),
    );
  }
}
