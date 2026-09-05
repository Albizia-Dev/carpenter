from pathlib import Path


def replace_once(path: str, old: str, new: str) -> None:
    target = Path(path)
    text = target.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{path}: expected one match, got {count}: {old!r}")
    target.write_text(text.replace(old, new))


components = "lib/src/foundation/tokens/components.mordant.part.yaml"
replace_once(
    components,
    '''    gap:\n      xsmall: "${spacing.control.gap}"\n      small: "${spacing.control.gap}"\n      medium: "${spacing.control.gap}"\n      large: "${spacing.control.gap}"\n      xlarge: "${spacing.control.gap}"\n''',
    '''    gap:\n      xsmall: "${spacing.control.gap}"\n      small: "${spacing.control.gap}"\n      medium: "${spacing.control.gap}"\n      large: "${spacing.control.gap}"\n      xlarge: "${spacing.control.gap}"\n\n    compactGap:\n      xsmall: "${spacing.control.compactGap}"\n      small: "${spacing.control.compactGap}"\n      medium: "${spacing.control.compactGap}"\n      large: "${spacing.control.compactGap}"\n      xlarge: "${spacing.control.compactGap}"\n''',
)
replace_once(
    components,
    '''  field:\n    height:\n      xsmall: "${component.action.height.xsmall}"\n      small: "${component.action.height.small}"\n      medium: "${component.action.height.medium}"\n      large: "${component.action.height.large}"\n      xlarge: "${component.action.height.xlarge}"\n\n    horizontalPadding:\n      xsmall: "${spacing.control.horizontalXsmall}"\n      small: "${spacing.control.horizontalSmall}"\n      medium: "${spacing.control.horizontalMedium}"\n      large: "${spacing.control.horizontalLarge}"\n      xlarge: "${spacing.control.horizontalXlarge}"\n''',
    '''  field:\n    height:\n      xsmall: "${component.action.height.xsmall}"\n      small: "${component.action.height.small}"\n      medium: "${component.action.height.medium}"\n      large: "${component.action.height.large}"\n      xlarge: "${component.action.height.xlarge}"\n\n    horizontalPadding:\n      xsmall: "${spacing.control.horizontalXsmall}"\n      small: "${spacing.control.horizontalSmall}"\n      medium: "${spacing.control.horizontalMedium}"\n      large: "${spacing.control.horizontalLarge}"\n      xlarge: "${spacing.control.horizontalXlarge}"\n\n    compactHorizontalPadding:\n      xsmall: "${spacing.control.compactHorizontalXsmall}"\n      small: "${spacing.control.compactHorizontalSmall}"\n      medium: "${spacing.control.compactHorizontalMedium}"\n      large: "${spacing.control.compactHorizontalLarge}"\n      xlarge: "${spacing.control.compactHorizontalXlarge}"\n''',
)
replace_once(
    components,
    '''    verticalPadding:\n      xsmall: "${component.action.verticalPadding.xsmall}"\n      small: "${component.action.verticalPadding.small}"\n      medium: "${component.action.verticalPadding.medium}"\n      large: "${component.action.verticalPadding.large}"\n      xlarge: "${component.action.verticalPadding.xlarge}"\n''',
    '''    verticalPadding:\n      xsmall: "${component.action.verticalPadding.xsmall}"\n      small: "${component.action.verticalPadding.small}"\n      medium: "${component.action.verticalPadding.medium}"\n      large: "${component.action.verticalPadding.large}"\n      xlarge: "${component.action.verticalPadding.xlarge}"\n\n    compactVerticalPadding:\n      xsmall: "${spacing.field.compactVerticalXsmall}"\n      small: "${spacing.field.compactVerticalSmall}"\n      medium: "${spacing.field.compactVerticalMedium}"\n      large: "${spacing.field.compactVerticalLarge}"\n      xlarge: "${spacing.field.compactVerticalXlarge}"\n''',
)
for name, source in [
    ("contentGap", "compactContentGap"),
    ("labelGap", "compactLabelGap"),
    ("supportingGap", "compactSupportingGap"),
    ("scrollPadding", "compactScrollPadding"),
]:
    token = "${spacing.field." + name + "}"
    compact_token = "${spacing.field." + source + "}"
    old = (
        f"    {name}:\n"
        + "".join(f'      {size}: "{token}"\n' for size in ["xsmall", "small", "medium", "large", "xlarge"])
    )
    compact_name = "compact" + name[0].upper() + name[1:]
    new = old + "\n" + f"    {compact_name}:\n" + "".join(
        f'      {size}: "{compact_token}"\n' for size in ["xsmall", "small", "medium", "large", "xlarge"]
    )
    replace_once(components, old, new)

