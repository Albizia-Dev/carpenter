import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/work_items/rsp_acceptance.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (
      name: 'ready',
      size: Size(800, 700),
      dark: false,
      scale: 1.0,
      phase: CarpenterRspAcceptancePhase.ready,
      creator: true,
    ),
    (
      name: 'uncertain_narrow',
      size: Size(390, 900),
      dark: false,
      scale: 1.0,
      phase: CarpenterRspAcceptancePhase.uncertain,
      creator: true,
    ),
    (
      name: 'rejected_dark',
      size: Size(600, 1100),
      dark: true,
      scale: 2.0,
      phase: CarpenterRspAcceptancePhase.rejected,
      creator: true,
    ),
    (
      name: 'accepted',
      size: Size(800, 700),
      dark: false,
      scale: 1.0,
      phase: CarpenterRspAcceptancePhase.accepted,
      creator: true,
    ),
    (
      name: 'review_after_recovery',
      size: Size(390, 900),
      dark: false,
      scale: 1.0,
      phase: CarpenterRspAcceptancePhase.reviewRequired,
      creator: true,
    ),
    (
      name: 'executor',
      size: Size(390, 900),
      dark: false,
      scale: 1.0,
      phase: CarpenterRspAcceptancePhase.ready,
      creator: false,
    ),
  ]) {
    testWidgets('RSP acceptance ${variant.name}', (tester) async {
      tester.view.physicalSize = variant.size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme =
          (variant.dark
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
                data: MediaQueryData(
                  size: variant.size,
                  textScaler: TextScaler.linear(variant.scale),
                  disableAnimations: true,
                ),
                child: ColoredBox(
                  key: const ValueKey('scene'),
                  color: theme.surface.base,
                  child: RspAcceptanceScene(
                    phase: variant.phase,
                    creator: variant.creator,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.runAsync(() => vg.waitForPendingDecodes());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('scene')),
        matchesGoldenFile('images/rsp_acceptance_${variant.name}.png'),
      );
      if (variant.name == 'ready' || variant.name == 'uncertain_narrow') {
        await tester.tap(
          find.text(
            variant.name == 'ready'
                ? 'Подтвердить результат'
                : 'Повторить проверку',
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Результат подтверждён. Исполнение поручения завершено.'),
          findsOneWidget,
        );
      }
      if (variant.phase == CarpenterRspAcceptancePhase.reviewRequired) {
        expect(find.text('Подтверждение не сохранено'), findsNothing);
        expect(find.text('Подтвердить результат'), findsNothing);
        await tester.tap(find.text('Обновить результат').last);
        await tester.pumpAndSettle();
        expect(find.text('Подтвердить результат'), findsOneWidget);
      }
      if (!variant.creator ||
          variant.phase == CarpenterRspAcceptancePhase.accepted) {
        expect(find.text('Подтвердить результат'), findsNothing);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
