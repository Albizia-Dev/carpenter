import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/work_items/rsp_detail.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final phase in [
    CarpenterRspDetailPhase.initial,
    CarpenterRspDetailPhase.loading,
    CarpenterRspDetailPhase.failure,
  ]) {
    testWidgets('RSP detail ${phase.name}', (tester) async {
      const size = Size(390, 900);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final theme = CarpenterThemeData.light().copyWith(
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
                  child: RspDetailScene(phase: phase),
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
        matchesGoldenFile('images/rsp_detail_${phase.name}.png'),
      );
      if (phase == CarpenterRspDetailPhase.failure) {
        await tester.tap(find.text('Повторить загрузку'));
        await tester.pumpAndSettle();
        expect(find.byType(CarpenterRspAcceptance), findsOneWidget);
        expect(find.text('Подтвердить результат'), findsOneWidget);
        expect(
          find.text('Результат подтверждён. Исполнение поручения завершено.'),
          findsNothing,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
