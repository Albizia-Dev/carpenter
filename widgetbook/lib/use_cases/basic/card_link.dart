import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final cardComponent = WidgetbookComponent(
  name: 'Card',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _cardPlayground)],
);

final linkComponent = WidgetbookComponent(
  name: 'Link',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _linkPlayground)],
);

Widget _cardPlayground(BuildContext context) {
  final theme = CarpenterTheme.of(context);
  final title = context.knobs.string(
    label: 'Content · Title',
    initialValue: 'Payment summary',
  );
  final body = context.knobs.string(
    label: 'Content · Body',
    initialValue: 'One related semantic block on a Carpenter surface.',
  );
  final semanticLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Payment summary card',
    defaultToNull: true,
  );
  final padded = context.knobs.boolean(
    label: 'Layout · Default padding',
    initialValue: true,
  );
  final customPadding = context.knobs.boolean(label: 'Layout · Custom padding');
  final padding = context.knobs.double.slider(
    label: 'Layout · Padding',
    initialValue: 16,
    min: 0,
    max: 48,
    divisions: 24,
  );
  final width = context.knobs.double.slider(
    label: 'Layout · Width',
    initialValue: 420,
    min: 180,
    max: 800,
    divisions: 31,
  );
  final bordered = context.knobs.boolean(
    label: 'Appearance · Border',
    initialValue: true,
  );
  final shape = context.knobs.object.segmented(
    label: 'Appearance · Shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.rounded,
    labelBuilder: semanticValueLabel,
  );
  final customBackground = context.knobs.boolean(
    label: 'Appearance · Custom background',
  );
  final background = context.knobs.color(
    label: 'Appearance · Background',
    initialValue: theme.overlay.background,
  );
  final customBorder = context.knobs.boolean(
    label: 'Appearance · Custom border color',
  );
  final border = context.knobs.color(
    label: 'Appearance · Border color',
    initialValue: theme.overlay.border,
  );
  final showStatus = context.knobs.boolean(
    label: 'Content · Status',
    initialValue: true,
  );
  final showAction = context.knobs.boolean(
    label: 'Content · Action',
    initialValue: true,
  );

  return preview(
    SizedBox(
      width: width,
      child: CarpenterCard(
        semanticLabel: semanticLabel,
        padded: padded,
        padding: customPadding ? EdgeInsets.all(padding) : null,
        bordered: bordered,
        shape: shape,
        backgroundColor: customBackground ? background : null,
        borderColor: customBorder ? border : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CarpenterText.title(
                    title,
                    emphasis: TypographyEmphasis.strong,
                  ),
                ),
                if (showStatus)
                  const CarpenterTag(
                    label: 'Ready',
                    tone: CarpenterTagTone.success,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            CarpenterText.body(body, colorRole: ContentColorRole.secondary),
            if (showAction) ...[
              const SizedBox(height: 16),
              CarpenterButton.text(label: 'Open details', onPressed: () {}),
            ],
          ],
        ),
      ),
    ),
  );
}

Widget _linkPlayground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Open bank account',
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final withIcon = context.knobs.boolean(
    label: 'Content · Icon',
    initialValue: true,
  );
  final role = context.knobs.object.segmented(
    label: 'Appearance · Role',
    options: ActionColorRole.values,
    initialOption: ActionColorRole.utility,
    labelBuilder: semanticValueLabel,
  );
  final autofocus = context.knobs.boolean(label: 'Accessibility · Autofocus');
  return preview(
    CarpenterLink(
      label: label,
      icon: withIcon ? Icons.open_in_new : null,
      colorRole: role,
      autofocus: autofocus,
      onInvoke: enabled ? () {} : null,
    ),
  );
}
