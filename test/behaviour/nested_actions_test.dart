import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import '../helpers/harness.dart';

void main() {
  CarpenterActionDescriptor group(VoidCallback invoke) =>
      CarpenterActionDescriptor.group(
        id: 'excel',
        label: 'Excel',
        children: [
          const CarpenterActionDescriptor(
            id: 'disabled',
            label: 'Недоступно',
            onInvoke: null,
          ),
          CarpenterActionDescriptor.group(
            id: 'reports',
            label: 'Отчёты',
            children: [
              CarpenterActionDescriptor(
                id: 'all',
                label: 'Все проекты',
                onInvoke: invoke,
              ),
            ],
          ),
        ],
      );

  testWidgets('nested menu navigates, goes back and invokes a leaf once', (
    tester,
  ) async {
    var calls = 0;
    var dismissed = 0;
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterMenu(
          items: [CarpenterMenuItem(action: group(() => calls++))],
          onDismissRequested: () => dismissed++,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(find.text('Отчёты'), findsOneWidget);
    expect(dismissed, 0);
    await tester.tap(find.text('Недоступно'));
    expect(calls, 0);
    await tester.tap(find.text('Отчёты'));
    await tester.pump();
    expect(find.text('Все проекты'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('Отчёты'), findsOneWidget);
    expect(dismissed, 0);
    await tester.tap(find.text('Отчёты'));
    await tester.pump();
    await tester.tap(find.text('Все проекты'));
    expect(calls, 1);
    expect(dismissed, 1);
  });

  for (final overflow in [false, true]) {
    testWidgets('action group opens ${overflow ? 'from overflow' : 'inline'}', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        carpenterOverlayHarness(
          SizedBox(
            width: 1000,
            child: CarpenterToolbar(
              items: [
                CarpenterToolbarItem(
                  action: group(() => calls++),
                  group: overflow
                      ? CarpenterToolbarGroup.overflow
                      : CarpenterToolbarGroup.primary,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      if (overflow) {
        await tester.tap(find.byType(CarpenterIconButton));
        await tester.pump();
      }
      await tester.tap(find.text('Excel'));
      await tester.pump();
      await tester.tap(find.text('Отчёты'));
      await tester.pump();
      await tester.tap(find.text('Все проекты'));
      await tester.pump();
      expect(calls, 1);
      expect(find.byType(CarpenterMenu), findsNothing);
    });
  }

  testWidgets('page header keeps overflow hidden on a wide screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterOverlayHarness(
        SizedBox(
          width: 1800,
          child: CarpenterPageHeader(
            title: 'Проекты+',
            primaryActions: [
              CarpenterActionDescriptor(
                id: 'create',
                label: 'Создать',
                onInvoke: () {},
              ),
            ],
            overflowActions: [group(() {})],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Создать'), findsOneWidget);
    expect(find.text('Excel'), findsNothing);
    await tester.tap(find.byType(CarpenterIconButton));
    await tester.pump();
    expect(find.text('Excel'), findsOneWidget);
  });
}
