import 'dart:ui' show PointerDeviceKind;

import 'package:carpenter/src/foundation/theme.dart';
import 'package:carpenter/src/internal/rendering/interactive_region.dart';
import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget harness(Widget child) => UnitsRoot(
    rem: const Px(16),
    child: CarpenterTheme(
      data: CarpenterThemeData.light(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: FocusScope(child: child),
      ),
    ),
  );

  testWidgets('tracks hover, press, cancel, and focus states', (tester) async {
    Set<WidgetState> states = const {};
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          focusNode: focusNode,
          onActivate: () {},
          builder: (context, value, showFocusHighlight) {
            states = value;
            return const SizedBox(width: 80, height: 40);
          },
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(900, 700));
    await tester.pump();
    await mouse.moveTo(tester.getCenter(find.byType(InteractiveRegion)));
    await tester.pump();
    expect(states, contains(WidgetState.hovered));

    await mouse.down(tester.getCenter(find.byType(InteractiveRegion)));
    await tester.pump();
    expect(states, contains(WidgetState.pressed));
    await mouse.cancel();
    await tester.pump();
    expect(states, isNot(contains(WidgetState.pressed)));

    await mouse.moveTo(const Offset(900, 700));
    await tester.pump();
    expect(states, isNot(contains(WidgetState.hovered)));
  });

  testWidgets('tracks programmatic focus acquire and loss', (tester) async {
    Set<WidgetState> states = const {};
    final focusNode = FocusNode();
    final otherFocusNode = FocusNode();
    addTearDown(() {
      focusNode.dispose();
      otherFocusNode.dispose();
    });
    await tester.pumpWidget(
      harness(
        Column(
          children: [
            InteractiveRegion(
              focusNode: focusNode,
              onActivate: () {},
              builder: (context, value, showFocusHighlight) {
                states = value;
                return const SizedBox(width: 80, height: 40);
              },
            ),
            Focus(
              focusNode: otherFocusNode,
              child: const SizedBox(width: 80, height: 40),
            ),
          ],
        ),
      ),
    );

    await tester.pump();
    focusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(states, contains(WidgetState.focused));
    otherFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(states, isNot(contains(WidgetState.focused)));
  });

  testWidgets('pointer, Enter, and Space invoke exactly once', (tester) async {
    var invocations = 0;
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          autofocus: true,
          onActivate: () => invocations += 1,
          builder: (context, states, showFocusHighlight) =>
              const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(InteractiveRegion));
    expect(invocations, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(invocations, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(invocations, 3);
  });

  testWidgets('routes additional shortcuts through the shared runtime', (
    tester,
  ) async {
    var directionalInvocations = 0;
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          autofocus: true,
          onActivate: () {},
          shortcutCallbacks: {
            const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
                directionalInvocations += 1,
          },
          builder: (context, states, showFocusHighlight) =>
              const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(directionalInvocations, 1);
  });

  testWidgets('disabled region blocks pointer and keyboard activation', (
    tester,
  ) async {
    Set<WidgetState> states = const {};
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          onActivate: null,
          builder: (context, value, showFocusHighlight) {
            states = value;
            return const SizedBox(width: 80, height: 40);
          },
        ),
      ),
    );

    expect(states, contains(WidgetState.disabled));
    await tester.tap(find.byType(InteractiveRegion));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(states, isNot(contains(WidgetState.pressed)));
    final disabledCursors = tester
        .widgetList<MouseRegion>(find.byType(MouseRegion))
        .map((region) => region.cursor);
    expect(disabledCursors, contains(SystemMouseCursors.basic));
  });

  testWidgets('enabled region uses the shared click cursor', (tester) async {
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          onActivate: () {},
          builder: (context, value, showFocusHighlight) =>
              const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    final enabledCursors = tester
        .widgetList<MouseRegion>(find.byType(MouseRegion))
        .map((region) => region.cursor);
    expect(enabledCursors, contains(SystemMouseCursors.click));
  });

  testWidgets('external FocusNode remains caller-owned', (tester) async {
    final focusNode = FocusNode();
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          focusNode: focusNode,
          onActivate: () {},
          builder: (context, states, showFocusHighlight) =>
              const SizedBox(width: 80, height: 40),
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());

    expect(focusNode.canRequestFocus, isTrue);
    focusNode.dispose();
  });

  testWidgets('autofocus acquires focus', (tester) async {
    Set<WidgetState> states = const {};
    await tester.pumpWidget(
      harness(
        InteractiveRegion(
          autofocus: true,
          onActivate: () {},
          builder: (context, value, showFocusHighlight) {
            states = value;
            return const SizedBox(width: 80, height: 40);
          },
        ),
      ),
    );
    await tester.pump();
    expect(states, contains(WidgetState.focused));
  });
}
