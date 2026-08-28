import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final menuComponent = WidgetbookComponent(
  name: 'Menu',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Long menu', builder: _longMenu),
  ],
);

Widget _playground(BuildContext context) {
  final first = context.knobs.string(
    label: 'Actions · First label',
    initialValue: 'Открыть',
  );
  final second = context.knobs.string(
    label: 'Actions · Second label',
    initialValue: 'Дублировать',
  );
  final disabled = context.knobs.boolean(
    label: 'Actions · Disable second',
    initialValue: true,
  );
  return preview(
    _MenuPreview(first: first, second: second, disabled: disabled),
  );
}

Widget _longMenu(BuildContext context) => preview(
  CarpenterMenu(
    items: [
      for (var index = 1; index <= 30; index++)
        CarpenterMenuItem(
          action: CarpenterActionDescriptor(
            id: 'item-$index',
            label: 'Действие $index',
            onInvoke: () {},
          ),
        ),
    ],
  ),
);

final class _MenuPreview extends StatefulWidget {
  const _MenuPreview({
    required this.first,
    required this.second,
    required this.disabled,
  });

  final String first;
  final String second;
  final bool disabled;

  @override
  State<_MenuPreview> createState() => _MenuPreviewState();
}

final class _MenuPreviewState extends State<_MenuPreview> {
  String _last = '—';

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterMenu(
        semanticLabel: 'Действия',
        items: [
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'first',
              label: widget.first,
              onInvoke: () => setState(() => _last = widget.first),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'second',
              label: widget.second,
              onInvoke: widget.disabled
                  ? null
                  : () => setState(() => _last = widget.second),
            ),
          ),
        ],
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterText.caption('Последнее действие: $_last'),
      const CarpenterText.caption(
        'Проверьте ↑/↓, Home/End, Enter/Space и typeahead.',
      ),
    ],
  );
}
