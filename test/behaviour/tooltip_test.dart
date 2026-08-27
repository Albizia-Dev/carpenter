import 'dart:ui' show PointerDeviceKind;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart' show kLongPressTimeout;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('hover observes show and hide delays', (tester) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        const CarpenterTooltip(
          text: 'Supplemental text',
          showDelay: TooltipDelay.short,
          hideDelay: TooltipDelay.short,
          child: SizedBox(width: 80, height: 32),
        ),
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(10, 10));
    await tester.pump();
    expect(find.text('Supplemental text'), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(find.text('Supplemental text'), findsOneWidget);
    await mouse.moveTo(const Offset(700, 500));
    await tester.pump(const Duration(milliseconds: 99));
    expect(find.text('Supplemental text'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(find.text('Supplemental text'), findsNothing);
  });

  testWidgets('descendant keyboard focus shows and Escape dismisses', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterTooltip(
          text: 'Focused help',
          showDelay: TooltipDelay.immediate,
          child: CarpenterButton(
            label: 'Control',
            focusNode: focus,
            onInvoke: _noop,
          ),
        ),
      ),
    );
    focus.requestFocus();
    await tester.pumpAndSettle();
    expect(find.text('Focused help'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Focused help'), findsNothing);
  });

  testWidgets('long press shows noninteractive tooltip and exposes semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        const CarpenterTooltip(
          text: 'Touch help',
          child: SizedBox(width: 80, height: 32),
        ),
      ),
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.tooltip == 'Touch help',
      ),
      findsOneWidget,
    );
    final gesture = await tester.startGesture(const Offset(10, 10));
    await tester.pump(kLongPressTimeout);
    await tester.pump();
    expect(find.text('Touch help'), findsOneWidget);
    await gesture.up();
  });

  testWidgets('supports dark high contrast, RTL and 200% text', (tester) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        const CarpenterTooltip(
          text: 'مساعدة إضافية',
          showDelay: TooltipDelay.immediate,
          child: SizedBox(width: 80, height: 32),
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: const Offset(10, 10));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

void _noop() {}
