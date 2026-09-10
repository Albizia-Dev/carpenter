import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/treasury/pages.dart';
import 'package:carpenter_widgetbook/use_cases/samples/treasury/specs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final spec in treasurySpecs) {
    for (final tab
        in spec.tabs.isEmpty
            ? [0]
            : List.generate(spec.tabs.length, (i) => i)) {
      for (final variant in [
        'desktop',
        if (spec.id == 'connectionNew') 'bankChecked',
        if (spec.id == 'accounts') ...[
          'filters',
          'filtersNarrow',
          'filtersScaled',
        ],
        if (tab == 0) 'narrow',
        if (tab == 0 &&
            [
              'accounts',
              'reconciliation',
              'account',
              'import',
              'connection',
            ].contains(spec.id))
          'large',
        if (tab == 0 &&
            [
              'accountNew',
              'entity',
              'payment',
              'reconciliation',
              'importNew',
            ].contains(spec.id))
          'scaled',
      ]) {
        testWidgets('${spec.id} tab $tab $variant', (tester) async {
          final size = switch (variant) {
            'narrow' || 'filtersNarrow' => const Size(390, 1100),
            'large' => const Size(1920, 1080),
            'scaled' || 'filtersScaled' => const Size(600, 1200),
            _ => const Size(1280, 1000),
          };
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme =
              (variant == 'scaled'
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
                      size: size,
                      textScaler: TextScaler.linear(
                        variant == 'scaled' || variant == 'filtersScaled'
                            ? 2
                            : 1,
                      ),
                      disableAnimations: true,
                    ),
                    child: ColoredBox(
                      key: const ValueKey('scene'),
                      color: theme.surface.base,
                      child: TreasuryPagePreview(
                        pageId: spec.id,
                        initialTab: tab,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.runAsync(() => vg.waitForPendingDecodes());
          await tester.pumpAndSettle();
          if (variant == 'bankChecked') {
            await tester.tap(find.text('Проверить и подключить'));
            await tester.pumpAndSettle();
          }
          if (variant.startsWith('filters')) {
            await tester.tap(find.text('Фильтры'));
            await tester.pumpAndSettle();
            tester
                .widgetList<CarpenterSelect<String>>(
                  find.byType(CarpenterSelect<String>),
                )
                .singleWhere((field) => field.label == 'Проблемы')
                .onChanged!('Только с проблемами');
            await tester.pumpAndSettle();
          }
          await tester.runAsync(() => vg.waitForPendingDecodes());
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('scene')),
            matchesGoldenFile('treasury/${spec.id}_${tab}_$variant.png'),
          );
          final scrollable = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('treasury-scroll')),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          if (scrollable.position.maxScrollExtent > 0) {
            scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            await expectLater(
              find.byKey(const ValueKey('scene')),
              matchesGoldenFile(
                'treasury/${spec.id}_${tab}_${variant}_bottom.png',
              ),
            );
          }
        });
      }
    }
  }
}
