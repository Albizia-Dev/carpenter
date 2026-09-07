import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/adaptive.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/text.dart';

typedef CarpenterDefinitionTerm<T> = String Function(T item);
typedef CarpenterDefinitionValueBuilder<T> = Widget Function(
  BuildContext context,
  T item,
);

/// Responsive term/value presentation for structured object metadata.
final class CarpenterDefinitionList<T> extends StatelessWidget {
  const CarpenterDefinitionList({
    super.key,
    required this.items,
    required this.term,
    required this.valueBuilder,
    this.semanticLabel = 'Details',
  });

  final List<T> items;
  final CarpenterDefinitionTerm<T> term;
  final CarpenterDefinitionValueBuilder<T> valueBuilder;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final theme = CarpenterTheme.of(context);
      final compact =
          const CarpenterViewportPolicy().resolve(
            context,
            constraints.maxWidth,
          ) ==
          CarpenterViewportClass.narrow;
      final radius = context.units(theme.shapes.radius(ShapeRole.rounded));
      return Semantics(
        container: true,
        explicitChildNodes: true,
        label: semanticLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.surface.subtle,
            border: Border.all(
              color: theme.overlay.border,
              width: context.units(theme.shapes.borderWidth),
            ),
            borderRadius: BorderRadius.circular(radius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < items.length; index++)
                  _DefinitionRow<T>(
                    item: items[index],
                    term: term(items[index]),
                    valueBuilder: valueBuilder,
                    compact: compact,
                    showBorder: index < items.length - 1,
                  ),
              ],
            ),
          ),
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
    required this.compact,
    required this.showBorder,
  });

  final T item;
  final String term;
  final CarpenterDefinitionValueBuilder<T> valueBuilder;
  final bool compact;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final label = CarpenterText.label(
      term,
      colorRole: ContentColorRole.secondary,
    );
    final value = valueBuilder(context, item);
    return Semantics(
      container: true,
      label: term,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: showBorder
              ? Border(
                  bottom: BorderSide(
                    color: theme.overlay.border,
                    width: context.units(theme.shapes.borderWidth),
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.all(context.units(theme.spacing.medium)),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    SizedBox(height: context.units(theme.spacing.small)),
                    value,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: label),
                    SizedBox(width: context.units(theme.spacing.medium)),
                    Expanded(flex: 3, child: value),
                  ],
                ),
        ),
      ),
    );
  }
}
