import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/treasury/pages.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'filters preserve selection when collapsed and reset individually',
    (tester) async {
      await tester.pumpWidget(
        UnitsRoot(
          rem: const Px(16),
          child: CarpenterTheme(
            data: CarpenterThemeData.light(),
            child: const Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: TreasuryPagePreview(pageId: 'accounts'),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CarpenterSelect<String>), findsNothing);
      await tester.tap(find.text('Фильтры'));
      await tester.pump();
      expect(find.byType(CarpenterSelect<String>), findsNWidgets(6));
      final currency = tester
          .widgetList<CarpenterSelect<String>>(
            find.byType(CarpenterSelect<String>),
          )
          .singleWhere((field) => field.label == 'Валюта');
      currency.onChanged!('RUB');
      await tester.pump();
      await tester.tap(find.text('Фильтры (1)'));
      await tester.pump();
      expect(find.byType(CarpenterSelect<String>), findsNothing);
      expect(find.text('Валюта: RUB ×'), findsOneWidget);
      await tester.tap(find.text('Фильтры (1)'));
      await tester.pump();
      expect(
        tester
            .widgetList<CarpenterSelect<String>>(
              find.byType(CarpenterSelect<String>),
            )
            .singleWhere((field) => field.label == 'Валюта')
            .value,
        'RUB',
      );
      await tester.tap(find.text('Валюта: RUB ×'));
      await tester.pump();
      expect(find.text('Фильтры'), findsOneWidget);
      expect(find.text('Сбросить'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
