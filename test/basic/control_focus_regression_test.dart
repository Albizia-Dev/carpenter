import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/internal/rendering/focus_ring.dart';
import 'package:carpenter/src/internal/selection/menu_panel.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'selected tab has no mouse focus outline and roves with keyboard',
    (tester) async {
      final strategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() => FocusManager.instance.highlightStrategy = strategy);
      var value = 1;
      final after = FocusNode();
      addTearDown(after.dispose);
      await tester.pumpWidget(
        CarpenterApp(
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                CarpenterTabs<int>(
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                  tabs: const [
                    CarpenterTab(value: 1, label: 'One'),
                    CarpenterTab(value: 2, label: 'Two'),
                    CarpenterTab(value: 3, label: 'Three'),
                  ],
                ),
                CarpenterButton(
                  label: 'After',
                  focusNode: after,
                  onInvoke: () {},
                ),
              ],
            ),
          ),
        ),
      );
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(find.text('Two')));
      await mouse.down(tester.getCenter(find.text('Two')));
      await mouse.up();
      await tester.pumpAndSettle();
      expect(value, 2);
      final tabs = find.byType(CarpenterTabs<int>);
      expect(
        tester
            .widgetList<FocusRing>(
              find.descendant(of: tabs, matching: find.byType(FocusRing)),
            )
            .any((ring) => ring.visible),
        isFalse,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(value, 3);
      expect(
        tester
            .widgetList<FocusRing>(
              find.descendant(of: tabs, matching: find.byType(FocusRing)),
            )
            .any((ring) => ring.visible),
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(value, 2);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      expect(after.hasFocus, isTrue);
      await mouse.removePointer();
    },
  );
  for (final combo in [false, true]) {
    testWidgets(
      '${combo ? 'combo' : 'autosuggest'} closes on Tab and allows one-click adjacent field focus',
      (tester) async {
        final text = TextEditingController();
        final nextText = TextEditingController();
        final focus = FocusNode();
        final next = FocusNode();
        addTearDown(text.dispose);
        addTearDown(nextText.dispose);
        addTearDown(focus.dispose);
        addTearDown(next.dispose);
        final options = [
          const CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
        ];
        await tester.pumpWidget(
          CarpenterApp(
            child: Column(
              children: [
                combo
                    ? CarpenterComboBox<int>(
                        controller: text,
                        value: null,
                        focusNode: focus,
                        onQueryChanged: (_) {},
                        onChanged: (_) {},
                        options: options,
                      )
                    : CarpenterAutosuggest<int>(
                        controller: text,
                        focusNode: focus,
                        onQueryChanged: (_) {},
                        onSuggestionSelected: (_) {},
                        suggestions: options,
                      ),
                const SizedBox(height: 180),
                CarpenterInput(controller: nextText, focusNode: next),
              ],
            ),
          ),
        );
        await tester.tap(find.byType(EditableText).first);
        await tester.pumpAndSettle();
        expect(find.byType(MenuPanel), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        expect(next.hasFocus, isTrue);
        expect(find.byType(MenuPanel), findsNothing);
        await tester.tap(find.byType(EditableText).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(EditableText).last);
        await tester.pumpAndSettle();
        expect(next.hasFocus, isTrue);
        expect(find.byType(MenuPanel), findsNothing);
        await tester.tap(find.byType(EditableText).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alpha'));
        await tester.pumpAndSettle();
        expect(focus.hasFocus, isTrue);
        expect(find.byType(MenuPanel), findsNothing);
      },
    );
  }
}
