import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'fixtures.dart' as data;
import 'specs.dart';

enum TreasuryVisualState { ready, loading, empty, error, warning, validation }

/// Backend-free projection of dsktp treasury pages. Navigation, field edits,
/// selection, disclosure and feedback are local to this specimen.
class TreasuryPagePreview extends StatefulWidget {
  const TreasuryPagePreview({
    super.key,
    required this.pageId,
    this.initialTab = 0,
    this.visualState = TreasuryVisualState.ready,
  });
  final String pageId;
  final int initialTab;
  final TreasuryVisualState visualState;
  @override
  State<TreasuryPagePreview> createState() => _TreasuryPreviewState();
}

class _TreasuryPreviewState extends State<TreasuryPagePreview> {
  late String _id = widget.pageId;
  late int _tab = widget.initialTab;
  final _inputs = <String, TextEditingController>{};
  final _choices = <String, String>{};
  final _selected = <String>{};
  final _expandedFilters = <String>{};
  String? _feedback;
  bool _submitted = false;
  bool _recovered = false;
  bool _bankChecked = false;
  List<String> get actions => _id == 'connectionNew'
      ? [
          _bankChecked ? 'Подключить к юрлицу' : 'Проверить и подключить',
          'Назад',
        ]
      : spec.actions;
  TreasurySpec get spec => treasurySpecs.firstWhere((s) => s.id == _id);
  TreasuryVisualState get state =>
      _recovered ? TreasuryVisualState.ready : widget.visualState;
  @override
  void didUpdateWidget(TreasuryPagePreview old) {
    super.didUpdateWidget(old);
    if (old.pageId != widget.pageId ||
        old.initialTab != widget.initialTab ||
        old.visualState != widget.visualState) {
      _reset(widget.pageId);
      _tab = widget.initialTab;
    }
  }

  void _reset(String id) {
    for (final c in _inputs.values) {
      c.dispose();
    }
    _inputs.clear();
    _choices.clear();
    _selected.clear();
    _expandedFilters.clear();
    _id = id;
    _tab = 0;
    _feedback = null;
    _submitted = false;
    _recovered = false;
    _bankChecked = false;
  }

