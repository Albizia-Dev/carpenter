/// Deterministic treasury data shared by every page. Never contacts a bank/API.
const legalName = 'ООО «Северный квартал»';
const counterparty = 'ООО «Электрокомплект»';
const accountNumber = '40702810000000004821';
const purpose =
    'Оплата кабельной продукции по счёту № 482 от 08.09.2026. В том числе НДС 20%.';
const paymentAmount = '684 250,50 ₽';
const fileName = 'Выписка_Северный_квартал_2026-09-10.txt';
const accountFields = <String, String>{
  'Название': 'Основной расчётный',
  'Номер счёта': accountNumber,
  'Юридическое лицо': legalName,
  'Банк': 'АО «АЛЬФА-БАНК»',
  'БИК': '044525593',
  'Валюта': 'RUB',
  'Статус': 'Активный · Основной',
};
const entityFields = <String, String>{
  'ИНН': '5406123456',
  'КПП': '540601001',
  'ОГРН': '1165476123456',
  'Адрес': 'г. Новосибирск, ул. Советская, д. 52',
};
const paymentFields = <String, String>{
  'Контрагент': counterparty,
  'ИНН плательщика': '5406987654',
  'Номер документа': '1043',
  'Дата платежа': '10.09.2026',
  'Владелец': legalName,
  'Расчётный счёт': 'Альфа-Банк · $accountNumber',
  'Источник': fileName,
  'Распределение': 'Доступен',
  'Создан': '10.09.2026 09:42',
  'Обновлён': '10.09.2026 09:45',
};
const statementFields = <String, String>{
  'Файл': fileName,
  'Статус': 'Обработана с замечаниями',
  'Период': '01.09.2026 — 10.09.2026',
  'Отправитель': 'АО «АЛЬФА-БАНК»',
  'Получатель': legalName,
  'Кодировка': 'Windows-1251',
  'Версия формата': '1.03',
  'Размер файла': '24,8 КБ',
  'Загружена': '10.09.2026 09:42',
  'Загрузил': 'Анна Иванова',
  'Обработана': '10.09.2026 09:43',
};
const bankFields = <String, String>{
  'БИК': '044525593',
  'Адрес': 'ул. Каланчёвская, д. 27',
  'Населённый пункт': 'Москва',
  'Регион': 'Москва',
};

/// Title, supporting content, amount/status, destination specimen.
typedef TreasuryRow = ({
  String title,
  String detail,
  String value,
  String target,
});
const accounts = <TreasuryRow>[
  (
    title: 'Альфа-Банк · Основной расчётный',
    detail: '$accountNumber · RUB · Основной · Обновлён 10.09.2026 09:42',
    value: '12 480 350,00 ₽',
    target: 'account',
  ),
  (
    title: 'Сбербанк · Резервный',
    detail: '40702810000000009130 · RUB · Остаток давно не обновлялся',
    value: '840 000,00 ₽',
    target: 'account',
  ),
];
const payments = <TreasuryRow>[
  (
    title: '+ 2 450 000,00 ₽',
    detail:
        '10.09.2026 · АО «Городские инженерные сети» · № 1042 · Оплата выполненных работ по договору № 18/26',
    value: 'Входящий',
    target: 'payment',
  ),
  (
    title: '− $paymentAmount',
    detail: '10.09.2026 · $counterparty · № 1043 · $purpose',
    value: 'Исходящий',
    target: 'payment',
  ),
  (
    title: '− 320 000,00 ₽',
    detail:
        '09.09.2026 · ООО «Проектное бюро Север» · № 1044 · Аванс за разработку документации',
    value: 'Исходящий',
    target: 'payment',
  ),
];
const allocations = <TreasuryRow>[
  (
    title: 'Договор № 18/26 · Северный парк',
    detail: '$counterparty · Платёж № 1043 · 10.09.2026 · Кабельная продукция',
    value: '500 000,00 ₽',
    target: 'reconciliationLinked',
  ),
  (
    title: 'Заказ № 482 · Наружное освещение',
    detail: '$legalName · Остаток платежа 184 250,50 ₽',
    value: '184 250,50 ₽',
    target: 'reconciliationLinked',
  ),
];
const banks = <TreasuryRow>[
  (
    title: 'АО «АЛЬФА-БАНК»',
    detail: 'БИК 044525593 · Москва · Корр. счёт 30101810200000000593',
    value: 'Актуален',
    target: 'bank',
  ),
  (
    title: 'ПАО Сбербанк',
    detail: 'БИК 044525225 · Москва · Корр. счёт 30101810400000000225',
    value: 'Актуален',
    target: 'bank',
  ),
];
const entities = <TreasuryRow>[
  (
    title: legalName,
    detail:
        'ИНН 5406123456 · КПП 540601001 · ОГРН 1165476123456 · Новосибирск, Советская, 52',
    value: 'Активно',
    target: 'entity',
  ),
  (
    title: 'ООО «Проектное бюро Север»',
    detail: 'ИНН 5406123490 · КПП 540601001 · Новосибирск',
    value: 'Активно',
    target: 'entity',
  ),
];
const imports = <TreasuryRow>[
  (
    title: fileName,
    detail:
        '10.09.2026 09:42 · Анна Иванова · 6 документов · 3 платежа · 2 дубликата · 1 ошибка',
    value: 'С замечаниями',
    target: 'import',
  ),
  (
    title: 'Выписка_2026-09-09.txt',
    detail: '09.09.2026 18:10 · Анна Иванова · 12 документов · 12 платежей',
    value: 'Обработана',
    target: 'import',
  ),
];
const issues = <TreasuryRow>[
  (
    title: 'Не определён контрагент',
    detail:
        'Платёж № 1043 · $counterparty · Не найдено юридическое лицо по ИНН 5406987654',
    value: '1 случай',
    target: 'issue',
  ),
  (
    title: 'Расчётный счёт не найден',
    detail:
        'Выписка от 10.09.2026 · Получатель $legalName · Требуется привязать счёт',
    value: '2 случая',
    target: 'issue',
  ),
];
