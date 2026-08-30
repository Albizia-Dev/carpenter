import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/src/components/layout/action_overflow.dart';

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
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          child: ActionOverflowLayout(
            gap: 8,
            minimumInlineActionWidth: 40,
            content: SizedBox(key: ValueKey('content'), width: 260, height: 20),
            actions: SizedBox(key: ValueKey('actions'), width: 200, height: 20),
          ),
        ),
      ),
    );

    final content = tester.getRect(find.byKey(const ValueKey('content')));
    final actions = tester.getRect(find.byKey(const ValueKey('actions')));
    expect(actions.top, greaterThanOrEqualTo(content.bottom + 8));
  });

  testWidgets('action layout stays inline when minimum action space remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 300,
          child: ActionOverflowLayout(
            gap: 8,
            minimumInlineActionWidth: 40,
            content: SizedBox(key: ValueKey('content'), width: 180, height: 20),
            actions: SizedBox(key: ValueKey('actions'), width: 100, height: 20),
          ),
        ),
      ),
    );

    final content = tester.getRect(find.byKey(const ValueKey('content')));
    final actions = tester.getRect(find.byKey(const ValueKey('actions')));
    expect(actions.top, content.top);
    expect(actions.left, greaterThan(content.right));
  });
}
