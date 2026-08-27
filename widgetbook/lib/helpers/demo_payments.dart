import 'package:carpenter/carpenter.dart';

enum DemoPaymentDirection { incoming, outgoing }

enum DemoPaymentStatus { review, matched, posted, rejected }

final class DemoPaymentAllocation {
  const DemoPaymentAllocation({
    required this.object,
    required this.kind,
    required this.amount,
    required this.state,
  });

  final String object;
  final String kind;
  final String amount;
  final String state;
}

final class DemoPaymentEvent {
  const DemoPaymentEvent({
    required this.id,
    required this.time,
    required this.title,
    required this.actor,
  });

  final String id;
  final String time;
  final String title;
  final String actor;
}

final class DemoPayment {
  const DemoPayment({
    required this.id,
    required this.documentNumber,
    required this.bookedAt,
    required this.direction,
    required this.amount,
    required this.currency,
    required this.status,
    required this.purpose,
    required this.legalEntity,
    required this.accountName,
    required this.accountNumber,
    required this.counterparty,
    required this.counterpartyInn,
    required this.counterpartyAccount,
    required this.counterpartyBank,
    required this.counterpartyBic,
    required this.allocations,
    required this.events,
  });

  final String id;
  final String documentNumber;
  final String bookedAt;
  final DemoPaymentDirection direction;
  final String amount;
  final String currency;
  final DemoPaymentStatus status;
  final String purpose;
  final String legalEntity;
  final String accountName;
  final String accountNumber;
  final String counterparty;
  final String counterpartyInn;
  final String counterpartyAccount;
  final String counterpartyBank;
  final String counterpartyBic;
  final List<DemoPaymentAllocation> allocations;
  final List<DemoPaymentEvent> events;

  String get signedAmount =>
      '${direction == DemoPaymentDirection.incoming ? '+' : '−'}$amount $currency';

  String get searchableText => [
    documentNumber,
    purpose,
    legalEntity,
    accountName,
    accountNumber,
    counterparty,
    counterpartyInn,
    status.name,
  ].join(' ');
}

FeedbackColorRole demoPaymentStatusRole(DemoPaymentStatus status) =>
    switch (status) {
      DemoPaymentStatus.review => FeedbackColorRole.warning,
      DemoPaymentStatus.matched => FeedbackColorRole.info,
      DemoPaymentStatus.posted => FeedbackColorRole.success,
      DemoPaymentStatus.rejected => FeedbackColorRole.danger,
    };

String demoPaymentStatusLabel(DemoPaymentStatus status) => switch (status) {
  DemoPaymentStatus.review => 'Требует разбора',
  DemoPaymentStatus.matched => 'Сопоставлен',
  DemoPaymentStatus.posted => 'Разнесён',
  DemoPaymentStatus.rejected => 'Отклонён',
};

