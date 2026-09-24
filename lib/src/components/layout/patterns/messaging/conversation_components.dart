import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../../foundation/roles.dart';
import '../../../../foundation/theme.dart';
import '../../../basic/avatar.dart';
import '../../../basic/button/icon_button.dart';
import '../../../basic/gravity_icons.g.dart';
import '../../../basic/icon.dart';
import '../../../basic/text.dart';
import '../../../behaviour/menu/menu.dart';
import '../../../behaviour/menu/menu_entry.dart';
import '../../../behaviour/popover.dart';
import '../../../collections/list_tile.dart';

/// The shape communicates whether an identity is a person or a shared room.
enum CarpenterConversationAvatarShape { person, room }

/// Delivery state supplied by the host; Carpenter never infers read receipts.
enum CarpenterMessageDelivery { sending, sent, read }

/// Themed avatar with an optional muted marker. Media resolution stays with
/// the host; an image failure returns to the initials.
final class CarpenterConversationAvatar extends StatelessWidget {
  const CarpenterConversationAvatar({
    super.key,
    required this.name,
    required this.shape,
    this.image,
    this.muted = false,
  });

  final String name;
  final CarpenterConversationAvatarShape shape;
  final ImageProvider<Object>? image;
  final bool muted;

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
                  color: theme.actions.primary.state,
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
    this.actions = const [],
  });

  final String title;
  final String preview;
  final Widget avatar;
  final bool selected;
  final VoidCallback onSelected;
  final int unreadCount;
  final bool markedUnread;
  final CarpenterMessageDelivery? previewDelivery;
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
      presentation: CarpenterListTilePresentation.collectionRow,
      selected: widget.selected,
      onInvoke: widget.onSelected,
      leading: widget.avatar,
      title: CarpenterText.label(
        widget.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        emphasis: TypographyEmphasis.strong,
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: CarpenterText.caption(
              widget.preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              colorRole: ContentColorRole.secondary,
            ),
          ),
          if (widget.previewDelivery case final delivery?)
            CarpenterIcon(
              switch (delivery) {
                CarpenterMessageDelivery.sending => GravityIcons.clock,
                CarpenterMessageDelivery.sent => GravityIcons.check,
                CarpenterMessageDelivery.read => GravityIcons.checkDouble,
              },
              size: IconSize.small,
              semanticLabel: switch (delivery) {
                CarpenterMessageDelivery.sending => 'Отправляется',
                CarpenterMessageDelivery.sent => 'Отправлено',
                CarpenterMessageDelivery.read => 'Прочитано',
              },
            ),
        ],
      ),
      trailing: widget.unreadCount > 0 || widget.markedUnread
          ? CarpenterText.caption(
              widget.unreadCount > 0 ? '${widget.unreadCount}' : '•',
              emphasis: TypographyEmphasis.strong,
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

/// Header geometry shared by conversation detail and standalone previews.
final class CarpenterConversationHeader extends StatelessWidget {
  const CarpenterConversationHeader({
    super.key,
    required this.title,
    required this.status,
    required this.avatar,
    this.onBack,
    this.actions,
  });

  final String title;
  final String status;
  final Widget avatar;
  final VoidCallback? onBack;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return Padding(
      padding: EdgeInsets.all(gap),
      child: Row(
        children: [
          if (onBack != null)
            CarpenterIconButton(
              icon: GravityIcons.arrowLeft,
              semanticLabel: 'К разговорам',
              onPressed: onBack,
              prominence: ActionProminence.ghost,
            ),
          avatar,
          SizedBox(width: gap),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CarpenterText.label(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  emphasis: TypographyEmphasis.strong,
                ),
                CarpenterText.caption(
                  status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  colorRole: ContentColorRole.secondary,
                ),
              ],
            ),
          ),
          ?actions,
        ],
      ),
    );
  }
}
