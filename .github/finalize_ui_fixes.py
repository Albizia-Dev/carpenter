from pathlib import Path


def patch_suggestion_field() -> None:
    path = Path('lib/src/internal/selection/suggestion_field.dart')
    source = path.read_text()
    old = '''  @override
  void initState() {
    super.initState();
    _attachFocusNode();
    _syncOptions();
  }
'''
    new = '''  @override
  void initState() {
    super.initState();
    _attachFocusNode();
    _syncOptions();
    _syncSelectedQuery();
  }
'''
    if old not in source:
        raise SystemExit('suggestion initState block not found')
    source = source.replace(old, new, 1)

    old = '''    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode(oldWidget.focusNode);
      _attachFocusNode();
    }
    _syncOptions();
'''
    new = '''    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode(oldWidget.focusNode);
      _attachFocusNode();
    }
    final selectedChanged =
        oldWidget.selectedOptionId != widget.selectedOptionId;
    _syncOptions();
    if (selectedChanged) _syncSelectedQuery();
'''
    if old not in source:
        raise SystemExit('suggestion didUpdate block not found')
    source = source.replace(old, new, 1)

    marker = '''  CarpenterOption<T>? get _highlighted {
'''
    method = '''  void _syncSelectedQuery() {
    if (!widget.replaceQueryOnSelection) return;
    final selected = widget.selectedOptionId;
    if (selected == null) return;
    for (final option in widget.options) {
      if (option.id != selected) continue;
      if (widget.controller.text == option.label) return;
      widget.controller.value = TextEditingValue(
        text: option.label,
        selection: TextSelection.collapsed(offset: option.label.length),
      );
      return;
    }
  }

'''
    if marker not in source:
        raise SystemExit('suggestion highlighted marker not found')
    path.write_text(source.replace(marker, method + marker, 1))


def patch_theme_tests() -> None:
    path = Path('test/foundation/theme_test.dart')
    source = path.read_text()
    old = '''        final style = theme.actions.resolve(
          role,
          ActionProminence.high,
          const <WidgetState>{},
        );
        expect(
          contrast(style.background, style.foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'high-prominence ${role.name}',
        );
'''
    new = '''        final style = theme.actions.resolve(
          role,
          ActionProminence.filled,
          const <WidgetState>{},
        );
        expect(
          contrast(style.background, style.foreground),
          greaterThanOrEqualTo(4.5),
          reason: 'filled-prominence ${role.name}',
        );
'''
    if old not in source:
        raise SystemExit('semantic action contrast block not found')
    source = source.replace(old, new, 1)

    start = source.index("  test('action prominence preserves distinct background contracts', () {")
    end = source.index("\n  test('utility is a complete action color role'", start)
    replacement = '''  test('action prominence preserves distinct background contracts', () {
    final actions = CarpenterThemeData.light().actions;
    const rest = <WidgetState>{};
    const hovered = <WidgetState>{WidgetState.hovered};

    final low = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.low,
      rest,
    );
    final normal = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.normal,
      rest,
    );
    final high = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.high,
      rest,
    );
    final filled = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.filled,
      rest,
    );
    final ghost = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.ghost,
      rest,
    );
    final hoveredGhost = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.ghost,
      hovered,
    );
    final outlined = actions.resolve(
      ActionColorRole.primary,
      ActionProminence.outlined,
      rest,
    );

    expect(low.background, isNot(actions.transparent));
    expect(normal.background, isNot(low.background));
    expect(high.background, isNot(normal.background));
    expect(filled.background, isNot(high.background));
    expect(ghost.background, actions.transparent);
    expect(hoveredGhost.background, isNot(actions.transparent));
    expect(outlined.background, actions.transparent);
    expect(outlined.border, isNot(actions.transparent));
  });
'''
    path.write_text(source[:start] + replacement + source[end:])


def patch_autosuggest_test() -> None:
    path = Path('test/basic/autosuggest_test.dart')
    source = path.read_text()
    source = source.replace(
        "testWidgets('free query is preserved while suggestion can be selected', (",
        "testWidgets('free query stays editable and selection replaces query', (",
        1,
    )
    old = "    expect(controller.text, 'arbitrary');\n"
    if old not in source:
        raise SystemExit('autosuggest expectation not found')
    path.write_text(source.replace(old, "    expect(controller.text, 'Alpha');\n", 1))


def patch_combo_tests() -> None:
    path = Path('test/basic/combo_box_test.dart')
    source = path.read_text()
    old = '''    expect(selected, 1);
    expect(controller.text, 'Alpha');
    expect(queries.last, 'Alpha');
'''
    new = '''    expect(selected, 1);
    expect(controller.text, 'Alpha');
    expect(queries, ['Al']);
'''
    if old not in source:
        raise SystemExit('combo keyboard expectations not found')
    source = source.replace(old, new, 1)
    source = source.replace(
        "testWidgets('pointer selection updates value, query and closes menu', (",
        "testWidgets('pointer selection updates value and closes menu without query echo', (",
        1,
    )
    old = '''    expect(selected, 2);
    expect(controller.text, 'Bravo');
    expect(queries, ['Bravo']);
    expect(open, isFalse);
'''
    new = '''    expect(selected, 2);
    expect(controller.text, 'Bravo');
    expect(queries, isEmpty);
    expect(open, isFalse);
'''
    if old not in source:
        raise SystemExit('combo pointer expectations not found')
    path.write_text(source.replace(old, new, 1))


