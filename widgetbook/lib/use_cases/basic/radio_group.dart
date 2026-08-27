import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

enum _Plan { starter, team, enterprise }

final radioGroupComponent = WidgetbookComponent(
  name: 'Radio Group',
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
            CarpenterRadioGroup<int>(
              value: 1,
              onChanged: (_) {},
              children: [
                CarpenterRadio(
                  value: 1,
                  label: semanticValueLabel(size),
                  size: size,
                ),
              ],
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
            CarpenterRadioGroup<int>(
              value: 1,
              onChanged: (_) {},
              children: [
                CarpenterRadio(
                  value: 1,
                  label: semanticValueLabel(role),
                  colorRole: role,
                ),
              ],
            ),
        ],
      );
    },
  ),
);

Widget _playground(BuildContext context) {
  final initialValue = context.knobs.object.segmented(
    label: 'State · Value',
    options: _Plan.values,
    initialOption: _Plan.team,
    labelBuilder: (value) => value.name,
  );
  final orientation = context.knobs.object.segmented(
    label: 'Layout · Orientation',
    options: Axis.values,
    labelBuilder: semanticValueLabel,
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
    _RadioPreview(
      key: ValueKey(initialValue),
      initialValue: initialValue,
      orientation: orientation,
      size: size,
      colorRole: colorRole,
      enabled: enabled,
    ),
  );
}

final class _RadioPreview extends StatefulWidget {
  const _RadioPreview({
    super.key,
    required this.initialValue,
    required this.orientation,
    required this.size,
    required this.colorRole,
    required this.enabled,
  });

  final _Plan initialValue;
  final Axis orientation;
  final ControlSize size;
  final SelectionColorRole colorRole;
  final bool enabled;

  @override
  State<_RadioPreview> createState() => _RadioPreviewState();
}

final class _RadioPreviewState extends State<_RadioPreview> {
  late var _value = widget.initialValue;

  @override
  Widget build(BuildContext context) => CarpenterRadioGroup<_Plan>(
    value: _value,
    orientation: widget.orientation,
    onChanged: widget.enabled
        ? (value) => setState(() => _value = value)
        : null,
    children: [
      CarpenterRadio(
        value: _Plan.starter,
        label: 'Starter',
        size: widget.size,
        colorRole: widget.colorRole,
      ),
      CarpenterRadio(
        value: _Plan.team,
        label: 'Team',
        description: 'Shared workspace and permissions',
        size: widget.size,
        colorRole: widget.colorRole,
      ),
      CarpenterRadio(
        value: _Plan.enterprise,
        label: 'Enterprise',
        size: widget.size,
        colorRole: widget.colorRole,
      ),
    ],
  );
}
