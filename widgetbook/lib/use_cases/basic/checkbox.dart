import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final checkboxComponent = WidgetbookComponent(
  name: 'Checkbox',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Color roles', builder: _colorRoles),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
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
            CarpenterCheckbox(
              value: CheckboxValue.checked,
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
            CarpenterCheckbox(
              value: CheckboxValue.checked,
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
  final initialValue = context.knobs.object.segmented(
    label: 'State · Value',
    options: CheckboxValue.values,
    labelBuilder: semanticValueLabel,
  );
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Include archived records',
  );
  final description = context.knobs.stringOrNull(
    label: 'Content · Description',
    initialValue: 'Mixed means only some descendants are included',
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
    _CheckboxPreview(
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

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterCheckbox(
    value: CheckboxValue.unchecked,
    label: 'Unchecked',
    onChanged: _noop,
  ),
  const CarpenterCheckbox(
    value: CheckboxValue.checked,
    label: 'Checked',
    onChanged: _noop,
  ),
  const CarpenterCheckbox(
    value: CheckboxValue.mixed,
    label: 'Partially selected',
    description: 'A visible label carries the state meaning with semantics',
    onChanged: _noop,
  ),
]);

final class _CheckboxPreview extends StatefulWidget {
  const _CheckboxPreview({
    super.key,
    required this.initialValue,
    required this.label,
    required this.description,
    required this.size,
    required this.colorRole,
    required this.enabled,
  });

  final CheckboxValue initialValue;
  final String label;
  final String? description;
  final ControlSize size;
  final SelectionColorRole colorRole;
  final bool enabled;

  @override
  State<_CheckboxPreview> createState() => _CheckboxPreviewState();
}

final class _CheckboxPreviewState extends State<_CheckboxPreview> {
  late var _value = widget.initialValue;

  @override
  Widget build(BuildContext context) => CarpenterCheckbox(
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

void _noop(CheckboxValue value) {}
