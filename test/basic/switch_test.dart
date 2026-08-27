import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('reports controlled pointer and keyboard changes', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterSwitch(
          value: false,
          label: 'Notifications',
          onChanged: changes.add,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byType(CarpenterSwitch));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(changes, [true, true]);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Notifications')),
      matchesSemantics(
        label: 'Notifications',
        hasToggledState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('selected and disabled semantics remain distinct', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterSwitch(value: true, label: 'Managed setting'),
      ),
    );
    await tester.tap(find.byType(CarpenterSwitch));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Managed setting')),
      matchesSemantics(
        label: 'Managed setting',
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
      ),
    );
  });

  testWidgets('supports dark high contrast, RTL, and 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterSwitch(
          value: true,
          label: 'الإشعارات',
          description: 'وصف طويل للإعداد',
          onChanged: _noop,
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}

void _noop(bool value) {}
