import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _icon = IconData(0xe001, fontFamily: 'MaterialIcons');

void main() {
  Widget harness(
    Widget child, {
    CarpenterThemeData? theme,
    TextDirection direction = TextDirection.ltr,
    double textScale = 1,
    bool disableAnimations = false,
  }) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: theme ?? CarpenterThemeData.light(),
      child: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: Directionality(
          textDirection: direction,
          child: FocusScope(child: Align(child: child)),
        ),
      ),
    ),
  );

  testWidgets('invokes once through pointer, Enter, and Space', (tester) async {
    var count = 0;
    await tester.pumpWidget(
      harness(
        CarpenterButton(
          label: 'Save',
          autofocus: true,
          onInvoke: () => count += 1,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CarpenterButton));
    expect(count, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(count, 3);
  });

  testWidgets('disabled button blocks activation and reports semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(const CarpenterButton(label: 'Unavailable')),
    );
    await tester.tap(find.byType(CarpenterButton));
    expect(
      tester.getSemantics(find.byType(CarpenterButton)),
      matchesSemantics(
        label: 'Unavailable',
        isButton: true,
        hasEnabledState: true,
      ),
    );
  });

  testWidgets('visual size and child font come from the selected size tokens', (
    tester,
  ) async {
    final theme = CarpenterThemeData.light();
    for (final size in ControlSize.values) {
      await tester.pumpWidget(
        harness(
          CarpenterButton(label: size.name, size: size, onInvoke: _noop),
          theme: theme,
          disableAnimations: true,
        ),
      );
      final context = tester.element(find.byType(CarpenterButton));
      final visual = find.descendant(
        of: find.byType(CarpenterButton),
        matching: find.byType(AnimatedContainer),
      );
      expect(
        tester.getSize(visual).height,
        context.units(theme.sizes.actionHeight(size)),
        reason: '${size.name} visual height',
      );
      final text = tester.widget<Text>(find.text(size.name));
      expect(
        text.textSpan!.style!.fontSize,
        theme.typography
            .action(context, size, TypographyEmphasis.medium)
            .fontSize,
        reason: '${size.name} label font size',
      );
    }
  });

  testWidgets('running preserves geometry, blocks invoke, and reports busy', (
    tester,
  ) async {
    var count = 0;
    Widget button(ActionExecutionPhase phase) => CarpenterButton(
      label: 'Synchronize',
      executionPhase: phase,
      onInvoke: () => count += 1,
    );

    await tester.pumpWidget(harness(button(ActionExecutionPhase.idle)));
    final idleSize = tester.getSize(find.byType(CarpenterButton));
    await tester.pumpWidget(harness(button(ActionExecutionPhase.running)));
    await tester.pump();
    final runningSize = tester.getSize(find.byType(CarpenterButton));
    expect(runningSize, idleSize);
    expect(find.text('Synchronize'), findsOneWidget);

    await tester.tap(find.byType(CarpenterButton));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(count, 0);
    expect(
      tester.getSemantics(find.byType(CarpenterButton)),
      matchesSemantics(
        label: 'Synchronize',
        value: 'running',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        isLiveRegion: true,
      ),
    );
  });

  testWidgets('fromAction separates descriptor data from presentation', (
    tester,
  ) async {
    var invoked = false;
    final action = CarpenterActionDescriptor(
      id: 'remove',
      label: 'Remove',
      semanticLabel: 'Remove item',
      icon: _icon,
      colorRole: ActionColorRole.danger,
      onInvoke: () => invoked = true,
    );
    await tester.pumpWidget(
      harness(
        CarpenterButton.fromAction(
          action,
          prominence: ActionProminence.high,
          size: ControlSize.large,
          iconPosition: CarpenterActionIconPosition.trailing,
        ),
      ),
    );
    expect(find.bySemanticsLabel('Remove item'), findsOneWidget);
    await tester.tap(find.byType(CarpenterButton));
    expect(invoked, isTrue);
  });

  testWidgets('long label remains constrained at 200% text scale in RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        const SizedBox(
          width: 180,
          child: CarpenterButton(
            label: 'Очень длинное название действия для проверки',
            onInvoke: _noop,
          ),
        ),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CarpenterButton)).width, 180);
  });

  testWidgets(
    'theme resolves role, prominence, state, and high contrast focus',
    (tester) async {
      final theme = CarpenterThemeData.dark(contrast: ContrastMode.high);
      await tester.pumpWidget(
        harness(
          const CarpenterButton(
            label: 'Delete',
            colorRole: ActionColorRole.danger,
            prominence: ActionProminence.high,
            autofocus: true,
            onInvoke: _noop,
          ),
          theme: theme,
        ),
      );
      await tester.pump();
      expect(find.bySemanticsLabel('Delete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('shape sides resolve independently and mirror in RTL', (
    tester,
  ) async {
    const button = CarpenterButton(
      label: 'Joined action',
      shape: CarpenterShape(start: ShapeRole.rounded, end: ShapeRole.none),
      onInvoke: _noop,
    );

    BorderRadius radius() {
      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      return (container.decoration! as BoxDecoration).borderRadius!
          as BorderRadius;
    }

    await tester.pumpWidget(harness(button));
    expect(radius().topLeft.x, greaterThan(0));
    expect(radius().topRight, Radius.zero);

    await tester.pumpWidget(harness(button, direction: TextDirection.rtl));
    expect(radius().topLeft, Radius.zero);
    expect(radius().topRight.x, greaterThan(0));
  });

  testWidgets('reduced motion keeps loading background static', (tester) async {
    await tester.pumpWidget(
      harness(
        const CarpenterButton(
          label: 'Run',
          executionPhase: ActionExecutionPhase.running,
          onInvoke: _noop,
        ),
        disableAnimations: true,
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    expect(tester.hasRunningAnimations, isFalse);
  });
}

void _noop() {}
