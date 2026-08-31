import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  const options = [
    CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
    CarpenterOption(id: 'b', value: 2, label: 'Bravo'),
  ];

  testWidgets('value and open state remain controlled when requested', (
    tester,
  ) async {
    int? value = 1;
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterSelect<int>(
              value: value,
              onChanged: (next) => update(() => value = next),
              open: open,
              onOpenChanged: (next) => update(() => open = next),
              options: options,
              label: 'Choice',
            );
          },
        ),
      ),
    );
    expect(find.text('Alpha'), findsOneWidget);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(value, 2);
    expect(open, isFalse);
    expect(find.text('Bravo'), findsOneWidget);
  });

  testWidgets('overlay state is self-managed by default', (tester) async {
    int? value;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterSelect<int>(
              value: value,
              onChanged: (next) => update(() => value = next),
              options: options,
              label: 'Choice',
              placeholder: 'Choose',
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Bravo'), findsOneWidget);

    await tester.tap(find.text('Bravo'));
    await tester.pumpAndSettle();
    expect(value, 2);
    expect(find.text('Bravo'), findsOneWidget);
    expect(find.text('Alpha'), findsNothing);
  });

  testWidgets('keyboard navigation selects and restores field focus', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    int? selected;
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterSelect<int>(
              value: selected,
              onChanged: (next) => update(() => selected = next),
              open: open,
              onOpenChanged: (next) => update(() => open = next),
              options: options,
              focusNode: focus,
            );
          },
        ),
      ),
    );
    focus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 2);
    expect(focus.hasFocus, isTrue);
  });

  testWidgets('disabled and readOnly prevent opening and error is semantic', (
    tester,
  ) async {
    var changes = 0;
    for (final availability in [
      FieldAvailability.disabled,
      FieldAvailability.readOnly,
    ]) {
      await tester.pumpWidget(
        carpenterOverlayHarness(
          CarpenterSelect<int>(
            value: null,
            onChanged: (_) => changes++,
            open: false,
            onOpenChanged: (_) => changes++,
            options: options,
            availability: availability,
            label: 'Choice',
            errorText: 'Required choice',
          ),
        ),
      );
      await tester.tap(find.byType(CarpenterSelect<int>));
    }
    expect(changes, 0);
    expect(find.text('Required choice'), findsOneWidget);
  });

  testWidgets('stable option identity and stressed modes render', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        const CarpenterSelect<int>(
          value: 2,
          onChanged: _ignoreInt,
          open: true,
          onOpenChanged: _ignoreBool,
          options: options,
          size: FieldSize.xlarge,
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Bravo'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}

void _ignoreInt(int value) {}
void _ignoreBool(bool value) {}
