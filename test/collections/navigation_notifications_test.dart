import 'package:carpenter/carpenter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('breadcrumbs invoke visible navigation and collapse long paths', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterBreadcrumbs(
          maxVisibleItems: 3,
          items: [
            CarpenterBreadcrumb(label: 'Home', onInvoke: () => invoked = true),
            CarpenterBreadcrumb(label: 'Area', onInvoke: () {}),
            CarpenterBreadcrumb(label: 'Section', onInvoke: () {}),
            CarpenterBreadcrumb(label: 'Object', onInvoke: () {}),
            const CarpenterBreadcrumb(label: 'Current'),
          ],
        ),
      ),
    );

    expect(find.text('Current'), findsOneWidget);
    expect(find.bySemanticsLabel('More breadcrumb items'), findsOneWidget);
    await tester.tap(find.text('Home'));
    expect(invoked, isTrue);
  });

  testWidgets('notification list delegates dismiss and renders unread state', (
    tester,
  ) async {
    Object? dismissed;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterNotificationList(
          items: const [
            CarpenterNotification(
              id: 'n1',
              title: 'Import complete',
              message: 'Three items require review.',
              unread: true,
              tone: FeedbackColorRole.warning,
            ),
          ],
          onDismiss: (id) => dismissed = id,
        ),
      ),
    );

    expect(find.text('New'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    expect(dismissed, 'n1');
  });

  testWidgets('notification list has a deterministic empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(const CarpenterNotificationList(items: [])),
    );
    expect(find.text('No notifications'), findsOneWidget);
  });
}