for name, source in [
    ("labelGap", "compactLabelGap"),
    ("supportingGap", "compactSupportingGap"),
]:
    token = "${spacing.selection." + name + "}"
    compact_token = "${spacing.selection." + source + "}"
    old = (
        f"    {name}:\n"
        + "".join(f'      {size}: "{token}"\n' for size in ["xsmall", "small", "medium", "large", "xlarge"])
    )
    compact_name = "compact" + name[0].upper() + name[1:]
    new = old + "\n" + f"    {compact_name}:\n" + "".join(
        f'      {size}: "{compact_token}"\n' for size in ["xsmall", "small", "medium", "large", "xlarge"]
    )
    replace_once(components, old, new)

replace_once(
    components,
    '''  status:\n    horizontalPadding: "${spacing.status.horizontal}"\n    verticalPadding: "${spacing.status.vertical}"\n''',
    '''  status:\n    horizontalPadding: "${spacing.status.horizontal}"\n    verticalPadding: "${spacing.status.vertical}"\n    compactHorizontalPadding: "${spacing.status.compactHorizontal}"\n    compactVerticalPadding: "${spacing.status.compactVertical}"\n''',
)
replace_once(
    components,
    '''    itemHorizontalPadding: "${spacing.overlay.menuItemHorizontal}"\n    itemVerticalPadding: "${spacing.overlay.menuItemVertical}"\n    itemGap: "${spacing.overlay.menuItemGap}"\n''',
    '''    itemHorizontalPadding: "${spacing.overlay.menuItemHorizontal}"\n    itemVerticalPadding: "${spacing.overlay.menuItemVertical}"\n    itemGap: "${spacing.overlay.menuItemGap}"\n    compactItemHorizontalPadding: "${spacing.overlay.compactMenuItemHorizontal}"\n    compactItemVerticalPadding: "${spacing.overlay.compactMenuItemVertical}"\n    compactItemGap: "${spacing.overlay.compactMenuItemGap}"\n''',
)
replace_once(
    components,
    '''    horizontalPadding: "${spacing.table.horizontal}"\n    verticalPadding: "${spacing.table.vertical}"\n    cellGap: "${spacing.table.cellGap}"\n    stateGap: "${spacing.table.stateGap}"\n''',
    '''    horizontalPadding: "${spacing.table.horizontal}"\n    verticalPadding: "${spacing.table.vertical}"\n    cellGap: "${spacing.table.cellGap}"\n    stateGap: "${spacing.table.stateGap}"\n    compactHorizontalPadding: "${spacing.table.compactHorizontal}"\n    compactVerticalPadding: "${spacing.table.compactVertical}"\n    compactCellGap: "${spacing.table.compactCellGap}"\n    compactStateGap: "${spacing.table.compactStateGap}"\n''',
)

