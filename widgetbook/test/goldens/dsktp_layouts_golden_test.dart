import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/dsktp_layouts.dart';
import 'package:flutter_svg/flutter_svg.dart' show vg;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../test/helpers/golden_fonts.dart';

void main() {
  setUpAll(() => loadGoldenFonts('../test/goldens/fonts'));
  for (final scene in [
    'project',
    'materials',
    'project_edit',
    'materials_loading',
  ]) {
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
      (name: 'medium', size: const Size(768, 850), scale: 1.3, dark: false),
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
                    child: scene.startsWith('project')
                        ? const DsktpProjectLayout()
                        : DsktpMaterialsLayout(
                            loading: scene == 'materials_loading',
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
        if (scene == 'project_edit') {
          await tester.tap(find.bySemanticsLabel('Редактировать'));
          await tester.pump();
        }
        await tester.runAsync(() => vg.waitForPendingDecodes());
        await tester.pumpAndSettle();
        await expectLater(
          find.byKey(const ValueKey('scene')),
          matchesGoldenFile('images/${scene}_${variant.name}.png'),
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
}
