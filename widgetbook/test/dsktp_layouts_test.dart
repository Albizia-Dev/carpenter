import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/dsktp_layouts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget harness(Widget child) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: const MediaQueryData(), child: child),
    ),
  ),
);

void main() {
  testWidgets('project example saves edited metadata', (tester) async {
    await tester.pumpWidget(harness(const DsktpProjectLayout()));
    await tester.tap(find.bySemanticsLabel('Редактировать'));
    await tester.pump();
    await tester.enterText(find.byType(EditableText).first, 'Новое название');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(find.text('Новое название'), findsOneWidget);
    expect(find.text('№104. Новое название'), findsOneWidget);
    expect(find.byType(EditableText), findsOneWidget);
  });
  testWidgets(
    'materials search filters content and loading retains navigation',
    (tester) async {
      await tester.pumpWidget(harness(const DsktpMaterialsLayout()));
      await tester.enterText(find.byType(EditableText), 'расчёт');
      await tester.pump();
      expect(find.text('Расчёт электрических нагрузок.xlsx'), findsOneWidget);
      expect(find.text('Пояснительная записка.pdf'), findsNothing);
      await tester.pumpWidget(
        harness(const DsktpMaterialsLayout(loading: true)),
      );
      expect(find.text('Загрузка материалов'), findsOneWidget);
      expect(
        find.byType(CarpenterExplorerLocationStrip<String>),
        findsOneWidget,
      );
      expect(find.byType(CarpenterHeaderActions), findsOneWidget);
      expect(find.byType(CarpenterInput), findsOneWidget);
    },
  );
}
