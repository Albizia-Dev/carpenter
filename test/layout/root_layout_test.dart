import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('expanded sidebar shows platform shortcut and selection', (
    tester,
  ) async {
    final command = CarpenterCommandController<void>(
      id: 'payments',
      title: 'Payments',
      shortcuts: const [
        SingleActivator(LogicalKeyboardKey.keyP, control: true),
      ],
    );
    addTearDown(command.dispose);

    await tester.pumpWidget(
      _harness(
        width: 360,
        child: CarpenterSidebar(
          targetPlatform: TargetPlatform.macOS,
          expanded: true,
          data: CarpenterSidebarData(
            selectedId: 'payments',
            sections: [
              CarpenterSidebarSection(
                items: [
                  CarpenterSidebarItem(
                    id: 'payments',
                    label: 'Payments',
                    icon: CarpenterIcons.paymentCard,
                    command: command,
                    onInvoke: _noop,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('⌘P'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(CarpenterSidebar)),
      matchesSemantics(label: 'Primary navigation'),
    );
  });

  testWidgets('desktop keeps one docked sidebar and can collapse it', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_harness(width: 1280, child: const _RootHarness()));
    expect(find.byType(CarpenterSidebar), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Toggle compact navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(CarpenterSidebar), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
    expect(find.bySemanticsLabel('Overview'), findsWidgets);
  });

  testWidgets('tablet overlay does not reflow the compact base layout', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(width: 768, child: const _RootHarness()));
    final closedBodySize = tester.getSize(find.byKey(const Key('root-body')));
    expect(find.byType(CarpenterSidebar), findsOneWidget);
    expect(find.text('Overview'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Open navigation'));
    await tester.pumpAndSettle();

    expect(find.byType(CarpenterSidebar), findsNWidgets(2));
    expect(find.text('Overview'), findsOneWidget);
    expect(tester.getSize(find.byKey(const Key('root-body'))), closedBodySize);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterSidebar), findsOneWidget);
  });

  testWidgets('mobile opens one drawer without reserving navigation width', (
    tester,
  ) async {
    await tester.pumpWidget(_harness(width: 390, child: const _RootHarness()));
    expect(find.byType(CarpenterSidebar), findsNothing);
    expect(tester.getSize(find.byKey(const Key('root-body'))).width, 390);

    await tester.tap(find.bySemanticsLabel('Open navigation'));
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterSidebar), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);

    await tester.tap(find.text('Payments'));
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterSidebar), findsNothing);
    expect(find.text('Selected: payments'), findsOneWidget);
  });

  testWidgets('root layout orders header before page content', (tester) async {
    await tester.pumpWidget(_harness(width: 1280, child: const _RootHarness()));
    final header = tester.getRect(find.text('Workspace'));
    final body = tester.getRect(find.byKey(const Key('root-body')));
    expect(header.top, lessThan(body.top));
  });
}

final class _RootHarness extends StatefulWidget {
  const _RootHarness();

  @override
  State<_RootHarness> createState() => _RootHarnessState();
}

final class _RootHarnessState extends State<_RootHarness> {
  var _open = false;
  var _expanded = true;
  var _selected = 'overview';

  CarpenterSidebarData get _sidebar => CarpenterSidebarData(
    selectedId: _selected,
    onSelected: (id) => setState(() => _selected = id),
    sections: [
      CarpenterSidebarSection(
        items: [
          CarpenterSidebarItem(
            id: 'overview',
            label: 'Overview',
            icon: CarpenterIcons.list,
            onInvoke: _noop,
          ),
          CarpenterSidebarItem(
            id: 'payments',
            label: 'Payments',
            icon: CarpenterIcons.paymentCard,
            onInvoke: _noop,
          ),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => CarpenterRootLayout(
    sidebar: _sidebar,
    sidebarOpen: _open,
    onSidebarOpenChanged: (value) => setState(() => _open = value),
    sidebarExpanded: _expanded,
    onSidebarExpandedChanged: (value) => setState(() => _expanded = value),
    headerBuilder: (context, layout) => CarpenterTopPanel(
      title: 'Workspace',
      leading: CarpenterIconButton(
        icon: CarpenterIcons.list,
        semanticLabel: layout.isDesktop
            ? 'Toggle compact navigation'
            : 'Open navigation',
        prominence: ActionProminence.ghost,
        onPressed: layout.isDesktop
            ? layout.toggleSidebarExpanded
            : layout.toggleSidebar,
      ),
    ),
    body: SizedBox.expand(
      key: const Key('root-body'),
      child: Center(child: Text('Selected: $_selected')),
    ),
  );
}

Widget _harness({required double width, required Widget child}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: const MediaQueryData(size: Size(1400, 900)),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: CarpenterCapabilityScope(
          capabilities: CarpenterInputCapabilities.pointerOriented,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, height: 700, child: child),
          ),
        ),
      ),
    ),
  ),
);

void _noop() {}
