import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/text.dart';
import 'table_column.dart';

typedef CarpenterTableFooterCellBuilder<T> =
    Widget Function(BuildContext context, List<T> items);

/// Local-data table for editable business grids.
///
/// The regular Carpenter table is optimized for collection adapters, sorting,
/// paging and server-backed snapshots. This widget is intentionally small and
/// mutation-friendly. Cell builders may contain inputs, checkboxes, date fields
/// and row actions. Header actions cover add/import operations and [footerCells]
/// provides aligned totals or other per-column summaries.
final class CarpenterEditableTable<T> extends StatelessWidget {
  const CarpenterEditableTable({
    super.key,
    required this.items,
    required this.columns,
    this.headerActions = const [],
    this.footerCells = const {},
    this.onRowSelected,
    this.onRowActivated,
    this.selected,
    this.minimumWidth = const Rem(48),
    this.emptyMessage = 'No rows',
    this.semanticLabel = 'Editable table',
  });

  final List<T> items;
  final List<CarpenterTableColumn<T>> columns;
  final List<Widget> headerActions;
  final Map<String, CarpenterTableFooterCellBuilder<T>> footerCells;
  final ValueChanged<T>? onRowSelected;
  final ValueChanged<T>? onRowActivated;
  final bool Function(T item)? selected;
  final LengthUnit minimumWidth;
  final String emptyMessage;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final rowGap = context.units(theme.spacing.small);
    final horizontal = context.units(theme.spacing.tableHorizontal);
    final vertical = context.units(theme.spacing.tableVertical);
    final borderWidth = context.units(theme.shapes.tableBorderWidth);
    final selectedBackground = theme.selection
        .resolve(
          role: SelectionColorRole.primary,
          selected: true,
          states: const <WidgetState>{},
        )
        .background;

    return Semantics(
      container: true,
      label: semanticLabel,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minWidth = context.units(minimumWidth);
          final viewportWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : minWidth;
          final contentWidth = math.max(viewportWidth, minWidth);

          final table = SizedBox(
            width: contentWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (headerActions.isNotEmpty) ...[
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Wrap(
                      spacing: rowGap,
                      runSpacing: rowGap,
                      children: headerActions,
                    ),
                  ),
                  SizedBox(height: rowGap),
                ],
                Container(
                  color: theme.surface.subtle,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontal,
                    vertical: vertical,
                  ),
                  child: _row(
                    context,
                    columns
                        .map(
                          (column) => CarpenterText.label(
                            column.header,
                            emphasis: TypographyEmphasis.strong,
                            semanticsLabel: column.semanticLabel,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
                if (items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: vertical * 3),
                    child: Center(
                      child: CarpenterText.body(
                        emptyMessage,
                        colorRole: ContentColorRole.secondary,
                      ),
                    ),
                  )
                else
                  for (final item in items)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onRowSelected == null
                          ? null
                          : () => onRowSelected!(item),
                      onDoubleTap: onRowActivated == null
                          ? null
                          : () => onRowActivated!(item),
                      child: Container(
                        decoration: BoxDecoration(
                          color: selected?.call(item) == true
                              ? selectedBackground
                              : theme.surface.base,
                          border: Border(
                            bottom: BorderSide(
                              color: theme.overlay.border,
                              width: borderWidth,
                            ),
                          ),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontal,
                          vertical: vertical,
                        ),
                        child: _row(
                          context,
                          columns
                              .map(
                                (column) => column.cellBuilder(context, item),
                              )
                              .toList(growable: false),
                        ),
                      ),
                    ),
                if (footerCells.isNotEmpty)
                  Container(
                    color: theme.surface.subtle,
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontal,
                      vertical: vertical,
                    ),
                    child: _row(
                      context,
                      columns
                          .map(
                            (column) =>
                                footerCells[column.id]?.call(context, items) ??
                                const SizedBox.shrink(),
                          )
                          .toList(growable: false),
                    ),
                  ),
              ],
            ),
          );

          if (contentWidth <= viewportWidth) return table;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: table,
          );
        },
      ),
    );
  }

  Widget _row(BuildContext context, List<Widget> cells) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var index = 0; index < columns.length; index++) ...[
          if (index > 0) SizedBox(width: gap),
          _columnBox(context, columns[index], cells[index]),
        ],
      ],
    );
  }

  Widget _columnBox(
    BuildContext context,
    CarpenterTableColumn<T> column,
    Widget child,
  ) {
    final alignment = switch (column.alignment) {
      CarpenterTableColumnAlignment.start => AlignmentDirectional.centerStart,
      CarpenterTableColumnAlignment.center => AlignmentDirectional.center,
      CarpenterTableColumnAlignment.end => AlignmentDirectional.centerEnd,
    };
    final aligned = Align(alignment: alignment, child: child);
    if (column.width.policy == CarpenterTableColumnWidthPolicy.fixed) {
      final preferred = column.width.preferred;
      return SizedBox(
        width: preferred == null ? null : context.units(preferred),
        child: aligned,
      );
    }
    return Expanded(flex: column.width.flex, child: aligned);
  }
}