theme = "lib/src/foundation/theme.dart"
replace_once(
    theme,
    '''  LengthUnit actionGap(ControlSize value) => switch (value) {\n    ControlSize.xsmall => tokens.component.action.gap.xsmall,\n    ControlSize.small => tokens.component.action.gap.small,\n    ControlSize.medium => tokens.component.action.gap.medium,\n    ControlSize.large => tokens.component.action.gap.large,\n    ControlSize.xlarge => tokens.component.action.gap.xlarge,\n  };\n''',
    '''  LengthUnit actionGap(ControlSize value) => switch ((density, value)) {\n    (CarpenterDensity.normal, ControlSize.xsmall) => tokens.component.action.gap.xsmall,\n    (CarpenterDensity.normal, ControlSize.small) => tokens.component.action.gap.small,\n    (CarpenterDensity.normal, ControlSize.medium) => tokens.component.action.gap.medium,\n    (CarpenterDensity.normal, ControlSize.large) => tokens.component.action.gap.large,\n    (CarpenterDensity.normal, ControlSize.xlarge) => tokens.component.action.gap.xlarge,\n    (CarpenterDensity.compact, ControlSize.xsmall) => tokens.component.action.compactGap.xsmall,\n    (CarpenterDensity.compact, ControlSize.small) => tokens.component.action.compactGap.small,\n    (CarpenterDensity.compact, ControlSize.medium) => tokens.component.action.compactGap.medium,\n    (CarpenterDensity.compact, ControlSize.large) => tokens.component.action.compactGap.large,\n    (CarpenterDensity.compact, ControlSize.xlarge) => tokens.component.action.compactGap.xlarge,\n  };\n''',
)
replace_once(
    theme,
    '''  LengthUnit get statusHorizontal => tokens.component.status.horizontalPadding;\n  LengthUnit get statusVertical => tokens.component.status.verticalPadding;\n''',
    '''  LengthUnit get statusHorizontal => density == CarpenterDensity.compact\n      ? tokens.component.status.compactHorizontalPadding\n      : tokens.component.status.horizontalPadding;\n  LengthUnit get statusVertical => density == CarpenterDensity.compact\n      ? tokens.component.status.compactVerticalPadding\n      : tokens.component.status.verticalPadding;\n''',
)
replace_once(
    theme,
    '''  LengthUnit get selectionGroupGap => tokens.spacing.selection.groupGap;\n''',
    '''  LengthUnit get selectionGroupGap => density == CarpenterDensity.compact\n      ? tokens.spacing.selection.compactGroupGap\n      : tokens.spacing.selection.groupGap;\n''',
)
replace_once(
    theme,
    '''  LengthUnit get overlayMenuItemHorizontal =>\n      tokens.component.menu.itemHorizontalPadding;\n  LengthUnit get overlayMenuItemVertical =>\n      tokens.component.menu.itemVerticalPadding;\n  LengthUnit get overlayMenuItemGap => tokens.component.menu.itemGap;\n''',
    '''  LengthUnit get overlayMenuItemHorizontal => density == CarpenterDensity.compact\n      ? tokens.component.menu.compactItemHorizontalPadding\n      : tokens.component.menu.itemHorizontalPadding;\n  LengthUnit get overlayMenuItemVertical => density == CarpenterDensity.compact\n      ? tokens.component.menu.compactItemVerticalPadding\n      : tokens.component.menu.itemVerticalPadding;\n  LengthUnit get overlayMenuItemGap => density == CarpenterDensity.compact\n      ? tokens.component.menu.compactItemGap\n      : tokens.component.menu.itemGap;\n''',
)
replace_once(
    theme,
    '''  LengthUnit get tableHorizontal => tokens.component.table.horizontalPadding;\n  LengthUnit get tableVertical => tokens.component.table.verticalPadding;\n  LengthUnit get tableCellGap => tokens.component.table.cellGap;\n  LengthUnit get tableStateGap => tokens.component.table.stateGap;\n''',
    '''  LengthUnit get tableHorizontal => density == CarpenterDensity.compact\n      ? tokens.component.table.compactHorizontalPadding\n      : tokens.component.table.horizontalPadding;\n  LengthUnit get tableVertical => density == CarpenterDensity.compact\n      ? tokens.component.table.compactVerticalPadding\n      : tokens.component.table.verticalPadding;\n  LengthUnit get tableCellGap => density == CarpenterDensity.compact\n      ? tokens.component.table.compactCellGap\n      : tokens.component.table.cellGap;\n  LengthUnit get tableStateGap => density == CarpenterDensity.compact\n      ? tokens.component.table.compactStateGap\n      : tokens.component.table.stateGap;\n''',
)
replace_once(
    theme,
    '''  LengthUnit get layoutToolbar => tokens.spacing.layout.toolbar;\n''',
    '''  LengthUnit get layoutToolbar => density == CarpenterDensity.compact\n      ? tokens.spacing.layout.compactToolbar\n      : tokens.spacing.layout.toolbar;\n''',
)

