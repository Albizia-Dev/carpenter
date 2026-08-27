import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('open state is controlled and menu activation dismisses', (
    tester,
  ) async {
    var open = false;
    var invoked = 0;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDropdown(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              label: 'Actions',
              items: [
                CarpenterMenuItem(
                  action: CarpenterActionDescriptor(
                    id: 'run',
                    label: 'Run',
                    onInvoke: () => invoked++,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    expect(find.text('Run'), findsOneWidget);
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(invoked, 1);
    expect(open, isFalse);
  });

  testWidgets('outside and Escape dismiss and focus returns to trigger', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterDropdown(
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              label: 'Actions',
              focusNode: focusNode,
              autofocus: true,
              items: const [
                CarpenterMenuItem(
                  action: CarpenterActionDescriptor(
                    id: 'disabled',
                    label: 'Disabled',
                    onInvoke: null,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(open, isFalse);
    expect(focusNode.hasFocus, isTrue);

    await tester.tap(find.text('Actions'));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(700, 500));
    await tester.pumpAndSettle();
    expect(open, isFalse);
  });
}
