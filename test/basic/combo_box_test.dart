import 'package:carpenter/carpenter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  const firstOptions = [
    CarpenterOption(id: 'a', value: 1, label: 'Alpha'),
    CarpenterOption(id: 'b', value: 2, label: 'Bravo'),
  ];

  testWidgets('query and selected value are controlled', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final queries = <String>[];
    int? selected;
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterComboBox<int>(
              controller: controller,
              value: selected,
              onChanged: (value) => update(() => selected = value),
              onQueryChanged: queries.add,
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              options: firstOptions,
            );
          },
        ),
      ),
    );
    await tester.enterText(find.byType(EditableText), 'Al');
    expect(queries, contains('Al'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(controller.text, 'Alpha');
    expect(queries.last, 'Alpha');
  });

  testWidgets('open menu does not block pointer editing in its input', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Alpha Bravo');
    addTearDown(controller.dispose);
    var open = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterComboBox<int>(
              controller: controller,
              value: null,
              onChanged: (_) {},
              onQueryChanged: (_) {},
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              options: firstOptions,
            );
          },
        ),
      ),
    );

    final editor = find.byType(EditableText);
    await tester.tap(editor);
    await tester.pumpAndSettle();
    expect(open, isTrue);

    final rect = tester.getRect(editor);
    await tester.tapAt(rect.centerLeft + const Offset(1, 0));
    await tester.pump();

    expect(open, isTrue);
    expect(controller.selection.baseOffset, lessThan(controller.text.length));
  });

  testWidgets('pointer selection updates value, query and closes menu', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var open = true;
    int? selected;
    final queries = <String>[];
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterComboBox<int>(
              controller: controller,
              value: selected,
              onChanged: (value) => update(() => selected = value),
              onQueryChanged: queries.add,
              open: open,
              onOpenChanged: (value) => update(() => open = value),
              options: firstOptions,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bravo').last);
    await tester.pumpAndSettle();

    expect(selected, 2);
    expect(controller.text, 'Bravo');
    expect(queries, ['Bravo']);
    expect(open, isFalse);
  });

  testWidgets('IME composing is not intercepted by suggestion activation', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    int? selected;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        CarpenterComboBox<int>(
          controller: controller,
          value: null,
          onChanged: (value) => selected = value,
          onQueryChanged: (_) {},
          open: true,
          onOpenChanged: (_) {},
          options: firstOptions,
          autofocus: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.value = const TextEditingValue(
      text: 'a',
      selection: TextSelection.collapsed(offset: 1),
      composing: TextRange(start: 0, end: 1),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, isNull);
  });

  testWidgets('async replacement removes stale highlight', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var options = firstOptions;
    int? selected;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterOverlayHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterComboBox<int>(
              controller: controller,
              value: selected,
              onChanged: (value) => selected = value,
              onQueryChanged: (_) {},
              open: true,
              onOpenChanged: (_) {},
              options: options,
              autofocus: true,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    update(
      () => options = const [
        CarpenterOption(id: 'c', value: 3, label: 'Charlie'),
      ],
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, isNull);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selected, 3);
  });

  testWidgets('loading, empty and failed states remain explicit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    for (final state in OptionsLoadState.values) {
      await tester.pumpWidget(
        carpenterOverlayHarness(
          CarpenterComboBox<int>(
            controller: controller,
            value: null,
            onChanged: (_) {},
            onQueryChanged: (_) {},
            open: true,
            onOpenChanged: (_) {},
            options: const [],
            loadState: state,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
