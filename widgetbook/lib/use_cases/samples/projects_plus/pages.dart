import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import '../dsktp_layouts.dart';
import 'specs.dart';

enum ProjectsPlusState { ready, loading, empty, error, conflict, readOnly }

/// Deterministic, backend-free Projects+ compositions; state belongs to the preview.
class ProjectsPlusPreview extends StatefulWidget {
  const ProjectsPlusPreview({
    super.key,
    required this.pageId,
    this.visualState = ProjectsPlusState.ready,
  });
  final String pageId;
  final ProjectsPlusState visualState;
  @override
  State<ProjectsPlusPreview> createState() => _PreviewState();
}

class _PreviewState extends State<ProjectsPlusPreview> {
  late String _id = widget.pageId;
  final _inputs = <String, TextEditingController>{};
  final _entityQueries = <String, String>{};
  final _moves = <String, int>{};
  bool _filtersOpen = false;
  bool _editingFinancials = false;
  bool _onlySuspended = false;
  bool _recovered = false;
  String? _feedback;
  String? _editingField;
  final _saved = <String, String>{};
  ProjectsPlusSpec get spec => projectsPlusSpecs.firstWhere((s) => s.id == _id);
  ProjectsPlusState get mode =>
      _recovered ? ProjectsPlusState.ready : widget.visualState;
  double get gap => context.units(CarpenterTheme.of(context).spacing.medium);
  TextEditingController input(String key, [String value = '']) =>
      _inputs.putIfAbsent(key, () => TextEditingController(text: value));
  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(ProjectsPlusPreview old) {
    super.didUpdateWidget(old);
    if (old.pageId != widget.pageId || old.visualState != widget.visualState) {
      _id = widget.pageId;
      _recovered = false;
      _feedback = null;
      _editingField = null;
      _filtersOpen = false;
      _onlySuspended = false;
    }
  }

