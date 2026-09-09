import 'package:carpenter/carpenter_older.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' hide Text;
import 'package:flutter/widgets.dart' as widgets show Text;
import 'package:flutter_test/flutter_test.dart';

Finder _findText(String value) => find.byWidgetPredicate(
  (widget) =>
      (widget is widgets.Text &&
          widget is! CarpenterText &&
          widget.data == value) ||
      (widget is EditableText && widget.controller.text == value),
);

Widget _host(Widget child, {double width = 280, double height = 720}) =>
    CarpenterScope.fromConfig(
      config: const CarpenterConfig(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(width: width, height: height, child: child),
        ),
      ),
    );

void main() {
  testWidgets('page, list and form blocks reflow at narrow widths', (
    tester,
  ) async {
    final selection = CarpenterSelectionController<String>(
      identity: (item) => item,
    )..toggle('record');

    Future<void> pumpAndExpect(Widget child) async {
      await tester.pumpWidget(_host(SingleChildScrollView(child: child)));
      expect(tester.takeException(), isNull);
    }

    await pumpAndExpect(
      CarpenterPageSection(
        id: CarpenterPageSectionId('narrow.section'),
        title: 'Длинный заголовок раздела',
        description: 'Описание раздела',
        commands: [
          CarpenterButton(
            type: .outlined,
            color: .secondary,
            onPressed: () {},
            child: const CarpenterText('Действие раздела'),
          ),
        ],
        child: const CarpenterText('Содержимое'),
      ),
    );
    expect(
      tester.getTopLeft(_findText('Действие раздела')).dy,
      greaterThan(tester.getBottomLeft(_findText('Описание раздела')).dy),
    );

    await pumpAndExpect(
      CarpenterListTile(
        title: const CarpenterText('Длинное название записи'),
        subtitle: const CarpenterText('Дополнительное описание записи'),
        trailing: CarpenterTrailingActions(
          actions: [
            CarpenterButton(
              type: .outlined,
              color: .secondary,
              onPressed: () {},
              child: const CarpenterText('Первое'),
            ),
            CarpenterButton(
              type: .outlined,
              color: .secondary,
              onPressed: () {},
              child: const CarpenterText('Второе'),
            ),
          ],
        ),
      ),
    );
    expect(
      tester.getTopLeft(_findText('Первое')).dy,
      greaterThan(tester.getTopLeft(_findText('Длинное название записи')).dy),
    );

    await pumpAndExpect(
      CarpenterSelectionBar<String>(
        controller: selection,
        commands: [
          CarpenterButton(
            type: .outlined,
            color: .secondary,
            onPressed: () {},
            child: const CarpenterText('Обработать'),
          ),
        ],
      ),
    );
    await pumpAndExpect(
      CarpenterNotice(
        title: const CarpenterText('Не удалось выполнить длинное действие'),
        content: const CarpenterText('Подробности ошибки остаются доступными.'),
        action: CarpenterButton(
          type: .outlined,
          color: .secondary,
          onPressed: () {},
          child: const CarpenterText('Повторить действие'),
        ),
        onClose: () {},
      ),
    );
    await pumpAndExpect(
      CarpenterPaginationBar(
        leading: const CarpenterText('Всего записей: 10 000'),
        page: 2,
        totalPages: 99,
        onPageChanged: (_) {},
      ),
    );
    await pumpAndExpect(
      const CarpenterFormField(
        label: 'Очень длинное обязательное наименование поля',
        required: true,
        child: CarpenterInput(),
      ),
    );
    selection.dispose();
  });

  testWidgets('filters, compact controls and timeline stay within 280 pixels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        SingleChildScrollView(
          child: CarpenterBlockGroup(
            spacing: 12,
            children: [
              CarpenterFilterControl(
                width: 440,
                child: CarpenterInput(placeholder: 'Поиск'),
              ),
              CarpenterSegmentedRadio<String>(
                value: 'one',
                options: const [
                  CarpenterSegmentedOption(
                    value: 'one',
                    label: 'Первый вариант',
                  ),
                  CarpenterSegmentedOption(
                    value: 'two',
                    label: 'Второй вариант',
                  ),
                  CarpenterSegmentedOption(
                    value: 'three',
                    label: 'Третий вариант',
                  ),
                ],
              ),
              const CarpenterSwitch(
                checked: true,
                label: 'Показывать архивные и неактивные записи',
              ),
              CarpenterTimeline(
                items: [
                  CarpenterTimelineItem(
                    id: 'narrow',
                    title: const CarpenterText(
                      'Создана запись с длинным названием',
                    ),
                    description: const CarpenterText(
                      'Подробное описание изменения',
                    ),
                    timestamp: DateTime(2026, 8, 8, 12, 30),
                  ),
                ],
              ),
              CarpenterColorPicker(
                value: const Color(0xFF356AE6),
                onChanged: (_) {},
                paletteHeight: 80,
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(CarpenterFilterControl)).width, 280);
    expect(
      tester.getTopLeft(_findText('2026-08-08T12:30:00.000')).dy,
      greaterThan(
        tester.getTopLeft(_findText('Создана запись с длинным названием')).dy,
      ),
    );
  });

  testWidgets(
    'surfaces and split layouts do not clamp past a narrow viewport',
    (tester) async {
      late CarpenterSurfaceController surfaces;
      await tester.pumpWidget(
        _host(
          CarpenterSurfaceHost(
            child: Builder(
              builder: (context) {
                surfaces = context.surfaces;
                return const CarpenterText('Основа');
              },
            ),
          ),
          width: 280,
        ),
      );

      final result = surfaces.openSidePanel<String>(
        (_) => const SizedBox.expand(child: CarpenterText('Узкая панель')),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(tester.getSize(_findText('Узкая панель')).width, 280);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      expect(await result, isNull);

      await tester.pumpWidget(
        _host(
          const CarpenterAdaptiveSplitLayout(
            primary: CarpenterText('Основная область'),
            secondary: CarpenterText('Вторичная область'),
            narrowRegion: CarpenterSplitNarrowRegion.secondary,
            breakpoint: 400,
          ),
          width: 500,
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_findText('Основная область'), findsNothing);
      expect(_findText('Вторичная область'), findsOneWidget);
    },
  );
}
