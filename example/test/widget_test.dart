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
    expect(DemoRoutes.parse(Uri(path: '/settings')).route, DemoRoutes.settings);
  });

  testWidgets('example navigates between application pages', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const CarpenterExampleApp(syncRouteInformation: false),
    );
    await tester.pump();

    expect(find.text('Active projects'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);

    await tester.tap(find.text('Projects').first);
    await tester.pump();
    expect(find.text('Project portfolio'), findsOneWidget);

    await tester.tap(find.text('Open featured').first);
    await tester.pump();
    expect(find.text('Treasury migration'), findsWidgets);
    expect(find.text('Timeline'), findsOneWidget);

    await tester.tap(find.text('Operations').first);
    await tester.pump();
    expect(find.text('Operations lab'), findsOneWidget);
    expect(find.text('Global command hotkeys'), findsOneWidget);
  });
}
