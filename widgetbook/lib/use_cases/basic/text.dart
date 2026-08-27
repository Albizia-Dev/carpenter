import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final textComponent = WidgetbookComponent(
  name: 'Text',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Edge cases', builder: _edgeCases),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
  ],
);

Widget _playground(BuildContext context) {
  final text = context.knobs.string(
    label: 'Content · Text',
    initialValue: 'Платёж по договору №1542',
    maxLines: 5,
  );
  final role = context.knobs.object.dropdown(
    label: 'Appearance · Typography role',
    options: TypographyRole.values,
    initialOption: TypographyRole.body,
    labelBuilder: semanticValueLabel,
  );
  final emphasis = context.knobs.object.segmented(
    label: 'Appearance · Emphasis',
    options: TypographyEmphasis.values,
    labelBuilder: semanticValueLabel,
  );
  final colorRole = context.knobs.object.dropdown(
    label: 'Appearance · Role',
    options: ContentColorRole.values,
    labelBuilder: semanticValueLabel,
  );
  final textAlign = context.knobs.objectOrNull.segmented(
    label: 'Appearance · Alignment',
    options: const [
      TextAlign.start,
      TextAlign.center,
      TextAlign.end,
      TextAlign.justify,
    ],
    labelBuilder: semanticValueLabel,
    defaultToNull: true,
  );
  final maxLines = context.knobs.intOrNull.input(
    label: 'Behaviour · Max lines',
    initialValue: 2,
    defaultToNull: true,
  );
  final overflow = context.knobs.objectOrNull.dropdown(
    label: 'Behaviour · Overflow',
    options: TextOverflow.values,
    initialOption: TextOverflow.ellipsis,
    labelBuilder: semanticValueLabel,
    defaultToNull: true,
  );
  final softWrap = context.knobs.booleanOrNull(
    label: 'Behaviour · Soft wrap',
    initialValue: true,
    defaultToNull: true,
  );
  final semanticsLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Payment under contract 1542',
    defaultToNull: true,
  );

  return preview(
    SizedBox(
      width: 420,
      child: CarpenterText(
        text,
        role: role,
        emphasis: emphasis,
        colorRole: colorRole,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        semanticsLabel: semanticsLabel,
      ),
    ),
  );
}

Widget _edgeCases(BuildContext context) => previewColumn([
  const SizedBox(width: 220, child: CarpenterText.body('')),
  const SizedBox(
    width: 220,
    child: CarpenterText.body(
      'Счёт на оплату по долгосрочному договору технического обслуживания',
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    ),
  ),
  const SizedBox(
    width: 160,
    child: CarpenterText.body(
      'оченьдлинноесловобезпробеловдляпроверкипереноса',
    ),
  ),
  const Directionality(
    textDirection: TextDirection.rtl,
    child: CarpenterText.body('نص من اليمين إلى اليسار'),
  ),
]);

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterText.body(
    '№1542',
    semanticsLabel: 'Номер договора: одна тысяча пятьсот сорок два',
  ),
  const CarpenterText.body('Текст масштабируется глобальным addon'),
]);
