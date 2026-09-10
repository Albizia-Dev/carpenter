import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/projects_plus/pages.dart';
import 'package:carpenter_widgetbook/use_cases/samples/projects_plus/specs.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import 'package:flutter_test/flutter_test.dart';
import '../../../test/helpers/golden_fonts.dart';

Widget overlayHost(Widget child) =>
    Overlay(initialEntries: [OverlayEntry(builder: (_) => child)]);

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final spec in projectsPlusSpecs) {
    for (final tab in [0]) {
      for (final variant in [
        'desktop',
        if (spec.id == 'projectCreate') ...[
          'selection',
          'selectionNarrow',
          'selectionScaled',
        ],
        if (spec.id == 'project') ...[
          'comparison',
          'comparisonNarrow',
          'comparisonScaled',
        ],
        if (spec.id == 'financials') 'editing',
        'narrow',
        'large',
        if (['project', 'financials', 'board', 'sspCreate'].contains(spec.id))
          'scaled',
        if (spec.id == 'project') ...[
          'loading',
          'empty',
          'error',
          'conflict',
          'readOnly',
        ],
      ]) {
        testWidgets('${spec.id} tab $tab $variant', (tester) async {
          final size = switch (variant) {
            'narrow' ||
            'selectionNarrow' ||
            'comparisonNarrow' => const Size(390, 1100),
            'large' => const Size(1920, 1080),
            'scaled' ||
            'selectionScaled' ||
            'comparisonScaled' => const Size(600, 1200),
            _ => const Size(1280, 1000),
          };
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final theme =
              ((variant == 'scaled' || variant.endsWith('Scaled'))
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
                        (variant == 'scaled' || variant.endsWith('Scaled')) ||
                                variant == 'filtersScaled'
                            ? 2
                            : 1,
                      ),
                      disableAnimations: true,
                    ),
                    child: overlayHost(
                      ColoredBox(
                        key: const ValueKey('scene'),
                        color: theme.surface.base,
                        child: ProjectsPlusPreview(
                          pageId: spec.id,
                          visualState: ProjectsPlusState.values.firstWhere(
                            (state) =>
                                state.name ==
                                (variant.startsWith('comparison')
                                    ? 'conflict'
                                    : variant),
                            orElse: () => ProjectsPlusState.ready,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.runAsync(() => vg.waitForPendingDecodes());
          await tester.pumpAndSettle();
          if (variant == 'editing') {
            await tester.tap(find.text('Редактировать финансы'));
            await tester.pumpAndSettle();
          }
          if (variant.startsWith('selection')) {
            final field = find.byWidgetPredicate(
              (widget) =>
                  widget is CarpenterMultiSelect<String> &&
                  widget.semanticLabel == 'Проектировщики',
            );
            await tester.enterText(
              find.descendant(of: field, matching: find.byType(EditableText)),
              'Михаил',
            );
            await tester.pumpAndSettle();
          }
          if (variant.startsWith('comparison')) {
            await tester.tap(find.text('Сравнить версии'));
            await tester.pumpAndSettle();
          }
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(const ValueKey('scene')),
            matchesGoldenFile('projects_plus/${spec.id}_${tab}_$variant.png'),
          );
          if ([
                'financials',
                'sspBoard',
                'board',
                'sections',
                'incoming',
              ].contains(spec.id) &&
              ['desktop', 'large'].contains(variant)) {
            var moved = false;
            for (final scroll in tester.stateList<ScrollableState>(
              find.byType(Scrollable),
            )) {
              if (scroll.position.axis == Axis.horizontal &&
                  scroll.position.maxScrollExtent > 0) {
                scroll.position.jumpTo(scroll.position.maxScrollExtent);
                moved = true;
              }
            }
            if (moved) {
              await tester.pumpAndSettle();
              await expectLater(
                find.byKey(const ValueKey('scene')),
                matchesGoldenFile(
                  'projects_plus/${spec.id}_${tab}_${variant}_right.png',
                ),
              );
            }
          }
          final scrollable = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byKey(const ValueKey('projects-scroll')),
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
                'projects_plus/${spec.id}_${tab}_${variant}_bottom.png',
              ),
            );
          }
        });
      }
    }
  }
}
