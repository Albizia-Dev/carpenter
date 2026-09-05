import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/components/behaviour/action_overflow.dart';

void main() {
  test('overflow policy degrades whole action groups', () {
    const entries = [
      ActionOverflowEntry(
        value: 'primary',
        group: ActionOverflowGroup.primary,
        expandedWidth: 100,
        iconWidth: 32,
      ),
      ActionOverflowEntry(
        value: 'secondary-a',
        group: ActionOverflowGroup.secondary,
        expandedWidth: 90,
        iconWidth: 32,
      ),
      ActionOverflowEntry(
        value: 'secondary-b',
        group: ActionOverflowGroup.secondary,
        expandedWidth: 90,
        iconWidth: 32,
      ),
    ];
    const resolver = ActionOverflowResolver<String>();

    final secondaryOverflow = resolver.resolve(
      entries: entries,
      availableWidth: 150,
      gap: 8,
      overflowWidth: 40,
    );
    expect(
      secondaryOverflow.stage,
      ActionOverflowStage.secondaryOverflow,
    );
    expect(secondaryOverflow.visible, ['primary']);
    expect(secondaryOverflow.overflow, ['secondary-a', 'secondary-b']);

    final iconOnly = resolver.resolve(
      entries: entries,
      availableWidth: 90,
      gap: 8,
      overflowWidth: 40,
    );
    expect(iconOnly.stage, ActionOverflowStage.iconOnly);
    expect(iconOnly.visible, ['primary']);
    expect(iconOnly.overflow, ['secondary-a', 'secondary-b']);

    final overflowOnly = resolver.resolve(
      entries: entries,
      availableWidth: 60,
      gap: 8,
      overflowWidth: 40,
    );
    expect(overflowOnly.stage, ActionOverflowStage.overflowOnly);
    expect(overflowOnly.visible, isEmpty);
    expect(
      overflowOnly.overflow,
      ['primary', 'secondary-a', 'secondary-b'],
    );
  });

  testWidgets('action layout relocates as one block when inline space is gone', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: ActionOverflowLayout(
              gap: 8,
              minimumInlineActionWidth: 100,
              content: const SizedBox(width: 260, height: 20),
              actions: const SizedBox(width: 200, height: 20),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ActionOverflowLayout)).height, 48);
  });

  testWidgets('action layout stays inline when minimum action space remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 300,
            child: ActionOverflowLayout(
              gap: 8,
              minimumInlineActionWidth: 40,
              content: const SizedBox(width: 180, height: 20),
              actions: const SizedBox(width: 100, height: 20),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(ActionOverflowLayout)).height, 20);
  });
}
