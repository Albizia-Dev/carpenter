import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

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
  final padded = context.knobs.boolean(
    label: 'Layout · Padded',
    initialValue: true,
  );
  return preview(
    CarpenterCard(
      semanticLabel: title,
      padded: padded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CarpenterText.title(title, emphasis: TypographyEmphasis.strong),
          const CarpenterText.body(
            'One related semantic block on a Carpenter surface.',
            colorRole: ContentColorRole.secondary,
          ),
        ],
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
  return preview(
    CarpenterLink(
      label: label,
      icon: withIcon ? Icons.open_in_new : null,
      onInvoke: enabled ? () {} : null,
    ),
  );
}
