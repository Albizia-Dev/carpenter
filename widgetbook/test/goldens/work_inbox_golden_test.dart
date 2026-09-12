import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/work_items/inbox.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final variant in [
    (
      name: 'wide',
      size: Size(1280, 900),
      dark: false,
      scale: 1.0,
      selected: 'deadline',
      phase: CarpenterWorkInboxPhase.ready,
    ),
    (
      name: 'narrow',
      size: Size(390, 1000),
      dark: false,
      scale: 1.0,
      selected: null,
      phase: CarpenterWorkInboxPhase.ready,
    ),
    (
      name: 'detail',
      size: Size(390, 1000),
      dark: false,
      scale: 1.0,
      selected: 'deadline',
      phase: CarpenterWorkInboxPhase.ready,
    ),
    (
      name: 'dark',
      size: Size(1280, 900),
      dark: true,
      scale: 1.0,
      selected: 'accept',
      phase: CarpenterWorkInboxPhase.stale,
    ),
    (
      name: 'large_text',
      size: Size(600, 1100),
      dark: true,
      scale: 2.0,
      selected: null,
      phase: CarpenterWorkInboxPhase.ready,
    ),
    (
      name: 'stale_detail',
      size: Size(390, 1000),
      dark: false,
      scale: 1.0,
      selected: 'deadline',
      phase: CarpenterWorkInboxPhase.stale,
    ),
    (
      name: 'failure',
      size: Size(390, 1000),
      dark: false,
      scale: 1.0,
      selected: null,
      phase: CarpenterWorkInboxPhase.failure,
    ),
  ]) {
    testWidgets('work inbox ${variant.name}', (tester) async {
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
                  child: WorkInboxScene(
                    initialSelection:
                        workInboxScenarioEntries[variant.selected],
                    phase: variant.phase,
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
        matchesGoldenFile('images/work_inbox_${variant.name}.png'),
      );
      if (variant.name == 'detail') {
        await tester.tap(find.text('К списку задач'));
        await tester.pumpAndSettle();
        expect(find.text('Поиск в моей работе'), findsOneWidget);
        await tester.tap(
          find.byKey(ValueKey(workInboxScenarioEntries['deadline']!)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Предложенный срок'), findsOneWidget);
      }
      if (variant.name == 'narrow') {
        await tester.enterText(find.byType(EditableText), '  КОМПЛЕКТУЮЩИМ  ');
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey(workInboxScenarioEntries['deadline']!)),
          findsOneWidget,
        );
        expect(
          find.byKey(ValueKey(workInboxScenarioEntries['accept']!)),
          findsNothing,
        );
        await tester.enterText(find.byType(EditableText), '');
        await tester.pumpAndSettle();
        await tester.tap(find.text('ЗОДО'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(ValueKey(workInboxScenarioEntries['accept']!)),
          findsNothing,
        );
        expect(
          find.byKey(ValueKey(workInboxScenarioEntries['develop']!)),
          findsOneWidget,
        );
        await tester.enterText(find.byType(EditableText), 'несуществующее');
        await tester.pumpAndSettle();
        expect(
          find.text('По этим условиям задач нет. Измените поиск или фильтр.'),
          findsOneWidget,
        );
      }
      if (variant.name == 'stale_detail') {
        expect(find.text('Показаны предыдущие данные'), findsOneWidget);
        await tester.tap(find.text('Повторить'));
        await tester.pumpAndSettle();
        expect(find.text('Показаны предыдущие данные'), findsNothing);
        expect(find.text('Предложенный срок'), findsOneWidget);
      }
      if (variant.name == 'failure') {
        await tester.tap(find.text('Повторить'));
        await tester.pumpAndSettle();
        expect(find.text('Очередь не загрузилась'), findsNothing);
        expect(
          find.byKey(ValueKey(workInboxScenarioEntries['accept']!)),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}
