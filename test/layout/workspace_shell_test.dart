import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('drawer consumes Escape, preserves editor and restores focus', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var outerEscapes = 0;
    var mounts = 0;
    await tester.pumpWidget(
      _host(
        CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                outerEscapes++,
          },
          child: _ShellProbe(onMount: () => mounts++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Черновик');
    final editorState = tester.state(find.byType(EditableText));
    await tester.tap(find.bySemanticsLabel('Открыть навигацию'));
    await tester.pumpAndSettle();
    expect(mounts, 1);
    expect(tester.state(find.byType(EditableText)), same(editorState));
    expect(find.bySemanticsLabel('Закрыть навигацию'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(outerEscapes, 0);
    expect(mounts, 1);
    expect(find.text('Черновик'), findsOneWidget);
    expect(find.bySemanticsLabel('Закрыть навигацию'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page survives compact preference and breakpoint changes', (
    tester,
  ) async {
    var mounts = 0;
    await tester.binding.setSurfaceSize(const Size(1400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_host(_ShellProbe(onMount: () => mounts++)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'Сохранить при resize');
    await tester.tap(find.bySemanticsLabel('Свернуть навигацию'));
    await tester.pumpAndSettle();
    for (final size in [
      const Size(820, 900),
      const Size(390, 844),
      const Size(1400, 900),
    ]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpAndSettle();
      expect(mounts, 1);
      expect(find.text('Сохранить при resize'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets(
    'all header actions survive narrow width, RTL and enlarged text',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final dark in [false, true]) {
        await tester.binding.setSurfaceSize(const Size(320, 740));
        await tester.pumpWidget(
          _host(
            const _ShellProbe(),
            dark: dark,
            scale: 2,
            direction: TextDirection.rtl,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.bySemanticsLabel('Мой профиль'), findsOneWidget);
        expect(find.bySemanticsLabel('Входящие'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.bySemanticsLabel('Открыть навигацию'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'palette skips unavailable destinations and invokes focused result once',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      final selected = <String>[];
      await tester.pumpWidget(
        _host(
          Center(
            child: SizedBox(
              width: 500,
              height: 400,
              child: CarpenterNavigationPalette(
                controller: controller,
                onQueryChanged: (_) {},
                onSelected: selected.add,
                destinations: const [
                  CarpenterNavigationDestination(
                    id: 'a',
                    label: 'Первый',
                    icon: GravityIcons.folder,
                  ),
                  CarpenterNavigationDestination(
                    id: 'b',
                    label: 'Недоступен',
                    icon: GravityIcons.folder,
                    enabled: false,
                    disabledReason: 'Нет доступа',
                  ),
                  CarpenterNavigationDestination(
                    id: 'c',
                    label: 'Третий',
                    description: 'Другой контур',
                    icon: GravityIcons.folder,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(selected, ['c']);
      expect(tester.takeException(), isNull);
    },
  );
}

class _ShellProbe extends StatefulWidget {
  const _ShellProbe({this.onMount});
  final VoidCallback? onMount;
  @override
  State<_ShellProbe> createState() => _ShellProbeState();
}

class _ShellProbeState extends State<_ShellProbe> {
  bool open = false, expanded = true;
  @override
  Widget build(BuildContext context) => CarpenterWorkspaceShell(
    applicationLabel: 'Okibi · Fermat',
    workspaceLabel: 'Казначейство',
    onWorkspacePressed: () {},
    sidebarOpen: open,
    onSidebarOpenChanged: (v) => setState(() => open = v),
    sidebarExpanded: expanded,
    onSidebarExpandedChanged: (v) => setState(() => expanded = v),
    actions: [
      CarpenterIconButton(
        icon: GravityIcons.bell,
        semanticLabel: 'Входящие',
        onPressed: () {},
      ),
      CarpenterIconButton(
        icon: GravityIcons.person,
        semanticLabel: 'Мой профиль',
        onPressed: () {},
      ),
    ],
    navigation: CarpenterSidebarData(
      selectedId: 'payments',
      onSelected: (_) {},
      sections: const [
        CarpenterSidebarSection(
          items: [
            CarpenterSidebarItem(
              id: 'payments',
              label: 'Платежи',
              icon: GravityIcons.creditCard,
            ),
          ],
        ),
      ],
    ),
    body: _EditorProbe(onMount: widget.onMount),
  );
}

class _EditorProbe extends StatefulWidget {
  const _EditorProbe({this.onMount});
  final VoidCallback? onMount;
  @override
  State<_EditorProbe> createState() => _EditorProbeState();
}

class _EditorProbeState extends State<_EditorProbe> {
  final controller = TextEditingController();
  @override
  void initState() {
    super.initState();
    widget.onMount?.call();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: CarpenterInput(controller: controller, label: 'Редактор'),
  );
}

Widget _host(
  Widget child, {
  bool dark = false,
  double scale = 1,
  TextDirection direction = TextDirection.ltr,
}) => WidgetsApp(
  color: const Color(0xff000000),
  pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
    settings: settings,
    pageBuilder: (context, _, _) => builder(context),
  ),
  home: UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: dark ? CarpenterThemeData.dark() : CarpenterThemeData.light(),
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Directionality(
            textDirection: direction,
            child: DefaultTextStyle(style: const TextStyle(), child: child),
          ),
        ),
      ),
    ),
  ),
);
