import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('secondary pointer press opens semantic context actions', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterContextActionRegion(
          actions: [
            CarpenterActionDescriptor(
              id: 'rename',
              label: 'Rename',
              onInvoke: () => invoked = true,
            ),
          ],
          child: const SizedBox(width: 160, height: 48),
        ),
      ),
    );

    final target = find.byType(CarpenterContextActionRegion);
    final gesture = await tester.startGesture(
      tester.getCenter(target),
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Rename'), findsOneWidget);
    await tester.tap(find.text('Rename'));
    expect(invoked, isTrue);
  });

  testWidgets('long press opens the same semantic context actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterContextActionRegion(
          actions: const [
            CarpenterActionDescriptor(
              id: 'download',
              label: 'Download',
              onInvoke: null,
            ),
          ],
          child: const SizedBox(width: 160, height: 48),
        ),
      ),
    );

    await tester.longPress(find.byType(CarpenterContextActionRegion));
    await tester.pumpAndSettle();

    expect(find.text('Download'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
