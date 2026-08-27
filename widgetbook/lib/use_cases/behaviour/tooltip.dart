import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final tooltipComponent = WidgetbookComponent(
  name: 'Tooltip',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final text = context.knobs.string(
    label: 'Content · Text',
    initialValue: 'Создать копию документа',
  );
  final placement = context.knobs.object.segmented(
    label: 'Position · Placement',
    options: OverlayPlacement.values,
    initialOption: OverlayPlacement.top,
    labelBuilder: semanticValueLabel,
  );
  final showDelay = context.knobs.object.segmented(
    label: 'Motion · Show delay',
    options: TooltipDelay.values,
    initialOption: TooltipDelay.long,
    labelBuilder: semanticValueLabel,
  );
  final hideDelay = context.knobs.object.segmented(
    label: 'Motion · Hide delay',
    options: TooltipDelay.values,
    initialOption: TooltipDelay.short,
    labelBuilder: semanticValueLabel,
  );
  return preview(
    CarpenterTooltip(
      text: text,
      placement: placement,
      showDelay: showDelay,
      hideDelay: hideDelay,
      child: const CarpenterButton(
        label: 'Наведи или сфокусируй',
        onInvoke: _noop,
      ),
    ),
  );
}

void _noop() {}
