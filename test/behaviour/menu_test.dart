import 'dart:ui' show Tristate;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  List<CarpenterMenuItem> items(List<String> invoked) => [
    CarpenterMenuItem(
      action: CarpenterActionDescriptor(
        id: 'alpha',
        label: 'Alpha',
        onInvoke: () => invoked.add('alpha'),
      ),
    ),
    const CarpenterMenuItem(
      action: CarpenterActionDescriptor(
        id: 'disabled',
        label: 'Disabled',
        onInvoke: null,
      ),
    ),
    CarpenterMenuItem(
      action: CarpenterActionDescriptor(
        id: 'bravo',
        label: 'Bravo',
        semanticLabel: 'Run Bravo',
        onInvoke: () => invoked.add('bravo'),
      ),
    ),
  ];

  testWidgets('pointer activates once and disabled item does not activate', (
    tester,
  ) async {
    final invoked = <String>[];
    var dismissals = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterMenu(
          items: items(invoked),
          onDismissRequested: () => dismissals++,
        ),
      ),
    );
    await tester.tap(find.text('Alpha'));
    expect(invoked, ['alpha']);
    expect(dismissals, 1);
    await tester.tap(find.text('Disabled'));
    expect(invoked, ['alpha']);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Disabled'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets(
    'keyboard skips disabled items and supports Home End activation',
    (tester) async {
      final invoked = <String>[];
      await tester.pumpWidget(
        carpenterHarness(CarpenterMenu(items: items(invoked))),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(invoked, ['bravo']);
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(invoked, ['bravo', 'alpha']);
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(invoked, ['bravo', 'alpha', 'bravo']);
    },
  );

  testWidgets('Escape dismisses and typeahead focuses a matching item', (
    tester,
  ) async {
    final invoked = <String>[];
    var dismissed = false;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterMenu(
          items: items(invoked),
          onDismissRequested: () => dismissed = true,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.keyB);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(invoked, ['bravo']);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(dismissed, isTrue);
  });

  testWidgets('action semantics and stressed visual modes remain valid', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterMenu(items: items(<String>[]), semanticLabel: 'Actions'),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(find.bySemanticsLabel('Run Bravo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
