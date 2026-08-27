import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final switchComponent = WidgetbookComponent(
  name: 'Switch',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Color roles', builder: _colorRoles),
  ],
);

Widget _sizeComparison(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final size in ControlSize.values)
            CarpenterSwitch(
              value: true,
              label: semanticValueLabel(size),
              size: size,
              onChanged: _noop,
            ),
        ],
      );
    },
  ),
);

Widget _colorRoles(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final role in SelectionColorRole.values)
            CarpenterSwitch(
              value: true,
              label: semanticValueLabel(role),
              colorRole: role,
              onChanged: _noop,
            ),
        ],
      );
    },
  ),
);

Widget _playground(BuildContext context) {
  final initialValue = context.knobs.boolean(
    label: 'State · Value',
    initialValue: true,
  );
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Email notifications',
  );
  final description = context.knobs.stringOrNull(
    label: 'Content · Description',
    initialValue: 'Send a digest when important changes occur',
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: ControlSize.values,
    labelBuilder: semanticValueLabel,
  );
  final colorRole = context.knobs.object.segmented(
    label: 'Appearance · Color role',
    options: SelectionColorRole.values,
    initialOption: SelectionColorRole.primary,
    labelBuilder: semanticValueLabel,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return preview(
    _SwitchPreview(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      label: label,
      description: description,
      size: size,
      colorRole: colorRole,
      enabled: enabled,
    ),
  );
}

final class _SwitchPreview extends StatefulWidget {
  const _SwitchPreview({
    super.key,
    required this.initialValue,
    required this.label,
    required this.description,
    required this.size,
    required this.colorRole,
    required this.enabled,
  });

  final bool initialValue;
  final String label;
  final String? description;
  final ControlSize size;
  final SelectionColorRole colorRole;
  final bool enabled;

  @override
  State<_SwitchPreview> createState() => _SwitchPreviewState();
}

final class _SwitchPreviewState extends State<_SwitchPreview> {
  late var _value = widget.initialValue;

  @override
  Widget build(BuildContext context) => CarpenterSwitch(
    value: _value,
    label: widget.label,
    description: widget.description,
    size: widget.size,
    colorRole: widget.colorRole,
    onChanged: widget.enabled
        ? (value) => setState(() => _value = value)
        : null,
  );
}

void _noop(bool value) {}
