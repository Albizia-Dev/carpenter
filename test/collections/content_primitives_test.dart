import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('tabs are controlled and support directional keyboard', (
    tester,
  ) async {
    var value = 1;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterTabs<int>(
              value: value,
              onChanged: (next) => update(() => value = next),
              tabs: const [
                CarpenterTab(value: 1, label: 'Overview'),
                CarpenterTab(value: 2, label: 'Allocations'),
                CarpenterTab(value: 3, label: 'History'),
              ],
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Allocations'));
    expect(value, 2);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(value, 3);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(value, 1);
  });

  testWidgets('definition list adapts without losing semantic content', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const SizedBox(
          width: 280,
          child: CarpenterDefinitionList<(String, String)>(
            items: [('Account', '40702 0000'), ('Payer', 'Northwind')],
            term: _term,
            valueBuilder: _value,
          ),
        ),
        textScale: 2,
        direction: TextDirection.rtl,
      ),
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Northwind'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('definition list is chrome-free and invokes row actions', (
    tester,
  ) async {
    var invocations = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterDefinitionList<(String, String)>(
          items: const [('Account', '40702 0000')],
          term: _term,
          valueBuilder: _value,
          actions: (item) => [
            CarpenterActionDescriptor(
              id: 'account.edit',
              label: 'Edit account',
              icon: GravityIcons.pencil,
              onInvoke: () => invocations += 1,
            ),
          ],
          secondaryActions: (item) => const [
            CarpenterActionDescriptor(
              id: 'account.copy',
              label: 'Copy account',
              onInvoke: null,
            ),
          ],
        ),
      ),
    );

    final listContext = tester.element(
      find.byType(CarpenterDefinitionList<(String, String)>),
    );
    final theme = CarpenterTheme.of(listContext);
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
          return false;
        }
        final decoration = widget.decoration as BoxDecoration;
        return decoration.color == theme.surface.subtle &&
            decoration.border != null;
      }),
      findsNothing,
    );
    expect(
      find.byWidgetPredicate((widget) {
        if (widget is! DecoratedBox || widget.decoration is! BoxDecoration) {
          return false;
        }
        final border = (widget.decoration as BoxDecoration).border;
        return border is Border &&
            border.top.style == BorderStyle.none &&
            border.left.style == BorderStyle.none &&
            border.right.style == BorderStyle.none &&
            border.bottom.style != BorderStyle.none;
      }),
      findsNothing,
    );
    expect(find.bySemanticsLabel('Действия'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Edit account'));
    expect(invocations, 1);
  });

  testWidgets('link invokes through pointer and keyboard', (tester) async {
    var invocations = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterCard(
          child: CarpenterLink(
            label: 'Open account',
            autofocus: true,
            onInvoke: () => invocations += 1,
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('Open account'));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(invocations, 2);
  });
}

String _term((String, String) value) => value.$1;

Widget _value(BuildContext context, (String, String) value) =>
    CarpenterText.body(value.$2);
