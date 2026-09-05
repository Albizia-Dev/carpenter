import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/overlay/anchored_overlay_positioner.dart';
import '../basic/button/button.dart';
import '../basic/button/icon_button.dart';
import '../basic/icons.dart';
import 'action_overflow.dart';
import 'menu/menu.dart';
import 'menu/menu_entry.dart';

enum CarpenterActionStripGroup { primary, secondary, overflow }

enum CarpenterActionStripPresentation { label, icon }

@immutable
final class CarpenterActionStripItem {
  const CarpenterActionStripItem({
    required this.action,
    this.group = CarpenterActionStripGroup.secondary,
    this.presentation = CarpenterActionStripPresentation.label,
    this.prominence = ActionProminence.ghost,
    this.size = ControlSize.medium,
    this.executionPhase = ActionExecutionPhase.idle,
  });

  final CarpenterActionDescriptor action;
  final CarpenterActionStripGroup group;
  final CarpenterActionStripPresentation presentation;
  final ActionProminence prominence;
  final ControlSize size;
  final ActionExecutionPhase executionPhase;
}

/// Adaptive action presentation shared by page toolbars and compact collection
/// action lanes.
///
/// Actions degrade by semantic group rather than one item at a time:
/// secondary actions overflow first, primary labels collapse to icons when all
/// primary actions have icons, and finally every action moves under overflow.
/// Actions in the [CarpenterActionStripGroup.overflow] group always stay under
/// the overflow button.
final class CarpenterActionStrip extends StatelessWidget {
  const CarpenterActionStrip({
    super.key,
    required this.items,
    this.alignment = AlignmentDirectional.centerEnd,
    this.overflowLabel = 'More actions',
    this.overflowSize = ControlSize.medium,
    this.semanticLabel = 'Actions',
  });

  final List<CarpenterActionStripItem> items;
  final AlignmentGeometry alignment;
  final String overflowLabel;
  final ControlSize overflowSize;
  final String semanticLabel;

