import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'focus_ring.dart';
import 'interactive_region.dart';

enum SelectionControlKind { checkbox, radio, toggle }

typedef SelectionIndicatorBuilder =
    Widget Function(
      BuildContext context,
      CarpenterSelectionStyle style,
      Size size,
    );

final class SelectionControl extends StatelessWidget {
  const SelectionControl({
    super.key,
    required this.kind,
    required this.selected,
    required this.label,
    required this.size,
    required this.onActivate,
    required this.indicatorBuilder,
    this.colorRole = SelectionColorRole.primary,
    this.description,
    this.mixed = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.shortcutCallbacks = const {},
  });

  final SelectionControlKind kind;
  final bool selected;
  final bool mixed;
  final String label;
  final String? description;
  final String? semanticLabel;
  final ControlSize size;
  final VoidCallback? onActivate;
  final SelectionIndicatorBuilder indicatorBuilder;
  final SelectionColorRole colorRole;
  final FocusNode? focusNode;
  final bool autofocus;
  final Map<ShortcutActivator, VoidCallback> shortcutCallbacks;

  @override
  Widget build(BuildContext context) {
    return InteractiveRegion(
      onActivate: onActivate,
      focusNode: focusNode,
      autofocus: autofocus,
      shortcutCallbacks: shortcutCallbacks,
      includeFocusSemantics: false,
      builder: (context, states, showFocusHighlight) {
        return Semantics(
          container: true,
          enabled: onActivate != null,
          checked: kind == SelectionControlKind.toggle || mixed
              ? null
              : selected,
          mixed: kind == SelectionControlKind.checkbox && mixed ? true : null,
          toggled: kind == SelectionControlKind.toggle ? selected : null,
          inMutuallyExclusiveGroup: kind == SelectionControlKind.radio
              ? true
              : null,
          focusable: onActivate != null ? true : null,
          focused: onActivate != null
              ? states.contains(WidgetState.focused)
              : null,
          label: semanticLabel ?? label,
          hint: description,
          onTap: onActivate,
          excludeSemantics: true,
          child: Builder(
            builder: (context) {
              final theme = CarpenterTheme.of(context);
              final style = theme.selection.resolve(
                role: colorRole,
                selected: selected || mixed,
                states: states,
              );
              final indicatorHeight = context.units(
                kind == SelectionControlKind.toggle
                    ? theme.sizes.switchHeight(size)
                    : kind == SelectionControlKind.radio
                    ? theme.sizes.radioSize(size)
                    : theme.sizes.checkboxSize(size),
              );
              final indicatorWidth = context.units(
                kind == SelectionControlKind.toggle
                    ? theme.sizes.switchWidth(size)
                    : kind == SelectionControlKind.radio
                    ? theme.sizes.radioSize(size)
                    : theme.sizes.checkboxSize(size),
              );
              final radius = context.units(
                kind == SelectionControlKind.checkbox
                    ? theme.shapes.checkboxRadius(size)
                    : theme.shapes.radius(ShapeRole.circular),
              );
              final labelStyle = theme.typography
                  .selectionLabel(context, size, TypographyEmphasis.medium)
                  .copyWith(color: style.foreground);
              final descriptionStyle = theme.typography
                  .selectionSupporting(
                    context,
                    size,
                    TypographyEmphasis.regular,
                  )
                  .copyWith(color: style.supporting);
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: math.max(
                    theme.sizes.actionExtent(context, size),
                    math.max(
                      indicatorHeight,
                      context.units(theme.sizes.minimumTarget),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FocusRing(
                      visible:
                          states.contains(WidgetState.focused) &&
                          showFocusHighlight,
                      borderRadius: BorderRadius.circular(radius),
                      child: indicatorBuilder(
                        context,
                        style,
                        Size(indicatorWidth, indicatorHeight),
                      ),
                    ),
                    SizedBox(
                      width: context.units(
                        theme.spacing.selectionLabelGapFor(size),
                      ),
                    ),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(label, style: labelStyle),
                          if (description != null) ...[
                            SizedBox(
                              height: context.units(
                                theme.spacing.selectionSupportingGapFor(size),
                              ),
                            ),
                            Text(description!, style: descriptionStyle),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
