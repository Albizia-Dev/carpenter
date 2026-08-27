import 'package:carpenter/carpenter.dart';
import 'package:carpenter_widgetbook/helpers/demo_network.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('demo source behaves like cursor-paginated network data', () async {
    final source = DemoNetworkSource<DemoInvoice>(
      records: demoInvoices,
      searchText: (invoice) => invoice.searchableText,
      latency: const Milliseconds(1),
    );

    final first = await source.fetch(limit: 5);
    expect(first.items, hasLength(5));
    expect(first.nextCursor, '5');

    final second = await source.fetch(cursor: first.nextCursor, limit: 5);
    expect(second.items.first.id, demoInvoices[5].id);
    expect(second.nextCursor, '10');

    final filtered = await source.fetch(query: 'Northwind', limit: 5);
    expect(filtered.items.map((invoice) => invoice.customer), [
      'Northwind Logistics',
    ]);
    expect(filtered.nextCursor, isNull);
  });

  test(
    'one-shot failure is recoverable like a transient request error',
    () async {
      final source = DemoNetworkSource<DemoInvoice>(
        records: demoInvoices,
        searchText: (invoice) => invoice.searchableText,
        latency: const Milliseconds(1),
      )..failNextRequest();

      await expectLater(source.fetch(), throwsA(isA<DemoNetworkFailure>()));
      final recovered = await source.fetch();
      expect(recovered.items, isNotEmpty);
    },
  );
}
