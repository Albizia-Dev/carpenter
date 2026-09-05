import 'package:carpenter/carpenter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('descriptor-driven surfaces omit hidden actions', (tester) async {
    const hiddenButton = CarpenterActionDescriptor(
      id: 'hidden-button',
      label: 'Hidden button',
      visible: false,
      onInvoke: null,
    );
    const hiddenMenu = CarpenterActionDescriptor(
      id: 'hidden-menu',
      label: 'Hidden menu item',
      visible: false,
      onInvoke: null,
    );
    const hiddenToolbar = CarpenterActionDescriptor(
      id: 'hidden-toolbar',
      label: 'Hidden toolbar action',
      visible: false,
      onInvoke: null,
    );
    final visibleMenu = CarpenterActionDescriptor(
      id: 'visible-menu',
      label: 'Visible menu item',
      onInvoke: () {},
    );
    final visibleToolbar = CarpenterActionDescriptor(
      id: 'visible-toolbar',
      label: 'Visible toolbar action',
      onInvoke: () {},
    );

    await tester.pumpWidget(
      carpenterHarness(
        Column(
          children: [
            CarpenterButton.fromAction(hiddenButton),
            CarpenterMenu(
              autofocus: false,
              items: [
                const CarpenterMenuItem(action: hiddenMenu),
                CarpenterMenuItem(action: visibleMenu),
              ],
            ),
            CarpenterToolbar(
              items: [
                const CarpenterToolbarItem(action: hiddenToolbar),
                CarpenterToolbarItem(action: visibleToolbar),
              ],
            ),
          ],
        ),
      ),
    );

    expect(find.text('Hidden button'), findsNothing);
    expect(find.text('Hidden menu item'), findsNothing);
    expect(find.text('Hidden toolbar action'), findsNothing);
    expect(find.text('Visible menu item'), findsOneWidget);
    expect(find.text('Visible toolbar action'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disabled descriptor reason becomes an accessibility hint', (
    tester,
  ) async {
    const action = CarpenterActionDescriptor(
      id: 'archive',
      label: 'Archive',
      semanticLabel: 'Archive record',
      disabledReason: 'Select a record first',
      onInvoke: null,
    );

    await tester.pumpWidget(carpenterHarness(CarpenterButton.fromAction(action)));

    final semantics = tester.getSemantics(
      find.bySemanticsLabel('Archive record'),
    );
    expect(semantics.hint, 'Select a record first');
    expect(semantics.hasFlag(SemanticsFlag.isEnabled), isFalse);
  });
}
