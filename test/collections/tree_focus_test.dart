import 'package:carpenter/carpenter.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final pointer in [PointerDeviceKind.mouse, PointerDeviceKind.touch]) {
    testWidgets('row selection takes keyboard focus from an input: $pointer', (
      tester,
    ) async {
      final input = FocusNode();
      final text = TextEditingController();
      addTearDown(text.dispose);
      addTearDown(input.dispose);
      Set<Object> selected = {};
      var commands = 0;
      await tester.pumpWidget(
        CarpenterApp(
          child: StatefulBuilder(
            builder: (context, update) => Column(
              children: [
                CarpenterInput(controller: text, focusNode: input),
                Expanded(
                  child: CallbackShortcuts(
                    bindings: {
                      const SingleActivator(LogicalKeyboardKey.f2): () =>
                          commands++,
                    },
                    child: CarpenterTreeTable<String>(
                      nodes: const [
                        CarpenterTreeNode(
                          id: 'one',
                          value: 'one',
                          label: 'Материал',
                        ),
                        CarpenterTreeNode(
                          id: 'two',
                          value: 'two',
                          label: 'Второй',
                        ),
                      ],
                      treeHeader: 'Имя',
                      treeCellBuilder: (_, node, _) => Text(node.label),
                      columns: const [],
                      selectedIds: selected,
                      selectionMode: CarpenterTreeSelectionMode.multiple,
                      onSelectionChanged: (value) =>
                          update(() => selected = value),
                      onActivated: (_) {},
                      onDrop: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      input.requestFocus();
      await tester.pumpAndSettle();
      expect(input.hasFocus, isTrue);
      await tester.tap(find.text('Материал'), kind: pointer);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(selected, {'one'});
      expect(input.hasFocus, isFalse);
      await tester.sendKeyEvent(LogicalKeyboardKey.f2);
      expect(commands, 1);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(selected, contains('two'));
      expect(tester.takeException(), isNull);
    });
  }
}
