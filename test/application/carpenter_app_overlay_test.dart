import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yx_navigation/yx_navigation.dart';

void main() {
  testWidgets('internal Carpenter routes provide an Overlay ancestor', (
    tester,
  ) async {
    const route = YxRoute(id: 'dialog');
    final navigation = RouteNodeStateManager(routeNode: route.toNode());
    addTearDown(navigation.close);

    await tester.pumpWidget(
      CarpenterApp(
        shells: [CarpenterRouterShell(navigation: navigation)],
        routes: [
          CarpenterRoute(
            route: route,
            page: (context) => CarpenterDialog(
              open: true,
              onOpenChanged: (_) {},
              title: 'Overlay works',
              content: const CarpenterText.body('Dialog content'),
              child: const SizedBox(key: Key('route-content')),
            ),
          ),
        ],
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('route-content')), findsOneWidget);
    expect(find.text('Overlay works'), findsOneWidget);
    expect(find.text('Dialog content'), findsOneWidget);
  });
}