const demoPayments = <DemoPayment>[
  DemoPayment(
    id: 'pay-90512',
    documentNumber: 'ПП-90512',
    bookedAt: '26 августа · 14:42',
    direction: DemoPaymentDirection.incoming,
    amount: '1 284 500,00',
    currency: '₽',
    status: DemoPaymentStatus.review,
    purpose:
        'Оплата по договору поставки № 18/24 от 12.02.2026, включая НДС 20%',
    legalEntity: 'ООО «Окиби Технологии»',
    accountName: 'Основной · Сибирский банк',
    accountNumber: '40702 •••• 4821',
    counterparty: 'ООО «Северная логистика»',
    counterpartyInn: 'ИНН 5406123456',
    counterpartyAccount: '40702 •••• 9017',
    counterpartyBank: 'АО «Альфа-Банк»',
    counterpartyBic: 'БИК 044525593',
    allocations: [
      DemoPaymentAllocation(
        object: 'Договор № 18/24',
        kind: 'Поставка оборудования',
        amount: '980 000,00 ₽',
        state: 'Подтверждено',
      ),
      DemoPaymentAllocation(
        object: 'Счёт № 412',
        kind: 'Монтажные работы',
        amount: '304 500,00 ₽',
        state: 'Предложено системой',
      ),
    ],
    events: [
      DemoPaymentEvent(
        id: 'evt-1',
        time: '14:42',
        title: 'Платёж получен из банковской выписки',
        actor: 'Интеграция · Сибирский банк',
      ),
      DemoPaymentEvent(
        id: 'evt-2',
        time: '14:43',
        title: 'Найдены два возможных объекта распределения',
        actor: 'Автоматическое сопоставление',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90511',
    documentNumber: 'ПП-90511',
    bookedAt: '26 августа · 13:18',
    direction: DemoPaymentDirection.outgoing,
    amount: '348 000,00',
    currency: '₽',
    status: DemoPaymentStatus.posted,
    purpose: 'Аренда офисного помещения за август 2026 года, без НДС',
    legalEntity: 'ООО «Окиби Технологии»',
    accountName: 'Основной · Сибирский банк',
    accountNumber: '40702 •••• 4821',
    counterparty: 'АО «Деловой квартал»',
    counterpartyInn: 'ИНН 5407982451',
    counterpartyAccount: '40702 •••• 1139',
    counterpartyBank: 'ПАО Сбербанк',
    counterpartyBic: 'БИК 045004641',
    allocations: [
      DemoPaymentAllocation(
        object: 'Счёт № ДК-0826',
        kind: 'Аренда',
        amount: '348 000,00 ₽',
        state: 'Разнесено полностью',
      ),
    ],
    events: [
      DemoPaymentEvent(
        id: 'evt-3',
        time: '13:18',
        title: 'Платёж отправлен банком',
        actor: 'Анна Лебедева',
      ),
      DemoPaymentEvent(
        id: 'evt-4',
        time: '13:24',
        title: 'Платёж разнесён на счёт № ДК-0826',
        actor: 'Михаил Орлов',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90510',
    documentNumber: 'ПП-90510',
    bookedAt: '26 августа · 11:07',
    direction: DemoPaymentDirection.incoming,
    amount: '76 430,50',
    currency: '₽',
    status: DemoPaymentStatus.matched,
    purpose: 'Оплата услуг сопровождения за июль, счёт 388',
    legalEntity: 'ООО «Окиби Сервис»',
    accountName: 'Операционный · Точка',
    accountNumber: '40702 •••• 1840',
    counterparty: 'ООО «Тайга Ритейл»',
    counterpartyInn: 'ИНН 2465120987',
    counterpartyAccount: '40702 •••• 7742',
    counterpartyBank: 'Филиал «Новосибирский» ВТБ',
    counterpartyBic: 'БИК 045004788',
    allocations: [
      DemoPaymentAllocation(
        object: 'Счёт № 388',
        kind: 'Сопровождение',
        amount: '76 430,50 ₽',
        state: 'Ожидает подтверждения',
      ),
    ],
    events: [
      DemoPaymentEvent(
        id: 'evt-5',
        time: '11:07',
        title: 'Платёж импортирован',
        actor: 'Интеграция · Точка',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90509',
    documentNumber: 'ПП-90509',
    bookedAt: '26 августа · 09:51',
    direction: DemoPaymentDirection.outgoing,
    amount: '2 100 000,00',
    currency: '₽',
    status: DemoPaymentStatus.review,
    purpose: 'Аванс за серверное оборудование по спецификации № 7',
    legalEntity: 'ООО «Окиби Технологии»',
    accountName: 'Закупки · Сибирский банк',
    accountNumber: '40702 •••• 4904',
    counterparty: 'ООО «Инфраструктурные решения»',
    counterpartyInn: 'ИНН 7704839201',
    counterpartyAccount: '40702 •••• 6492',
    counterpartyBank: 'ПАО Росбанк',
    counterpartyBic: 'БИК 044525256',
    allocations: [],
    events: [
      DemoPaymentEvent(
        id: 'evt-6',
        time: '09:51',
        title: 'Платёж ожидает ручной проверки',
        actor: 'Контроль казначейства',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90508',
    documentNumber: 'ПП-90508',
    bookedAt: '25 августа · 18:36',
    direction: DemoPaymentDirection.incoming,
    amount: '512 900,00',
    currency: '₽',
    status: DemoPaymentStatus.posted,
    purpose: 'Оплата лицензий Carpenter Enterprise, 120 рабочих мест',
    legalEntity: 'ООО «Окиби Сервис»',
    accountName: 'Операционный · Точка',
    accountNumber: '40702 •••• 1840',
    counterparty: 'АО «Городские системы»',
    counterpartyInn: 'ИНН 7812984103',
    counterpartyAccount: '40702 •••• 2388',
    counterpartyBank: 'ПАО Банк Санкт-Петербург',
    counterpartyBic: 'БИК 044030790',
    allocations: [
      DemoPaymentAllocation(
        object: 'Заказ SO-2041',
        kind: 'Лицензии',
        amount: '512 900,00 ₽',
        state: 'Разнесено полностью',
      ),
    ],
    events: [
      DemoPaymentEvent(
        id: 'evt-7',
        time: '18:36',
        title: 'Платёж разнесён автоматически',
        actor: 'Правило «Лицензии»',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90507',
    documentNumber: 'ПП-90507',
    bookedAt: '25 августа · 16:02',
    direction: DemoPaymentDirection.outgoing,
    amount: '94 700,00',
    currency: '₽',
    status: DemoPaymentStatus.rejected,
    purpose: 'Возврат ошибочно перечисленных денежных средств',
    legalEntity: 'ООО «Окиби Сервис»',
    accountName: 'Операционный · Точка',
    accountNumber: '40702 •••• 1840',
    counterparty: 'ИП Кузнецов Артём Сергеевич',
    counterpartyInn: 'ИНН 540301928477',
    counterpartyAccount: '40802 •••• 1076',
    counterpartyBank: 'АО «ТБанк»',
    counterpartyBic: 'БИК 044525974',
    allocations: [],
    events: [
      DemoPaymentEvent(
        id: 'evt-8',
        time: '16:02',
        title: 'Платёж отклонён банковским контролем',
        actor: 'АО «ТБанк»',
      ),
    ],
  ),
  DemoPayment(
    id: 'pay-90506',
    documentNumber: 'ПП-90506',
    bookedAt: '25 августа · 12:44',
    direction: DemoPaymentDirection.incoming,
    amount: '238 100,00',
    currency: '₽',
    status: DemoPaymentStatus.matched,
    purpose: 'Погашение задолженности по акту сверки от 20.08.2026',
    legalEntity: 'ООО «Окиби Технологии»',
    accountName: 'Основной · Сибирский банк',
    accountNumber: '40702 •••• 4821',
    counterparty: 'ООО «Академ Поставка»',
    counterpartyInn: 'ИНН 5408256012',
    counterpartyAccount: '40702 •••• 5530',
    counterpartyBank: 'Банк Левобережный (ПАО)',
    counterpartyBic: 'БИК 045004850',
    allocations: [
      DemoPaymentAllocation(
        object: 'Акт сверки от 20.08',
        kind: 'Задолженность',
        amount: '238 100,00 ₽',
        state: 'Ожидает подтверждения',
      ),
    ],
    events: [
      DemoPaymentEvent(
        id: 'evt-9',
        time: '12:44',
        title: 'Найдено совпадение по сумме и контрагенту',
        actor: 'Автоматическое сопоставление',
      ),
    ],
  ),
];
