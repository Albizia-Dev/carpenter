import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as widgets show Text;

import 'package:carpenter/carpenter_older.dart';

Finder _findText(String value) => find.byWidgetPredicate(
  (widget) =>
      (widget is widgets.Text &&
          widget is! CarpenterText &&
          widget.data == value) ||
      (widget is EditableText && widget.controller.text == value),
);

void main() {
  test('CarpenterColorPicker разбирает короткий и полный RGB HEX', () {
    expect(carpenterParseRgbColor('#0f8'), const Color(0xFF00FF88));
    expect(carpenterParseRgbColor('12ABEF'), const Color(0xFF12ABEF));
    expect(carpenterParseRgbColor('#abcd'), isNull);
    expect(carpenterFormatRgbHex(const Color(0xFF0A1B2C)), '#0A1B2C');
  });

  testWidgets('CarpenterColorPicker принимает HEX и синхронизирует RGB', (
    tester,
  ) async {
    Color? changed;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 520,
            child: CarpenterColorPicker(
              value: const Color(0xFF356AE6),
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(EditableText).first, '#0f8');
    await tester.pump();

    expect(changed, const Color(0xFF00FF88));
    final fields = tester
        .widgetList<EditableText>(find.byType(EditableText))
        .map((field) => field.controller.text)
        .toList();
    expect(fields, ['#0f8', '0', '255', '136']);
  });

  test('CarpenterFace строится из конфига и считает rem', () {
    const config = CarpenterConfig(rem: 10, density: 1.5);
    final carpenter = Carpenter.fromConfig(config);

    expect(carpenter.face.rem(2), 30);
    expect(carpenter.rem(2), 30);
    expect(carpenter.face.color('action.primary'), isNotNull);
    expect(carpenter.face.radius('control'), carpenter.face.radius('md'));
  });

  test('CarpenterFace принимает dynamic color/type/dimension tokens', () {
    const customAction = Color(0xFF123456);
    const customPaletteStep = Color(0xFFABCDEF);
    final carpenter = Carpenter.fromConfig(
      CarpenterConfig(
        color: CarpenterColorConfig(
          palette: CarpenterPaletteConfig(
            scales: {
              'brand': CarpenterColorScaleConfig.seed(
                Color(0xFF006ADC),
                steps: ['soft', 'solid', 'contrast'],
                overrides: {'solid': customPaletteStep},
              ),
              'primary': CarpenterColorScaleConfig.seed(Color(0xFF006ADC)),
              'accent': CarpenterColorScaleConfig.seed(Color(0xFF7C5CFF)),
              'neutral': CarpenterColorScaleConfig.seed(
                Color(0xFF006ADC),
                neutral: true,
              ),
              'success': CarpenterColorScaleConfig.seed(Color(0xFF12A150)),
              'warning': CarpenterColorScaleConfig.seed(Color(0xFFE6A700)),
              'danger': CarpenterColorScaleConfig.seed(Color(0xFFD92D20)),
              'info': CarpenterColorScaleConfig.seed(Color(0xFF2563EB)),
            },
          ),
          semantic: {'action.primary': customAction},
        ),
        type: const CarpenterTypeConfig(
          fontFamily: 'Arial',
          secondaryFontFamily: 'Arial',
          tokens: {'display.hero': TextStyle(fontSize: 42)},
        ),
        dimension: const CarpenterDimensionConfig(
          rem: 10,
          density: 2,
          space: {'gutter.tight': 7},
          radius: {'control': 11},
          size: {'avatar.hero': 80},
          tokens: {'layout.sidebar': 280},
        ),
      ),
    );

    expect(carpenter.face.color('action.primary'), customAction);
    expect(carpenter.face.color.palette('brand')('solid'), customPaletteStep);
    expect(carpenter.face.type('display.hero').fontSize, 42);
    expect(carpenter.face.type('body').fontFamily, 'Arial');
    expect(carpenter.face.type.secondary('body').fontFamily, 'Arial');
    expect(carpenter.face.type.secondary('display.hero').fontFamily, 'Arial');
    expect(carpenter.face.space('gutter.tight'), 7);
    expect(carpenter.face.radius('control'), 11);
    expect(carpenter.face.size('avatar.hero'), 80);
    expect(carpenter.face.dimension('layout.sidebar'), 280);
    expect(carpenter.face.rem(1), 20);
  });

  testWidgets('CarpenterScope отдает Face через BuildContext', (tester) async {
    late CarpenterFace face;

    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Builder(
          builder: (context) {
            face = context.face;
            return const SizedBox();
          },
        ),
      ),
    );

    expect(face.rem(1), 16);
  });

  testWidgets('Базовые компоненты строятся внутри CarpenterScope', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              CarpenterText('Text'),
              CarpenterIcon(IconData(0x2713)),
              CarpenterTag(label: 'Tag'),
              CarpenterProgress(value: 0.5),
              CarpenterLoader(),
              CarpenterCard(child: CarpenterText('Card')),
              CarpenterButton(label: 'Button'),
              CarpenterAvatar(initials: 'RR'),
              CarpenterLink(label: 'Link'),
              CarpenterCheckbox(value: true, label: 'Checkbox'),
              CarpenterSwitch(value: true, label: 'Switch'),
              CarpenterRadio<String>(
                value: 'a',
                groupValue: 'a',
                label: 'Radio',
              ),
              CarpenterSegmentedRadio<String>(
                value: 'a',
                options: [
                  CarpenterSegmentedOption(value: 'a', label: 'A'),
                  CarpenterSegmentedOption(value: 'b', label: 'B'),
                ],
              ),
              CarpenterInput(label: 'Input', initialValue: 'Value'),
              CarpenterHotkeyScope(
                commands: [
                  CarpenterHotkeyCommand(
                    id: 'save',
                    title: 'Save',
                    macOSActivators: [
                      SingleActivator(LogicalKeyboardKey.keyS, meta: true),
                    ],
                  ),
                ],
                child: CarpenterHotkeyDisplay(showCommands: false),
              ),
            ],
          ),
        ),
      ),
    );

    expect(_findText('Text'), findsOneWidget);
    expect(_findText('Tag'), findsOneWidget);
    expect(_findText('Card'), findsOneWidget);
    expect(_findText('Button'), findsOneWidget);
    expect(_findText('Link'), findsOneWidget);
    expect(_findText('Checkbox'), findsOneWidget);
    expect(_findText('Switch'), findsOneWidget);
    expect(_findText('Radio'), findsOneWidget);
    expect(_findText('Input'), findsOneWidget);
    expect(_findText('Value'), findsOneWidget);
    expect(_findText('Hotkeys'), findsOneWidget);
  });

  testWidgets('CarpenterInput поддерживает скрытый ввод', (tester) async {
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterInput(initialValue: 'secret', obscureText: true),
        ),
      ),
    );

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.obscureText, isTrue);
    expect(editable.obscuringCharacter, '•');
  });

  testWidgets('CarpenterInput выделяет текст мышью', (tester) async {
    final controller = TextEditingController(text: 'alpha beta gamma');
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 320,
              child: CarpenterInput(controller: controller),
            ),
          ),
        ),
      ),
    );

    final editable = find.byType(EditableText);
    final rect = tester.getRect(editable);
    final gesture = await tester.startGesture(
      Offset(rect.left + 4, rect.center.dy),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(Offset(rect.left + 90, rect.center.dy));
    await gesture.up();
    await tester.pump();

    expect(controller.selection.isCollapsed, isFalse);
    expect(controller.selection.end, greaterThan(controller.selection.start));
    controller.dispose();
  });

  testWidgets('CarpenterInput расширяет выделение с Shift', (tester) async {
    final controller = TextEditingController(text: 'abcdef');
    final focusNode = FocusNode();
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterInput(controller: controller, focusNode: focusNode),
        ),
      ),
    );

    focusNode.requestFocus();
    controller.selection = const TextSelection.collapsed(offset: 6);
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();

    expect(
      controller.selection,
      const TextSelection(baseOffset: 6, extentOffset: 5),
    );
    focusNode.dispose();
    controller.dispose();
  });

  test('CarpenterHotkeyFormatter учитывает платформенные модификаторы', () {
    const macFormatter = CarpenterHotkeyFormatter(
      platform: TargetPlatform.macOS,
    );
    const linuxFormatter = CarpenterHotkeyFormatter(
      platform: TargetPlatform.linux,
    );

    expect(
      macFormatter.formatActivator(
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true),
      ),
      '⌘K',
    );
    expect(
      linuxFormatter.formatActivator(
        const SingleActivator(LogicalKeyboardKey.keyK, control: true),
      ),
      'Ctrl+K',
    );
  });

  test('macOS заменяет Ctrl на Command, сохраняя Alt как Option', () {
    final command = CarpenterHotkeyCommand(
      id: 'settings',
      title: 'Settings',
      activators: [
        SingleActivator(LogicalKeyboardKey.period, control: true, alt: true),
      ],
    );

    final mac =
        command.activatorsFor(TargetPlatform.macOS).single as SingleActivator;
    final windows =
        command.activatorsFor(TargetPlatform.windows).single as SingleActivator;

    expect(mac.control, isFalse);
    expect(mac.meta, isTrue);
    expect(mac.alt, isTrue);
    expect(windows.control, isTrue);
    expect(windows.meta, isFalse);
  });

  testWidgets('CarpenterHotkeyScope показывает текущую нажатую клавишу', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterHotkeyScope(
            platform: TargetPlatform.macOS,
            child: CarpenterHotkeyDisplay(
              title: 'Keyboard',
              emptyLabel: 'Press any key',
              showCommands: false,
            ),
          ),
        ),
      ),
    );

    expect(_findText('Press any key'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();

    expect(_findText('A'), findsWidgets);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
    await tester.pumpAndSettle();

    expect(_findText('Press any key'), findsOneWidget);
  });

  testWidgets('CarpenterHotkeyScope вызывает команду через Shortcuts/Actions', (
    tester,
  ) async {
    String? invokedCommandId;

    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterHotkeyScope(
            platform: TargetPlatform.macOS,
            commands: [
              CarpenterHotkeyCommand(
                id: 'theme.toggle',
                title: 'Toggle theme',
                macOSActivators: [
                  SingleActivator(
                    LogicalKeyboardKey.keyD,
                    meta: true,
                    shift: true,
                  ),
                ],
              ),
            ],
            onCommand: (command) {
              invokedCommandId = command.id;
            },
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyD);
    await tester.pump();

    expect(invokedCommandId, 'theme.toggle');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyD);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  });

  testWidgets(
    'вложенный CarpenterHotkeyScope передает родительскую команду наружу',
    (tester) async {
      final invokedCommandIds = <String>[];
      final backCommand = CarpenterHotkeyCommand(
        id: 'navigation.back',
        title: 'Back',
        activators: [SingleActivator(LogicalKeyboardKey.escape)],
      );
      final createCommand = CarpenterHotkeyCommand(
        id: 'allocation.create',
        title: 'Create allocation',
        activators: [SingleActivator(LogicalKeyboardKey.enter)],
      );

      await tester.pumpWidget(
        CarpenterScope.fromConfig(
          config: const CarpenterConfig(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CarpenterHotkeyScope(
              commands: [backCommand],
              autofocus: false,
              onCommand: (command) => invokedCommandIds.add(command.id),
              child: CarpenterHotkeyScope(
                commands: [createCommand],
                onCommand: (command) => invokedCommandIds.add(command.id),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(invokedCommandIds, ['navigation.back', 'allocation.create']);
    },
  );

  testWidgets('CarpenterApp собирает runtime, frame и hotkeys', (tester) async {
    String? invokedCommandId;

    await tester.pumpWidget(
      CarpenterApp(
        config: const CarpenterConfig(),
        platform: TargetPlatform.macOS,
        commands: [
          CarpenterHotkeyCommand(
            id: 'file.save',
            title: 'Save',
            macOSActivators: [
              SingleActivator(LogicalKeyboardKey.keyS, meta: true),
            ],
          ),
        ],
        onHotkeyCommand: (command) {
          invokedCommandId = command.id;
        },
        topPanelBuilder: (context, panel) {
          return const CarpenterTopPanel(title: 'App panel');
        },
        child: Builder(
          builder: (context) {
            final face = context.face;

            return CarpenterText(
              'App body ${face.rem(1).round()}',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      ),
    );

    expect(_findText('App panel'), findsOneWidget);
    expect(_findText('App body 16'), findsOneWidget);

    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyS);
    await tester.pump();

    expect(invokedCommandId, 'file.save');

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  });

  testWidgets('CarpenterHost подключает runtime без владения WidgetsApp', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterHost(
        config: const CarpenterConfig(rem: 12),
        shells: const [_HostCapabilityShell()],
        child: Builder(
          builder: (context) {
            final capability = context.runtime.read<_SecondTestCapability>();
            return CarpenterText(
              '${capability.value} ${context.face.rem(1).round()}',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      ),
    );

    expect(find.byType(WidgetsApp), findsNothing);
    expect(_findText('host capability 12'), findsOneWidget);
  });

  testWidgets('CarpenterApp рендерит yx route tree через modules', (
    tester,
  ) async {
    const rootRoute = YxRoute(id: 'root');
    const dashboardRoute = YxRoute(id: 'dashboard');
    const detailsRoute = YxRoute(id: 'details');
    final navigation = RouteNodeStateManager(
      routeNode: rootRoute.toNode(children: [dashboardRoute.toNode()]),
    );

    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        shells: [CarpenterRouterShell(navigation: navigation)],
        modules: [
          _TestModule(
            rootRoute: rootRoute,
            dashboardRoute: dashboardRoute,
            detailsRoute: detailsRoute,
          ),
        ],
      ),
    );

    expect(_findText('Root shell: dashboard'), findsOneWidget);
    expect(_findText('Dashboard page'), findsOneWidget);

    navigation.mutate((root) {
      root.setChildren([
        detailsRoute.toNode(arguments: {'id': '42'}),
      ]);
      return root;
    });
    await tester.pumpAndSettle();

    expect(_findText('Root shell: details'), findsOneWidget);
    expect(_findText('Details page 42'), findsOneWidget);

    await navigation.close();
  });

  testWidgets('CarpenterApp валидирует shell dependencies', (tester) async {
    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        shells: const [_NeedsTestCapabilityShell()],
        child: const SizedBox(),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('_TestCapability'));
  });

  testWidgets('CarpenterApp валидирует module dependencies', (tester) async {
    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        modules: const [_NeedsTestCapabilityModule()],
        child: const SizedBox(),
      ),
    );

    final error = tester.takeException();
    expect(error, isA<StateError>());
    expect(error.toString(), contains('_TestCapability'));
  });

  testWidgets('Shell pipeline расширяет typed runtime слева направо', (
    tester,
  ) async {
    final events = <String>[];

    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        shells: [
          _ProvidesTestCapabilityShell(events),
          _RequiresTestCapabilityShell(events),
        ],
        child: Builder(
          builder: (context) {
            final message = context.runtime.read<_SecondTestCapability>().value;

            return CarpenterText(message, textDirection: TextDirection.ltr);
          },
        ),
      ),
    );

    expect(events, ['provide-first', 'configure-second', 'wrap-first']);
    expect(_findText('second sees first'), findsOneWidget);
  });

  testWidgets('Module shell capabilities доступны routes модуля', (
    tester,
  ) async {
    const rootRoute = YxRoute(id: 'root');
    final navigation = RouteNodeStateManager(routeNode: rootRoute.toNode());

    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        shells: [CarpenterRouterShell(navigation: navigation)],
        modules: [_CapabilityModule(route: rootRoute)],
      ),
    );

    expect(_findText('module capability'), findsOneWidget);

    await navigation.close();
  });

  testWidgets('Route scope наследуется shell и page', (tester) async {
    const rootRoute = YxRoute(id: 'root');
    const childRoute = YxRoute(id: 'child');
    final navigation = RouteNodeStateManager(
      routeNode: rootRoute.toNode(children: [childRoute.toNode()]),
    );

    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        shells: [CarpenterRouterShell(navigation: navigation)],
        routes: [
          CarpenterRoute(
            route: rootRoute,
            scope: (_, child) =>
                _InheritedLabel(label: 'root-scope', child: child),
            shell: (_, child) {
              return Builder(
                builder: (context) {
                  return Column(
                    textDirection: TextDirection.ltr,
                    children: [
                      CarpenterText(
                        'shell sees ${_InheritedLabel.of(context)}',
                      ),
                      child,
                    ],
                  );
                },
              );
            },
            children: [
              CarpenterRoute(
                route: childRoute,
                page: (_) {
                  return Builder(
                    builder: (context) {
                      return CarpenterText(
                        'page sees ${_InheritedLabel.of(context)}',
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );

    expect(_findText('shell sees root-scope'), findsOneWidget);
    expect(_findText('page sees root-scope'), findsOneWidget);

    await navigation.close();
  });

  testWidgets('HotkeyShell может дергать router через runtime', (tester) async {
    const rootRoute = YxRoute(id: 'root');
    const homeRoute = YxRoute(id: 'home');
    const commandRoute = YxRoute(id: 'command');
    final navigation = RouteNodeStateManager(
      routeNode: rootRoute.toNode(children: [homeRoute.toNode()]),
    );

    await tester.pumpWidget(
      CarpenterApp(
        useFrame: false,
        platform: TargetPlatform.macOS,
        shells: [
          CarpenterRouterShell(navigation: navigation),
          CarpenterHotkeyShell(
            platform: TargetPlatform.macOS,
            commands: [
              CarpenterHotkeyCommand(
                id: 'go.command',
                title: 'Go command',
                macOSActivators: [
                  SingleActivator(LogicalKeyboardKey.keyG, meta: true),
                ],
              ),
            ],
            onCommand: (runtime, command) {
              runtime.router.navigation.mutate((root) {
                root.setChildren([commandRoute.toNode()]);
                return root;
              });
            },
          ),
        ],
        routes: [
          CarpenterRoute(
            route: rootRoute,
            children: [
              CarpenterRoute(
                route: homeRoute,
                page: (_) => const CarpenterText('Home page'),
              ),
              CarpenterRoute(
                route: commandRoute,
                page: (_) => const CarpenterText('Command page'),
              ),
            ],
          ),
        ],
      ),
    );

    expect(_findText('Home page'), findsOneWidget);

    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyG);
    await tester.pumpAndSettle();

    expect(_findText('Command page'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyG);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await navigation.close();
  });

  testWidgets('CarpenterAppFrame выбирает desktop top panel override', (
    tester,
  ) async {
    Future<void> pump(TargetPlatform platform) {
      return tester.pumpWidget(
        CarpenterScope.fromConfig(
          config: const CarpenterConfig(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: CarpenterAppFrame(
              targetPlatform: platform,
              topPanelBuilder: (context, panel) {
                return const CarpenterTopPanel(title: 'Touch panel');
              },
              desktopTopPanelBuilder: (context, panel) {
                return const CarpenterTopPanel(title: 'Desktop panel');
              },
              child: const SizedBox(),
            ),
          ),
        ),
      );
    }

    await pump(TargetPlatform.macOS);
    expect(_findText('Desktop panel'), findsOneWidget);
    expect(_findText('Touch panel'), findsNothing);

    await pump(TargetPlatform.android);
    expect(_findText('Touch panel'), findsOneWidget);
    expect(_findText('Desktop panel'), findsNothing);
  });

  test('CarpenterCommandController публикует выполнение и результат', () async {
    final started = Completer<void>();
    final release = Completer<void>();
    final command = CarpenterCommandController<int>(
      id: 'test.command',
      title: 'Test',
      execute: (value) async {
        started.complete();
        await release.future;
        return CarpenterCommandResult(message: '$value');
      },
    );

    final future = command.execute(42);
    await started.future;
    expect(command.value.execution, CarpenterCommandExecution.executing);
    release.complete();
    expect((await future).message, '42');
    expect(command.value.execution, CarpenterCommandExecution.idle);
    command.dispose();
  });

  testWidgets('CarpenterSurfaceHost открывает и закрывает side panel', (
    tester,
  ) async {
    late CarpenterSurfaceController surfaces;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterSurfaceHost(
            child: Builder(
              builder: (context) {
                surfaces = context.surfaces;
                return const CarpenterText('base');
              },
            ),
          ),
        ),
      ),
    );

    final result = surfaces.openSidePanel<String>(
      (context) => GestureDetector(
        onTap: () => CarpenterSurfaceCloseScope.maybeClose(context, 'done'),
        child: const CarpenterText('panel'),
      ),
    );
    await tester.pump();
    expect(_findText('base'), findsOneWidget);
    expect(_findText('panel'), findsOneWidget);

    await tester.tap(_findText('panel'));
    await tester.pump();
    expect(await result, 'done');
    expect(_findText('panel'), findsNothing);
  });

  testWidgets('CarpenterPage показывает loading на уровне страницы', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: CarpenterPage(
              loading: true,
              content: CarpenterText('content'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CarpenterPageLoadingBar), findsOneWidget);
    expect(find.byType(CarpenterLoader), findsNothing);
  });

  testWidgets('CarpenterPageHeader переносит команды под заголовок на mobile', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 360,
              child: CarpenterPageHeader(
                title: CarpenterText('Расчётные счета'),
                subtitle: CarpenterText('Денежные позиции'),
                commandBar: CarpenterText('Добавить счёт'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(
      tester.getTopLeft(_findText('Добавить счёт')).dy,
      greaterThan(tester.getBottomLeft(_findText('Денежные позиции')).dy),
    );
  });

  testWidgets('CarpenterTabs переключает выбранную вкладку', (tester) async {
    var selected = 0;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) => CarpenterTabs<int>(
              value: selected,
              tabs: const [
                CarpenterTab(value: 0, child: CarpenterText('One')),
                CarpenterTab(value: 1, child: CarpenterText('Two')),
              ],
              onChanged: (value) => setState(() => selected = value),
            ),
          ),
        ),
      ),
    );

    await tester.tap(_findText('Two'));
    await tester.pump();
    expect(selected, 1);
  });

  testWidgets('CarpenterControl активируется Enter и Space', (tester) async {
    final focusNode = FocusNode();
    var activations = 0;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterControl(
            focusNode: focusNode,
            onTap: () => activations++,
            builder: (context, state) => const SizedBox(
              width: 80,
              height: 40,
              child: CarpenterText('Control'),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(activations, 2);
    focusNode.dispose();
  });

  testWidgets('disabled CarpenterInput не удерживает фокус', (tester) async {
    final focusNode = FocusNode();
    var enabled = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return CarpenterInput(
                focusNode: focusNode,
                enabled: enabled,
                initialValue: 'value',
              );
            },
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
    rebuild(() => enabled = false);
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);
    focusNode.dispose();
  });

  testWidgets(
    'CarpenterDatePicker выбирает дату из календаря без ввода текста',
    (tester) async {
      DateTime? selected = DateTime(2025, 12, 15);
      await tester.pumpWidget(
        CarpenterScope.fromConfig(
          config: const CarpenterConfig(),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Navigator(
              onGenerateRoute: (_) => PageRouteBuilder<void>(
                pageBuilder: (context, animation, secondaryAnimation) => Center(
                  child: CarpenterDatePicker(
                    selected: selected,
                    onChanged: (value) => selected = value,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(_findText('15.12.2025'), findsOneWidget);
      await tester.tap(_findText('15.12.2025'));
      await tester.pumpAndSettle();

      expect(_findText('Декабрь 2025'), findsOneWidget);
      expect(find.byType(EditableText), findsNothing);
      await tester.tap(_findText('20'));
      await tester.pumpAndSettle();

      expect(selected, DateTime(2025, 12, 20));
      expect(_findText('Выберите дату'), findsNothing);
    },
  );

  testWidgets('CarpenterSelect позволяет выбрать null как значение', (
    tester,
  ) async {
    var called = false;
    String? value = 'category';
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Navigator(
            onGenerateRoute: (_) => PageRouteBuilder<void>(
              pageBuilder: (context, animation, secondaryAnimation) => Center(
                child: CarpenterSelect<String?>(
                  value: value,
                  items: const [
                    CarpenterSelectItem(
                      value: null,
                      child: CarpenterText('Без категории'),
                    ),
                    CarpenterSelectItem(
                      value: 'category',
                      child: CarpenterText('Категория'),
                    ),
                  ],
                  onChanged: (next) {
                    called = true;
                    value = next;
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(_findText('Категория'));
    await tester.pumpAndSettle();
    await tester.tap(_findText('Без категории'));
    await tester.pumpAndSettle();

    expect(called, isTrue);
    expect(value, isNull);
  });

  testWidgets('CarpenterSurfaceHost закрывает панель по Escape', (
    tester,
  ) async {
    late CarpenterSurfaceController surfaces;
    await tester.pumpWidget(
      CarpenterScope.fromConfig(
        config: const CarpenterConfig(),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: CarpenterSurfaceHost(
            child: Builder(
              builder: (context) {
                surfaces = context.surfaces;
                return const CarpenterText('base');
              },
            ),
          ),
        ),
      ),
    );

    final result = surfaces.openSidePanel<String>(
      (context) => const CarpenterText('escape panel'),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(await result, isNull);
    expect(_findText('escape panel'), findsNothing);
  });
}

class _TestModule extends CarpenterModuleBase {
  const _TestModule({
    required this.rootRoute,
    required this.dashboardRoute,
    required this.detailsRoute,
  });

  final YxRoute rootRoute;
  final YxRoute dashboardRoute;
  final YxRoute detailsRoute;

  @override
  String get id => 'test';

  @override
  Set<Type> get requires => const {CarpenterRouterRuntime};

  @override
  List<CarpenterRoute> get routes => [
    CarpenterRoute(
      route: rootRoute,
      shell: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              CarpenterText('Root shell: ${context.chain.last.node.route.id}'),
              child,
            ],
          ),
        );
      },
      children: [
        CarpenterRoute(
          route: dashboardRoute,
          page: (_) => const CarpenterText('Dashboard page'),
        ),
        CarpenterRoute(
          route: detailsRoute,
          page: (context) =>
              CarpenterText('Details page ${context.arguments['id']}'),
        ),
      ],
    ),
  ];
}

class _TestCapability {}

class _SecondTestCapability {
  const _SecondTestCapability(this.value);

  final String value;
}

class _NeedsTestCapabilityShell extends CarpenterShellBase {
  const _NeedsTestCapabilityShell();

  @override
  String get id => 'needs-test';

  @override
  Set<Type> get requires => const {_TestCapability};
}

class _NeedsTestCapabilityModule extends CarpenterModuleBase {
  const _NeedsTestCapabilityModule();

  @override
  String get id => 'needs-test';

  @override
  Set<Type> get requires => const {_TestCapability};

  @override
  List<CarpenterRoute> get routes => const [];
}

class _ProvidesTestCapabilityShell extends CarpenterShellBase {
  const _ProvidesTestCapabilityShell(this.events);

  final List<String> events;

  @override
  String get id => 'provides-test';

  @override
  Set<Type> get provides => const {_TestCapability};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    events.add('provide-first');
    return context.runtime.extend(_TestCapability());
  }

  @override
  Widget wrap(CarpenterShellBuildContext context, Widget child) {
    events.add('wrap-first');
    return child;
  }
}

class _RequiresTestCapabilityShell extends CarpenterShellBase {
  const _RequiresTestCapabilityShell(this.events);

  final List<String> events;

  @override
  String get id => 'requires-test';

  @override
  Set<Type> get requires => const {_TestCapability};

  @override
  Set<Type> get provides => const {_SecondTestCapability};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    events.add('configure-second');
    context.runtime.read<_TestCapability>();
    return context.runtime.extend(
      const _SecondTestCapability('second sees first'),
    );
  }
}

class _CapabilityModule extends CarpenterModuleBase {
  const _CapabilityModule({required this.route});

  final YxRoute route;

  @override
  String get id => 'capability-module';

  @override
  List<CarpenterShell> get shells => const [_ModuleCapabilityShell()];

  @override
  List<CarpenterRoute> get routes => [
    CarpenterRoute(
      route: route,
      page: (context) {
        final capability = context.runtime.read<_SecondTestCapability>();

        return CarpenterText(
          capability.value,
          textDirection: TextDirection.ltr,
        );
      },
    ),
  ];
}

class _ModuleCapabilityShell extends CarpenterShellBase {
  const _ModuleCapabilityShell();

  @override
  String get id => 'module-capability';

  @override
  Set<Type> get provides => const {_SecondTestCapability};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime.extend(
      const _SecondTestCapability('module capability'),
    );
  }
}

class _HostCapabilityShell extends CarpenterShellBase {
  const _HostCapabilityShell();

  @override
  String get id => 'host-capability';

  @override
  Set<Type> get provides => const {_SecondTestCapability};

  @override
  CarpenterRuntime configure(CarpenterShellConfigureContext context) {
    return context.runtime.extend(
      const _SecondTestCapability('host capability'),
    );
  }
}

class _InheritedLabel extends InheritedWidget {
  const _InheritedLabel({required this.label, required super.child});

  final String label;

  static String of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_InheritedLabel>();
    assert(scope != null, 'No _InheritedLabel found in context.');
    return scope!.label;
  }

  @override
  bool updateShouldNotify(_InheritedLabel oldWidget) =>
      label != oldWidget.label;
}
