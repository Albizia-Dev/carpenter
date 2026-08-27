import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final tabsComponent = WidgetbookComponent(
  name: 'Tabs',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _tabsPlayground)],
);

final definitionListComponent = WidgetbookComponent(
  name: 'Definition List',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _definitionPlayground),
  ],
);

Widget _tabsPlayground(BuildContext context) {
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return preview(_TabsPreview(enabled: enabled));
}

final class _TabsPreview extends StatefulWidget {
  const _TabsPreview({required this.enabled});

  final bool enabled;

  @override
  State<_TabsPreview> createState() => _TabsPreviewState();
}

final class _TabsPreviewState extends State<_TabsPreview> {
  var _value = 0;

  @override
  Widget build(BuildContext context) => CarpenterTabs<int>(
    value: _value,
    onChanged: widget.enabled
        ? (value) => setState(() => _value = value)
        : null,
    tabs: const [
      CarpenterTab(value: 0, label: 'Overview'),
      CarpenterTab(value: 1, label: 'Allocations'),
      CarpenterTab(value: 2, label: 'History'),
    ],
  );
}

Widget _definitionPlayground(BuildContext context) {
  final longValues = context.knobs.boolean(label: 'Content · Long values');
  final values = longValues
      ? const [
          ('Legal entity', 'Northwind Logistics International Holdings'),
          ('Account', 'Primary operating account · 40702 •••• 4821'),
          ('Status', 'Waiting for manual treasury reconciliation'),
        ]
      : const [
          ('Legal entity', 'Northwind Logistics'),
          ('Account', '40702 •••• 4821'),
          ('Status', 'Ready'),
        ];
  return preview(
    CarpenterDefinitionList<(String, String)>(
      items: values,
      term: (item) => item.$1,
      valueBuilder: (context, item) => CarpenterText.body(item.$2),
    ),
  );
}
