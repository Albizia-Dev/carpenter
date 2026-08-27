import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/curated_icons.dart';
import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final iconComponent = WidgetbookComponent(
  name: 'Icon',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
  ],
);

Widget _playground(BuildContext context) {
  final glyph = context.knobs.object.dropdown(
    label: 'Content · Icon',
    options: curatedIcons,
    initialOption: curatedIcons[3],
    labelBuilder: (option) => option.label,
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: IconSize.values,
    labelBuilder: semanticValueLabel,
  );
  final colorRole = context.knobs.object.dropdown(
    label: 'Appearance · Role',
    options: ContentColorRole.values,
    labelBuilder: semanticValueLabel,
  );
  final semanticLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Search',
  );

  return preview(
    CarpenterIcon(
      glyph.data,
      size: size,
      colorRole: colorRole,
      semanticLabel: semanticLabel,
    ),
  );
}

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterIcon(Icons.info, semanticLabel: 'Information'),
  const CarpenterText.body(
    'Decorative icons should omit a semantic label; meaningful icons name their action.',
  ),
]);
