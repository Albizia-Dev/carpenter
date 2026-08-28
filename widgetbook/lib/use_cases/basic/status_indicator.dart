import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

final statusIndicatorComponent = WidgetbookComponent(
  name: 'Status Indicator',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Color roles', builder: _colorRoles),
    WidgetbookUseCase(name: 'Edge cases', builder: _edgeCases),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
  ],
);

Widget _colorRoles(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final role in FeedbackColorRole.values)
            CarpenterStatusIndicator(
              label: semanticValueLabel(role),
              role: role,
            ),
        ],
      );
    },
  ),
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Оплачен',
  );
  final role = context.knobs.object.dropdown(
    label: 'Appearance · Role',
    options: FeedbackColorRole.values,
    initialOption: FeedbackColorRole.success,
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
  return preview(
    CarpenterStatusIndicator(
      label: label,
      role: role,
      shape: CarpenterShape(start: startShape, end: endShape),
    ),
  );
}

Widget _edgeCases(BuildContext context) => preview(
  const SizedBox(
    width: context.units(11.25.rem),
    child: CarpenterStatusIndicator(
      label: 'Ожидает дополнительного согласования',
      role: FeedbackColorRole.warning,
    ),
  ),
);

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterStatusIndicator(
    label: 'Успешно завершено',
    role: FeedbackColorRole.success,
  ),
  const CarpenterStatusIndicator(
    label: 'Требует внимания',
    role: FeedbackColorRole.warning,
  ),
  const CarpenterText.body('Meaning is carried by text as well as color.'),
]);
