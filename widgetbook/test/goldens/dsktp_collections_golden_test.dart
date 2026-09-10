import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/dsktp_collections.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final scene in ['lists', 'tree', 'accordion', 'groups', 'accounts']) {
    for (final variant in [
      (
        name: 'desktop_large',
        size: const Size(1920, 1080),
        scale: 1.0,
        dark: false,
      ),
      (
        name: 'desktop_dark',
        size: const Size(1280, 900),
        scale: 1.0,
        dark: true,
      ),
      (name: 'wide', size: const Size(1280, 800), scale: 1.0, dark: false),
      (name: 'narrow', size: const Size(390, 1000), scale: 1.0, dark: false),
      (name: 'dark_200', size: const Size(600, 1100), scale: 2.0, dark: true),
    ]) {
      if (scene.contains('_') && variant.name != 'narrow') continue;
      testWidgets('$scene ${variant.name}', (tester) async {
        tester.view.physicalSize = variant.size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme =
            (variant.dark
                    ? CarpenterThemeData.dark()
                    : CarpenterThemeData.light())
                .copyWith(
                  typography: const CarpenterTypographyTheme(
                    fontFamily: 'Onest',
                  ),
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
                    child: scene == 'accounts'
                        ? const DsktpGroupedListLayout(accounts: true)
                        : scene == 'groups'
                        ? const DsktpGroupedListLayout()
                        : scene == 'accordion'
                        ? const DsktpAccordionLayout()
                        : DsktpCollectionsLayout(tree: scene == 'tree'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.runAsync(() => vg.waitForPendingDecodes());
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('scene')),
          matchesGoldenFile('images/${scene}_${variant.name}.png'),
        );
        if (scene != 'tree' &&
            (variant.name == 'narrow' || variant.name == 'dark_200')) {
          await tester.drag(
            find.byType(SingleChildScrollView).first,
            const Offset(0, -1800),
          );
          await tester.pumpAndSettle();
          await expectLater(
            find.byKey(const ValueKey('scene')),
            matchesGoldenFile('images/${scene}_${variant.name}_bottom.png'),
          );
        }
        if ((scene == 'accordion' ||
                scene == 'groups' ||
                scene == 'accounts') &&
            variant.name == 'wide') {
          await tester.tap(
            find.text(
              scene == 'accounts'
                  ? 'ООО «Северный квартал»'
                  : scene == 'groups'
                  ? '10 сентября'
                  : 'Платежи',
            ),
          );
          await tester.pumpAndSettle();
          expect(
            find.text(
              scene == 'accounts'
                  ? 'Альфа-Банк · Основной расчётный'
                  : 'ООО «Электрокомплект»',
            ),
            findsNothing,
          );
          if (scene == 'accounts')
            expect(find.text('Т-Банк · Операционный'), findsOneWidget);
          await expectLater(
            find.byKey(const ValueKey('scene')),
            matchesGoldenFile('images/${scene}_wide_collapsed.png'),
          );
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
