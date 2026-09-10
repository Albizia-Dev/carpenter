/// Complete route/page inventory; IDs also identify deterministic golden scenes.
class TreasurySpec {
  const TreasurySpec(
    this.id,
    this.title,
    this.source, {
    this.route = '',
    this.tabs = const [],
    this.actions = const [],
    this.form = const {},
    this.subtitle = '',
  });
  final String id, title, source, route, subtitle;
  final List<String> tabs, actions;
  final Map<String, String> form;
}

const a = 'accounts/ui/';
const p = 'payments/ui/';
const b = 'bank_connections/ui/';
const s = 'statement_import/ui/';
const r = 'payment_reconciliation/ui/payment_reconciliation_page.dart';
const le = '../legal_entity/ui/';
const treasurySpecs = [
  TreasurySpec(
    'accounts',
    'Расчётные счета',
    '${a}accounts_page.dart',
    route: '/treasury/accounts',
    actions: ['Добавить счёт', 'Загрузить выписку'],
  ),
  TreasurySpec(
    'accountNew',
    'Новый расчётный счёт',
    '${a}account_editor_page.dart',
    route: '/treasury/accounts/new',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Название': 'Основной расчётный',
      'Номер счёта': '40702810000000004821',
      'Юридическое лицо': 'ООО «Северный квартал»',
      'Банк': 'АО «АЛЬФА-БАНК» · 044525593',
      'Валюта': 'RUB',
    },
  ),
  TreasurySpec(
    'accountEdit',
    'Изменить расчётный счёт',
    '${a}account_editor_page.dart',
    route: '/treasury/accounts/:accountId/edit',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Название': 'Основной расчётный',
      'Номер счёта': '40702810000000004821',
      'Банк': 'АО «АЛЬФА-БАНК» · 044525593',
      'Валюта': 'RUB',
    },
  ),
  TreasurySpec(
    'account',
    'Альфа-Банк · Основной расчётный',
    '${a}account_details_page.dart',
    route: '/treasury/accounts/:accountId',
    tabs: [
      'Основное',
      'Платежи',
      'Распределённые платежи',
      'Сверка остатков',
      'История',
    ],
    actions: ['Редактировать', 'В архив', 'Очистить счёт'],
  ),
  TreasurySpec(
    'banks',
    'Банки',
    'bank_directory/ui/canonical_bank_page.dart',
    route: '/treasury/banks',
    subtitle: 'Единый актуальный справочник банков',
    actions: ['Синхронизировать', 'Обновить список'],
  ),
  TreasurySpec(
    'bank',
    'АО «АЛЬФА-БАНК»',
    'bank_directory/ui/canonical_bank_page.dart',
    subtitle: 'БИК 044525593 · Москва',
  ),
  TreasurySpec(
    'connections',
    'Банковские подключения',
    '${b}bank_connections_page.dart',
    route: '/treasury/bank-connections',
    subtitle: 'Прямой доступ к счетам и выпискам внешних банков',
    actions: ['Подключить банк', 'Обновить'],
  ),
  TreasurySpec(
    'connectionNew',
    'Подключить банк',
    '${b}bank_connection_create_page.dart',
    route: '/treasury/bank-connections/new',
    actions: ['Проверить и подключить', 'Назад', 'Подключить к юрлицу'],
    form: {
      'Режим подключения': 'Рабочая',
      'Название': 'Альфа-Банк · Северный квартал',
      'Ключ доступа': 'demo-token-not-a-real-credential',
    },
  ),
  TreasurySpec(
    'connection',
    'Альфа-Банк · Северный квартал',
    '${b}bank_connection_details_page.dart',
    route: '/treasury/bank-connections/:connectionId',
    tabs: ['Счета', 'Выписка из банка', 'История синхронизаций'],
    actions: [
      'Синхронизировать',
      'Проверить',
      'Изменить оформление',
      'Отключить',
    ],
  ),
  TreasurySpec(
    'payments',
    'Платежи',
    '${p}payments_page.dart',
    route: '/treasury/payments',
    actions: ['Создать платёж', 'Обновить'],
  ),
  TreasurySpec(
    'paymentNew',
    'Новый платёж',
    '${p}payments_page.dart',
    actions: ['Создать', 'Отмена'],
    form: {
      'Расчётный счёт': 'Альфа-Банк · Основной расчётный',
      'Сумма': '684 250,50',
      'Дата платежа': '10.09.2026',
      'Направление': 'Исходящий',
      'Контрагент': 'ООО «Электрокомплект»',
      'ИНН контрагента': '5406987654',
      'Номер документа': '1043',
      'Назначение': 'Оплата кабельной продукции по счёту № 482 от 08.09.2026',
      'Валюта': 'RUB',
      'Вид операции': 'Платёжное поручение',
    },
  ),
  TreasurySpec(
    'payment',
    '− 684 250,50 ₽',
    '${p}payment_details_page.dart',
    route: '/treasury/payments/:paymentId',
    subtitle:
        'Оплата кабельной продукции по счёту № 482 от 08.09.2026. В том числе НДС 20%.',
    tabs: ['Основное', 'Распределённые платежи'],
    actions: ['Редактировать', 'В архив', 'Восстановить'],
  ),
  TreasurySpec(
    'paymentPurpose',
    'Назначение платежа',
    '${p}payment_details_dialogs.dart',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Назначение':
          'Оплата кабельной продукции по счёту № 482 от 08.09.2026. В том числе НДС 20%.',
    },
  ),
  TreasurySpec(
    'incomplete',
    'Незавершённые платежи',
    '${p}incomplete_payments_page.dart',
    route: '/treasury/audit/incomplete-payments',
    subtitle: 'Банковские операции, которым не хватает данных для импорта',
    actions: ['Обновить'],
  ),
  TreasurySpec(
    'incompleteResolve',
    'Дополнить банковскую операцию',
    '${p}incomplete_payments_page.dart',
    actions: ['Импортировать платёж', 'Отмена'],
    form: {
      'Контрагент': 'ООО «Электрокомплект»',
      'Дата платежа': '10.09.2026',
      'Номер документа': '1043',
      'Назначение': 'Поставка кабельной продукции',
      'Валюта': 'RUB',
      'Вид операции': 'Платёжное поручение',
    },
  ),
  TreasurySpec(
    'reconciliation',
    'Распределение платежей',
    r,
    route: '/treasury/payment-reconciliation',
    actions: ['Создать связь', 'Уже связанные', 'Автораспределить', 'Обновить'],
  ),
  TreasurySpec(
    'reconciliationLinked',
    'Уже связанные',
    r,
    actions: ['Создать связь', 'Обновить'],
  ),
  TreasurySpec(
    'reconciliationLink',
    'Установить связь',
    r,
    actions: ['Установить связь', 'Отмена'],
    form: {
      'Объект': 'Договор № 18/26 · Северный парк',
      'Платёж': '№ 1043 · ООО «Электрокомплект»',
      'Сумма связи': '500 000,00',
    },
  ),
  TreasurySpec(
    'reconciliationAuto',
    'Автораспределение',
    r,
    actions: ['Автораспределить', 'Отмена'],
    form: {'Точность сравнения суммы': 'Точное совпадение'},
  ),
  TreasurySpec(
    'imports',
    'Импорт банковских выписок',
    '${s}statement_import_page.dart',
    route: '/treasury/statement-imports',
    actions: ['Загрузить выписку', 'Проблемы', 'Обновить'],
  ),
  TreasurySpec(
    'importNew',
    'Новая банковская выписка',
    '${s}statement_import_flow.dart',
    actions: ['Выбрать файл', 'Импортировать'],
  ),
  TreasurySpec(
    'import',
    'Выписка_Северный_квартал_2026-09-10.txt',
    '${s}statement_import_details_page.dart',
    route: '/treasury/statement-imports/:importId',
    tabs: ['Сведения', 'Сущности (5)', 'Ошибки (1)'],
    actions: ['Обработать повторно', 'Обновить'],
  ),
  TreasurySpec(
    'importIssues',
    'Проблемы импорта выписок',
    '${s}statement_import_page.dart',
    actions: ['К импортам', 'Обновить'],
  ),
  TreasurySpec(
    'issue',
    'Не определён контрагент',
    '${s}statement_import_page.dart',
    actions: ['Разрешить', 'Игнорировать', 'Готово'],
  ),
  TreasurySpec(
    'issueResolve',
    'Разрешить проблему импорта',
    '${s}statement_import_page.dart',
    actions: ['Применить', 'Отмена'],
    form: {
      'Расчётный счёт': 'Альфа-Банк · Основной расчётный',
      'Комментарий': 'Реквизиты проверены по договору',
    },
  ),
  TreasurySpec(
    'audit',
    'Аудит казначейства',
    'audit/ui/treasury_audit_page.dart',
    route: '/treasury/audit',
    actions: ['Пересчитать'],
  ),
  TreasurySpec(
    'entities',
    'Юридические лица',
    '${le}legal_entities_page.dart',
    route: '/legal-entities',
    actions: ['Добавить', 'Обновить'],
  ),
  TreasurySpec(
    'entityNew',
    'Новое юридическое лицо',
    '${le}legal_entities_page.dart',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Тип': 'Организация',
      'Отображаемое название': 'ООО «Северный квартал»',
      'Полное наименование':
          'Общество с ограниченной ответственностью «Северный квартал»',
      'ИНН': '5406123456',
      'КПП': '540601001',
      'ОГРН': '1165476123456',
      'Юридический адрес': 'г. Новосибирск, ул. Советская, д. 52',
    },
  ),
  TreasurySpec(
    'entityEdit',
    'Изменить юридическое лицо',
    '${le}legal_entities_page.dart',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Тип': 'Организация',
      'Отображаемое название': 'ООО «Северный квартал»',
      'Полное наименование':
          'Общество с ограниченной ответственностью «Северный квартал»',
      'ИНН': '5406123456',
      'КПП': '540601001',
      'ОГРН': '1165476123456',
      'Юридический адрес': 'г. Новосибирск, ул. Советская, д. 52',
    },
  ),
  TreasurySpec(
    'entity',
    'ООО «Северный квартал»',
    '${le}legal_entity_details_page.dart',
    route: '/legal-entities/:legalEntityId',
    tabs: [
      'Основное',
      'Счета',
      'Платежи',
      'Распределённые платежи',
      'Подразделения',
    ],
    actions: ['Добавить счёт', 'Редактировать', 'В архив'],
  ),
  TreasurySpec(
    'unitNew',
    'Добавить подразделение',
    '${le}legal_entity_details_page.dart',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Тип': 'Филиал',
      'Название': 'Новосибирский филиал',
      'КПП': '540643001',
      'Адрес': 'г. Новосибирск, ул. Депутатская, д. 2',
      'Дата открытия': '01.02.2024',
      'Дата закрытия': '',
    },
  ),
  TreasurySpec(
    'unitEdit',
    'Изменить подразделение',
    '${le}legal_entity_details_page.dart',
    actions: ['Сохранить', 'Отмена'],
    form: {
      'Тип': 'Филиал',
      'Название': 'Новосибирский филиал',
      'КПП': '540643001',
      'Адрес': 'г. Новосибирск, ул. Депутатская, д. 2',
      'Дата открытия': '01.02.2024',
      'Дата закрытия': '',
    },
  ),
];
