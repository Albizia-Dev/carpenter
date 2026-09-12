import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/messenger/catalog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';
import 'messenger_workspace_test.dart' show host;

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (name: 'wide', size: const Size(1000, 800), dark: false, scale: 1.0),
    (name: 'narrow_dark', size: const Size(390, 844), dark: true, scale: 1.3),
  ]) {
    testWidgets('recovery ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const RecoveryScenario(),
          dark: variant.dark,
          scale: variant.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CarpenterMessengerRecovery),
        matchesGoldenFile('messenger_recovery_${variant.name}.png'),
      );
    });
  }
  testWidgets('explicit choice enables save; cancellation remains available', (
    tester,
  ) async {
    await tester.pumpWidget(host(const RecoveryScenario()));
    await tester.pumpAndSettle();
    final save = find.widgetWithText(CarpenterButton, 'Сохранить выбранное');
    expect(tester.widget<CarpenterButton>(save).onPressed, isNull);
    await tester.tap(find.text('Оставить с устройства'));
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: на устройстве'), findsOneWidget);
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('Черновики сохранены'), findsOneWidget);
  });
  testWidgets('keyboard selects a whole version', (tester) async {
    await tester.pumpWidget(host(const RecoveryScenario()));
    await tester.pumpAndSettle();
    Focus.of(tester.element(find.text('Оставить с устройства'))).requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Выбрано: на устройстве'), findsOneWidget);
  });
  testWidgets('no conflicts can be saved or cancelled', (tester) async {
    await tester.pumpWidget(host(const RecoveryScenario(noConflicts: true)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CarpenterButton>(
            find.widgetWithText(CarpenterButton, 'Сохранить выбранное'),
          )
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    expect(find.text('Восстановление отменено'), findsOneWidget);
  });
}
