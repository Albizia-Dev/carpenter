import 'package:carpenter_example/demo_routes.dart';
import 'package:carpenter_example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _pumpExample(WidgetTester tester, {Uri? initialUri}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    CarpenterExampleApp(
      syncRouteInformation: false,
      initialUri: initialUri,
    ),
  );
  await _pumpFrames(tester);
}

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

  testWidgets('sidebar navigation executes the same route commands', (
    tester,
  ) async {
    await _pumpExample(tester);

    expect(find.text('Active projects'), findsOneWidget);
    expect(find.text('Overview'), findsWidgets);

    await tester.tap(find.text('Projects').first);
    await _pumpFrames(tester);
    expect(find.text('Project portfolio'), findsOneWidget);

    await tester.tap(find.text('Planning').first);
    await _pumpFrames(tester);
    expect(find.text('Delivery planning'), findsOneWidget);
  });

  testWidgets('planning route renders reorder and kanban surfaces', (
    tester,
  ) async {
    await _pumpExample(tester, initialUri: Uri(path: '/planning'));

    expect(find.text('Delivery planning'), findsOneWidget);
    expect(find.text('Triage order'), findsOneWidget);
    expect(find.text('Backlog'), findsWidgets);
  });

  testWidgets('explorer route renders the controlled resource tree', (
    tester,
  ) async {
    await _pumpExample(tester, initialUri: Uri(path: '/explorer'));

    expect(find.text('Resource explorer'), findsOneWidget);
    expect(find.text('Finance'), findsWidgets);
    expect(find.text('Bank accounts'), findsWidgets);
  });

  testWidgets('settings route renders typed and masked fields', (tester) async {
    await _pumpExample(tester, initialUri: Uri(path: '/settings'));

    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Display name'), findsOneWidget);
    expect(find.text('Workspace code'), findsOneWidget);
  });

  testWidgets('deep project URL renders through yx navigation', (tester) async {
    await _pumpExample(tester, initialUri: Uri(path: '/projects/CP-1042'));

    expect(find.text('Treasury migration'), findsWidgets);
    expect(find.text('CP-1042 · Finance platform'), findsOneWidget);
    expect(find.text('Timeline'), findsOneWidget);
    expect(find.text('Projects'), findsWidgets);
  });
}
