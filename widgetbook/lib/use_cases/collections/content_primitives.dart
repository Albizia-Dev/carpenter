import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final tabsComponent = WidgetbookComponent(
  name: 'Tabs',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _tabsPlayground)],
);

final definitionListComponent = WidgetbookComponent(
  name: 'Definition list',
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterTabs<int>(
        value: _value,
        onChanged: widget.enabled
            ? (value) => setState(() => _value = value)
            : null,
        tabs: const [
          CarpenterTab(value: 0, label: 'Overview'),
          CarpenterTab(value: 1, label: 'Allocations'),
          CarpenterTab(value: 2, label: 'History'),
        ],
      ),
      SizedBox(height: context.units(.75.rem)),
      CarpenterButton(label: 'После табов — Tab для перехода', onInvoke: () {}),
    ],
  );
}

Widget _definitionPlayground(BuildContext context) {
  final longValues = context.knobs.boolean(label: 'Content · Long values');
  final actions = context.knobs.boolean(
    label: 'Content · Row actions',
    initialValue: true,
  );
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
      actions: actions
          ? (item) => [
              CarpenterActionDescriptor(
                id: 'definition.edit.${item.$1}',
                label: 'Edit ${item.$1}',
                icon: GravityIcons.pencil,
                onInvoke: () {},
              ),
            ]
          : null,
    ),
  );
}
