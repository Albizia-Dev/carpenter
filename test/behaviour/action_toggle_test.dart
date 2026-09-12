import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'one controlled toggle keeps state across button, icon and menu',
    (tester) async {
      var value = false;
      var changes = 0;
      await tester.pumpWidget(
        CarpenterApp(
          child: StatefulBuilder(
            builder: (context, setState) {
              final action = CarpenterActionDescriptor.toggle(
                id: 'matching',
                label: 'Совпадение по ИНН',
                icon: GravityIcons.person,
                value: value,
                colorRole: ActionColorRole.success,
                onChanged: (next) => setState(() {
                  value = next;
                  changes++;
                }),
              );
              return Column(
                children: [
                  CarpenterButton.fromAction(action),
                  CarpenterIconButton.fromAction(action),
                  CarpenterMenu(items: [CarpenterMenuItem(action: action)]),
                ],
              );
            },
          ),
        ),
      );
      final textButton = find.byType(CarpenterButton);
      void check(bool expected) => expect(
        tester.getSemantics(textButton),
        matchesSemantics(
          label: 'Совпадение по ИНН',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasToggledState: true,
          isToggled: expected,
        ),
      );
      check(false);
      final offColor = tester
          .widget<Text>(find.text('Совпадение по ИНН').first)
          .style!
          .color;
      await tester.tap(textButton);
      await tester.pumpAndSettle();
      check(true);
      expect(
        tester.widget<Text>(find.text('Совпадение по ИНН').first).style!.color,
        isNot(offColor),
      );
      await tester.tap(find.byType(CarpenterIconButton));
      await tester.pumpAndSettle();
      check(false);
      await tester.tap(
        find.descendant(
          of: find.byType(CarpenterMenu),
          matching: find.text('Совпадение по ИНН'),
        ),
      );
      await tester.pumpAndSettle();
      check(true);
      expect(changes, 3);
      expect(
        tester.getSemantics(find.text('Совпадение по ИНН').last),
        matchesSemantics(
          label: 'Совпадение по ИНН',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          hasToggledState: true,
          isToggled: true,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('disabled toggle exposes state without invoking a change', (
    tester,
  ) async {
    await tester.pumpWidget(
      CarpenterApp(
        child: CarpenterButton.fromAction(
          CarpenterActionDescriptor.toggle(
            id: 'disabled',
            label: 'Фильтр',
            value: true,
            onChanged: null,
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(CarpenterButton)),
      matchesSemantics(
        label: 'Фильтр',
        isButton: true,
        hasEnabledState: true,
        hasToggledState: true,
        isToggled: true,
      ),
    );
  });
}
