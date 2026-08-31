import 'package:carpenter_example/demo_routes.dart';
import 'package:carpenter_example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo routes parse and serialize stable URLs', () {
    final detail = DemoRoutes.parse(Uri(path: '/projects/CP-1047'));
    expect(detail.route, DemoRoutes.project);
    expect(detail.arguments['id'], 'CP-1047');
    expect(DemoRoutes.serialize(detail).path, '/projects/CP-1047');
    expect(DemoRoutes.parse(Uri(path: '/planning')).route, DemoRoutes.planning);
    expect(DemoRoutes.parse(Uri(path: '/explorer')).route, DemoRoutes.explorer);
    expect(DemoRoutes.parse(Uri(path: '/settings')).route, DemoRoutes.settings);
  });

  testWidgets('sidebar navigates across real feature surfaces', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const CarpenterExampleApp(syncRouteInformation: false),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active projects'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);

    await tester.tap(find.text('Projects').first);
    await tester.pumpAndSettle();
    expect(find.text('Project portfolio'), findsOneWidget);

    await tester.tap(find.text('Planning').first);
    await tester.pumpAndSettle();
    expect(find.text('Delivery planning'), findsOneWidget);
    expect(find.text('Triage order'), findsOneWidget);

    await tester.tap(find.text('Explorer').first);
    await tester.pumpAndSettle();
    expect(find.text('Resource explorer'), findsOneWidget);
    expect(find.text('Bank accounts'), findsWidgets);

    await tester.tap(find.text('Operations').first);
    await tester.pumpAndSettle();
    expect(find.text('Operations lab'), findsOneWidget);
    expect(find.text('Global command hotkeys'), findsOneWidget);

    await tester.tap(find.text('Settings').first);
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Workspace code'), findsOneWidget);
  });

  testWidgets('deep project URL renders through yx navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      CarpenterExampleApp(
        syncRouteInformation: false,
        initialUri: Uri(path: '/projects/CP-1042'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Treasury migration'), findsWidgets);
    expect(find.text('CP-1042 · Finance platform'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
  });
}