def patch_colors_catalog() -> None:
    path = Path('widgetbook/lib/use_cases/foundation/colors.dart')
    source = path.read_text()
    old = '''      _PaletteFamily('neutral', palette.neutral),
      _PaletteFamily('brand', palette.brand),
      _PaletteFamily('secondary', palette.secondary),
      _PaletteFamily('success', palette.success),
      _PaletteFamily('warning', palette.warning),
      _PaletteFamily('danger', palette.danger),
      _PaletteFamily('info', palette.info),
      _PaletteFamily('utility', palette.utility),
'''
    new = '''      _PaletteFamily('neutral', (weight) => palette.neutral[weight]),
      _PaletteFamily('brand', (weight) => palette.brand[weight]),
      _PaletteFamily('secondary', (weight) => palette.secondary[weight]),
      _PaletteFamily('success', (weight) => palette.success[weight]),
      _PaletteFamily('warning', (weight) => palette.warning[weight]),
      _PaletteFamily('danger', (weight) => palette.danger[weight]),
      _PaletteFamily('info', (weight) => palette.info[weight]),
      _PaletteFamily('utility', (weight) => palette.utility[weight]),
'''
    if old not in source:
        raise SystemExit('palette family list not found')
    source = source.replace(old, new, 1)
    old = '''final class _PaletteFamily {
  const _PaletteFamily(this.name, this.values);

  final String name;
  final dynamic values;
}
'''
    new = '''final class _PaletteFamily {
  const _PaletteFamily(this.name, this.colorAt);

  final String name;
  final Color Function(int weight) colorAt;
}
'''
    if old not in source:
        raise SystemExit('palette family class not found')
    source = source.replace(old, new, 1)
    old = '''                    family.values[weight] as Color,
                    _contrastFor(family.values[weight] as Color),
'''
    new = '''                    family.colorAt(weight),
                    _contrastFor(family.colorAt(weight)),
'''
    if old not in source:
        raise SystemExit('palette color lookup not found')
    path.write_text(source.replace(old, new, 1))


def patch_pagination_playground() -> None:
    path = Path('widgetbook/lib/use_cases/collections/migrated_collections.dart')
    source = path.read_text()
    source = source.replace(
        "  useCases: [WidgetbookUseCase(name: 'Playground', builder: _pagination)],",
        "  useCases: [\n    WidgetbookUseCase(name: 'Playground', builder: _pagination),\n    WidgetbookUseCase(name: 'Scenarios', builder: _paginationScenarios),\n  ],",
        1,
    )
    start = source.index('Widget _pagination(BuildContext context) {')
    end = source.index('\nWidget _inspector(BuildContext context) {', start)
    replacement = '''Widget _pagination(BuildContext context) {
  final totalPages = context.knobs.double
      .slider(
        label: 'Data · Total pages',
        initialValue: 37,
        min: 1,
        max: 500,
        divisions: 499,
      )
      .round();
  final initialPage = context.knobs.double
      .slider(
        label: 'Data · Initial page',
        initialValue: 18,
        min: 1,
        max: 500,
        divisions: 499,
      )
      .round();
  final siblingCount = context.knobs.int.slider(
    label: 'Navigation · Sibling pages',
    initialValue: 1,
    min: 0,
    max: 4,
  );
  final leading = context.knobs.stringOrNull(
    label: 'Content · Leading text',
    initialValue: '1–50 of 1,842 records',
    defaultToNull: false,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 820,
    min: 260,
    max: 1200,
    divisions: 47,
  );
  return _PaginationPreview(
    initialPage: initialPage,
    totalPages: totalPages,
    siblingCount: siblingCount,
    leading: leading,
    width: width,
  );
}

Widget _paginationScenarios(BuildContext context) => previewColumn([
  const _PaginationPreview(
    initialPage: 1,
    totalPages: 3,
    siblingCount: 1,
    leading: 'Small result set',
    width: 720,
  ),
  const _PaginationPreview(
    initialPage: 18,
    totalPages: 37,
    siblingCount: 1,
    leading: '1–50 of 1,842 records',
    width: 900,
  ),
  const _PaginationPreview(
    initialPage: 243,
    totalPages: 500,
    siblingCount: 2,
    leading: 'Large data set',
    width: 1100,
  ),
  const _PaginationPreview(
    initialPage: 18,
    totalPages: 37,
    siblingCount: 1,
    leading: null,
    width: 360,
  ),
]);

final class _PaginationPreview extends StatefulWidget {
  const _PaginationPreview({
    required this.initialPage,
    required this.totalPages,
    required this.siblingCount,
    required this.leading,
    required this.width,
  });

  final int initialPage;
  final int totalPages;
  final int siblingCount;
  final String? leading;
  final double width;

  @override
  State<_PaginationPreview> createState() => _PaginationPreviewState();
}

final class _PaginationPreviewState extends State<_PaginationPreview> {
  late int _page = _normalized(widget.initialPage);

  int _normalized(int value) {
    if (value < 1) return 1;
    if (value > widget.totalPages) return widget.totalPages;
    return value;
  }

  @override
  void didUpdateWidget(_PaginationPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPage != widget.initialPage) {
      _page = _normalized(widget.initialPage);
    } else if (_page > widget.totalPages) {
      _page = widget.totalPages;
    }
  }

  @override
  Widget build(BuildContext context) => preview(
    SizedBox(
      width: widget.width,
      child: CarpenterPaginationBar(
        page: _page,
        totalPages: widget.totalPages,
        siblingCount: widget.siblingCount,
        leading: widget.leading == null
            ? null
            : CarpenterText.caption(widget.leading!),
        onPageChanged: (page) => setState(() => _page = page),
      ),
    ),
  );
}
'''
    path.write_text(source[:start] + replacement + source[end:])


patch_suggestion_field()
patch_theme_tests()
patch_autosuggest_test()
patch_combo_tests()
patch_colors_catalog()
patch_pagination_playground()
