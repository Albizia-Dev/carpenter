import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';

import 'demo_network.dart';

Widget demoInvoiceTable({
  required CollectionSnapshot<DemoInvoice> snapshot,
  required CollectionSelection<int> selection,
  ValueChanged<CollectionSelection<int>>? onSelectionChanged,
  VoidCallback? onLoadMore,
}) => CarpenterTable<DemoInvoice, int>(
  semanticLabel: 'Customer invoices',
  snapshot: snapshot,
  rowKey: (invoice) => invoice.id,
  rowSemanticLabel: (invoice) =>
      '${invoice.number}, ${invoice.customer}, ${invoice.amount}',
  selection: selection,
  onSelectionChanged: onSelectionChanged,
  onLoadMore: onLoadMore,
  columns: [
    CarpenterTableColumn<DemoInvoice>.text(
      id: 'number',
      header: 'Invoice',
      value: (invoice) => invoice.number,
      sortable: true,
    ),
    CarpenterTableColumn<DemoInvoice>.text(
      id: 'customer',
      header: 'Customer',
      value: (invoice) => invoice.customer,
      sortable: true,
    ),
    CarpenterTableColumn<DemoInvoice>.number(
      id: 'amount',
      header: 'Amount',
      value: (invoice) => invoice.amount,
      formatter: (value) => '${value.toInt()} ₽',
      sortable: true,
    ),
    CarpenterTableColumn<DemoInvoice>.status(
      id: 'status',
      header: 'Status',
      label: (invoice) => demoInvoiceStatusLabel(invoice.status),
      role: (invoice) => demoInvoiceStatusRole(invoice.status),
    ),
  ],
);

Widget demoInvoiceDetails(DemoInvoice invoice) => Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    CarpenterText.title(invoice.number),
    CarpenterText.body(invoice.customer),
    CarpenterStatusIndicator(
      label: demoInvoiceStatusLabel(invoice.status),
      role: demoInvoiceStatusRole(invoice.status),
    ),
    CarpenterText.body(invoice.purpose),
    CarpenterText.label('${invoice.amount} ₽'),
  ],
);
