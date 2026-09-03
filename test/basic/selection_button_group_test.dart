import 'dart:ui' show Tristate;

import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('selection button group emits one controlled value', (
    tester,
  ) async {
    var value = 'common';
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterSelectionButtonGroup<String>(
            value: value,
            onChanged: (next) => setState(() => value = next),
            options: const [
              CarpenterSelectionButtonOption(value: 'common', label: 'Common'),
              CarpenterSelectionButtonOption(value: 'p', label: 'Stage P'),
              CarpenterSelectionButtonOption(value: 'r', label: 'Stage R'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('Stage P'));
    await tester.pump();
    expect(value, 'p');
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Stage P'))
          .flagsCollection
          .isToggled,
      Tristate.isTrue,
    );
  });

  testWidgets('selection button group supports arrow navigation', (
    tester,
  ) async {
    var value = 'common';
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterSelectionButtonGroup<String>(
          value: value,
          onChanged: (next) => value = next,
          options: const [
            CarpenterSelectionButtonOption(value: 'common', label: 'Common'),
            CarpenterSelectionButtonOption(value: 'p', label: 'Stage P'),
          ],
        ),
      ),
    );

    final firstControl = tester.widget<FocusableActionDetector>(
      find.byType(FocusableActionDetector).first,
    );
    firstControl.focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    expect(value, 'p');
  });
}
