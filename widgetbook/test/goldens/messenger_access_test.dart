import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/messenger/access.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';
import 'messenger_workspace_test.dart' show host;

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (
      name: 'wide',
      size: const Size(1100, 800),
      dark: false,
      scale: 1.0,
      stage: CarpenterAccessStage.credentials,
    ),
    (
      name: 'phone_dark',
      size: const Size(390, 844),
      dark: true,
      scale: 1.0,
      stage: CarpenterAccessStage.credentials,
    ),
    (
      name: 'large_text',
      size: const Size(390, 844),
      dark: false,
      scale: 2.0,
      stage: CarpenterAccessStage.credentials,
    ),
    (
      name: 'waiting',
      size: const Size(390, 844),
      dark: false,
      scale: 1.0,
      stage: CarpenterAccessStage.waiting,
    ),
    (
      name: 'failure_dark',
      size: const Size(390, 844),
      dark: true,
      scale: 1.3,
      stage: CarpenterAccessStage.failure,
    ),
  ]) {
    testWidgets('access ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          MessengerAccessScenario(stage: variant.stage),
          dark: variant.dark,
          scale: variant.scale,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byType(CarpenterMessengerAccess),
        matchesGoldenFile('messenger_access_${variant.name}.png'),
      );
    });
  }
  for (final dark in [false, true]) {
    testWidgets('browser account confirmation ${dark ? "dark" : "light"}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        host(
          const MessengerAccessScenario(browserAccount: true),
          dark: dark,
          scale: dark ? 2 : 1,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Продолжить вход'), findsOneWidget);
      final change = find.text('Войти в другой аккаунт');
      await tester.ensureVisible(change);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(CarpenterMessengerAccess),
        matchesGoldenFile(
          'messenger_access_account_${dark ? "dark" : "light"}.png',
        ),
      );
      await tester.tap(change);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('browser consent may omit account switch independently', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MessengerAccessScenario(
          browserAccount: true,
          showSecondary: false,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Продолжить вход'), findsOneWidget);
    expect(find.text('Войти в другой аккаунт'), findsNothing);
  });
  testWidgets(
    'form requires both values; password is obscured and Enter submits once',
    (tester) async {
      await tester.pumpWidget(host(const MessengerAccessScenario()));
      await tester.pumpAndSettle();
      final input = find.byType(EditableText);
      final submit = find.widgetWithText(CarpenterButton, 'Войти');
      expect(tester.widget<CarpenterButton>(submit).onPressed, isNull);
      await tester.enterText(input.at(0), 'alice');
      await tester.enterText(input.at(1), 'fixture-password');
      await tester.pump();
      expect(tester.widget<EditableText>(input.at(1)).obscureText, true);
      expect(tester.widget<CarpenterButton>(submit).onPressed, isNotNull);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.text('Действие получено'), findsOneWidget);
      expect(tester.widget<EditableText>(input.at(1)).controller.text, isEmpty);
    },
  );
  testWidgets('visibility toggle is explicit and preserves caller value', (
    tester,
  ) async {
    await tester.pumpWidget(host(const MessengerAccessScenario()));
    await tester.pumpAndSettle();
    final input = find.byType(EditableText).at(1);
    await tester.enterText(input, 'fixture-password');
    await tester.tap(find.bySemanticsLabel('Показать пароль'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(input).obscureText, false);
    await tester.tap(find.bySemanticsLabel('Скрыть пароль'));
    await tester.pumpAndSettle();
    expect(tester.widget<EditableText>(input).obscureText, true);
    expect(
      tester.widget<EditableText>(input).controller.text,
      'fixture-password',
    );
  });
  testWidgets('submitting blocks duplicate action and editing', (tester) async {
    await tester.pumpWidget(
      host(
        const MessengerAccessScenario(stage: CarpenterAccessStage.submitting),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CarpenterButton>(
            find.widgetWithText(CarpenterButton, 'Войти'),
          )
          .onPressed,
      isNull,
    );
    expect(find.byType(CarpenterProgress), findsOneWidget);
    for (final field in tester.widgetList<CarpenterInput>(
      find.byType(CarpenterInput),
    )) {
      expect(field.availability, FieldAvailability.disabled);
    }
  });
  testWidgets('keyboard inset keeps submit reachable by scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewInsets: const EdgeInsets.only(bottom: 280)),
            child: const MessengerAccessScenario(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final submit = find.widgetWithText(CarpenterButton, 'Войти');
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });
}
