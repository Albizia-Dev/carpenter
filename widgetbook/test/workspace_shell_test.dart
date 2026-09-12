import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/use_cases/samples/workspace/catalog.dart';
import 'package:carpenter_widgetbook/use_cases/samples/workspace/scenarios.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final scene in workspaceScenarioLabels.keys) {
    testWidgets('workspace $scene renders in wide and narrow dark hosts', (
      tester,
    ) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final narrow in [false, true]) {
        final size = narrow ? const Size(390, 844) : const Size(1440, 900);
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          UnitsRoot(
            rem: const Px(16),
            child: CarpenterTheme(
              data: narrow
                  ? CarpenterThemeData.dark()
                  : CarpenterThemeData.light(),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    disableAnimations: true,
                    textScaler: TextScaler.linear(scene == 'large' ? 2 : 1),
                  ),
                  child: DefaultTextStyle(
                    style: const TextStyle(),
                    child: Overlay(
                      initialEntries: [
                        OverlayEntry(
                          builder: (_) => WorkspaceShellPreview(
                            key: ValueKey('$scene.$narrow'),
                            scenario: scene,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        // Loading scenes intentionally keep progress animations alive.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(tester.takeException(), isNull, reason: '$scene at $size');
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
