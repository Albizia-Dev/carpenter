import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

final contextActionsComponent = WidgetbookComponent(
  name: 'Context actions',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _contextActions)],
);

Widget _contextActions(BuildContext context) => preview(
  CarpenterContextActionRegion(
    semanticLabel: 'Demo row actions',
    actions: [
      CarpenterActionDescriptor(id: 'open', label: 'Open', onInvoke: () {}),
      CarpenterActionDescriptor(
        id: 'archive',
        label: 'Archive',
        onInvoke: () {},
      ),
    ],
    child: SizedBox(
      width: context.units(30.rem),
      child: CarpenterCard(
        child: Padding(
          padding: EdgeInsets.all(context.units(1.rem)),
          child: CarpenterText.body(
            'Right-click this surface, or long-press it on touch, to open the same semantic actions.',
          ),
        ),
      ),
    ),
  ),
);