  @override
  void dispose() {
    for (final c in _inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _open(String id) => setState(() => _reset(id));
  double get gap => context.units(CarpenterTheme.of(context).spacing.medium);
  TextEditingController input(String label, String value) =>
      _inputs.putIfAbsent(label, () => TextEditingController(text: value));

  void _action(String label) {
    if (_id == 'connectionNew' && label == 'Назад') {
      if (_bankChecked) {
        setState(() {
          _bankChecked = false;
          _feedback = null;
        });
      } else {
        _open('connections');
      }
      return;
    }
    if (_id == 'connectionNew' &&
        label == 'Подключить к юрлицу' &&
        _selected.isEmpty) {
      setState(() => _feedback = 'Выберите юридическое лицо');
      return;
    }
    final target = switch (label) {
      'Создать счёт' || 'Добавить счёт' => 'accountNew',
      'Импортировать выписку' || 'Загрузить выписку' => 'importNew',
      'Подключить банк' => 'connectionNew',
      'Создать платёж' => 'paymentNew',
      'Изменить назначение' => 'paymentPurpose',
      'Уже связанные' => 'reconciliationLinked',
      'Создать связь' => 'reconciliationLink',
      'Автораспределить' when _id != 'reconciliationAuto' =>
        'reconciliationAuto',
      'Проблемы' => 'importIssues',
      'К импортам' => 'imports',
      'Разрешить' => 'issueResolve',
      'Добавить' => 'entityNew',
      'Добавить подразделение' => 'unitNew',
      'Редактировать' =>
        _id == 'entity'
            ? 'entityEdit'
            : _id == 'payment'
            ? 'paymentPurpose'
            : 'accountEdit',
      'Отмена' =>
        _id.startsWith('entity')
            ? 'entities'
            : _id.startsWith('account')
            ? 'accounts'
            : 'payments',
      _ => null,
    };
    if (target != null) {
      _open(target);
      return;
    }
    setState(() {
      _submitted = true;
      if (spec.form.isNotEmpty &&
          spec.form.entries.any(
            (e) =>
                e.key != 'Дата закрытия' &&
                input(e.key, e.value).text.trim().isEmpty,
          )) {
        _feedback = 'Заполните обязательные поля';
      } else {
        _recovered = true;
        if (label == 'Проверить и подключить') _bankChecked = true;
        _feedback = switch (label) {
          'Проверить и подключить' =>
            'Доступ проверен. Выберите юридическое лицо.',
          'Выбрать файл' => 'Выбрана ${data.fileName}',
          _ => '$label: выполнено в примере',
        };
      }
    });
  }

  Widget text(String value, {bool secondary = false}) => CarpenterText.body(
    value,
    colorRole: secondary
        ? ContentColorRole.secondary
        : ContentColorRole.primary,
  );
  Widget stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) SizedBox(height: gap),
        child,
      ],
    ],
  );
  Widget section(String title, Widget child) => CarpenterRecordSection(
    id: CarpenterPageSectionId('$_id.$title'),
    title: title,
    child: child,
  );
  Widget details(Map<String, String> values) => CarpenterRecordDetails(
    details: [
      for (final e in values.entries)
        CarpenterRecordDetail(label: e.key, value: text(e.value)),
    ],
  );
  Widget notice(String title, String message, {bool error = false}) =>
      CarpenterNotice(
        title: title,
        message: message,
        tone: error ? CarpenterNoticeTone.danger : CarpenterNoticeTone.warning,
      );
  Widget metrics(Map<String, String> values) => CarpenterRecordSummary(
    children: [
      for (final e in values.entries)
        CarpenterRecordMetric(label: e.key, value: text(e.value)),
    ],
  );
  Widget search(String placeholder) => CarpenterInput(
    controller: input('search.$placeholder', ''),
    placeholder: placeholder,
    onChanged: (_) => setState(() {}),
  );
  Widget choice(String label, List<String> values, {bool labeled = true}) =>
      CarpenterSelect<String>(
        label: labeled ? label : null,
        value: _choices[label] ?? values.first,
        options: [
          for (final v in values) CarpenterOption(id: v, value: v, label: v),
        ],
        onChanged: (v) => setState(() => _choices[label] = v),
      );
  Widget filters(String placeholder, List<Widget> fields, {int primary = 0}) {
    final choices = fields.whereType<CarpenterSelect<String>>().toList();
    final active = choices
        .where((field) => field.value != field.options.first.value)
        .toList();
    return CarpenterFilterBar(
      searchController: input('search.$placeholder', ''),
      searchLabel: '',
      searchPlaceholder: placeholder,
      semanticLabel: 'Поиск и фильтры',
      onSearchChanged: (_) => setState(() {}),
      filterToggleLabel: 'Фильтры',
      activeFilterCount: active.length,
      filtersExpanded: _expandedFilters.contains(placeholder),
      onFiltersExpandedChanged: (expanded) => setState(() {
        expanded
            ? _expandedFilters.add(placeholder)
            : _expandedFilters.remove(placeholder);
      }),
      filterControls: [
        for (final field in fields.take(primary))
          SizedBox(width: context.units(15.rem), child: field),
      ],
      advancedFilters: CarpenterFieldGroup(
        columns: 3,
        children: fields.skip(primary).toList(),
      ),
      activeFilterSummary: [
        for (final field in active)
          CarpenterButton(
            label: '${field.label}: ${field.value} ×',
            semanticLabel: 'Убрать фильтр ${field.label}: ${field.value}',
            prominence: ActionProminence.ghost,
            size: ControlSize.small,
            onInvoke: () => setState(() => _choices.remove(field.label)),
          ),
      ],
      clearAction: CarpenterActionDescriptor(
        id: 'clear-filters',
        label: 'Сбросить',
        onInvoke: () => setState(() {
          for (final field in choices) {
            _choices.remove(field.label);
          }
        }),
      ),
    );
  }

  Widget rows(List<data.TreasuryRow> values, {bool select = false}) {
    final query = _inputs.entries
        .where((e) => e.key.startsWith('search.'))
        .map((e) => e.value.text.trim().toLowerCase())
        .where((v) => v.isNotEmpty)
        .firstOrNull;
    final filtered = values
        .where(
          (row) =>
              query == null ||
              '${row.title} ${row.detail}'.toLowerCase().contains(query),
        )
        .toList();
    if (filtered.isEmpty)
      return text('По текущим фильтрам ничего не найдено', secondary: true);
    return CarpenterCard(
      padded: false,
      child: Column(
        children: [
          for (final (i, row) in filtered.indexed) ...[
            if (i > 0)
              Container(
                height: 1,
                color: CarpenterTheme.of(context).overlay.border,
              ),
            CarpenterListTile(
              selected: _selected.contains(row.title),
              title: Text(row.title),
              subtitle: Text(row.detail),
              trailing: CarpenterText.label(
                row.value,
                emphasis: TypographyEmphasis.strong,
              ),
              onInvoke: () => select
                  ? setState(() {
                      if (_id == 'connectionNew') _selected.clear();
                      _selected.contains(row.title)
                          ? _selected.remove(row.title)
                          : _selected.add(row.title);
                    })
                  : _open(row.target),
            ),
          ],
        ],
      ),
    );
  }

  Widget group(String title, List<data.TreasuryRow> values) =>
      CarpenterExpander.listGroup(
        initiallyExpanded: true,
        header: text(title),
        content: Column(
          children: [
            for (final row in values)
              CarpenterListTile(
                title: Text(row.title),
                subtitle: Text(row.detail),
                trailing: text(row.value),
                onInvoke: () => _open(row.target),
              ),
          ],
        ),
      );
  Widget payments({bool withFilters = true}) => stack([
    if (withFilters) ...[
      filters('Сумма, документ или контрагент', [
        choice('Направление', ['Все направления', 'Входящий', 'Исходящий']),
        choice('Расчётный счёт', [
          'Все расчётные счета',
          'Альфа-Банк · Основной расчётный',
        ]),
        choice('Период', ['Все даты', '01.09.2026 — 10.09.2026', 'За месяц']),
      ], primary: 1),
    ],
    rows(
      data.payments
          .where(
            (r) =>
                _choices['Направление'] == null ||
                _choices['Направление'] == 'Все направления' ||
                r.value == _choices['Направление'],
          )
          .toList(),
    ),
    pagination(3),
  ]);
  Widget pagination(int count) => CarpenterPaginationBar(
    page: 1,
    totalPages: 1,
    pageLabelBuilder: (page, total) => 'Страница $page из $total',
    previousPageLabel: 'Предыдущая страница',
    nextPageLabel: 'Следующая страница',
    leading: text('Всего: $count', secondary: true),
    onPageChanged: (_) {},
  );

  Widget editor(MapEntry<String, String> entry) {
    final label = entry.key;
    final controller = input(label, entry.value);
    final options = switch (label) {
      'Режим подключения' => ['Рабочая', 'Тестовый режим'],
      'Направление' => ['Исходящий', 'Входящий'],
      'Вид операции' => [
        'Платёжное поручение',
        'Банковский ордер',
        'Расход наличных',
      ],
      'Тип' =>
        _id.startsWith('unit')
            ? [
                'Филиал',
                'Представительство',
                'Обособленное подразделение',
                'Другое',
              ]
            : ['Организация', 'Индивидуальный предприниматель'],
      'Юридическое лицо' => [data.legalName, 'ООО «Проектное бюро Север»'],
      'Банк' => [entry.value, 'ПАО Сбербанк · 044525225'],
      'Расчётный счёт' => [entry.value, 'Сбербанк · Резервный'],
      'Контрагент' => [entry.value, 'АО «Городские инженерные сети»'],
      'Точность сравнения суммы' => [
        'Точное совпадение',
        'До рубля',
        'До 10 рублей',
      ],
      _ => <String>[],
    };
    if (options.isNotEmpty) return choice(label, options, labeled: false);
    if (label.startsWith('Дата')) {
      final parts = controller.text.split('.');
      final value = parts.length == 3
          ? DateTime(
              int.parse(parts[2]),
              int.parse(parts[1]),
              int.parse(parts[0]),
            )
          : null;
      return CarpenterDateInput(
        value: value,
        onChanged: (date) => setState(
          () => controller.text = date == null
              ? ''
              : '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
        ),
      );
    }
    if ([
      'Назначение',
      'Комментарий',
      'Юридический адрес',
      'Адрес',
    ].contains(label))
      return CarpenterTextArea(
        controller: controller,
        minLines: 2,
        maxLines: 4,
      );
    return CarpenterInput(
      controller: controller,
      placeholder: label,
      obscureText: label == 'Ключ доступа',
    );
  }

  Widget form() => stack([
    if (_id.startsWith('account'))
      const CarpenterNotice(
        title: 'Черновик сохраняется автоматически',
        tone: CarpenterNoticeTone.info,
      ),
    if (state == TreasuryVisualState.validation ||
        (_submitted && _feedback == 'Заполните обязательные поля'))
      notice(
        'Проверьте данные',
        'Укажите корректные реквизиты перед сохранением.',
        error: true,
      ),
    section(
      _id == 'connectionNew' ? 'Доступ к банку' : 'Основные данные',
      CarpenterFieldGroup(
        columns: 1,
        children: [
          for (final entry in spec.form.entries)
            CarpenterFormField(
              label: entry.key,
              required: ![
                'Дата закрытия',
                'Комментарий',
                'Название',
              ].contains(entry.key),
              error:
                  state == TreasuryVisualState.validation &&
                      entry.key == spec.form.keys.first
                  ? 'Проверьте значение'
                  : null,
              child: editor(entry),
            ),
        ],
      ),
    ),
    if (_id == 'connectionNew' && _bankChecked)
      section('Выберите юридическое лицо', rows(data.entities, select: true)),
    if (_id == 'reconciliationAuto')
      metrics({
        'Проверено': '3 платежа',
        'Подходящие пары': '1',
        'Сумма': '684 250,50 ₽',
      }),
  ]);

  Widget _body() {
    if (spec.form.isNotEmpty) return form();
    switch (_id) {
      case 'accounts':
        return stack([
          metrics({
            'Всего денег': '15 791 050,00 ₽',
            'Проблемы': '1',
            'Без остатка': '0 счетов',
          }),
          filters('Юрлицо, ИНН, банк, БИК, номер или название счёта', [
            choice('Архив', ['Активные', 'Показывать архивные']),
            choice('Проблемы', [
              'Все счета',
              'Только с проблемами',
              'Без проблем',
            ]),
            choice('Дата обновления', [
              'Любая',
              'Обновлены недавно',
              'Давно не обновлялись',
              'Дата неизвестна',
            ]),
            choice('Валюта', ['Все валюты', 'RUB']),
            choice('Сортировка', [
              'По юридическому лицу',
              'По остатку',
              'По свежести',
              'По проблемам',
              'По дате обновления',
            ]),
            choice('Направление', ['По возрастанию', 'По убыванию']),
          ]),
          group(
            '${data.legalName} · ИНН 5406123456 · 13 320 350,00 ₽',
            data.accounts,
          ),
          group('ООО «Проектное бюро Север» · 2 470 700,00 ₽', const [
            (
              title: 'Т-Банк · Операционный',
              detail: '40702810000000002075 · RUB · 10.09.2026 09:40',
              value: '2 150 700,00 ₽',
              target: 'account',
            ),
            (
              title: 'Газпромбанк · Проектный',
              detail: '40702810000000006612 · RUB · 09.09.2026 18:15',
              value: '320 000,00 ₽',
              target: 'account',
            ),
          ]),
          pagination(4),
        ]);
      case 'account':
        return stack([
          if (_tab == 0) ...[
            notice(
              'Обнаружено расхождение остатков',
              'Остаток банка отличается от расчётного на 18 750,00 ₽.',
            ),
            section('Реквизиты', details(data.accountFields)),
          ],
          if (_tab == 1) payments(),
          if (_tab == 2)
            section('Распределённые платежи', rows(data.allocations)),
          if (_tab == 3)
            stack([
              metrics({
                'Остаток банка': '12 480 350,00 ₽',
                'Расчётный остаток': '12 461 600,00 ₽',
                'Разница': '+ 18 750,00 ₽',
              }),
              rows(const [
                (
                  title: '09.09.2026 — 10.09.2026',
                  detail:
                      'Начальный остаток 11 016 150,50 ₽ · Приход 2 450 000,00 ₽ · Расход 1 004 550,50 ₽',
                  value: 'Расхождение',
                  target: 'account',
                ),
              ]),
            ]),
          if (_tab == 4)
            rows(const [
              (
                title: '12 480 350,00 ₽',
                detail: '10.09.2026 09:42 · Банковское подключение',
                value: 'Текущий',
                target: 'connection',
              ),
              (
                title: '11 016 150,50 ₽',
                detail: '09.09.2026 18:15 · Импорт выписки',
                value: 'Предыдущий',
                target: 'import',
              ),
            ]),
        ]);
      case 'banks':
        return stack([
          search('Название, БИК, город или реквизиты'),
          rows(data.banks),
          pagination(2),
        ]);
      case 'bank':
        return stack([
          metrics({
            'Банк': 'Альфа-Банк',
            'Регистрационный номер': '1326',
            'Источник': 'Банк России',
          }),
          section('Реквизиты и адрес', details(data.bankFields)),
          section('Корреспондентские счета', text('30101810200000000593')),
          section('SWIFT', text('ALFARUMM')),
        ]);
      case 'connections':
        return rows(const [
          (
            title: 'Альфа-Банк · Северный квартал',
            detail:
                'Рабочая · ООО «Северный квартал» · Последняя синхронизация 10.09.2026 09:42',
            value: 'Подключено',
            target: 'connection',
          ),
          (
            title: 'Т-Банк · Проектное бюро',
            detail: 'Рабочая · Требуется обновить ключ доступа',
            value: 'Ошибка доступа',
            target: 'connection',
          ),
        ]);
      case 'connection':
        return stack([
          choice('Юридическое лицо', [data.legalName, 'Не привязано']),
          if (_choices['Юридическое лицо'] == 'Не привязано')
            notice(
              'Подключение не привязано к юрлицу',
              'Остатки и операции не будут импортированы до привязки.',
            ),
          if (_tab == 0) section('Обнаруженные счета', rows(data.accounts)),
          if (_tab == 1) ...[
            choice('Счёт', ['Альфа-Банк · ${data.accountNumber}']),
            payments(withFilters: false),
          ],
          if (_tab == 2)
            rows(const [
              (
                title: '10.09.2026 09:42 · Синхронизация завершена',
                detail:
                    'С остатками и операциями · Счетов: 2 · Операций: 6 · Импортировано: 3 · Дубликатов: 2 · Предупреждений: 1',
                value: 'С замечаниями',
                target: 'import',
              ),
              (
                title: '09.09.2026 18:15 · Синхронизация завершена',
                detail: 'Только остатки · Счетов: 2',
                value: 'Успешно',
                target: 'connection',
              ),
            ]),
        ]);
      case 'payments':
        return payments();
      case 'payment':
        return _tab == 1
            ? section('Связанные сущности', rows(data.allocations))
            : stack([
                section('Реквизиты платежа', details(data.paymentFields)),
                section(
                  'Контрагент',
                  details({
                    'Контрагент': data.counterparty,
                    'ИНН': '5406987654',
                  }),
                ),
              ]);
      case 'incomplete':
        return stack([
          notice(
            'Не хватает реквизитов',
            'Дополните данные банковской операции для импорта.',
          ),
          rows(const [
            (
              title: '− 684 250,50 ₽',
              detail:
                  '10.09.2026 · ООО «Электрокомплект» · Не определён контрагент · Валюта RUB',
              value: 'Дополнить',
              target: 'incompleteResolve',
            ),
          ]),
        ]);
      case 'reconciliation':
        return LayoutBuilder(
          builder: (context, constraints) {
            final objects = section(
              'Распределить на',
              stack([
                choice('Тип объекта', [
                  'Договор',
                  'Заказ',
                  'Аванс',
                  'Этап платежа',
                ]),
                filters('Сущность, сумма, юрлицо или контрагент', [
                  choice('Фильтр по ИНН', ['Все', 'Совпадение контрагента']),
                  choice('Своё юрлицо', [
                    'Все юридические лица',
                    data.legalName,
                  ]),
                ]),
                rows(data.allocations, select: true),
                pagination(2),
              ]),
            );
            final paymentPanel = section(
              'Платежи',
              stack([
                filters('Сумма, документ, юрлицо, счёт или контрагент', [
                  choice('Направление', ['Все', 'Приход', 'Расход']),
                  choice('Период', ['Все даты', '01.09.2026 — 10.09.2026']),
                ]),
                rows(data.payments, select: true),
                pagination(3),
              ]),
            );
            return constraints.maxWidth >= 1040
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: objects),
                      SizedBox(width: gap),
                      Expanded(child: paymentPanel),
                    ],
                  )
                : stack([objects, paymentPanel]);
          },
        );
      case 'reconciliationLinked':
        return stack([
          search('Номер, название, контрагент или ИНН'),
          rows(data.allocations),
          pagination(2),
        ]);
      case 'imports':
        return stack([rows(data.imports), pagination(2)]);
      case 'importNew':
        return stack([
          section(
            'Загрузка выписки',
            CarpenterCard(
              child: stack([
                const CarpenterIcon(GravityIcons.file),
                text('Перетащите файл банковской выписки или выберите файл'),
                text(data.fileName, secondary: true),
              ]),
            ),
          ),
          metrics({
            'Документы': '6',
            'Счета': '2',
            'Готово к импорту': '3',
            'Дубликаты': '2',
            'Ошибки': '1',
          }),
          notice(
            'Проблемы обработки выписки',
            'Один документ требует уточнения контрагента.',
          ),
          rows(data.issues),
        ]);
      case 'import':
        return stack([
          if (_tab == 0)
            section('Сведения о выписке', details(data.statementFields)),
          if (_tab == 1) ...[
            group('Расчётные счета (2)', data.accounts),
            group('Платежи (3)', data.payments),
          ],
          if (_tab == 2) rows(data.issues.take(1).toList()),
        ]);
      case 'importIssues':
        return stack([
          filters('Поиск по проблемам', [
            choice('Статус', ['Открытые', 'Закрытые', 'Все']),
            choice('Категория', [
              'Все категории',
              'Контрагент',
              'Расчётный счёт',
            ]),
          ]),
          rows(data.issues),
          pagination(2),
        ]);
      case 'issue':
        return stack([
          notice(
            'Не определён контрагент',
            'Не найдено юридическое лицо по ИНН 5406987654.',
          ),
          details({
            'Первый случай': '10.09.2026 09:42',
            'Последний случай': '10.09.2026 09:42',
            'Статус': 'Открыта',
            'Всего случаев': '1',
          }),
          section('Случаи', rows([data.imports.first])),
        ]);
      case 'audit':
        return stack([
          metrics({
            'Ошибки': '1 группа',
            'Предупреждения': '2 группы',
            'Объекты': '3',
            'Рассчитано': '10.09.2026 09:45',
          }),
          CarpenterExpander.listGroup(
            initiallyExpanded: true,
            header: text('Расчётные счета · 1 объект'),
            content: group('Расхождение остатков', const [
              (
                title: 'Альфа-Банк · Основной расчётный',
                detail: 'Расхождение 18 750,00 ₽ за 09–10 сентября',
                value: 'Открыть',
                target: 'account',
              ),
            ]),
          ),
          CarpenterExpander.listGroup(
            initiallyExpanded: true,
            header: text('Платежи · 2 объекта'),
            content: group('Недостаточно реквизитов для импорта', data.issues),
          ),
        ]);
      case 'entities':
        return stack([
          search('Название, ИНН, КПП, ОГРН или адрес'),
          choice('Статус', ['Активные', 'Архивные', 'Все']),
          rows(data.entities),
          pagination(2),
        ]);
      case 'entity':
        return switch (_tab) {
          0 => section('Реквизиты', details(data.entityFields)),
          1 => group('Расчётные счета', data.accounts),
          2 => payments(),
          3 => rows(data.allocations),
          _ => stack([
            CarpenterButton(
              label: 'Добавить подразделение',
              onInvoke: () => _action('Добавить подразделение'),
            ),
            rows(const [
              (
                title: 'Новосибирский филиал',
                detail:
                    'Филиал · КПП 540643001 · Новосибирск, Депутатская, 2 · Открыт 01.02.2024',
                value: 'Активен',
                target: 'unitEdit',
              ),
            ]),
          ]),
        };
      default:
        throw StateError('Missing treasury page: $_id');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final body = switch (state) {
      TreasuryVisualState.loading =>
        const CarpenterPageStatePresentation.loading(title: 'Загрузка данных'),
      TreasuryVisualState.empty => const CarpenterPageStatePresentation(
        kind: CarpenterPageStateKind.zero,
        title: 'Данных пока нет',
        description: 'Измените фильтры или добавьте первую запись.',
      ),
      TreasuryVisualState.error => stack([
        notice(
          'Не удалось загрузить данные',
          'Проверьте соединение и повторите запрос.',
          error: true,
        ),
        CarpenterButton(
          label: 'Повторить',
          onInvoke: () => setState(() => _recovered = true),
        ),
      ]),
      _ =>
        spec.tabs.isEmpty
            ? _body()
            : CarpenterRecordTabs<int>(
                value: _tab,
                onChanged: (v) => setState(() => _tab = v),
                tabs: [
                  for (final (i, label) in spec.tabs.indexed)
                    CarpenterRecordTab(
                      value: i,
                      label: label,
                      content: i == _tab ? _body() : const SizedBox.shrink(),
                    ),
                ],
              ),
    };
    return DefaultTextStyle(
      style: theme.typography
          .resolve(context, TypographyRole.body, TypographyEmphasis.regular)
          .copyWith(color: theme.content.resolve(ContentColorRole.primary)),
      child: SingleChildScrollView(
        key: const ValueKey('treasury-scroll'),
        padding: EdgeInsets.all(context.units(theme.spacing.layoutSection)),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: context.units(
                spec.form.isEmpty
                    ? theme.sizes.layoutPageMaxWidth
                    : theme.sizes.layoutNarrowEnd,
              ),
            ),
            child: stack([
              CarpenterEntityHeader(
                title: spec.title,
                subtitle: spec.subtitle.isEmpty ? null : spec.subtitle,
                breadcrumbs: CarpenterBreadcrumbs(
                  items: [
                    CarpenterBreadcrumb(
                      label: 'Казначейство',
                      onInvoke: () => _open('accounts'),
                    ),
                    CarpenterBreadcrumb(label: spec.title),
                  ],
                ),
                primaryActions: [
                  for (final label
                      in (spec.form.isEmpty ? actions : <String>[]).take(1))
                    CarpenterActionDescriptor(
                      id: label,
                      label: label,
                      onInvoke: () => _action(label),
                    ),
                ],
                secondaryActions: [
                  for (final label
                      in (spec.form.isEmpty ? actions : <String>[]).skip(1))
                    CarpenterActionDescriptor(
                      id: label,
                      label: label,
                      onInvoke: () => _action(label),
                    ),
                ],
              ),
              if (_feedback != null)
                CarpenterNotice(
                  title: _feedback!,
                  tone:
                      _feedback == 'Заполните обязательные поля' ||
                          _feedback == 'Выберите юридическое лицо'
                      ? CarpenterNoticeTone.danger
                      : CarpenterNoticeTone.success,
                ),
              if (state == TreasuryVisualState.warning)
                notice(
                  'Требуется внимание',
                  'Часть данных не обновлена. Последние сохранённые значения остаются доступны.',
                ),
              if (_id == 'account')
                metrics({
                  'Текущий остаток': '12 480 350,00 ₽',
                  'Обновлён': '10.09.2026 09:42',
                }),
              if (_id == 'import')
                metrics({
                  'Документы': '6',
                  'Платежи': '3',
                  'Дубликаты': '2',
                  'Ошибки': '1',
                }),
              body,
              if (spec.form.isNotEmpty)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final label in actions.reversed)
                      CarpenterButton(
                        label: label,
                        prominence: label == actions.first
                            ? ActionProminence.filled
                            : ActionProminence.ghost,
                        onInvoke: () => _action(label),
                      ),
                  ],
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
