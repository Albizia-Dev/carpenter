import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/text.dart';
import '../behaviour/action_strip.dart';

typedef CarpenterDefinitionTerm<T> = String Function(T item);
typedef CarpenterDefinitionValueBuilder<T> =
    Widget Function(BuildContext context, T item);

/// Resolves semantic actions for one definition-list item.
typedef CarpenterDefinitionActionsBuilder<T> =
    List<CarpenterActionDescriptor> Function(T item);

/// Responsive term/value presentation for structured object metadata.
///
/// The list deliberately provides no card chrome or row dividers so its owner
/// can place it inside any semantic page region without nested surfaces.
/// [actions] and [secondaryActions] describe optional row actions; primary
/// icon-bearing actions stay inline when space permits while secondary actions
/// use the shared adaptive overflow presentation. Icon action lanes reserve
/// only their control extent. Actions follow the intrinsic value width, while
/// long values and editors may use the available space without pushing actions out.
/// Wide layouts align terms to the longest label, capped at 40% of the row;
/// narrow layouts place each term above its value. Text actions follow below
/// the value on narrow layouts so their labels retain the available width.
final class CarpenterDefinitionList<T> extends StatelessWidget {
  /// Creates a chrome-free responsive definition list.
  const CarpenterDefinitionList({
    super.key,
    required this.items,
    required this.term,
    required this.valueBuilder,
    this.actions,
    this.secondaryActions,
    this.semanticLabel = 'Details',
    this.actionsSemanticLabel = 'Row actions',
    this.actionsOverflowLabel = 'More actions',
  });

  /// Structured values presented in source order.
  final List<T> items;

  /// Resolves the human-readable term for an item.
  final CarpenterDefinitionTerm<T> term;

  /// Builds the value presentation for an item.
  final CarpenterDefinitionValueBuilder<T> valueBuilder;

  /// Resolves primary actions that may remain inline beside an item's value.
  final CarpenterDefinitionActionsBuilder<T>? actions;

  /// Resolves lower-priority actions placed in the adaptive overflow menu.
  final CarpenterDefinitionActionsBuilder<T>? secondaryActions;

  /// Accessible name for the complete definition list.
  final String semanticLabel;

  /// Accessible name for each non-empty row action group.
  final String actionsSemanticLabel;

  /// Accessible and visible label for the row action overflow control.
  final String actionsOverflowLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact =
          const CarpenterViewportPolicy().resolve(
            context,
            constraints.maxWidth,
          ) ==
          CarpenterViewportClass.narrow;
      final theme = CarpenterTheme.of(context);
      var termWidth = 0.0;
      if (!compact) {
        for (final item in items) {
          final painter = TextPainter(
            text: TextSpan(
              text: term(item),
              style: theme.typography.resolve(
                context,
                TypographyRole.label,
                TypographyEmphasis.regular,
              ),
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout();
          termWidth = math.max(termWidth, painter.width.ceilToDouble());
          painter.dispose();
        }
        final inset = context.units(theme.spacing.medium);
        termWidth = math.min(
          termWidth,
          math.max(0, constraints.maxWidth - inset * 3) * 0.4,
        );
      }
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final item in items)
              _DefinitionRow<T>(
                item: item,
                term: term(item),
                valueBuilder: valueBuilder,
                actions: actions?.call(item) ?? const [],
                secondaryActions: secondaryActions?.call(item) ?? const [],
                compact: compact,
                termWidth: termWidth,
                actionsSemanticLabel: actionsSemanticLabel,
                actionsOverflowLabel: actionsOverflowLabel,
              ),
          ],
        ),
      );
    },
  );
}

final class _DefinitionRow<T> extends StatelessWidget {
  const _DefinitionRow({
    required this.item,
    required this.term,
    required this.valueBuilder,
    required this.actions,
    required this.secondaryActions,
    required this.compact,
    required this.termWidth,
    required this.actionsSemanticLabel,
    required this.actionsOverflowLabel,
  });

  final T item;
  final String term;
  final CarpenterDefinitionValueBuilder<T> valueBuilder;
  final List<CarpenterActionDescriptor> actions;
  final List<CarpenterActionDescriptor> secondaryActions;
  final bool compact;
  final double termWidth;
  final String actionsSemanticLabel;
  final String actionsOverflowLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final label = CarpenterText.label(
      term,
      colorRole: ContentColorRole.secondary,
    );
    final value = valueBuilder(context, item);
    final actionStrip = _buildActionStrip();
    return Semantics(
      container: true,
      label: term,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: context.units(theme.spacing.medium),
          vertical: context.units(theme.spacing.small),
        ),
        child: compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label,
                  SizedBox(height: context.units(theme.spacing.small)),
                  _ValueAndActions(
                    value: value,
                    actions: actionStrip,
                    primaryActions: actions,
                    secondaryActions: secondaryActions,
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(width: termWidth, child: label),
                  SizedBox(width: context.units(theme.spacing.medium)),
                  Expanded(
                    child: _ValueAndActions(
                      value: value,
                      actions: actionStrip,
                      primaryActions: actions,
                      secondaryActions: secondaryActions,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget? _buildActionStrip() {
    if (![...actions, ...secondaryActions].any((action) => action.visible)) {
      return null;
    }
    return CarpenterActionStrip(
      alignment: AlignmentDirectional.centerStart,
      items: [
        for (final action in actions)
          CarpenterActionStripItem(
            action: action,
            group: CarpenterActionStripGroup.primary,
            presentation: action.icon == null
                ? CarpenterActionStripPresentation.label
                : CarpenterActionStripPresentation.icon,
            size: ControlSize.xsmall,
          ),
        for (final action in secondaryActions)
          CarpenterActionStripItem(
            action: action,
            group: CarpenterActionStripGroup.overflow,
            size: ControlSize.xsmall,
          ),
      ],
      overflowLabel: actionsOverflowLabel,
      overflowSize: ControlSize.xsmall,
      semanticLabel: actionsSemanticLabel,
    );
  }
}

final class _ValueAndActions extends StatelessWidget {
  const _ValueAndActions({
    required this.value,
    required this.actions,
    required this.primaryActions,
    required this.secondaryActions,
  });

  final List<CarpenterActionDescriptor> primaryActions;
  final List<CarpenterActionDescriptor> secondaryActions;

  final Widget value;
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    final actionStrip = actions;
    if (actionStrip == null) return value;
    return LayoutBuilder(
      builder: (context, constraints) {
        final visible = primaryActions
            .where((action) => action.visible)
            .toList();
        final iconLane = visible.every((action) => action.icon != null);
        final compact =
            const CarpenterViewportPolicy().resolve(
              context,
              constraints.maxWidth,
            ) ==
            CarpenterViewportClass.narrow;
        if (!iconLane && compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              value,
              SizedBox(
                height: context.units(CarpenterTheme.of(context).spacing.small),
              ),
              actionStrip,
            ],
          );
        }
        final preferred = iconLane
            ? CarpenterActionStrip.compactExtent(
                context,
                inlineActions: visible.length,
                reserveOverflow: secondaryActions.any(
                  (action) => action.visible,
                ),
              )
            : constraints.maxWidth / 2;
        final extent = math.min(preferred, constraints.maxWidth / 2);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(fit: FlexFit.loose, child: value),
            SizedBox(
              width: context.units(
                CarpenterTheme.of(context).spacing.layoutToolbar,
              ),
            ),
            SizedBox(width: extent, child: actionStrip),
          ],
        );
      },
    );
  }
}
