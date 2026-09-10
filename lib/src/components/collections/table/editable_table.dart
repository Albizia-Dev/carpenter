import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';

import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../../basic/text.dart';
import 'table_column.dart';

/// Builds one footer cell from all rows currently supplied to the editable
/// table. Calculate totals from items rather than maintaining a second
/// independent list.
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
  /// Presents caller-owned local rows and editable cell builders. It does not
  /// own draft values, persist changes, sort, or page data. Keep editor
  /// controllers outside cell builders and dispose them when rows are
  /// removed.
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
    this.freezeFirstColumn = false,
    this.semanticLabel = 'Editable table',
  });

  /// Rows displayed in list order and passed together to footer builders.
  /// Mutate application state and rebuild to reflect edits, insertion, or
  /// removal.
  final List<T> items;

  /// Keeps the first column visible while the remaining columns scroll.
  /// The same cell remains mounted, preserving focus and editor state.
  final bool freezeFirstColumn;

  /// Ordered column descriptors supplying headers, cell builders, horizontal
  /// alignment, and width policy. Use stable unique IDs to address footer
  /// cells.
  final List<CarpenterTableColumn<T>> columns;

  /// Actions placed above the header in an end-aligned wrapping row. The
  /// table does not implement add, import, or save operations itself.
  final List<Widget> headerActions;

  /// Footer builders keyed by column ID. Each receives the full items list.
  /// Columns without a matching builder get an empty footer cell; an empty
  /// map omits the entire footer.
  final Map<String, CarpenterTableFooterCellBuilder<T>> footerCells;

  /// Optional notification for a row tap. Selection is not stored; rebuild
  /// with an updated selected predicate to change highlighting.
  final ValueChanged<T>? onRowSelected;

  /// Optional notification for a row double tap. This is separate from row
  /// selection and does not automatically open an editor.
  final ValueChanged<T>? onRowActivated;

  /// Caller-owned predicate deciding whether each row is highlighted. Null
  /// means no rows are highlighted.
  final bool Function(T item)? selected;

  /// Minimum table content width, defaulting to 48 rem. A narrower viewport
  /// gets horizontal scrolling rather than compressed columns. The sum of fixed
  /// column widths, flexible minima and row insets also contributes to this floor.
  final LengthUnit minimumWidth;

  /// Text displayed instead of body rows when items is empty. Headers, header
  /// actions, and configured footer cells remain available.
  final String emptyMessage;

  /// Accessible name for the table container, defaulting to Editable table.
  final String semanticLabel;

  /// Composes headers, editable rows, and aligned footer cells using
  /// CarpenterTheme. Width constraints determine whether a horizontal scroll
  /// view is needed; vertical scrolling belongs to the parent.
  @override
  Widget build(BuildContext context) => _EditableTableScrollHost(
    builder: (context, controller) => _build(context, controller),
  );

  Widget _build(BuildContext context, ScrollController controller) {
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
          final columnsWidth = columns.fold<double>(0, (total, column) {
            final width =
                column.width.policy == CarpenterTableColumnWidthPolicy.fixed
                ? column.width.preferred
                : column.width.minimum;
            return total + context.units(width ?? theme.sizes.tableColumnMin);
          });
          final requiredWidth =
              columnsWidth +
              horizontal * 2 +
              math.max(0, columns.length - 1) *
                  context.units(theme.spacing.small);
          final contentWidth = math.max(
            viewportWidth,
            math.max(minWidth, requiredWidth),
          );

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
                    controller,
                    theme.surface.subtle,
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
                          controller,
                          selected?.call(item) == true
                              ? selectedBackground
                              : theme.surface.base,
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
                      controller,
                      theme.surface.subtle,
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
            controller: controller,
            scrollDirection: Axis.horizontal,
            child: table,
          );
        },
      ),
    );
  }

  Widget _row(
    BuildContext context,
    ScrollController controller,
    Color background,
    List<Widget> cells,
  ) {
    final gap = context.units(CarpenterTheme.of(context).spacing.small);
    return _PinnedTableRow(
      offset: freezeFirstColumn && controller.hasClients
          ? controller.offset
          : 0,
      direction: Directionality.of(context),
      background: background,
      inset: context.units(CarpenterTheme.of(context).spacing.tableHorizontal),
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

final class _EditableTableScrollHost extends StatefulWidget {
  const _EditableTableScrollHost({required this.builder});
  final Widget Function(BuildContext, ScrollController) builder;
  @override
  State<_EditableTableScrollHost> createState() =>
      _EditableTableScrollHostState();
}

final class _EditableTableScrollHostState
    extends State<_EditableTableScrollHost> {
  final controller = ScrollController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => widget.builder(context, controller),
  );
}

/// Paints the first flex child after its siblings, with a matching hit-test and
/// semantics transform. Layout still includes it exactly once.
final class _PinnedTableRow extends MultiChildRenderObjectWidget {
  const _PinnedTableRow({
    required this.offset,
    required this.direction,
    required this.background,
    required this.inset,
    required super.children,
  });
  final double offset;
  final TextDirection direction;
  final Color background;
  final double inset;
  @override
  _RenderPinnedTableRow createRenderObject(BuildContext context) =>
      _RenderPinnedTableRow(offset, direction, background, inset);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPinnedTableRow renderObject,
  ) {
    renderObject
      ..textDirection = direction
      ..pinOffset = offset
      ..background = background
      ..inset = inset;
  }
}

final class _RenderPinnedTableRow extends RenderFlex {
  _RenderPinnedTableRow(
    this._pinOffset,
    TextDirection direction,
    this._background,
    this._inset,
  ) : super(
        direction: Axis.horizontal,
        textDirection: direction,
        crossAxisAlignment: CrossAxisAlignment.center,
      );
  double _pinOffset;
  Color _background;
  double _inset;
  set inset(double value) {
    if (_inset == value) return;
    _inset = value;
    markNeedsPaint();
  }

  set pinOffset(double value) {
    if (_pinOffset == value) return;
    _pinOffset = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  set background(Color value) {
    if (_background == value) return;
    _background = value;
    markNeedsPaint();
  }

  Offset _offset(RenderBox child) =>
      (child.parentData! as FlexParentData).offset +
      (child == firstChild
          ? Offset(
              textDirection == TextDirection.rtl ? -_pinOffset : _pinOffset,
              0,
            )
          : Offset.zero);
  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild == null ? null : childAfter(firstChild!);
    while (child != null) {
      context.paintChild(child, offset + _offset(child));
      child = childAfter(child);
    }
    final first = firstChild;
    if (first != null) {
      final position = offset + _offset(first);
      context.canvas.drawRect(
        Rect.fromLTWH(
          position.dx - _inset,
          offset.dy,
          first.size.width + _inset * 2,
          size.height,
        ),
        Paint()..color = _background,
      );
      context.paintChild(first, position);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    bool hit(RenderBox child) => result.addWithPaintOffset(
      offset: _offset(child),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
    final first = firstChild;
    if (first != null) {
      if (hit(first)) return true;
      // The opaque pinned surface must also occlude pointer events below it.
      final pinnedBounds = Rect.fromLTWH(
        _offset(first).dx - _inset,
        0,
        first.size.width + _inset * 2,
        size.height,
      );
      if (pinnedBounds.contains(position)) return false;
    }
    var child = lastChild;
    while (child != null && child != firstChild) {
      if (hit(child)) return true;
      child = childBefore(child);
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final offset = _offset(child);
    transform.translateByDouble(offset.dx, offset.dy, 0, 1);
  }
}
