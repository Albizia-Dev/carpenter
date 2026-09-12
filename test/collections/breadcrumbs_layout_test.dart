import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets(
    'short paths retain first and current; empty and singleton are safe',
    (tester) async {
      for (final count in [0, 1, 2, 3]) {
        // Overlay.initialEntries is initial-only: recreate the host for each case.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          carpenterOverlayHarness(
            CarpenterBreadcrumbs(
              items: [
                for (var i = 0; i < count; i++)
                  CarpenterBreadcrumb(label: 'Item $i'),
              ],
            ),
          ),
        );
        for (var i = 0; i < count; i++) {
          expect(find.text('Item $i'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  for (final direction in TextDirection.values) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('one line at narrow width, $direction, scale $scale', (
        tester,
      ) async {
        for (final width in [0.0, 24.0, 80.0, 180.0, 420.0]) {
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpWidget(
            carpenterOverlayHarness(
              SizedBox(
                width: width,
                child: CarpenterBreadcrumbs(
                  maxVisibleItems: 6,
                  items: [
                    CarpenterBreadcrumb(
                      label: 'VeryLongUnbrokenWorkspaceTitle',
                      onInvoke: () {},
                    ),
                    CarpenterBreadcrumb(label: 'Projects', onInvoke: () {}),
                    CarpenterBreadcrumb(label: 'Documents', onInvoke: () {}),
                    const CarpenterBreadcrumb(
                      label:
                          '\u0422\u0435\u043a\u0443\u0449\u0430\u044f \u043f\u0430\u043f\u043a\u0430',
                    ),
                  ],
                ),
              ),
              direction: direction,
              textScale: scale,
            ),
          );
          expect(tester.takeException(), isNull, reason: 'width $width');
          final texts = tester.widgetList<Text>(
            find.descendant(
              of: find.byType(CarpenterBreadcrumbs),
              matching: find.byType(Text),
            ),
          );
          expect(
            texts.every((text) => text.maxLines == 1 && text.softWrap == false),
            isTrue,
          );
          final boxes = find.descendant(
            of: find.byType(CarpenterBreadcrumbs),
            matching: find.byType(Text),
          );
          final centers = [
            for (final element in boxes.evaluate())
              tester.getCenter(find.byWidget(element.widget)).dy,
          ];
          expect(centers.toSet().length, lessThanOrEqualTo(1));
        }
      });
    }
  }

  testWidgets('width, not only item count, collapses clickable ancestors', (
    tester,
  ) async {
    String? invoked;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 160,
          child: CarpenterBreadcrumbs(
            maxVisibleItems: 8,
            items: [
              CarpenterBreadcrumb(
                label: 'Workspace',
                onInvoke: () => invoked = 'workspace',
              ),
              CarpenterBreadcrumb(
                label: 'Long ancestor',
                onInvoke: () => invoked = 'ancestor',
              ),
              const CarpenterBreadcrumb(label: 'Current folder'),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Long ancestor'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Другие разделы'));
    await tester.pumpAndSettle();
    expect(find.text('Long ancestor'), findsOneWidget);
    await tester.tap(find.text('Long ancestor'));
    await tester.pumpAndSettle();
    expect(invoked, 'ancestor');
    expect(find.text('Long ancestor'), findsNothing);
  });

  testWidgets(
    'works inside intrinsic page header and dismisses menu with escape',
    (tester) async {
      await tester.pumpWidget(
        carpenterOverlayHarness(
          SizedBox(
            width: 380,
            child: CarpenterPageHeader(
              title: 'Project',
              breadcrumbs: CarpenterBreadcrumbs(
                items: [
                  CarpenterBreadcrumb(
                    label: 'A very long workspace name',
                    onInvoke: () {},
                  ),
                  CarpenterBreadcrumb(
                    label: 'Intermediate parent',
                    onInvoke: () {},
                  ),
                  const CarpenterBreadcrumb(label: 'Materials'),
                ],
              ),
              primaryActions: [
                CarpenterActionDescriptor(
                  id: 'refresh',
                  label: 'Refresh',
                  onInvoke: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.bySemanticsLabel('Другие разделы'));
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Intermediate parent'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
