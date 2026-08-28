import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/curated_icons.dart';
import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final iconButtonComponent = WidgetbookComponent(
  name: 'Icon Button',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Color roles', builder: _colorRoles),
    WidgetbookUseCase(name: 'Shape matrix', builder: _shapeMatrix),
    WidgetbookUseCase(name: 'States', builder: _states),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
  ],
);

Widget _sizeComparison(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final size in ControlSize.values)
            CarpenterIconButton(
              icon: Icons.add,
              semanticLabel: '${semanticValueLabel(size)} add action',
              size: size,
              colorRole: ActionColorRole.primary,
              onPressed: _noop,
            ),
        ],
      );
    },
  ),
);

Widget _colorRoles(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final role in ActionColorRole.values)
            CarpenterIconButton(
              icon: Icons.add,
              semanticLabel: '${semanticValueLabel(role)} add action',
              colorRole: role,
              prominence: ActionProminence.filled,
              onPressed: _noop,
            ),
        ],
      );
    },
  ),
);

Widget _shapeMatrix(BuildContext context) => preview(
  Wrap(
    spacing: context.units(1.rem),
    runSpacing: context.units(1.rem),
    children: [
      for (final start in ShapeRole.values)
        for (final end in ShapeRole.values)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CarpenterIconButton(
                icon: Icons.add,
                semanticLabel: '${start.name} to ${end.name}',
                shape: CarpenterShape(start: start, end: end),
                prominence: ActionProminence.high,
                colorRole: ActionColorRole.primary,
                onPressed: _noop,
              ),
              SizedBox(height: context.units(.25.rem)),
              CarpenterText.caption('${start.name} → ${end.name}'),
            ],
          ),
    ],
  ),
);

Widget _playground(BuildContext context) {
  final icon = context.knobs.object.dropdown(
    label: 'Content · Icon',
    options: curatedIcons,
    initialOption: curatedIcons.first,
    labelBuilder: (option) => option.label,
  );
  final semanticLabel = context.knobs.string(
    label: 'Accessibility · Semantic label',
    initialValue: 'Добавить',
  );
  final role = context.knobs.object.segmented(
    label: 'Appearance · Role',
    options: ActionColorRole.values,
    labelBuilder: semanticValueLabel,
  );
  final prominence = context.knobs.object.segmented(
    label: 'Appearance · Prominence',
    options: ActionProminence.values,
    initialOption: ActionProminence.normal,
    labelBuilder: semanticValueLabel,
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: ControlSize.values,
    labelBuilder: semanticValueLabel,
  );
  final startShape = context.knobs.object.segmented(
    label: 'Appearance · Start shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.rounded,
    labelBuilder: semanticValueLabel,
  );
  final endShape = context.knobs.object.segmented(
    label: 'Appearance · End shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.rounded,
    labelBuilder: semanticValueLabel,
  );
  final execution = context.knobs.object.segmented(
    label: 'State · Execution',
    options: ActionExecutionPhase.values,
    labelBuilder: semanticValueLabel,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );

  return preview(
    CarpenterIconButton(
      icon: icon.data,
      semanticLabel: semanticLabel,
      colorRole: role,
      prominence: prominence,
      size: size,
      shape: CarpenterShape(start: startShape, end: endShape),
      executionPhase: execution,
      onPressed: enabled ? _noop : null,
    ),
  );
}

Widget _states(BuildContext context) => previewColumn([
  const CarpenterIconButton(
    icon: Icons.add,
    semanticLabel: 'Enabled add',
    onPressed: _noop,
  ),
  const CarpenterIconButton(
    icon: Icons.delete,
    semanticLabel: 'Disabled delete',
  ),
  const CarpenterIconButton(
    icon: Icons.sync,
    semanticLabel: 'Synchronizing',
    executionPhase: ActionExecutionPhase.running,
  ),
]);

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterIconButton(
    icon: Icons.delete,
    semanticLabel: 'Удалить договор',
    autofocus: true,
    colorRole: ActionColorRole.danger,
    onPressed: _noop,
  ),
  const CarpenterText.body(
    'The visible glyph never replaces the required semantic label.',
  ),
]);

void _noop() {}
