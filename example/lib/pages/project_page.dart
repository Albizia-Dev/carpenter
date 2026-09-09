import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

import '../demo_routes.dart';

final class ProjectPage extends StatefulWidget {
  const ProjectPage({
    super.key,
    required this.projectId,
    required this.navigator,
    required this.toaster,
  });

  final String projectId;
  final DemoNavigator navigator;
  final CarpenterToasterController toaster;

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

final class _ProjectPageState extends State<ProjectPage> {
  static const _background = Color(0xFF111115);
  static const _surface = Color(0xFF242429);
  static const _surfaceStrong = Color(0xFF2D2D33);
  static const _border = Color(0xFF393940);
  static const _text = Color(0xFFE8E8EC);
  static const _muted = Color(0xFFAAAAB2);
  static const _accent = Color(0xFF5CA5E8);
  static const _accentDark = Color(0xFF172139);
  static const _statusBackground = Color(0xFF07344A);
  static const _statusText = Color(0xFF9CDCF8);
  static const _dangerBackground = Color(0xFF432426);
  static const _dangerText = Color(0xFFF08A8A);

  int _activeVolume = 1;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _projectHeader(),
              const SizedBox(height: 22),
              _sectionTitle('О проекте'),
              const SizedBox(height: 12),
              _metadata(),
              const SizedBox(height: 22),
              _documentActions(),
              const SizedBox(height: 12),
              _volumeTabs(),
              const SizedBox(height: 18),
              _stageLabel(),
              const SizedBox(height: 14),
              _search(),
              const SizedBox(height: 10),
              _documentsTable(),
              const SizedBox(height: 24),
              _sectionTitle('Связи'),
              const SizedBox(height: 12),
              _relationRow(
                title: 'Связанные договоры',
                emptyText: 'Нет связанных договоров',
              ),
              const SizedBox(height: 14),
              _relationRow(
                title: 'Связанные задачи',
                emptyText: 'Нет связанных задач',
              ),
              const SizedBox(height: 14),
              _relationRow(
                title: 'Связанные договоры',
                emptyText: '',
              ),
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: _trashButton()),
              const SizedBox(height: 22),
              _sectionTitle('Линейный объект Демо-объект 25'),
              const SizedBox(height: 22),
              _sectionTitle('Этапы оплаты'),
              const SizedBox(height: 10),
              _paymentStages(),
              const SizedBox(height: 18),
              _sectionTitle('Авансы'),
              const SizedBox(height: 10),
              _advances(),
              const SizedBox(height: 18),
              _execution(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _projectHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('№104. Демо-объект 25', size: 18, weight: FontWeight.w700),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _statusBackground,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: _label(
                    'Отдано на согласование',
                    size: 12,
                    color: _statusText,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        _button('✎  Редактировать'),
        const SizedBox(width: 8),
        _iconButton('⋯'),
      ],
    );
  }

  Widget _metadata() {
    return Column(
      children: [
        _metadataRow('Ник', 'Демо-объект 25', trailing: '✎   ⓘ   ⋯'),
        _metadataRow('Контрагент-заказчик', 'ООО «Ромашка»', link: true),
        _metadataRow('№ документа стадии П', '22-12'),
        _metadataRow('№ документа стадии Р', ''),
        _metadataRow('Проектировщики', 'Нет выбранных пользователей', centered: true),
        _metadataRow('ГИП', 'Нет выбранных пользователей', centered: true),
      ],
    );
  }

  Widget _metadataRow(
    String name,
    String value, {
    bool link = false,
    bool centered = false,
    String trailing = '✎',
  }) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          SizedBox(
            width: 265,
            child: _label(name, size: 12, color: _muted, weight: FontWeight.w600),
          ),
          Expanded(
            child: Align(
              alignment: centered ? Alignment.center : Alignment.centerLeft,
              child: _label(
                value,
                size: 13,
                color: link ? const Color(0xFFB99AF5) : _text,
                decoration: link ? TextDecoration.underline : null,
              ),
            ),
          ),
          SizedBox(
            width: 76,
            child: Align(
              alignment: Alignment.centerRight,
              child: _label(trailing, size: 13, color: _muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _documentActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _button('▣  Добавить раздел'),
        const SizedBox(width: 8),
        _button('▱  Добавить файл'),
        const SizedBox(width: 8),
        _iconButton('⋯'),
      ],
    );
  }

  Widget _volumeTabs() {
    const labels = ['Общее', 'Тома П', 'Тома Р'];
    return Row(
      children: List.generate(labels.length, (index) {
        final active = index == _activeVolume;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _activeVolume = index),
            child: Container(
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? _accent : _accentDark,
                border: Border.all(color: _background, width: 1),
                borderRadius: index == 0
                    ? const BorderRadius.horizontal(left: Radius.circular(6))
                    : index == labels.length - 1
                    ? const BorderRadius.horizontal(right: Radius.circular(6))
                    : null,
              ),
              child: _label(
                '${index == 0 ? '▣' : '◇'}  ${labels[index]}',
                size: 12,
                color: active ? const Color(0xFF10141A) : _accent,
                weight: FontWeight.w600,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _stageLabel() {
    return Row(
      children: [
        Transform.rotate(
          angle: .34,
          child: Container(width: 11, height: 1, color: const Color(0xFF8B62D8)),
        ),
        const SizedBox(width: 6),
        _label('Стадия П', size: 12, color: _muted, weight: FontWeight.w600),
      ],
    );
  }

  Widget _search() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Поиск в текущем разделе', size: 12, color: _muted, weight: FontWeight.w600),
        const SizedBox(height: 7),
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF666674)),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              _label('⌕', size: 18, color: _muted),
              const SizedBox(width: 7),
              _label('Название материала', size: 12, color: _muted),
            ],
          ),
        ),
      ],
    );
  }

  Widget _documentsTable() {
    final rows = <List<String>>[
      ['›   ▥  Электрика   ✎', '1', '', '✎', '', '⋯'],
      ['    ▥  Отопление   ✎', '2', '', '✎', '', '⋯'],
      ['›   ▥  Тестовый раздел   ✎', '3', '', '✎', '', '⋯'],
      ['›   ▥  Конструкции   ✎', '4', '', '✎', '', '⋯'],
      ['    ▱  demo-1.jpg', '', '', '', '', '@'],
      ['    ▱  demo.jpg', '', '', '', '', '@'],
      ['    ▱  Предварительный план.pdf', '', '', '', '', '@'],
      ['    ▱  Предварительный расчёт.xlsx', '', '', '', '', '@'],
      ['    ▱  Электронный макет.dwg', '', '', '', '', '@'],
    ];

    return _grid(
      header: const ['Наименование', '№', 'Шифр', 'Проектировщик', 'Статус', ''],
      flexes: const [6, 2, 4, 4, 3, 1],
      rows: rows,
      rowHeight: 34,
    );
  }

  Widget _relationRow({required String title, required String emptyText}) {
    return SizedBox(
      minHeight: 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 220,
            child: _label(title, size: 12, weight: FontWeight.w600),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 22),
              child: Align(
                alignment: Alignment.center,
                child: _label(emptyText, size: 12, color: _muted),
              ),
            ),
          ),
          _iconButton('⊕'),
        ],
      ),
    );
  }

  Widget _paymentStages() {
    return _grid(
      header: const [
        'Название этапа',
        'Сумма в руб.',
        'Срок',
        'Срок ПРД',
        'Акт у Заказчика',
        'Возвращён оригинал',
      ],
      flexes: const [5, 3, 2, 2, 3, 3],
      rows: const [
        ['Аванс', '', '90', '0', '☐', '☐'],
        ['Этап оплаты 1', '', '90', '0', '☐', '☐'],
        ['Этап оплаты 2', '', '90', '0', '☐', '☐'],
        ['Этап оплаты 3', '', '90', '0', '☐', '☐'],
      ],
      footer: const ['Итого', '0,00', '360', '', '', ''],
      rowHeight: 43,
    );
  }

  Widget _advances() {
    return _grid(
      header: const ['Авансы', 'Сумма акта', 'Дата акта', 'Факт. сумма', 'Факт. дата'],
      flexes: const [5, 3, 3, 3, 3],
      rows: const [
        ['Демо-аванс', '0,00', '20.08.2026', '50 000,00', '26.05.2026'],
      ],
      footer: const ['Итого', '0,00', '', '50 000,00', ''],
      rowHeight: 43,
    );
  }

  Widget _execution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _grid(
          header: const ['Выполнение', 'Сумма акта', 'Дата акта', 'Зачёт аванса', 'Факт. сумма'],
          flexes: const [5, 3, 3, 3, 3],
          rows: const [
            ['', '0,00', '20.08.2026', '0,00', '400,00'],
          ],
          footer: const ['Итого', '0,00', '', '0,00', '400,00'],
          rowHeight: 43,
        ),
      ],
    );
  }

  Widget _grid({
    required List<String> header,
    required List<int> flexes,
    required List<List<String>> rows,
    List<String>? footer,
    double rowHeight = 36,
  }) {
    Widget buildRow(
      List<String> cells, {
      required Color background,
      required FontWeight weight,
      required bool separators,
      required double height,
    }) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: background,
          border: const Border(bottom: BorderSide(color: _border)),
        ),
        child: Row(
          children: List.generate(cells.length, (index) {
            return Expanded(
              flex: flexes[index],
              child: Container(
                height: double.infinity,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: separators && index < cells.length - 1
                    ? const BoxDecoration(
                        border: Border(right: BorderSide(color: _border)),
                      )
                    : null,
                child: _label(
                  cells[index],
                  size: 12,
                  weight: weight,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            );
          }),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: DecoratedBox(
        decoration: BoxDecoration(border: Border.all(color: _border)),
        child: Column(
          children: [
            buildRow(
              header,
              background: _surface,
              weight: FontWeight.w700,
              separators: true,
              height: 36,
            ),
            for (final row in rows)
              buildRow(
                row,
                background: _surfaceStrong,
                weight: FontWeight.w400,
                separators: false,
                height: rowHeight,
              ),
            if (footer case final footerCells?)
              buildRow(
                footerCells,
                background: _surface,
                weight: FontWeight.w700,
                separators: false,
                height: 34,
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String value) =>
      _label(value, size: 13, weight: FontWeight.w700);

  Widget _button(String value) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _surfaceStrong,
        borderRadius: BorderRadius.circular(7),
      ),
      child: _label(value, size: 12, color: _muted, weight: FontWeight.w600),
    );
  }

  Widget _iconButton(String value) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _surfaceStrong,
        borderRadius: BorderRadius.circular(7),
      ),
      child: _label(value, size: 15, color: _muted, weight: FontWeight.w600),
    );
  }

  Widget _trashButton() {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _dangerBackground,
        borderRadius: BorderRadius.circular(7),
      ),
      child: _label('♙', size: 14, color: _dangerText),
    );
  }

  Widget _label(
    String value, {
    double size = 13,
    Color color = _text,
    FontWeight weight = FontWeight.w400,
    TextDecoration? decoration,
    TextOverflow? overflow,
    int? maxLines,
  }) {
    return Text(
      value,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        decoration: decoration,
        decorationColor: color,
        height: 1.2,
      ),
    );
  }
}