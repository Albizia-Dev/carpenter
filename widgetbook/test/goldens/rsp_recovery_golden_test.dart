import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/work_items/rsp_recovery.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final scenario in [
    for (final phase in CarpenterRspRecoveryPhase.values) (phase, false),
    (CarpenterRspRecoveryPhase.ready, true),
  ]) {
    final phase = scenario.$1;
    final empty = scenario.$2;
    final name = empty ? 'empty' : phase.name;
    testWidgets('RSP recovery $name', (tester) async {
      const size = Size(390, 900);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme =
          (phase == CarpenterRspRecoveryPhase.ready
                  ? CarpenterThemeData.dark()
                  : CarpenterThemeData.light())
              .copyWith(
                typography: const CarpenterTypographyTheme(fontFamily: 'Onest'),
              );
      await tester.pumpWidget(
        UnitsRoot(
          rem: const Px(16),
          child: CarpenterTheme(
            data: theme,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: MediaQuery(
                data: const MediaQueryData(size: size, disableAnimations: true),
                child: ColoredBox(
                  key: const ValueKey('scene'),
                  color: theme.surface.base,
                  child: RspRecoveryScene(
                    phase: phase,
                    empty: empty,
                    label:
                        'РСП №501 · Проверить документы для реконструкции инженерных сетей квартала Северный парк',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => vg.waitForPendingDecodes());
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(CarpenterRspAcceptance), findsNothing);
      expect(find.text('Подтвердить результат'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('scene')),
        matchesGoldenFile('images/rsp_recovery_$name.png'),
      );
      if (phase == CarpenterRspRecoveryPhase.ready && !empty) {
        final row = find.byType(CarpenterListTile);
        expect(row, findsOneWidget);
        // Establish focus inside the row before exercising Enter activation.
        Focus.of(
          tester.element(
            find.text(
              'РСП №501 · Проверить документы для реконструкции инженерных сетей квартала Северный парк',
            ),
          ),
        ).requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(find.byType(CarpenterRspDetail), findsOneWidget);
        expect(find.text('Подтвердить результат'), findsNothing);
      } else {
        expect(find.byType(CarpenterListTile), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
