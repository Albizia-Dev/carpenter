import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/messenger/catalog.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';
import 'messenger_workspace_test.dart' show host;

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (name: 'wide', size: const Size(900, 500), dark: false, scale: 1.0),
    (name: 'narrow_dark', size: const Size(390, 844), dark: true, scale: 2.0),
  ]) {
    testWidgets('attachments ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const AttachmentTrayScenario(),
          dark: variant.dark,
          scale: variant.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CarpenterAttachmentTray),
        matchesGoldenFile('attachments_${variant.name}.png'),
      );
    });
  }
  testWidgets('retry and cancel target separate files, ready is not sent', (
    tester,
  ) async {
    await tester.pumpWidget(host(const AttachmentTrayScenario()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отменить'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Загрузка отменена'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -130));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Повторить'));
    Focus.of(tester.element(find.text('Повторить'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.textContaining('Файл загружен'), findsWidgets);
    expect(find.text('Отправлено'), findsNothing);
    expect(find.text('Повторить'), findsNothing);
  });
  testWidgets('workspace keeps composer reachable at narrow 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(const MessengerScenario(showAttachments: true), scale: 2),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CarpenterAttachmentTray), findsOneWidget);
    final rect = tester.getRect(find.byType(CarpenterMessageComposer));
    expect(rect.bottom, lessThanOrEqualTo(844));
    expect(rect.height, greaterThan(0));
  });
  testWidgets('verification uses activity indicator; empty tray stays hidden', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(const AttachmentTrayScenario(verifying: true)),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<CarpenterProgress>(find.byType(CarpenterProgress)).value,
      isNull,
    );
    await tester.pumpWidget(host(const CarpenterAttachmentTray(items: [])));
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterButton), findsNothing);
    expect(find.byType(ListView), findsNothing);
  });
}
