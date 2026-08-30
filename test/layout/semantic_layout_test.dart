import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('application shell adapts navigation by size and capabilities', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      _harness(
        width: 1200,
        child: _shell(),
        capabilities: CarpenterInputCapabilities.pointerOriented,
      ),
    );
    expect(find.text('side'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        width: 390,
        child: _shell(),
        capabilities: CarpenterInputCapabilities.touchOriented,
      ),
    );
    expect(find.text('bottom'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('toolbar moves action groups into one shared overflow menu', (
    tester,
  ) async {
    var invoked = 0;
    final items = List.generate(
      5,
      (index) => CarpenterToolbarItem(
        action: CarpenterActionDescriptor(
          id: 'action-$index',
          label: 'Long action $index',
          onInvoke: () => invoked += 1,
        ),
        group: index == 0
            ? CarpenterToolbarGroup.primary
            : CarpenterToolbarGroup.secondary,
      ),
    );
    await tester.pumpWidget(
      _overlayHarness(width: 260, child: CarpenterToolbar(items: items)),
    );

    final overflowTrigger = find.bySemanticsLabel('More actions');
    expect(overflowTrigger, findsOneWidget);
    await tester.tap(overflowTrigger);
    await tester.pumpAndSettle();
    expect(find.byType(CarpenterMenu), findsOneWidget);
    await tester.tap(find.text('Long action 4').last);
    expect(invoked, 1);
  });

  testWidgets('split resize is controlled, clamped and keyboard accessible', (
    tester,
  ) async {
    double? changed;
    await tester.pumpWidget(
      _harness(
        width: 700,
        child: CarpenterSplitView(
          primary: const ColoredBox(
            color: Color(0x00000000),
            child: Text('Primary'),
          ),
          secondary: const Text('Secondary'),
          position: 0.5,
          minimumPosition: 0.4,
          maximumPosition: 0.6,
          onPositionChanged: (value) => changed = value,
        ),
      ),
    );

    final divider = find.bySemanticsLabel('Resize regions');
    await tester.drag(divider, const Offset(500, 0));
    expect(changed, 0.6);

    await tester.tap(divider);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(changed, closeTo(0.45, 0.001));
  });

  testWidgets('master detail is inline wide and pushed narrow', (tester) async {
    var closed = false;
    await tester.pumpWidget(
      _harness(
        width: 1000,
        child: CarpenterMasterDetail(
          master: const Text('Master'),
          detail: const Text('Detail'),
          onDetailVisibilityChanged: (value) => closed = !value,
        ),
      ),
    );
    expect(find.text('Master'), findsOneWidget);
    expect(find.text('Detail'), findsOneWidget);

    await tester.pumpWidget(
      _harness(
        width: 390,
        child: CarpenterMasterDetail(
          master: const Text('Master'),
          detail: const Text('Detail'),
          onDetailVisibilityChanged: (value) => closed = !value,
        ),
      ),
    );
    expect(find.text('Master'), findsNothing);
    expect(find.text('Detail'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, isTrue);
  });

  testWidgets('adaptive region transfers focus on controlled transition', (
    tester,
  ) async {
    final primaryFocus = FocusNode();
    final regionFocus = FocusNode();
    Widget build(bool visible) => _harness(
      width: 390,
      child: CarpenterAdaptiveRegion(
        primary: const Text('Primary'),
        region: const Text('Region'),
        role: CarpenterRegionRole.detail,
        policy: CarpenterBreakpointRegionPolicy.masterDetail,
        regionVisible: visible,
        primaryFocusNode: primaryFocus,
        regionFocusNode: regionFocus,
      ),
    );

    await tester.pumpWidget(build(false));
    primaryFocus.requestFocus();
    await tester.pumpWidget(build(true));
    await tester.pump();
    expect(regionFocus.hasFocus, isTrue);

    primaryFocus.dispose();
    regionFocus.dispose();
  });

  testWidgets('page region owns exactly one scroll viewport when requested', (
    tester,
  ) async {
    final controller = ScrollController();
    await tester.pumpWidget(
      _harness(
        width: 600,
        child: CarpenterPageRegion(
          header: const CarpenterPageHeader(title: 'Scrollable page'),
          scrollOwnership: CarpenterRegionScrollOwnership.region,
          scrollController: controller,
          body: Column(
            children: List.generate(
              50,
              (index) => SizedBox(height: 48, child: Text('Item $index')),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -400),
    );
    await tester.pump();
    expect(controller.offset, greaterThan(0));
    controller.dispose();
  });

  testWidgets('layout remains valid in RTL at 200 percent text scale', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 390,
        direction: TextDirection.rtl,
        textScale: 2,
        child: CarpenterPageRegion(
          header: CarpenterPageHeader(
            title: 'Заголовок страницы',
            subtitle: 'Длинное описание семантического региона',
            secondaryActions: [
              CarpenterActionDescriptor(
                id: 'edit',
                label: 'Редактировать документ',
                onInvoke: _noop,
              ),
            ],
          ),
          body: const Text('Content'),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('adaptive and split regions remain bounded at tiny widths', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 6,
        child: CarpenterAdaptiveRegion(
          primary: const Text('Primary'),
          region: const Text('Secondary'),
          role: CarpenterRegionRole.secondary,
          policy: CarpenterBreakpointRegionPolicy.secondary,
          regionVisible: true,
          onRegionVisibilityChanged: (_) {},
        ),
      ),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _harness(
        width: 6,
        child: CarpenterSplitView(
          primary: const SizedBox.shrink(),
          secondary: const SizedBox.shrink(),
          position: 0.5,
          onPositionChanged: (_) {},
        ),
      ),
    );
    await tester.drag(
      find.bySemanticsLabel('Resize regions'),
      const Offset(1, 0),
    );
    expect(tester.takeException(), isNull);
  });
}

Widget _shell() => CarpenterApplicationShell(
  navigation: CarpenterNavigationRegion(
    builder: (context, presentation) => Center(child: Text(presentation.name)),
  ),
  primaryContent: const Center(child: Text('Content')),
);

Widget _harness({
  required double width,
  required Widget child,
  double height = 600,
  TextDirection direction = TextDirection.ltr,
  double textScale = 1,
  CarpenterInputCapabilities capabilities = CarpenterInputCapabilities.hybrid,
}) => UnitsRoot(
  rem: const Px(16),
  child: CarpenterTheme(
    data: CarpenterThemeData.light(),
    child: MediaQuery(
      data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
      child: Directionality(
        textDirection: direction,
        child: CarpenterCapabilityScope(
          capabilities: capabilities,
          child: Center(
            child: SizedBox(width: width, height: height, child: child),
          ),
        ),
      ),
    ),
  ),
);

Widget _overlayHarness({required double width, required Widget child}) =>
    UnitsRoot(
      rem: const Px(16),
      child: CarpenterTheme(
        data: CarpenterThemeData.light(),
        child: MediaQuery(
          data: const MediaQueryData(size: Size(800, 600)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Overlay(
              initialEntries: [
                OverlayEntry(
                  builder: (context) => Align(
                    alignment: Alignment.topLeft,
                    child: SizedBox(width: width, child: child),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

void _noop() {}
