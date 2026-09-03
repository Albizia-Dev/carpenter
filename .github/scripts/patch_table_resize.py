from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    file = Path(path)
    text = file.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f'{path}: expected one match, got {count}')
    file.write_text(text.replace(old, new, 1))


table = 'lib/src/components/collections/table/table.dart'
replace_once(
    table,
    '''      final explicitWidth =
          _localColumnWidths[column.id] ??
          widget.columnWidths[column.id] ??
          column.width.preferred;
''',
    '''      final isPinned =
          _localColumnWidths.containsKey(column.id) ||
          widget.columnWidths.containsKey(column.id);
      final explicitWidth =
          _localColumnWidths[column.id] ??
          widget.columnWidths[column.id] ??
          column.width.preferred;
''',
)
replace_once(
    table,
    '''      if (!column.isActionColumn &&
          column.width.policy == CarpenterTableColumnWidthPolicy.flexible) {
        totalFlex += column.width.flex;
      }
''',
    '''      if (!isPinned &&
          !column.isActionColumn &&
          column.width.policy == CarpenterTableColumnWidthPolicy.flexible) {
        totalFlex += column.width.flex;
      }
''',
)
replace_once(
    table,
    '''      for (final column in widget.columns) {
        if (column.isActionColumn ||
            column.width.policy != CarpenterTableColumnWidthPolicy.flexible) {
          continue;
        }
''',
    '''      for (final column in widget.columns) {
        final isPinned =
            _localColumnWidths.containsKey(column.id) ||
            widget.columnWidths.containsKey(column.id);
        if (isPinned ||
            column.isActionColumn ||
            column.width.policy != CarpenterTableColumnWidthPolicy.flexible) {
          continue;
        }
''',
)
replace_once(
    table,
    '''final class _ResizeHandleState extends State<_ResizeHandle> {
  late double _dragWidth;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragWidth = widget.currentWidth,
      onHorizontalDragUpdate: (details) {
        final logicalDelta = Directionality.of(context) == TextDirection.rtl
            ? -details.delta.dx
            : details.delta.dx;
        _dragWidth = (_dragWidth + logicalDelta).clamp(
          widget.minimumWidth,
          widget.maximumWidth,
        );
        widget.onChanged(_dragWidth);
      },
      child: SizedBox(width: widget.width, height: double.infinity),
    ),
  );
}
''',
    '''final class _ResizeHandleState extends State<_ResizeHandle> {
  late double _dragWidth;
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final active = _hovered || _dragging;
    final strokeWidth = active
        ? context.units(theme.focus.width)
        : context.units(theme.shapes.tableBorderWidth);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragWidth = widget.currentWidth;
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (details) {
          final logicalDelta = Directionality.of(context) == TextDirection.rtl
              ? -details.delta.dx
              : details.delta.dx;
          _dragWidth = (_dragWidth + logicalDelta).clamp(
            widget.minimumWidth,
            widget.maximumWidth,
          );
          widget.onChanged(_dragWidth);
        },
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.width,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: strokeWidth,
              height: double.infinity,
              child: ColoredBox(
                color: active ? theme.focus.color : theme.overlay.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''',
)

tree = 'lib/src/components/collections/tree/tree_table.dart'
replace_once(
    tree,
    '''      final explicit =
          _localColumnWidths[spec.id] ??
          widget.columnWidths[spec.id] ??
          spec.width.preferred;
''',
    '''      final isPinned =
          _localColumnWidths.containsKey(spec.id) ||
          widget.columnWidths.containsKey(spec.id);
      final explicit =
          _localColumnWidths[spec.id] ??
          widget.columnWidths[spec.id] ??
          spec.width.preferred;
''',
)
replace_once(
    tree,
    '''      if (spec.width.policy == CarpenterTableColumnWidthPolicy.flexible) {
        totalFlex += spec.width.flex;
      }
''',
    '''      if (!isPinned &&
          spec.width.policy == CarpenterTableColumnWidthPolicy.flexible) {
        totalFlex += spec.width.flex;
      }
''',
)
replace_once(
    tree,
    '''      for (final spec in specs) {
        if (spec.width.policy != CarpenterTableColumnWidthPolicy.flexible) {
          continue;
        }
''',
    '''      for (final spec in specs) {
        final isPinned =
            _localColumnWidths.containsKey(spec.id) ||
            widget.columnWidths.containsKey(spec.id);
        if (isPinned ||
            spec.width.policy != CarpenterTableColumnWidthPolicy.flexible) {
          continue;
        }
''',
)
replace_once(
    tree,
    '''final class _TreeResizeHandleState extends State<_TreeResizeHandle> {
  late double _dragWidth;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragWidth = widget.currentWidth,
      onHorizontalDragUpdate: (details) {
        final logicalDelta = Directionality.of(context) == TextDirection.rtl
            ? -details.delta.dx
            : details.delta.dx;
        _dragWidth = (_dragWidth + logicalDelta).clamp(
          widget.minimumWidth,
          widget.maximumWidth,
        );
        widget.onChanged(_dragWidth);
      },
      child: SizedBox(width: widget.width, height: double.infinity),
    ),
  );
}
''',
    '''final class _TreeResizeHandleState extends State<_TreeResizeHandle> {
  late double _dragWidth;
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final active = _hovered || _dragging;
    final strokeWidth = active
        ? context.units(theme.focus.width)
        : context.units(theme.shapes.tableBorderWidth);
    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) {
          _dragWidth = widget.currentWidth;
          setState(() => _dragging = true);
        },
        onHorizontalDragUpdate: (details) {
          final logicalDelta = Directionality.of(context) == TextDirection.rtl
              ? -details.delta.dx
              : details.delta.dx;
          _dragWidth = (_dragWidth + logicalDelta).clamp(
            widget.minimumWidth,
            widget.maximumWidth,
          );
          widget.onChanged(_dragWidth);
        },
        onHorizontalDragEnd: (_) => setState(() => _dragging = false),
        onHorizontalDragCancel: () => setState(() => _dragging = false),
        child: SizedBox(
          width: widget.width,
          height: double.infinity,
          child: Center(
            child: SizedBox(
              width: strokeWidth,
              height: double.infinity,
              child: ColoredBox(
                color: active ? theme.focus.color : theme.overlay.border,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''',
)
