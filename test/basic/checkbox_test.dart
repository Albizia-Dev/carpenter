import 'dart:ui' show CheckedState;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('reports controlled transitions through pointer and keyboard', (
    tester,
  ) async {
    final changes = <CheckboxValue>[];
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterCheckbox(
          value: CheckboxValue.unchecked,
          label: 'Include archived',
          onChanged: changes.add,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(CarpenterCheckbox));
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(changes, [CheckboxValue.checked, CheckboxValue.checked]);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Include archived')),
      matchesSemantics(
        label: 'Include archived',
        hasCheckedState: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        isFocused: true,
        hasTapAction: true,
      ),
    );
  });

  testWidgets('exposes checked, unchecked, and mixed semantics', (
    tester,
  ) async {
    for (final value in CheckboxValue.values) {
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterCheckbox(value: value, label: value.name, onChanged: _noop),
        ),
      );
      final semantics = tester.getSemantics(find.bySemanticsLabel(value.name));
      expect(semantics.label, value.name);
      expect(semantics.flagsCollection.isChecked, switch (value) {
        CheckboxValue.unchecked => CheckedState.isFalse,
        CheckboxValue.checked => CheckedState.isTrue,
        CheckboxValue.mixed => CheckedState.mixed,
      });
    }
  });

  testWidgets('disabled blocks activation and reports disabled semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterCheckbox(
          value: CheckboxValue.checked,
          label: 'Locked option',
        ),
      ),
    );
    await tester.tap(find.byType(CarpenterCheckbox));
    expect(
      tester.getSemantics(find.bySemanticsLabel('Locked option')),
      matchesSemantics(
        label: 'Locked option',
        hasCheckedState: true,
        isChecked: true,
        hasEnabledState: true,
      ),
    );
  });

  testWidgets('supports dark high contrast, RTL, and 200% text', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterCheckbox(
          value: CheckboxValue.mixed,
          label: 'اختيار مختلط',
          description: 'وصف طويل للاختيار',
          onChanged: _noop,
        ),
        theme: CarpenterThemeData.dark(contrast: ContrastMode.high),
        direction: TextDirection.rtl,
        textScale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('resolves every semantic selection color role', (tester) async {
    final theme = CarpenterThemeData.light();
    final backgrounds = <Color>{};
    for (final role in SelectionColorRole.values) {
      await tester.pumpWidget(
        carpenterHarness(
          CarpenterCheckbox(
            value: CheckboxValue.checked,
            label: role.name,
            colorRole: role,
            onChanged: _noop,
          ),
          theme: theme,
        ),
      );
      final indicator = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      final decoration = indicator.decoration! as BoxDecoration;
      backgrounds.add(decoration.color!);
      expect(
        decoration.color,
        theme.selection
            .resolve(role: role, selected: true, states: const {})
            .background,
      );
    }
    expect(backgrounds, hasLength(SelectionColorRole.values.length));
  });
}

void _noop(CheckboxValue value) {}
