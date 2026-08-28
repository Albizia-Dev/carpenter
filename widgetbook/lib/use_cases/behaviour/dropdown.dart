import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

final dropdownComponent = WidgetbookComponent(
  name: 'Dropdown',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Trigger · Label',
    initialValue: 'Действия',
  );
  final role = context.knobs.object.segmented(
    label: 'Trigger · Role',
    options: ActionColorRole.values,
    initialOption: ActionColorRole.utility,
    labelBuilder: semanticValueLabel,
  );
  final prominence = context.knobs.object.segmented(
    label: 'Trigger · Prominence',
    options: ActionProminence.values,
    labelBuilder: semanticValueLabel,
  );
  final size = context.knobs.object.segmented(
    label: 'Trigger · Size',
    options: ControlSize.values,
    labelBuilder: semanticValueLabel,
  );
  final requestedOpen = context.knobs.boolean(label: 'State · Open');
  final disableArchive = context.knobs.boolean(label: 'Menu · Disable archive');
  return preview(
    _DropdownPreview(
      label: label,
      role: role,
      prominence: prominence,
      size: size,
      requestedOpen: requestedOpen,
      disableArchive: disableArchive,
    ),
  );
}

final class _DropdownPreview extends StatefulWidget {
  const _DropdownPreview({
    required this.label,
    required this.role,
    required this.prominence,
    required this.size,
    required this.requestedOpen,
    required this.disableArchive,
  });

  final String label;
  final ActionColorRole role;
  final ActionProminence prominence;
  final ControlSize size;
  final bool requestedOpen;
  final bool disableArchive;

  @override
  State<_DropdownPreview> createState() => _DropdownPreviewState();
}

final class _DropdownPreviewState extends State<_DropdownPreview> {
  late bool _open = widget.requestedOpen;
  String _last = '—';

  @override
  void didUpdateWidget(_DropdownPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.requestedOpen != widget.requestedOpen) {
      _open = widget.requestedOpen;
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterDropdown(
        open: _open,
        onOpenChanged: (value) => setState(() => _open = value),
        label: widget.label,
        colorRole: widget.role,
        prominence: widget.prominence,
        size: widget.size,
        items: [
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'duplicate',
              label: 'Дублировать',
              onInvoke: () => setState(() => _last = 'Дублировать'),
            ),
          ),
          CarpenterMenuItem(
            action: CarpenterActionDescriptor(
              id: 'archive',
              label: 'Архивировать',
              onInvoke: widget.disableArchive
                  ? null
                  : () => setState(() => _last = 'Архивировать'),
            ),
          ),
        ],
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterText.caption('Последнее действие: $_last'),
    ],
  );
}
