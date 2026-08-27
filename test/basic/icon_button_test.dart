import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _icon = IconData(0xe002, fontFamily: 'MaterialIcons');

void main() {
  Widget harness(Widget child, {CarpenterThemeData? theme}) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(child: Align(child: child)),
      ),
    ),
  );

  testWidgets('has full hit target and required accessible label', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const CarpenterIconButton(icon: _icon, semanticLabel: 'Remove')),
    );
    final size = tester.getSize(find.byType(CarpenterIconButton));
    expect(size.width, greaterThanOrEqualTo(44));
    expect(size.height, greaterThanOrEqualTo(44));
    expect(
      tester.getSemantics(find.byType(CarpenterIconButton)),
      matchesSemantics(label: 'Remove', isButton: true, hasEnabledState: true),
    );
  });

  testWidgets('visual icon control is not enlarged to the hit target', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    await tester.pumpWidget(
      harness(
        const CarpenterIconButton(
          icon: _icon,
          semanticLabel: 'Compact remove',
          size: ControlSize.xsmall,
        ),
        theme: theme,
      ),
    );
    final context = tester.element(find.byType(CarpenterIconButton));
    final visual = find.descendant(
      of: find.byType(CarpenterIconButton),
      matching: find.byType(AnimatedContainer),
    );
    final expectedVisual = context.units(
      theme.sizes.actionHeight(ControlSize.xsmall),
    );
    expect(tester.getSize(visual), Size.square(expectedVisual));
    expect(
      tester.getSize(find.byType(CarpenterIconButton)).height,
      greaterThanOrEqualTo(context.units(theme.sizes.minimumTarget)),
    );
  });

  testWidgets('fromAction uses icon and spoken label fallback', (tester) async {
    const action = CarpenterActionDescriptor(
      id: 'archive',
      label: 'Archive',
      icon: _icon,
      onInvoke: null,
    );
    await tester.pumpWidget(harness(CarpenterIconButton.fromAction(action)));
    expect(find.bySemanticsLabel('Archive'), findsOneWidget);
  });

  test('fromAction fails fast without an icon', () {
    const action = CarpenterActionDescriptor(
      id: 'invalid',
      label: 'Invalid',
      onInvoke: null,
    );
    expect(() => CarpenterIconButton.fromAction(action), throwsAssertionError);
  });

  testWidgets('running is stable, busy, and blocks repeat invocation', (
    tester,
  ) async {
    var count = 0;
    Widget iconButton(ActionExecutionPhase phase) => CarpenterIconButton(
      icon: _icon,
      semanticLabel: 'Sync',
      executionPhase: phase,
      onInvoke: () => count += 1,
    );
    await tester.pumpWidget(harness(iconButton(ActionExecutionPhase.idle)));
    final idleSize = tester.getSize(find.byType(CarpenterIconButton));
    await tester.pumpWidget(harness(iconButton(ActionExecutionPhase.running)));
    await tester.pump();
    expect(tester.getSize(find.byType(CarpenterIconButton)), idleSize);
    expect(find.byIcon(_icon), findsOneWidget);
    await tester.tap(find.byType(CarpenterIconButton));
    expect(count, 0);
    expect(
      tester.getSemantics(find.byType(CarpenterIconButton)),
      matchesSemantics(
        label: 'Sync',
        value: 'running',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isLiveRegion: true,
      ),
    );
  });

  testWidgets('supports danger role in dark high contrast', (tester) async {
    await tester.pumpWidget(
      harness(
        const CarpenterIconButton(
          icon: _icon,
          semanticLabel: 'Delete',
          colorRole: ActionColorRole.danger,
          prominence: ActionProminence.normal,
          onInvoke: _noop,
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('supports every ordinary button role and prominence', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        Wrap(
          children: [
            for (final role in ActionColorRole.values)
              for (final prominence in ActionProminence.values)
                CarpenterIconButton(
                  icon: _icon,
                  semanticLabel: '${role.name} ${prominence.name}',
                  colorRole: role,
                  prominence: prominence,
                  onInvoke: _noop,
                ),
          ],
        ),
      ),
    );

    expect(
      find.byType(CarpenterIconButton),
      findsNWidgets(
        ActionColorRole.values.length * ActionProminence.values.length,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
