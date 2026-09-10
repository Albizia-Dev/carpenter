import 'package:carpenter/carpenter.dart';
import 'package:carpenter/src/components/behaviour/action_strip.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/harness.dart';

void main() {
  testWidgets('narrow definition keeps text action visible below its value', (
    tester,
  ) async {
    var invoked = false;
    await tester.pumpWidget(
      carpenterHarness(
        Center(
          child: SizedBox(
            width: 350,
            child: CarpenterDefinitionList<String>(
              items: const ['Актуальная версия'],
              term: (item) => item,
              valueBuilder: (_, _) =>
                  const Text('Северный парк · корректировка'),
              actions: (_) => [
                CarpenterActionDescriptor(
                  id: 'load',
                  label: 'Загрузить актуальную',
                  onInvoke: () => invoked = true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final action = find.text('Загрузить актуальную');
    expect(action, findsOneWidget);
    expect(
      tester.getRect(action).top,
      greaterThan(
        tester.getRect(find.text('Северный парк · корректировка')).bottom,
      ),
    );
    await tester.tap(action);
    expect(invoked, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets('short definition values keep their action nearby on desktop', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterDefinitionList<String>(
          items: const ['Ник'],
          term: (item) => item,
          valueBuilder: (_, _) => const Text('Северный парк'),
          actions: (_) => [
            CarpenterActionDescriptor(
              id: 'edit',
              label: 'Изменить',
              icon: GravityIcons.pencil,
              onInvoke: () {},
            ),
          ],
        ),
      ),
    );
    final value = tester.getRect(find.text('Северный парк'));
    final action = tester.getRect(find.byType(CarpenterActionStrip));
    expect(action.left - value.right, inInclusiveRange(0, 24));
    expect((action.center.dy - value.center.dy).abs(), lessThan(1));
    expect(tester.takeException(), isNull);
  });
  testWidgets('scaled table header uses complete lines within a fixed row', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const SizedBox(
          width: 140,
          height: 56,
          child: CarpenterTableText.header('Очень длинное название колонки'),
        ),
        textScale: 2,
      ),
    );
    final text = tester.widget<Text>(
      find.text('Очень длинное название колонки'),
    );
    expect(text.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tree retains surviving row identities when roots are filtered', (
    tester,
  ) async {
    var filtered = false;
    late StateSetter update;
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return CarpenterTreeView<String>(
              nodes: [
                if (!filtered)
                  const CarpenterTreeNode(
                    id: 'first',
                    value: 'first',
                    label: 'Первый файл',
                  ),
                const CarpenterTreeNode(
                  id: 'second',
                  value: 'second',
                  label: 'Второй файл',
                ),
              ],
            );
          },
        ),
      ),
    );
    update(() => filtered = true);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Первый файл'), findsNothing);
    expect(find.text('Второй файл'), findsOneWidget);
    update(() => filtered = false);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.text('Первый файл'), findsOneWidget);
  });

  testWidgets('status background stays compact in a stretched metadata group', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const CarpenterBlockGroup(
          children: [
            CarpenterStatusIndicator(
              label: 'Готово',
              role: FeedbackColorRole.success,
            ),
          ],
        ),
      ),
    );
    final background = find.descendant(
      of: find.byType(CarpenterStatusIndicator),
      matching: find.byType(DecoratedBox),
    );
    expect(tester.getSize(background).width, lessThan(150));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one icon action leaves most of a definition value lane usable', (
    tester,
  ) async {
    const valueKey = ValueKey('value');
    await tester.pumpWidget(
      carpenterHarness(
        CarpenterDefinitionList<String>(
          items: const ['Заказчик'],
          term: (item) => item,
          valueBuilder: (_, _) => const SizedBox(
            key: valueKey,
            child: CarpenterText.body('Длинное название организации'),
          ),
          actions: (_) => [
            CarpenterActionDescriptor(
              id: 'edit',
              label: 'Изменить',
              icon: GravityIcons.pencil,
              onInvoke: () {},
            ),
          ],
        ),
      ),
    );
    expect(tester.getSize(find.byKey(valueKey)).width, greaterThan(320));
    expect(tester.takeException(), isNull);
  });

  testWidgets('wrapped scopes preserve keyboard order across rows', (
    tester,
  ) async {
    var selected = 'a';
    await tester.pumpWidget(
      carpenterHarness(
        StatefulBuilder(
          builder: (context, setState) => CarpenterSelectionButtonGroup<String>(
            fillAvailableWidth: true,
            options: const [
              CarpenterSelectionButtonOption(value: 'a', label: 'Общее'),
              CarpenterSelectionButtonOption(value: 'b', label: 'Тома П'),
              CarpenterSelectionButtonOption(
                value: 'c',
                label: 'Система электроснабжения',
              ),
            ],
            value: selected,
            onChanged: (next) => setState(() => selected = next),
          ),
        ),
      ),
    );
    final first = tester.getRect(find.bySemanticsLabel('Общее'));
    final last = tester.getRect(
      find.bySemanticsLabel('Система электроснабжения'),
    );
    expect(last.top, greaterThan(first.bottom));
    tester
        .widget<FocusableActionDetector>(
          find.byType(FocusableActionDetector).first,
        )
        .focusNode!
        .requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(selected, 'c');
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pump();
    expect(selected, 'a');
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow action label occupies one line inside its control', (
    tester,
  ) async {
    await tester.pumpWidget(
      carpenterHarness(
        const SizedBox(
          width: 160,
          child: CarpenterButton(
            label: 'Добавить стандартную директорию',
            icon: GravityIcons.folderPlus,
          ),
        ),
        textScale: 2,
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byType(CarpenterButton),
            matching: find.byType(RichText),
          )
          .first,
    );
    expect(paragraph.maxLines, 1);
    expect(paragraph.didExceedMaxLines, isTrue);
    expect(
      tester.getRect(find.byType(RichText)).height,
      lessThanOrEqualTo(tester.getSize(find.byType(CarpenterButton)).height),
    );
    expect(tester.takeException(), isNull);
  });
}
