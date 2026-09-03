import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../../internal/overlay/anchored_overlay_positioner.dart';
import '../../basic/button/icon_button.dart';
import '../../basic/icons.dart';
import '../../behaviour/menu/menu.dart';
import '../../behaviour/menu/menu_entry.dart';

@immutable
final class CarpenterTableActions {
  const CarpenterTableActions({
    this.primary = const [],
    this.secondary = const [],
  });

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;

  bool get isEmpty => primary.isEmpty && secondary.isEmpty;
}

typedef CarpenterTableActionsBuilder<T> = CarpenterTableActions Function(
  T item,
);

/// Compact action surface used by table and tree-table rows.
///
/// Two icon-bearing primary actions can stay inline. Remaining primary actions
/// and every secondary action live under the ellipsis button. The owning table
/// reserves the whole lane, so the set of actions never changes row geometry.
///
/// The overflow menu deliberately uses an [OverlayEntry] rather than the
/// regular dropdown portal. Flutter's [OverlayPortal] lifecycle is tied to a
/// lazy sliver child and can drop the overlay while a table row is hosted by a
/// [ListView]. Keeping the menu entry in the overlay makes row actions work in
/// virtualized tables without giving up lazy row construction.
final class CarpenterTableActionCell extends StatelessWidget {
  const CarpenterTableActionCell({
    super.key,
    this.primary = const [],
    this.secondary = const [],
    this.overflowLabel = 'More actions',
    this.semanticLabel = 'Row actions',
  });

  final List<CarpenterActionDescriptor> primary;
  final List<CarpenterActionDescriptor> secondary;
  final String overflowLabel;
  final String semanticLabel;

  static double preferredColumnWidth(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final control = context.units(theme.sizes.actionHeight(ControlSize.xsmall));
    final gap = context.units(theme.spacing.layoutToolbar);
    final padding = context.units(theme.spacing.tableHorizontal);

    return control * 3 + gap * 2 + padding * 2;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutToolbar);
    final inline = <CarpenterActionDescriptor>[];
    final overflow = <CarpenterActionDescriptor>[];

    for (final action in primary) {
      if (action.icon != null && inline.length < 2) {
        inline.add(action);
      } else {
        overflow.add(action);
      }
    }
    overflow.addAll(secondary);

    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < inline.length; index++) ...[
              if (index > 0) SizedBox(width: gap),
              CarpenterIconButton.fromAction(
                inline[index],
                prominence: ActionProminence.ghost,
                size: ControlSize.xsmall,
              ),
            ],
            if (overflow.isNotEmpty) ...[
              if (inline.isNotEmpty) SizedBox(width: gap),
              _TableOverflowMenuButton(
                actions: overflow,
                label: overflowLabel,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

final class _TableOverflowMenuButton extends StatefulWidget {
  const _TableOverflowMenuButton({
    required this.actions,
    required this.label,
  });

  final List<CarpenterActionDescriptor> actions;
  final String label;

  @override
  State<_TableOverflowMenuButton> createState() =>
      _TableOverflowMenuButtonState();
}

final class _TableOverflowMenuButtonState
    extends State<_TableOverflowMenuButton> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  @override
  void didUpdateWidget(_TableOverflowMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open && oldWidget.actions != widget.actions) {
      _entry?.markNeedsBuild();
    }
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final overlay = Overlay.of(context, rootOverlay: true);
    final anchorBox =
        _anchorKey.currentContext?.findRenderObject() as RenderBox?;
    final overlayBox = overlay.context.findRenderObject() as RenderBox?;
    if (anchorBox == null || overlayBox == null || !anchorBox.hasSize) return;

    final anchorTopLeft = overlayBox.globalToLocal(
      anchorBox.localToGlobal(Offset.zero),
    );
    final anchorRect = anchorTopLeft & anchorBox.size;
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.overlayAnchorGap);
    final inset = context.units(theme.spacing.overlayViewportInset);

    _entry = OverlayEntry(
      builder: (overlayContext) => Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _close,
            child: const SizedBox.expand(),
          ),
          CustomSingleChildLayout(
            delegate: _TableMenuLayoutDelegate(
              anchor: anchorRect,
              gap: gap,
              viewportInset: inset,
              textDirection: Directionality.of(overlayContext),
            ),
            child: CarpenterMenu(
              items: [
                for (final action in widget.actions)
                  CarpenterMenuItem(action: action),
              ],
              onDismissRequested: _close,
              semanticLabel: widget.label,
            ),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
    setState(() {});
  }

  void _close() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: _anchorKey,
    child: CarpenterIconButton(
      icon: CarpenterIcons.more,
      semanticLabel: widget.label,
      prominence: ActionProminence.ghost,
      size: ControlSize.xsmall,
      onPressed: _toggle,
    ),
  );
}

final class _TableMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _TableMenuLayoutDelegate({
    required this.anchor,
    required this.gap,
    required this.viewportInset,
    required this.textDirection,
  });

  final Rect anchor;
  final double gap;
  final double viewportInset;
  final TextDirection textDirection;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(
        Size(
          (constraints.maxWidth - viewportInset * 2)
              .clamp(0, constraints.maxWidth)
              .toDouble(),
          (constraints.maxHeight - viewportInset * 2)
              .clamp(0, constraints.maxHeight)
              .toDouble(),
        ),
      );

  @override
  Offset getPositionForChild(Size size, Size childSize) =>
      AnchoredOverlayPositioner.calculate(
        viewport: size,
        anchor: anchor,
        child: childSize,
        preferred: OverlayPlacement.bottomEnd,
        textDirection: textDirection,
        gap: gap,
        viewportInset: viewportInset,
        fallbacks: const [OverlayPlacement.topEnd],
      ).offset;

  @override
  bool shouldRelayout(_TableMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.gap != gap ||
      oldDelegate.viewportInset != viewportInset ||
      oldDelegate.textDirection != textDirection;
}