field_names = ["xsmall", "small", "medium", "large", "xlarge"]
for method, normal, compact in [
    ("fieldHorizontal", "horizontalPadding", "compactHorizontalPadding"),
    ("fieldVertical", "verticalPadding", "compactVerticalPadding"),
    ("fieldContentGapFor", "contentGap", "compactContentGap"),
    ("fieldLabelGapFor", "labelGap", "compactLabelGap"),
    ("fieldSupportingGapFor", "supportingGap", "compactSupportingGap"),
    ("fieldScrollPaddingFor", "scrollPadding", "compactScrollPadding"),
]:
    old = f"  LengthUnit {method}(FieldSize value) => switch (value) {{\n" + "".join(
        f"    FieldSize.{name} => tokens.component.field.{normal}.{name},\n" for name in field_names
    ) + "  };\n"
    new = f"  LengthUnit {method}(FieldSize value) => switch ((density, value)) {{\n" + "".join(
        f"    (CarpenterDensity.normal, FieldSize.{name}) => tokens.component.field.{normal}.{name},\n" for name in field_names
    ) + "".join(
        f"    (CarpenterDensity.compact, FieldSize.{name}) => tokens.component.field.{compact}.{name},\n" for name in field_names
    ) + "  };\n"
    replace_once(theme, old, new)

control_names = ["xsmall", "small", "medium", "large", "xlarge"]
for method, normal, compact in [
    ("selectionLabelGapFor", "labelGap", "compactLabelGap"),
    ("selectionSupportingGapFor", "supportingGap", "compactSupportingGap"),
]:
    old = f"  LengthUnit {method}(ControlSize value) => switch (value) {{\n" + "".join(
        f"    ControlSize.{name} => tokens.component.selection.{normal}.{name},\n" for name in control_names
    ) + "  };\n"
    new = f"  LengthUnit {method}(ControlSize value) => switch ((density, value)) {{\n" + "".join(
        f"    (CarpenterDensity.normal, ControlSize.{name}) => tokens.component.selection.{normal}.{name},\n" for name in control_names
    ) + "".join(
        f"    (CarpenterDensity.compact, ControlSize.{name}) => tokens.component.selection.{compact}.{name},\n" for name in control_names
    ) + "  };\n"
    replace_once(theme, old, new)

tests = "test/foundation/theme_test.dart"
replace_once(
    tests,
    '''  test('compact density reduces semantic control padding', () {\n    final normal = CarpenterThemeData.light();\n    final compact = CarpenterThemeData.light(density: CarpenterDensity.compact);\n    expect(\n      compact.spacing.controlHorizontal(ControlSize.medium).value,\n      lessThan(normal.spacing.controlHorizontal(ControlSize.medium).value),\n    );\n  });\n''',
    '''  test('compact density reduces spacing across component families', () {\n    final normal = CarpenterThemeData.light();\n    final compact = CarpenterThemeData.light(density: CarpenterDensity.compact);\n\n    expect(compact.spacing.controlHorizontal(ControlSize.medium).value, lessThan(normal.spacing.controlHorizontal(ControlSize.medium).value));\n    expect(compact.spacing.actionGap(ControlSize.medium).value, lessThan(normal.spacing.actionGap(ControlSize.medium).value));\n    expect(compact.spacing.fieldHorizontal(FieldSize.medium).value, lessThan(normal.spacing.fieldHorizontal(FieldSize.medium).value));\n    expect(compact.spacing.fieldVertical(FieldSize.medium).value, lessThan(normal.spacing.fieldVertical(FieldSize.medium).value));\n    expect(compact.spacing.fieldContentGapFor(FieldSize.medium).value, lessThan(normal.spacing.fieldContentGapFor(FieldSize.medium).value));\n    expect(compact.spacing.selectionLabelGapFor(ControlSize.medium).value, lessThan(normal.spacing.selectionLabelGapFor(ControlSize.medium).value));\n    expect(compact.spacing.selectionGroupGap.value, lessThan(normal.spacing.selectionGroupGap.value));\n    expect(compact.spacing.statusHorizontal.value, lessThan(normal.spacing.statusHorizontal.value));\n    expect(compact.spacing.overlayMenuItemHorizontal.value, lessThan(normal.spacing.overlayMenuItemHorizontal.value));\n    expect(compact.spacing.overlayMenuItemVertical.value, lessThan(normal.spacing.overlayMenuItemVertical.value));\n    expect(compact.spacing.tableHorizontal.value, lessThan(normal.spacing.tableHorizontal.value));\n    expect(compact.spacing.tableVertical.value, lessThan(normal.spacing.tableVertical.value));\n    expect(compact.spacing.layoutToolbar.value, lessThan(normal.spacing.layoutToolbar.value));\n\n    expect(compact.sizes.control(ControlSize.medium), normal.sizes.control(ControlSize.medium));\n    expect(compact.sizes.minimumTarget, normal.sizes.minimumTarget);\n  });\n''',
)
