import 'package:carpenter/carpenter.dart';

final class DemoNetworkPage<T> {
  const DemoNetworkPage({required this.items, required this.nextCursor});

  final List<T> items;
  final String? nextCursor;
}

/// Deterministic Widgetbook-only source with network-like latency, cursors,
/// filtering and one-shot failures. It deliberately performs no real I/O.
final class DemoNetworkSource<T> {
  DemoNetworkSource({
    required List<T> records,
    required this.searchText,
    this.latency = const Milliseconds(450),
  }) : _records = List.unmodifiable(records);

  final List<T> _records;
  final String Function(T value) searchText;
  final TimeUnit latency;
  bool _failNext = false;

  void failNextRequest() => _failNext = true;

  Future<DemoNetworkPage<T>> fetch({
    String query = '',
    String? cursor,
    int limit = 8,
  }) async {
    await Future<void>.delayed(latency.toDuration());
    if (_failNext) {
      _failNext = false;
      throw const DemoNetworkFailure('The demo service timed out');
    }
    final normalized = query.trim().toLowerCase();
    final matches = normalized.isEmpty
        ? _records
        : _records
              .where(
                (record) =>
                    searchText(record).toLowerCase().contains(normalized),
              )
              .toList(growable: false);
    final offset = int.tryParse(cursor ?? '') ?? 0;
    final end = (offset + limit).clamp(0, matches.length);
    final items = matches.sublist(offset.clamp(0, end), end);
    return DemoNetworkPage<T>(
      items: items,
      nextCursor: end < matches.length ? '$end' : null,
    );
  }
}

final class DemoNetworkFailure implements Exception {
  const DemoNetworkFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DemoInvoice {
  const DemoInvoice({
    required this.id,
    required this.number,
    required this.customer,
    required this.purpose,
    required this.amount,
    required this.status,
  });

  final int id;
  final String number;
  final String customer;
  final String purpose;
  final int amount;
  final DemoInvoiceStatus status;

  String get searchableText => '$number $customer $purpose ${status.name}';
}

enum DemoInvoiceStatus { draft, review, approved, overdue }

const demoInvoices = <DemoInvoice>[
  DemoInvoice(
    id: 101,
    number: 'INV-2026-0412',
    customer: 'Northwind Logistics',
    purpose: 'Warehouse automation milestone',
    amount: 2480000,
    status: DemoInvoiceStatus.review,
  ),
  DemoInvoice(
    id: 102,
    number: 'INV-2026-0413',
    customer: 'Contoso Retail',
    purpose: 'Store analytics subscription',
    amount: 684000,
    status: DemoInvoiceStatus.approved,
  ),
  DemoInvoice(
    id: 103,
    number: 'INV-2026-0414',
    customer: 'Alpine Energy',
    purpose: 'Metering integration',
    amount: 1275000,
    status: DemoInvoiceStatus.overdue,
  ),
  DemoInvoice(
    id: 104,
    number: 'INV-2026-0415',
    customer: 'Fabrikam Manufacturing',
    purpose: 'Production planning rollout',
    amount: 3320000,
    status: DemoInvoiceStatus.draft,
  ),
  DemoInvoice(
    id: 105,
    number: 'INV-2026-0416',
    customer: 'Adventure Works',
    purpose: 'Partner portal delivery',
    amount: 940000,
    status: DemoInvoiceStatus.review,
  ),
  DemoInvoice(
    id: 106,
    number: 'INV-2026-0417',
    customer: 'Tailspin Toys',
    purpose: 'Demand forecast extension',
    amount: 518000,
    status: DemoInvoiceStatus.approved,
  ),
  DemoInvoice(
    id: 107,
    number: 'INV-2026-0418',
    customer: 'Wide World Importers',
    purpose: 'Customs document workflow',
    amount: 1860000,
    status: DemoInvoiceStatus.review,
  ),
  DemoInvoice(
    id: 108,
    number: 'INV-2026-0419',
    customer: 'City Power & Light',
    purpose: 'Service desk modernization',
    amount: 760000,
    status: DemoInvoiceStatus.overdue,
  ),
  DemoInvoice(
    id: 109,
    number: 'INV-2026-0420',
    customer: 'Lucerne Publishing',
    purpose: 'Rights management migration',
    amount: 1430000,
    status: DemoInvoiceStatus.draft,
  ),
  DemoInvoice(
    id: 110,
    number: 'INV-2026-0421',
    customer: 'Proseware Services',
    purpose: 'Billing reconciliation',
    amount: 615000,
    status: DemoInvoiceStatus.approved,
  ),
  DemoInvoice(
    id: 111,
    number: 'INV-2026-0422',
    customer: 'Consolidated Messenger',
    purpose: 'Route planning pilot',
    amount: 885000,
    status: DemoInvoiceStatus.review,
  ),
  DemoInvoice(
    id: 112,
    number: 'INV-2026-0423',
    customer: 'Woodgrove Bank',
    purpose: 'Treasury reporting package',
    amount: 4210000,
    status: DemoInvoiceStatus.overdue,
  ),
];

FeedbackColorRole demoInvoiceStatusRole(DemoInvoiceStatus status) =>
    switch (status) {
      DemoInvoiceStatus.draft => FeedbackColorRole.neutral,
      DemoInvoiceStatus.review => FeedbackColorRole.info,
      DemoInvoiceStatus.approved => FeedbackColorRole.success,
      DemoInvoiceStatus.overdue => FeedbackColorRole.danger,
    };

String demoInvoiceStatusLabel(DemoInvoiceStatus status) => switch (status) {
  DemoInvoiceStatus.draft => 'Draft',
  DemoInvoiceStatus.review => 'In review',
  DemoInvoiceStatus.approved => 'Approved',
  DemoInvoiceStatus.overdue => 'Overdue',
};