  /// Width of a compact icon lane with a fixed number of inline action slots.
  ///
  /// This deliberately excludes parent cell padding so collection components
  /// can reserve their own chrome without duplicating control geometry.
  static double compactExtent(
    BuildContext context, {
    int inlineActions = 2,
    bool reserveOverflow = true,
    ControlSize size = ControlSize.xsmall,
  }) {
    assert(inlineActions >= 0);
    final theme = CarpenterTheme.of(context);
    final control = context.units(theme.sizes.actionHeight(size));
    final gap = context.units(theme.spacing.layoutToolbar);
    final count = inlineActions + (reserveOverflow ? 1 : 0);
    if (count == 0) return 0;
    return control * count + gap * (count - 1);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = _layoutItems(context, constraints.maxWidth);
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: Align(
          alignment: alignment,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < layout.visible.length; index++) ...[
                if (index > 0) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: _ActionStripAction(
                    item: layout.visible[index],
                    forceIcon: layout.iconOnly,
                  ),
                ),
              ],
              if (layout.overflow.isNotEmpty) ...[
                if (layout.visible.isNotEmpty) _gap(context),
                Flexible(
                  fit: FlexFit.loose,
                  child: _ActionStripOverflowButton(
                    items: layout.overflow,
                    label: overflowLabel,
                    size: overflowSize,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  Widget _gap(BuildContext context) => SizedBox(
    width: context.units(CarpenterTheme.of(context).spacing.layoutToolbar),
  );

  _ActionStripLayout _layoutItems(BuildContext context, double availableWidth) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.layoutToolbar);
    final overflowWidth = context.units(theme.sizes.actionHeight(overflowSize));
    final entries = [
      for (final item in items)
        ActionOverflowEntry(
          value: item,
          group: switch (item.group) {
            CarpenterActionStripGroup.primary => ActionOverflowGroup.primary,
            CarpenterActionStripGroup.secondary =>
              ActionOverflowGroup.secondary,
            CarpenterActionStripGroup.overflow => ActionOverflowGroup.overflow,
          },
          expandedWidth: _itemWidth(context, item),
          iconWidth: item.action.icon == null
              ? null
              : context.units(theme.sizes.actionHeight(item.size)),
        ),
    ];
    final resolution = const ActionOverflowResolver<CarpenterActionStripItem>()
        .resolve(
          entries: entries,
          availableWidth: availableWidth,
          gap: gap,
          overflowWidth: overflowWidth,
        );
    return _ActionStripLayout(
      visible: resolution.visible,
      overflow: resolution.overflow,
      iconOnly: resolution.iconOnly,
    );
  }

  double _itemWidth(BuildContext context, CarpenterActionStripItem item) {
    final theme = CarpenterTheme.of(context);
    if (item.presentation == CarpenterActionStripPresentation.icon &&
        item.action.icon != null) {
      return context.units(theme.sizes.actionHeight(item.size));
    }
    final painter = TextPainter(
      text: TextSpan(
        text: item.action.label,
        style: theme.typography.action(
          context,
          item.size,
          TypographyEmphasis.medium,
        ),
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final horizontal = context.units(
      theme.spacing.actionHorizontalPadding(item.size),
    );
    final icon = item.action.icon == null
        ? 0.0
        : context.units(theme.sizes.actionIcon(item.size)) +
              context.units(theme.spacing.actionGap(item.size));
    return painter.width + horizontal * 2 + icon;
  }
}

final class _ActionStripAction extends StatelessWidget {
  const _ActionStripAction({required this.item, required this.forceIcon});

  final CarpenterActionStripItem item;
  final bool forceIcon;

  @override
  Widget build(BuildContext context) {
    final iconOnly =
        (forceIcon ||
            item.presentation == CarpenterActionStripPresentation.icon) &&
        item.action.icon != null;
    if (iconOnly) {
      return CarpenterIconButton.fromAction(
        item.action,
        prominence: item.prominence,
        size: item.size,
        executionPhase: item.executionPhase,
      );
    }
    return CarpenterButton.fromAction(
      item.action,
      prominence: item.prominence,
      size: item.size,
      executionPhase: item.executionPhase,
    );
  }
}

final class _ActionStripOverflowButton extends StatefulWidget {
  const _ActionStripOverflowButton({
    required this.items,
    required this.label,
    required this.size,
  });

  final List<CarpenterActionStripItem> items;
  final String label;
  final ControlSize size;

  @override
  State<_ActionStripOverflowButton> createState() =>
      _ActionStripOverflowButtonState();
}

final class _ActionStripOverflowButtonState
    extends State<_ActionStripOverflowButton> {
  final GlobalKey _anchorKey = GlobalKey();
  OverlayEntry? _entry;

  bool get _open => _entry != null;

  @override
  void didUpdateWidget(_ActionStripOverflowButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_open && oldWidget.items != widget.items) _entry?.markNeedsBuild();
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
            delegate: _ActionStripMenuLayoutDelegate(
              anchor: anchorRect,
              gap: gap,
              viewportInset: inset,
              textDirection: Directionality.of(overlayContext),
            ),
            child: CarpenterMenu(
              items: [
                for (final item in widget.items)
                  CarpenterMenuItem(action: item.action),
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
      size: widget.size,
      onPressed: _toggle,
    ),
  );
}

final class _ActionStripMenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _ActionStripMenuLayoutDelegate({
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
  bool shouldRelayout(_ActionStripMenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.gap != gap ||
      oldDelegate.viewportInset != viewportInset ||
      oldDelegate.textDirection != textDirection;
}

final class _ActionStripLayout {
  const _ActionStripLayout({
    required this.visible,
    required this.overflow,
    required this.iconOnly,
  });

  final List<CarpenterActionStripItem> visible;
  final List<CarpenterActionStripItem> overflow;
  final bool iconOnly;
}
