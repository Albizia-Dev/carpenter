import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/projects_plus/pages.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(String id) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Overlay(
          initialEntries: [
            OverlayEntry(builder: (_) => ProjectsPlusPreview(pageId: id)),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets(
    'project board search preserves the matching project and opens its card',
    (tester) async {
      await tester.pumpWidget(host('board'));
      await tester.enterText(find.byType(EditableText), '104');
      await tester.pump();
      expect(find.text('№ 104 · Северный парк'), findsOneWidget);
      expect(find.text('№ 105 · Школа на Озёрной'), findsNothing);
      await tester.tap(find.text('№ 104 · Северный парк'));
      await tester.pump();
      expect(find.text('Документы проекта'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('edited financial values remain after saving the specimen', (
    tester,
  ) async {
    await tester.pumpWidget(host('financials'));
    await tester.tap(find.text('Редактировать финансы'));
    await tester.pump();
    await tester.enterText(
      find.byType(EditableText).first,
      'Уточнённый этап П',
    );
    await tester.tap(find.text('Сохранить финансы'));
    await tester.pump();
    expect(find.text('Уточнённый этап П'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
