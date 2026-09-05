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
  final surfaceRole = context.knobs.object.segmented(
    label: 'Appearance · Surface role',
    options: CarpenterCardSurfaceRole.values,
    initialOption: CarpenterCardSurfaceRole.overlay,
    labelBuilder: semanticValueLabel,
  );
  final feedbackSurface = context.knobs.boolean(
    label: 'Appearance · Feedback surface',
  );
  final feedbackRole = context.knobs.object.segmented(
    label: 'Appearance · Feedback role',
    options: FeedbackColorRole.values,
    initialOption: FeedbackColorRole.info,
    labelBuilder: semanticValueLabel,
  );
  final showStatus = context.knobs.boolean(
    label: 'Content · Status',
    initialValue: true,
  );
  final showAction = context.knobs.boolean(
    label: 'Content · Action',
    initialValue: true,
  );

  final content = Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: feedbackSurface
                ? CarpenterText.feedback(
                    title,
                    feedbackRole: feedbackRole,
                    role: TypographyRole.title,
                    emphasis: TypographyEmphasis.strong,
                  )
                : CarpenterText.title(
                    title,
                    emphasis: TypographyEmphasis.strong,
                  ),
          ),
          if (showStatus)
            const CarpenterTag(label: 'Ready', tone: CarpenterTagTone.success),
        ],
      ),
      SizedBox(height: context.units(.5.rem)),
      if (feedbackSurface)
        CarpenterText.feedback(body, feedbackRole: feedbackRole)
      else
        CarpenterText.body(body, colorRole: ContentColorRole.secondary),
      if (showAction) ...[
        SizedBox(height: context.units(1.rem)),
        CarpenterButton.text(label: 'Open details', onPressed: () {}),
      ],
    ],
  );

  return preview(
    SizedBox(
      width: width,
      child: feedbackSurface
          ? CarpenterCard.feedback(
              semanticLabel: semanticLabel,
              role: feedbackRole,
              padded: padded,
              bordered: bordered,
              shape: shape,
              child: content,
            )
          : CarpenterCard(
              semanticLabel: semanticLabel,
              padded: padded,
              bordered: bordered,
              shape: shape,
              surfaceRole: surfaceRole,
              child: content,
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
