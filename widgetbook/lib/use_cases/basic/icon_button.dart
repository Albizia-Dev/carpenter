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
              onInvoke: _noop,
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
              prominence: ActionProminence.high,
              onInvoke: _noop,
            ),
        ],
      );
    },
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
    initialOption: ShapeRole.circular,
    labelBuilder: semanticValueLabel,
  );
  final endShape = context.knobs.object.segmented(
    label: 'Appearance · End shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.circular,
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
      onInvoke: enabled ? _noop : null,
    ),
  );
}

Widget _states(BuildContext context) => previewColumn([
  const CarpenterIconButton(
    icon: Icons.add,
    semanticLabel: 'Enabled add',
    onInvoke: _noop,
  ),
  const CarpenterIconButton(
    icon: Icons.delete,
    semanticLabel: 'Disabled delete',
  ),
  const CarpenterIconButton(
    icon: Icons.sync,
    semanticLabel: 'Synchronizing',
    executionPhase: ActionExecutionPhase.running,
    onInvoke: _noop,
  ),
]);

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterIconButton(
    icon: Icons.delete,
    semanticLabel: 'Удалить договор',
    autofocus: true,
    colorRole: ActionColorRole.danger,
    onInvoke: _noop,
  ),
  const CarpenterText.body(
    'The visible glyph never replaces the required semantic label.',
  ),
]);

void _noop() {}
