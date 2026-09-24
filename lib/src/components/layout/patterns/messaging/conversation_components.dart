import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/avatar.dart';
import '../../../basic/badge.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
import '../../../collections/list_tile.dart';
import 'messaging_models.dart';

/// Themed avatar with an optional muted marker. Media resolution stays with
/// the host; an image failure returns to the initials.
final class CarpenterConversationAvatar extends StatelessWidget {
  const CarpenterConversationAvatar({
    super.key,
    required this.name,
    required this.shape,
    this.image,
    this.muted = false,
    this.colorRole = ActionColorRole.primary,
  });

  final String name;
  final CarpenterConversationAvatarShape shape;
  final ImageProvider<Object>? image;
  final bool muted;
  final ActionColorRole colorRole;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extent = context.units(theme.sizes.control(ControlSize.medium));
    final initials = name.characters.take(1).toString();
    final fallback = Center(
      child: CarpenterText.label(initials, colorRole: ContentColorRole.inverse),
    );
    final avatar = shape == CarpenterConversationAvatarShape.person
        ? CarpenterAvatar(
            initials: initials,
            semanticLabel: name,
            foregroundImage: image,
          )
        : Semantics(
            image: true,
            label: name,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                context.units(theme.shapes.radius(ShapeRole.rounded)),
              ),
              child: SizedBox.square(
                dimension: extent,
                child: ColoredBox(
                  color: theme.actions
                      .resolve(colorRole, ActionProminence.filled, const {})
                      .background,
                  child: image == null
                      ? fallback
                      : Image(
                          image: image!,
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                          errorBuilder: (_, _, _) => fallback,
                        ),
                ),
              ),
            ),
          );
    if (!muted) return avatar;
    return SizedBox.square(
      dimension: extent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          PositionedDirectional(
            end: 0,
            bottom: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.surface.base,
                borderRadius: BorderRadius.circular(
                  context.units(theme.shapes.radius(ShapeRole.rounded)),
                ),
              ),
              child: const CarpenterIcon(
                GravityIcons.bellSlash,
                size: IconSize.small,
                semanticLabel: 'Без звука',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A conversation row with controlled selection and host-supplied actions.
final class CarpenterConversationTile extends StatefulWidget {
  const CarpenterConversationTile({
    super.key,
    required this.title,
    required this.preview,
    required this.avatar,
    required this.selected,
    required this.onSelected,
    this.unreadCount = 0,
    this.markedUnread = false,
    this.previewDelivery,
    this.timestampLabel,
    this.previewContent,
    this.actions = const [],
  });

  final String title;
  final String preview;
  final Widget avatar;
  final bool selected;
  final VoidCallback onSelected;
  final int unreadCount;
  final bool markedUnread;
  final CarpenterDeliveryState? previewDelivery;
  final String? timestampLabel;
  final Widget? previewContent;
  final List<CarpenterMenuItem> actions;

  @override
  State<CarpenterConversationTile> createState() =>
      _CarpenterConversationTileState();
}

class _CarpenterConversationTileState extends State<CarpenterConversationTile> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final tile = CarpenterListTile(
      presentation: CarpenterListTilePresentation.standard,
      selected: widget.selected,
      onInvoke: widget.onSelected,
      leading: widget.avatar,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.label(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            emphasis: TypographyEmphasis.strong,
          ),
          Row(
            children: [
              Expanded(
                child:
                    widget.previewContent ??
                    CarpenterText.caption(
                      widget.preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      colorRole: ContentColorRole.secondary,
                    ),
              ),
            ],
          ),
        ],
      ),
      trailing:
          widget.timestampLabel != null ||
              widget.previewDelivery != null ||
              widget.unreadCount > 0 ||
              widget.markedUnread
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.previewDelivery case final delivery?)
                      CarpenterIcon(
                        switch (delivery) {
                          CarpenterDeliveryState.sending => GravityIcons.clock,
                          CarpenterDeliveryState.sent => GravityIcons.check,
                          CarpenterDeliveryState.read =>
                            GravityIcons.checkDouble,
                          CarpenterDeliveryState.failed =>
                            GravityIcons.exclamationShape,
                        },
                        size: IconSize.small,
                        semanticLabel: switch (delivery) {
                          CarpenterDeliveryState.sending => 'Отправляется',
                          CarpenterDeliveryState.sent => 'Отправлено',
                          CarpenterDeliveryState.read => 'Прочитано',
                          CarpenterDeliveryState.failed => 'Ошибка отправки',
                        },
                      ),
                    if (widget.timestampLabel case final timestamp?) ...[
                      SizedBox(
                        width: context.units(
                          CarpenterTheme.of(context).spacing.xsmall,
                        ),
                      ),
                      CarpenterText.caption(
                        timestamp,
                        colorRole: ContentColorRole.secondary,
                      ),
                    ],
                  ],
                ),
                if (widget.unreadCount > 0 || widget.markedUnread) ...[
                  SizedBox(
                    height: context.units(
                      CarpenterTheme.of(context).spacing.xsmall,
                    ),
                  ),
                  if (widget.unreadCount > 0)
                    CarpenterBadge.count(
                      widget.unreadCount,
                      semanticLabel: '${widget.unreadCount} непрочитанных',
                    )
                  else
                    const CarpenterText.caption(
                      '•',
                      emphasis: TypographyEmphasis.strong,
                    ),
                ],
              ],
            )
          : null,
    );
    if (widget.actions.isEmpty) return tile;
    return GestureDetector(
      onSecondaryTap: () => setState(() => _menuOpen = true),
      onLongPress: () => setState(() => _menuOpen = true),
      child: CarpenterPopover(
        open: _menuOpen,
        onOpenChanged: (open) => setState(() => _menuOpen = open),
        content: CarpenterMenu(
          semanticLabel: 'Действия с разговором',
          onDismissRequested: () => setState(() => _menuOpen = false),
          items: widget.actions,
        ),
        anchor: tile,
      ),
    );
  }
}

/// A neutral loading row for the first conversation directory request.
final class CarpenterConversationSkeleton extends StatelessWidget {
  const CarpenterConversationSkeleton({super.key});

  /// Initial directory placeholder count within the requested five to seven.
  static const initialCount = 6;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final barHeight = context.units(theme.spacing.small);
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Row(
        children: [
          SizedBox.square(
            dimension: context.units(theme.sizes.control(ControlSize.medium)),
            child: ColoredBox(color: theme.surface.subtle),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: context.units(theme.sizes.tableColumn),
                  height: barHeight,
                  child: ColoredBox(color: theme.surface.subtle),
                ),
                SizedBox(height: barHeight),
                SizedBox(
                  width: context.units(theme.sizes.tableColumn),
                  height: barHeight,
                  child: ColoredBox(color: theme.surface.subtle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
