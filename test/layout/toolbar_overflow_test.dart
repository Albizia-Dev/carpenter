import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('overflow menu opens without changing toolbar geometry', (
    tester,
  ) async {
    var invocations = 0;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 56,
          child: CarpenterToolbar(
            items: [
              CarpenterToolbarItem(
                group: CarpenterToolbarGroup.overflow,
                action: CarpenterActionDescriptor(
                  id: 'archive',
                  label: 'Archive',
                  onInvoke: () => invocations += 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final before = tester.getSize(find.byType(CarpenterToolbar));
    await tester.tap(find.bySemanticsLabel('Действия'));
    await tester.pumpAndSettle();

    expect(find.text('Archive'), findsOneWidget);
    expect(tester.getSize(find.byType(CarpenterToolbar)), before);

    await tester.tap(find.text('Archive'));
    await tester.pumpAndSettle();
    expect(invocations, 1);
    expect(tester.takeException(), isNull);
  });
}
