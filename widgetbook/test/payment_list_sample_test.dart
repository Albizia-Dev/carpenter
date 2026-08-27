import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/helpers/layout_viewport.dart';
import 'package:carpenter_widgetbook/use_cases/samples/payment_list.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment sample loads and drives master detail selection', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildPaymentListSample()));
    expect(find.text('Загружаем платежи'), findsOneWidget);

    await tester.pump(const Milliseconds(500).toDuration());
    expect(find.text('ООО «Северная логистика»'), findsWidgets);
    expect(find.text('Реквизиты'), findsOneWidget);

    await tester.tap(find.text('АО «Деловой квартал»').first);
    await tester.pump();
    expect(find.text('−348 000,00 ₽'), findsWidgets);
    expect(find.textContaining('Аренда офисного помещения'), findsWidgets);
  });

  testWidgets('detail tabs, links and actions are interactive', (tester) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(_harness(buildPaymentListSample()));
    await tester.pump(const Milliseconds(500).toDuration());

    expect(find.text('Реквизиты'), findsOneWidget);
    if (find.text('Распределить').evaluate().isEmpty) {
      await tester.tap(find.text('Ещё').last);
      await tester.pumpAndSettle();
    }
    final allocate = find.text('Распределить').last;
    await tester.tap(allocate);
    await tester.pump();
    expect(find.textContaining('Открыто распределение'), findsOneWidget);

    await tester.tap(find.text('ООО «Окиби Технологии»').last);
    await tester.pump();
    expect(find.textContaining('Открыто юридическое лицо'), findsOneWidget);

    await tester.tap(find.text('Распределение'));
    await tester.pump();
    expect(find.text('Договор № 18/24'), findsOneWidget);

    await tester.tap(find.text('История'));
    await tester.pump();
    expect(find.text('Платёж получен из банковской выписки'), findsOneWidget);
  });

  testWidgets('sample remains valid in compact pushed presentation', (
    tester,
  ) async {
    await _useLargeSurface(tester);
    await tester.pumpWidget(
      _harness(
        layoutViewportFrame(
          preset: LayoutViewportPreset.mobilePortrait,
          child: buildPaymentListSample(),
        ),
      ),
    );
    await tester.pump(const Milliseconds(500).toDuration());
    expect(find.textContaining('ПП-90512'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _useLargeSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _harness(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(size: Size(1400, 1000)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => Center(
                child: SizedBox(width: 1300, height: 940, child: child),
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
