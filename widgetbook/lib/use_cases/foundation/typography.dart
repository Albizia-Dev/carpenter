import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final foundationTypographyComponent = WidgetbookComponent(
  name: 'Typography',
  useCases: [
    WidgetbookUseCase(name: 'Scale', builder: _scale),
    WidgetbookUseCase(name: 'Content stress', builder: _contentStress),
  ],
);

Widget _scale(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.large);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final role in TypographyRole.values) ...[
            CarpenterText(
              semanticValueLabel(role),
              role: role,
              emphasis: TypographyEmphasis.strong,
            ),
            SizedBox(height: gap),
            for (final emphasis in TypographyEmphasis.values) ...[
              CarpenterText(
                '${semanticValueLabel(role)} · ${semanticValueLabel(emphasis)} · Платёж по договору №1542',
                role: role,
                emphasis: emphasis,
              ),
              SizedBox(height: gap / 2),
            ],
            SizedBox(height: gap),
          ],
        ],
      );
    },
  ),
);

Widget _contentStress(BuildContext context) => previewColumn([
  SizedBox(
    width: context.units(17.5.rem),
    child: CarpenterText.body(
      'Длинный русский текст для проверки переноса, плотности и поведения типографики в узком рабочем интерфейсе.',
    ),
  ),
  SizedBox(
    width: context.units(17.5.rem),
    child: CarpenterText.body(
      'A deliberately long English sentence used to expose wrapping and density differences between scripts.',
    ),
  ),
  SizedBox(
    width: context.units(11.25.rem),
    child: CarpenterText.body(
      'оченьдлинноесловобезпробеловкотороенедолжноломатькомпоновку',
    ),
  ),
  Directionality(
    textDirection: TextDirection.rtl,
    child: SizedBox(
      width: context.units(17.5.rem),
      child: CarpenterText.body(
        'نص طويل لاختبار اتجاه الكتابة من اليمين إلى اليسار',
      ),
    ),
  ),
  const CarpenterText.body('Статусы: ✓ ⚠ ⛔ · 1 234 567,89 ₽ · №1542'),
]);
