import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../../internal/rendering/interactive_region.dart';
import '../basic/gravity_icons.g.dart';
import '../basic/icon.dart';
import '../basic/card.dart';

/// Collapsible content surface with a keyboard-accessible disclosure header.
/// Header actions remain independently interactive; content is removed when closed.
final class CarpenterExpander extends StatefulWidget {
  const CarpenterExpander({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.onChanged,
  }) : _listGroup = false;

  /// Groups homogeneous list rows without adding a card or content insets.
  ///
  /// Place groups directly inside one collection surface. Rows own their
  /// padding; the group only supplies a disclosure header and separator.
  const CarpenterExpander.listGroup({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.onChanged,
  }) : _listGroup = true;

  final bool _listGroup;
  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;

  @override
  State<CarpenterExpander> createState() => _CarpenterExpanderState();
}

final class _CarpenterExpanderState extends State<CarpenterExpander> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(CarpenterExpander oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded)
      _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onChanged?.call(_expanded);
  }

  Widget _reveal(BuildContext context, Widget child) {
    final motion = CarpenterTheme.of(context).motion;
    final duration = motion.transitionDuration(context);
    // A zero-duration AnimatedSize can invalidate itself during layout when
    // a nested section disappears. Reduced motion needs no animation widget.
    if (duration == Duration.zero) return child;
    return AnimatedSize(
      duration: duration,
      curve: motion.stateCurve,
      alignment: Alignment.topCenter,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    final primary = theme.content.resolve(ContentColorRole.primary);
    final body = Column(
      mainAxisSize: widget._listGroup ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          expanded: _expanded,
          button: true,
          onTap: _toggle,
          child: InteractiveRegion(
            onActivate: _toggle,
            builder: (context, states, showFocusHighlight) => DecoratedBox(
              decoration: BoxDecoration(
                color: states.contains(WidgetState.hovered)
                    ? theme.overlay.hovered
                    : widget._listGroup
                    ? theme.surface.subtle
                    : const Color(0x00000000),
                border: showFocusHighlight
                    ? Border.all(
                        color: theme.focus.color,
                        width: context.units(theme.focus.width),
                      )
                    : null,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: context.units(theme.sizes.minimumTarget),
                ),
                child: Padding(
                  padding: EdgeInsets.all(gap),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: AnimatedRotation(
                          turns: _expanded
                              ? (Directionality.of(context) == TextDirection.rtl
                                    ? -.25
                                    : .25)
                              : 0,
                          duration: theme.motion.transitionDuration(context),
                          curve: theme.motion.stateCurve,
                          child: CarpenterIcon(
                            Directionality.of(context) == TextDirection.rtl
                                ? GravityIcons.chevronLeft
                                : GravityIcons.chevronRight,
                            size: IconSize.small,
                          ),
                        ),
                      ),
                      SizedBox(width: gap),
                      Expanded(
                        child: DefaultTextStyle(
                          style: theme.typography
                              .resolve(
                                context,
                                TypographyRole.body,
                                TypographyEmphasis.medium,
                              )
                              .copyWith(color: primary),
                          child: widget.header,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _reveal(
          context,
          _expanded
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: theme.overlay.border),
                    ),
                  ),
                  child: Padding(
                    padding: widget._listGroup
                        ? EdgeInsets.zero
                        : EdgeInsets.all(gap),
                    child: DefaultTextStyle(
                      style: theme.typography
                          .resolve(
                            context,
                            TypographyRole.body,
                            TypographyEmphasis.regular,
                          )
                          .copyWith(color: primary),
                      child: widget.content,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
    return widget._listGroup ? body : CarpenterCard(padded: false, child: body);
  }
}