  void open(String id) => setState(() {
    _id = id;
    _feedback = null;
    _editingField = null;
  });
  Widget stack(List<Widget> children) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) SizedBox(height: gap),
        child,
      ],
    ],
  );
  Widget text(String value) => CarpenterText.body(value);
  Widget section(String title, Widget child) => CarpenterRecordSection(
    id: CarpenterPageSectionId('$_id.$title'),
    title: title,
    child: child,
  );
  Widget details(Map<String, String> fields) =>
      CarpenterDefinitionList<MapEntry<String, String>>(
        items: fields.entries.toList(),
        term: (e) => e.key,
        valueBuilder: (context, e) => text(e.value),
      );
  Widget button(String label, VoidCallback action) =>
      CarpenterButton(label: label, onInvoke: action);
  Widget links(Map<String, String> destinations) => Wrap(
    spacing: gap,
    runSpacing: gap,
    children: [
      for (final e in destinations.entries) button(e.key, () => open(e.value)),
    ],
  );

  Widget search() =>
      !['board', 'sspBoard', 'orders', 'tenders'].contains(spec.kind)
      ? CarpenterInput(
          controller: input('$_id.search'),
          placeholder: 'Номер, название или контрагент',
          onChanged: (_) => setState(() {}),
        )
      : CarpenterFilterBar(
          searchController: input('$_id.search'),
          searchLabel: '',
          searchPlaceholder: 'Номер, название или контрагент',
          onSearchChanged: (_) => setState(() {}),
          semanticLabel: 'Поиск и фильтры',
          filterToggleLabel: 'Фильтры',
          filtersExpanded: _filtersOpen,
          onFiltersExpandedChanged: (v) => setState(() => _filtersOpen = v),
          activeFilterCount: _onlySuspended ? 1 : 0,
          activeFilterSummary: [
            if (_onlySuspended)
              button(
                'Приостановленные ×',
                () => setState(() => _onlySuspended = false),
              ),
          ],
          advancedFilters: CarpenterSelect<bool>(
            label: 'Состояние проекта',
            value: _onlySuspended,
            options: const [
              CarpenterOption(id: 'all', value: false, label: 'Все проекты'),
              CarpenterOption(
                id: 'suspended',
                value: true,
                label: 'Приостановленные',
              ),
            ],
            onChanged: (v) => setState(() => _onlySuspended = v),
          ),
        );

  Widget rows(List<(String, String, String)> values, {String? target}) {
    final q = input('$_id.search').text.toLowerCase();
    final filtered = values
        .where((r) => '${r.$1} ${r.$2}'.toLowerCase().contains(q))
        .toList();
    if (filtered.isEmpty) return text('Ничего не найдено');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in filtered.indexed) ...[
          if (i > 0)
            Container(
              height: 1,
              color: CarpenterTheme.of(context).overlay.border,
            ),
          CarpenterListTile(
            title: CarpenterText.label(
              r.$1,
              emphasis: TypographyEmphasis.strong,
            ),
            subtitle: Wrap(
              spacing: gap,
              runSpacing: gap / 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CarpenterText.caption(
                  r.$2,
                  colorRole: ContentColorRole.secondary,
                ),
                if (['В работе', 'На проверке', 'Заявка подана'].contains(r.$3))
                  CarpenterStatusIndicator(
                    label: r.$3,
                    role: FeedbackColorRole.info,
                  )
                else
                  CarpenterText.caption(
                    r.$3,
                    colorRole: ContentColorRole.secondary,
                  ),
              ],
            ),
            onInvoke: target == null ? null : () => open(target),
          ),
        ],
      ],
    );
  }

  static const documents = [
    ('Договор_18-26.pdf', '10.09.2026 · Михаил Соколов', '1,8 МБ'),
    ('Задание_на_проектирование.pdf', '09.09.2026 · Анна Иванова', '840 КБ'),
  ];
  static const tasks = [
    (
      'РСП № 307 · Рабочая документация',
      'Анна Иванова · Срок 18.09.2026',
      'В работе',
    ),
    (
      'РСП № 308 · Проверить замечания',
      'Алексей Петров · Срок 11.09.2026',
      'На проверке',
    ),
  ];

  Widget board() {
    final isProject = spec.kind == 'board';
    final stages = isProject
        ? [
            'Начато проектирование',
            'Отдано на согласование',
            'Есть все согласования',
            'Сдано',
          ]
        : spec.kind == 'sspBoard'
        ? [
            'Требуется',
            'Выписать счет',
            'Отдано на согласование',
            'Замечания',
            'Согласовано',
          ]
        : ['Новые', 'В работе', 'Завершены'];
    final titles = isProject
        ? [
            '№ 104 · Северный парк',
            '№ 105 · Школа на Озёрной',
            '№ 106 · Очистные сооружения',
            '№ 107 · Тепловой пункт',
          ]
        : spec.kind == 'sspBoard'
        ? [
            'ССП № 52 · Электроснабжение',
            'ССП № 53 · Водоснабжение',
            'ССП № 54 · Теплоснабжение',
          ]
        : spec.kind == 'orders'
        ? ['Заказ № 482 · Наружное освещение', 'Заказ № 483 · Водоснабжение']
        : ['Тендер № 126 · Северный парк', 'Тендер № 127 · Школа на Озёрной'];
    final q = input('$_id.search').text.toLowerCase();
    return stack([
      search(),
      SizedBox(
        height: context.units(34.rem),
        child: CarpenterKanban<int, String>(
          semanticLabel: spec.title,
          emptyLabel: 'Нет карточек',
          columns: [
            for (var i = 0; i < stages.length; i++)
              CarpenterKanbanColumn(
                id: i,
                value: i,
                title: stages[i],
                cards: [
                  for (final (index, title) in titles.indexed)
                    if ((_moves[title] ?? index % stages.length) == i &&
                        title.toLowerCase().contains(q) &&
                        (!_onlySuspended || index == 1))
                      title,
                ],
              ),
          ],
          cardKey: (card) => card,
          onMove: mode == ProjectsPlusState.readOnly
              ? null
              : (move) =>
                    setState(() => _moves[move.card] = move.targetColumn.value),
          cardBuilder: (context, title, cardState) => CarpenterCard(
            padded: false,
            child: CarpenterListTile(
              title: CarpenterText.label(
                title,
                emphasis: TypographyEmphasis.strong,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CarpenterText.caption(
                    isProject
                        ? 'ООО «Северный квартал»'
                        : spec.kind == 'sspBoard'
                        ? 'АО «Городские инженерные сети»'
                        : 'ООО «Северный квартал»',
                    colorRole: ContentColorRole.secondary,
                  ),
                  SizedBox(height: gap),
                  CarpenterText.body(
                    isProject
                        ? 'ГИП: Михаил Соколов'
                        : spec.kind == 'sspBoard'
                        ? 'Согласование до 18 сентября'
                        : spec.kind == 'orders'
                        ? '1 250 000,00 ₽'
                        : 'НМЦ: 12 500 000,00 ₽',
                  ),
                  CarpenterText.caption(
                    isProject
                        ? 'Проектировщик: Анна Иванова'
                        : spec.kind == 'sspBoard'
                        ? 'Том 5.1 · ИОС1 · 240 000,00 ₽'
                        : spec.kind == 'orders'
                        ? 'Наружное освещение · срок 30 сентября'
                        : 'Заявки до 18 сентября · 2 участника',
                    colorRole: ContentColorRole.secondary,
                  ),
                ],
              ),
              trailing: title.contains('105')
                  ? const CarpenterStatusIndicator(
                      label: 'Приостановлен',
                      role: FeedbackColorRole.warning,
                    )
                  : null,
              onInvoke: () => open(
                isProject
                    ? 'project'
                    : spec.kind == 'sspBoard'
                    ? 'sspDetails'
                    : spec.kind == 'orders'
                    ? 'order'
                    : 'tender',
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget table(List<String> headers, List<List<String>> values) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final query = input('$_id.search').text.toLowerCase();
          final visible = values
              .where((row) => row.join(' ').toLowerCase().contains(query))
              .toList();
          if (visible.isEmpty) return text('Ничего не найдено');
          Widget cell(List<String> row, int i) =>
              _editingFinancials &&
                  ![
                    'Разница: акт − оплата',
                    'Дней просрочки',
                    'Остаток незачтённых авансов',
                  ].contains(headers[i])
              ? CarpenterInput(
                  controller: input('financial.${row.first}.$i', row[i]),
                  semanticLabel: headers[i],
                )
              : CarpenterTableText.cell(
                  _inputs['financial.${row.first}.$i']?.text ?? row[i],
                );
          if (constraints.maxWidth <
              MediaQuery.textScalerOf(context).scale(context.units(40.rem))) {
            return stack([
              for (final row in visible)
                CarpenterExpander.listGroup(
                  initiallyExpanded: true,
                  header: text(row.first),
                  content: CarpenterDefinitionList<int>(
                    items: List.generate(headers.length - 1, (i) => i + 1),
                    term: (i) => headers[i],
                    valueBuilder: (context, i) => _editingFinancials
                        ? cell(row, i)
                        : text(
                            _inputs['financial.${row.first}.$i']?.text ??
                                row[i],
                          ),
                  ),
                ),
            ]);
          }
          return CarpenterEditableTable<List<String>>(
            items: visible,
            freezeFirstColumn: true,
            semanticLabel: headers.first,
            emptyMessage: 'Нет записей',
            columns: [
              for (var i = 0; i < headers.length; i++)
                CarpenterTableColumn<List<String>>.custom(
                  id: '$i',
                  header: headers[i],
                  cellBuilder: (context, row) => cell(row, i),
                  width: CarpenterTableColumnWidth.fixed(
                    width: i == 0 || headers[i].length > 18 ? 17.rem : 11.rem,
                  ),
                ),
            ],
          );
        },
      );

  Widget financials() => stack([
    Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        CarpenterButton(
          label: _editingFinancials
              ? 'Сохранить финансы'
              : 'Редактировать финансы',
          onInvoke: mode == ProjectsPlusState.readOnly
              ? null
              : () => setState(() {
                  _editingFinancials = !_editingFinancials;
                }),
        ),
      ],
    ),
    section(
      'Этапы оплаты',
      table(
        [
          'Название этапа',
          'Сумма в руб.',
          'Срок',
          'Срок ПРД',
          'Акт у Заказчика',
          'Возвращён оригинал',
          'Комментарий',
          'МГЭ',
        ],
        [
          [
            'Проектная документация',
            '1 500 000,00',
            '15.09.2026',
            '12.09.2026',
            'Да',
            'Нет',
            'После согласования',
            'Да',
          ],
          [
            'Рабочая документация',
            '2 000 000,00',
            '30.09.2026',
            '25.09.2026',
            'Нет',
            'Нет',
            'По комплектам',
            'Нет',
          ],
        ],
      ),
    ),
    section(
      'Авансы',
      table(
        [
          'Авансы',
          'Сумма акта',
          'Дата акта',
          'Факт. сумма',
          'Факт. дата',
          'Разница: акт − оплата',
          'Дней просрочки',
          'Остаток незачтённых авансов',
          'Комментарий',
        ],
        [
          [
            'Аванс по договору № 18/26',
            '750 000,00',
            '01.09.2026',
            '750 000,00',
            '03.09.2026',
            '0,00',
            '2',
            '250 000,00',
            'Зачесть в этапе П',
          ],
        ],
      ),
    ),
    section(
      'Выполнение',
      table(
        [
          'Выполнение',
          'Сумма акта',
          'Дата акта',
          'Зачёт аванса',
          'Факт. сумма',
          'Факт. дата',
          'Разница: акт − оплата',
          'Дней просрочки',
          'Комментарий',
        ],
        [
          [
            'Акт № 12',
            '1 500 000,00',
            '08.09.2026',
            '500 000,00',
            '1 000 000,00',
            '10.09.2026',
            '500 000,00',
            '2',
            'Этап П',
          ],
        ],
      ),
    ),
  ]);

  Widget project() => stack([
    section(
      'О проекте',
      CarpenterDefinitionList<MapEntry<String, String>>(
        items: const {
          'Ник': 'Северный парк',
          '№ документа стадии П': '104-26-П',
          '№ документа стадии Р': '104-26-Р',
          'Контрагент-заказчик': 'ООО «Северный квартал»',
          'Проектировщики': 'Анна Иванова, Алексей Петров',
          'ГИП': 'Михаил Соколов',
        }.entries.toList(),
        term: (e) => e.key,
        valueBuilder: (context, e) => _editingField == e.key
            ? CarpenterInput(
                controller: input('edit.${e.key}', _saved[e.key] ?? e.value),
                semanticLabel: e.key,
              )
            : text(_saved[e.key] ?? e.value),
        actions: (e) => mode == ProjectsPlusState.readOnly
            ? []
            : [
                CarpenterActionDescriptor(
                  id: e.key,
                  label: _editingField == e.key ? 'Сохранить' : 'Изменить',
                  icon: _editingField == e.key
                      ? GravityIcons.check
                      : GravityIcons.pencil,
                  onInvoke: () => setState(() {
                    if (_editingField == e.key) {
                      _saved[e.key] = input('edit.${e.key}').text;
                      _editingField = null;
                    } else {
                      _editingField = e.key;
                    }
                  }),
                ),
              ],
      ),
    ),
    section('Документы проекта', rows(documents)),
    section(
      'Материалы проекта',
      const SizedBox(height: 640, child: DsktpMaterialsLayout()),
    ),
    section(
      'Связи',
      stack([
        links({
          'Договор № 18/26': 'order',
          'Заказ № 482': 'order',
          'ССП № 52': 'sspDetails',
        }),
        rows(tasks),
      ]),
    ),
    section('Финансы', financials()),
  ]);

  Widget form() => stack([
    CarpenterFieldGroup(
      columns: 1,
      children: [
        for (final e in spec.fields.entries.where(
          (e) => e.key != 'Связанные задачи',
        ))
          CarpenterFormField(label: e.key, child: field(e)),
      ],
    ),
    if (spec.id.startsWith('ssp')) section('Связанные задачи', rows(tasks)),
    Wrap(
      alignment: WrapAlignment.end,
      spacing: gap,
      runSpacing: gap,
      children: [
        button('Отмена', () => open('board')),
        CarpenterButton.filled(
          label: 'Сохранить',
          onInvoke: mode == ProjectsPlusState.readOnly
              ? null
              : () => setState(() {
                  _feedback =
                      spec.fields.entries.any(
                        (e) =>
                            input('$_id.${e.key}', e.value).text.trim().isEmpty,
                      )
                      ? 'Заполните поля формы'
                      : 'Изменения сохранены в примере';
                }),
        ),
      ],
    ),
  ]);
  Widget field(MapEntry<String, String> e) {
    final c = input('$_id.${e.key}', e.value);
    final availability = mode == ProjectsPlusState.readOnly
        ? FieldAvailability.readOnly
        : FieldAvailability.enabled;
    if ([
      'Проектировщики',
      'Договоры',
      'РСП',
      'Связанные задачи',
    ].contains(e.key)) {
      final selected = c.text
          .split(', ')
          .where((value) => value.isNotEmpty)
          .toList();
      final candidates = <String>{
        ...e.value.split(', '),
        ...selected,
        if (e.key == 'Проектировщики') 'Михаил Соколов',
        for (var i = 1; i <= 250; i++)
          switch (e.key) {
            'Проектировщики' =>
              'Проектировщик ${i.toString().padLeft(3, '0')} · Отдел ${i % 12 + 1}',
            'Договоры' => 'Договор № ${i + 18}/26 · Рабочая документация',
            _ => 'РСП № ${i + 307} · Проверить раздел ${i % 12 + 1}',
          },
      };
      final query = (_entityQueries[e.key] ?? '').toLowerCase();
      return CarpenterMultiSelect<String>(
        key: ValueKey('$_id.${e.key}'),
        semanticLabel: e.key,
        placeholder: 'Найти и добавить',
        removeLabel: 'Удалить',
        emptyText: 'Ничего не найдено',
        loadingText: 'Поиск…',
        failedText: 'Не удалось загрузить варианты',
        availability: availability,
        values: [
          for (final value in selected)
            CarpenterOption(id: value, value: value, label: value),
        ],
        suggestions: [
          for (final value in candidates.where(
            (value) => value.toLowerCase().contains(query),
          ))
            CarpenterOption(id: value, value: value, label: value),
        ],
        onQueryChanged: (value) =>
            setState(() => _entityQueries[e.key] = value),
        onChanged: (values) => setState(
          () => c.text = values.map((option) => option.value).join(', '),
        ),
      );
    }

    if ([
      'Проект',
      'Контрагент-заказчик',
      'Контрагент-согласующий',
      'Клиент',
      'Кто платит',
      'ГИП',
      'ССП',
      'Контрагент',
    ].contains(e.key)) {
      if (e.key == 'Кто платит') {
        return CarpenterSelect<String>(
          value: c.text,
          availability: availability,
          options: [
            for (final value in [e.value, 'Исполнитель'])
              CarpenterOption(id: value, value: value, label: value),
          ],
          onChanged: (value) => setState(() => c.text = value),
        );
      }
      final options = <String>{
        e.value,
        c.text,
        if (e.key == 'ГИП') 'Алексей Петров',
        for (var i = 1; i <= 250; i++)
          switch (e.key) {
            'ГИП' => 'ГИП ${i.toString().padLeft(3, '0')} · Проектный отдел',
            'Проект' => 'Проект № ${i + 104} · Жилой квартал',
            'ССП' => 'ССП № ${i + 52} · Инженерные сети',
            _ => 'ООО «Проектная компания ${i.toString().padLeft(3, '0')}»',
          },
      };
      final query = (_entityQueries[e.key] ?? '').toLowerCase();
      return CarpenterComboBox<String>(
        controller: input('$_id.${e.key}.query', c.text),
        value: c.text,
        availability: availability,
        semanticLabel: e.key,
        placeholder: 'Найти по названию или номеру',
        emptyText: 'Ничего не найдено',
        options: [
          for (final value
              in options
                  .where((value) => value.toLowerCase().contains(query))
                  .take(20))
            CarpenterOption(id: value, value: value, label: value),
        ],
        onQueryChanged: (value) =>
            setState(() => _entityQueries[e.key] = value),
        onChanged: (value) => setState(() => c.text = value),
      );
    }

    if (e.key == 'Дата')
      return CarpenterDateInput(
        value: DateTime.tryParse(c.text.split('.').reversed.join('-')),
        availability: availability,
        onChanged: (v) => setState(
          () => c.text = v == null
              ? ''
              : '${v.day.toString().padLeft(2, '0')}.${v.month.toString().padLeft(2, '0')}.${v.year}',
        ),
      );
    if ([
      'Комментарий',
      'Описание работ',
      'Полное название',
      'Тема',
    ].contains(e.key))
      return CarpenterTextArea(
        controller: c,
        minLines: 2,
        maxLines: 4,
        availability: availability,
      );
    return CarpenterInput(
      controller: c,
      semanticLabel: e.key,
      availability: availability,
    );
  }

  Widget body() {
    switch (spec.kind) {
      case 'form':
        return form();
      case 'board':
      case 'sspBoard':
      case 'orders':
      case 'tenders':
        return board();
      case 'project':
        return project();
      case 'materials':
        return const SizedBox(height: 720, child: DsktpMaterialsLayout());
      case 'financials':
        return financials();
      case 'volumes':
        return stack([
          links({
            'Назначить проектировщика': 'assignments',
            'Открыть материалы': 'materials',
          }),
          table(
            [
              'Том',
              '№',
              'Шифр',
              'Проектировщик',
              'Статус',
              'Примечание',
              'Файлы',
            ],
            [
              [
                'Система электроснабжения',
                '5.1',
                '104-26-П-ИОС1',
                'Анна Иванова',
                'На проверке',
                'Уточнить нагрузки',
                'ИОС1.pdf',
              ],
              [
                'Водоснабжение',
                '5.2',
                '104-26-П-ИОС2',
                'Алексей Петров',
                'В работе',
                'До 18.09.2026',
                'ИОС2.dwg',
              ],
            ],
          ),
        ]);
      case 'assignments':
        return stack([
          details({
            'Том': '5.1 · Система электроснабжения',
            'Проектировщик': 'Анна Иванова',
            'Статус': 'На проверке',
            'Примечание': 'Уточнить нагрузки по замечанию № 52',
          }),
          section('Файлы назначения', rows(documents)),
        ]);
      case 'branches':
        return stack([
          search(),
          CarpenterExpander.listGroup(
            initiallyExpanded: true,
            header: text('№ 104 · Северный парк'),
            content: rows([
              (
                'Основная ветвь',
                '10.09.2026 · Анна Иванова · Обновлена схема',
                'Версия 3',
              ),
              (
                'Корректировка по замечаниям',
                '09.09.2026 · Михаил Соколов',
                'Версия 2',
              ),
            ], target: 'project'),
          ),
        ]);
      case 'sspDetails':
        return stack([
          details(spec.fields),
          links({
            'Редактировать': 'sspEdit',
            'Замечания': 'sspStatus',
            'История': 'sspHistory',
          }),
          section('Файлы', rows(documents)),
          section('Связанные задачи', rows(tasks)),
        ]);
      case 'history':
        return rows([
          (
            'Замечания',
            '10.09.2026 09:40 · Михаил Соколов · Уточнить точку подключения',
            'Замечания_ИОС1.pdf',
          ),
          (
            'Отдано на согласование',
            '09.09.2026 15:20 · Анна Иванова',
            'ИОС1.pdf',
          ),
          ('Требуется', '01.09.2026 10:00 · Михаил Соколов', 'Создано'),
        ]);
      case 'order':
        return stack([
          details(spec.fields),
          section('Связанные задачи', rows(tasks)),
        ]);
      case 'tender':
        return stack([
          details(spec.fields),
          section(
            'Участники',
            rows([
              (
                'ООО «Проектное бюро Север»',
                'Анна Иванова · Участник тендера',
                'Заявка подана',
              ),
            ]),
          ),
          section('Связи', rows(tasks)),
        ]);
      case 'pretenders':
        return stack([
          search(),
          rows([
            (
              'Реконструкция инженерных сетей',
              'ООО «Северный квартал» · 12 500 000,00 ₽',
              '18.09.2026',
            ),
          ], target: 'tender'),
        ]);
      case 'incoming':
      case 'outgoing':
        return stack([
          search(),
          links({'Зарегистрировать номер': 'numberCreate'}),
          table(
            [
              'Номер',
              'Дата',
              'Тема',
              'Контрагент',
              'Проект',
              'ССП',
              'Файл',
              'Ответ',
            ],
            [
              [
                spec.kind == 'incoming' ? 'ВХ-52/26' : 'ИСХ-104/26',
                '10.09.2026',
                'Замечания к электроснабжению',
                'АО «Городские инженерные сети»',
                'Северный парк',
                '№ 52',
                'Замечания_ИОС1.pdf',
                'ИСХ-105/26',
              ],
              [
                spec.kind == 'incoming' ? 'ВХ-51/26' : 'ИСХ-103/26',
                '09.09.2026',
                'Направление документации',
                'ООО «Северный квартал»',
                'Северный парк',
                '№ 53',
                'Письмо.pdf',
                'Ожидается',
              ],
            ],
          ),
        ]);
      case 'files':
        return stack([
          search(),
          CarpenterExpander.listGroup(
            initiallyExpanded: true,
            header: text('Северный парк / Общее'),
            content: rows(documents, target: 'numberCreate'),
          ),
        ]);
      default:
        throw StateError('Missing preview: ${spec.kind}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final destinations = switch (_id) {
      'board' => {
        'Создать проект': 'projectCreate',
        'Ветви': 'branches',
        'Протокол совещания': 'meeting',
      },
      'project' => {
        'Редактировать': 'projectEdit',
        'Материалы': 'materials',
        'Финансы': 'financials',
      },
      'sspBoard' => {'Создать ССП': 'sspCreate'},
      'orders' => {'Создать заказ': 'orderCreate'},
      'tenders' => {'Предтендеры': 'pretenders'},
      _ => <String, String>{},
    };
    return DefaultTextStyle(
      style: theme.typography
          .resolve(context, TypographyRole.body, TypographyEmphasis.regular)
          .copyWith(color: theme.content.resolve(ContentColorRole.primary)),
      child: SingleChildScrollView(
        key: const ValueKey('projects-scroll'),
        padding: EdgeInsets.all(context.units(theme.spacing.layoutSection)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.units(
                spec.kind == 'form'
                    ? theme.sizes.layoutNarrowEnd
                    : theme.sizes.layoutPageMaxWidth,
              ),
            ),
            child: stack([
              CarpenterEntityHeader(
                title: spec.title,
                breadcrumbs: CarpenterBreadcrumbs(
                  items: [
                    CarpenterBreadcrumb(
                      label: 'Проекты+',
                      onInvoke: () => open('board'),
                    ),
                    if (_id != 'board') CarpenterBreadcrumb(label: spec.title),
                  ],
                ),
                primaryActions: [
                  for (final e in destinations.entries.take(1))
                    CarpenterActionDescriptor(
                      id: e.value,
                      label: e.key,
                      onInvoke: () => open(e.value),
                    ),
                ],
                secondaryActions: [
                  for (final e in destinations.entries.skip(1))
                    CarpenterActionDescriptor(
                      id: e.value,
                      label: e.key,
                      onInvoke: () => open(e.value),
                    ),
                ],
              ),
              if (_feedback != null)
                CarpenterNotice(
                  title: _feedback!,
                  tone: _feedback == 'Заполните поля формы'
                      ? CarpenterNoticeTone.danger
                      : CarpenterNoticeTone.success,
                ),
              if (mode == ProjectsPlusState.conflict)
                CarpenterNotice(
                  title: 'Проект изменился',
                  message:
                      'Михаил Соколов изменил карточку. Сравните версии перед сохранением.',
                  tone: CarpenterNoticeTone.warning,
                ),
              if (mode == ProjectsPlusState.conflict)
                CarpenterExpander.listGroup(
                  header: text('Сравнить версии'),
                  content: CarpenterDefinitionList<String>(
                    items: const ['Ваш вариант', 'Актуальная версия'],
                    term: (item) => item,
                    valueBuilder: (_, item) => text(
                      item == 'Ваш вариант'
                          ? _saved['Ник'] ?? 'Северный парк'
                          : 'Северный парк · корректировка',
                    ),
                    actions: (item) => [
                      CarpenterActionDescriptor(
                        id: item,
                        label: item == 'Ваш вариант'
                            ? 'Оставить черновик'
                            : 'Загрузить актуальную',
                        onInvoke: () => setState(() {
                          if (item == 'Актуальная версия') {
                            _saved['Ник'] = 'Северный парк · корректировка';
                            _recovered = true;
                            _feedback = 'Актуальная версия загружена';
                          } else {
                            _feedback =
                                'Черновик сохранён локально для сравнения';
                          }
                        }),
                      ),
                    ],
                  ),
                ),
              if (mode == ProjectsPlusState.readOnly)
                const CarpenterNotice(
                  title: 'Только просмотр',
                  message: 'Редактирование недоступно для текущих прав.',
                  tone: CarpenterNoticeTone.info,
                ),
              if (mode == ProjectsPlusState.loading)
                const CarpenterPageStatePresentation(
                  kind: CarpenterPageStateKind.initialLoading,
                  title: 'Загрузка',
                  description: 'Получаем данные проекта',
                )
              else if (mode == ProjectsPlusState.empty)
                const CarpenterPageStatePresentation(
                  kind: CarpenterPageStateKind.zero,
                  title: 'Нет данных',
                  description: 'По текущим условиям ничего не найдено',
                )
              else if (mode == ProjectsPlusState.error)
                stack([
                  const CarpenterNotice(
                    title: 'Не удалось загрузить данные',
                    tone: CarpenterNoticeTone.danger,
                  ),
                  button('Повторить', () => setState(() => _recovered = true)),
                ])
              else
                body(),
            ]),
          ),
        ),
      ),
    );
  }
}
