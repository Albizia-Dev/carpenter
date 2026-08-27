import 'dart:ui' show CheckedState, Tristate;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

enum _Choice { first, second, third }

void main() {
  List<CarpenterRadio<_Choice>> radios({FocusNode? firstFocusNode}) => [
    CarpenterRadio(
      value: _Choice.first,
      label: 'First',
      focusNode: firstFocusNode,
    ),
    const CarpenterRadio(value: _Choice.second, label: 'Second'),
    const CarpenterRadio(
      value: _Choice.third,
      label: 'Third',
      description: 'Generic enum value',
    ),
  ];

  testWidgets('pointer requests controlled generic selection', (tester) async {
    _Choice? changed;
    Widget group(_Choice? value) => CarpenterRadioGroup<_Choice>(
      value: value,
      onChanged: (next) => changed = next,
      children: radios(),
    );

    await tester.pumpWidget(carpenterHarness(group(_Choice.first)));
    await tester.tap(find.text('Second'));
    expect(changed, _Choice.second);
    expect(
      tester.getSemantics(find.bySemanticsLabel('First')),
      matchesSemantics(
        label: 'First',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
        isEnabled: true,
        isInMutuallyExclusiveGroup: true,
        isFocusable: true,
        hasTapAction: true,
      ),
    );

    await tester.pumpWidget(carpenterHarness(group(_Choice.second)));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Second'))
          .flagsCollection
          .isChecked,
      CheckedState.isTrue,
    );
  });

  testWidgets('arrow keys move focus and request next selection', (
    tester,
  ) async {
    final changes = <_Choice>[];
    final firstFocusNode = FocusNode();
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterRadioGroup<_Choice>(
          value: _Choice.first,
          onChanged: changes.add,
          children: radios(firstFocusNode: firstFocusNode),
        ),
      ),
    );
    firstFocusNode.requestFocus();
    await tester.pumpAndSettle();
    expect(firstFocusNode.hasFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(changes, [_Choice.second]);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Second'))
          .flagsCollection
          .isFocused,
      Tristate.isTrue,
    );
    firstFocusNode.dispose();
  });

  testWidgets('horizontal orientation and disabled group are explicit', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterRadioGroup<_Choice>(
          value: _Choice.first,
          onChanged: null,
          orientation: Axis.horizontal,
          children: radios(),
        ),
      ),
    );
    expect(find.byType(Wrap), findsOneWidget);
    await tester.tap(find.text('Second'));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Second'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
  });

  testWidgets('Tab traversal enters the selected radio', (tester) async {
    final before = FocusNode();
    final first = FocusNode();
    final selected = FocusNode();
    final third = FocusNode();
    addTearDown(() {
      before.dispose();
      first.dispose();
      selected.dispose();
      third.dispose();
    });
    await tester.pumpWidget(
      carpenterHarness(
        Column(
          children: [
            Focus(autofocus: true, focusNode: before, child: const SizedBox()),
            CarpenterRadioGroup<_Choice>(
              value: _Choice.second,
              onChanged: (_) {},
              children: [
                CarpenterRadio(
                  value: _Choice.first,
                  label: 'First',
                  focusNode: first,
                ),
                CarpenterRadio(
                  value: _Choice.second,
                  label: 'Second',
                  focusNode: selected,
                ),
                CarpenterRadio(
                  value: _Choice.third,
                  label: 'Third',
                  focusNode: third,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(before.hasFocus, isTrue);
    before.nextFocus();
    await tester.pump();
    expect(
      [first, selected, third].where((node) => node.hasFocus),
      hasLength(1),
    );
  });

  testWidgets('supports dark high contrast, RTL, and 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterRadioGroup<_Choice>(
          value: _Choice.third,
          onChanged: (_) {},
          children: const [
            CarpenterRadio(value: _Choice.first, label: 'الأول'),
            CarpenterRadio(value: _Choice.second, label: 'الثاني'),
            CarpenterRadio(value: _Choice.third, label: 'الثالث'),
          ],
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
