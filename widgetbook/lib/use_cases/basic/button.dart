import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/curated_icons.dart';
import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final buttonComponent = WidgetbookComponent(
  name: 'Button',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Color roles', builder: _colorRoles),
    WidgetbookUseCase(name: 'States', builder: _states),
    WidgetbookUseCase(name: 'Edge cases', builder: _edgeCases),
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
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final size in ControlSize.values)
            CarpenterButton(
              label: semanticValueLabel(size),
              size: size,
              colorRole: ActionColorRole.primary,
              prominence: ActionProminence.normal,
              onInvoke: _noop,
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
          for (final role in ActionColorRole.values)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CarpenterButton(
                  label: semanticValueLabel(role),
                  colorRole: role,
                  prominence: ActionProminence.high,
                  onInvoke: _noop,
                ),
                SizedBox(height: gap),
                CarpenterButton(
                  label: 'Normal',
                  colorRole: role,
                  prominence: ActionProminence.normal,
                  onInvoke: _noop,
                ),
              ],
            ),
        ],
      );
    },
  ),
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Сохранить',
  );
  final showIcon = context.knobs.boolean(
    label: 'Content · Show icon',
    initialValue: true,
  );
  final icon = context.knobs.object.dropdown(
    label: 'Content · Icon',
    options: curatedIcons,
    initialOption: curatedIcons[5],
    labelBuilder: (option) => option.label,
  );
  final iconPosition = context.knobs.object.segmented(
    label: 'Content · Icon position',
    options: CarpenterActionIconPosition.values,
    labelBuilder: semanticValueLabel,
  );
  final role = context.knobs.object.segmented(
    label: 'Appearance · Role',
    options: ActionColorRole.values,
    initialOption: ActionColorRole.primary,
    labelBuilder: semanticValueLabel,
  );
  final prominence = context.knobs.object.segmented(
    label: 'Appearance · Prominence',
    options: ActionProminence.values,
    initialOption: ActionProminence.high,
    labelBuilder: semanticValueLabel,
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: ControlSize.values,
    labelBuilder: semanticValueLabel,
  );
  final startShape = context.knobs.object.segmented(
    label: 'Appearance · Start shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.rounded,
    labelBuilder: semanticValueLabel,
  );
  final endShape = context.knobs.object.segmented(
    label: 'Appearance · End shape',
    options: ShapeRole.values,
    initialOption: ShapeRole.rounded,
    labelBuilder: semanticValueLabel,
  );
  final execution = context.knobs.object.segmented(
    label: 'State · Execution',
    options: ActionExecutionPhase.values,
    labelBuilder: semanticValueLabel,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final semanticLabel = context.knobs.stringOrNull(
    label: 'Accessibility · Semantic label',
    initialValue: 'Сохранить изменения',
    defaultToNull: true,
  );
  final autofocus = context.knobs.boolean(label: 'Accessibility · Autofocus');

  return preview(
    _InvocationPreview(
      builder: (onInvoke) => CarpenterButton(
        label: label,
        icon: showIcon ? icon.data : null,
        iconPosition: iconPosition,
        colorRole: role,
        prominence: prominence,
        size: size,
        shape: CarpenterShape(start: startShape, end: endShape),
        executionPhase: execution,
        onInvoke: enabled ? onInvoke : null,
        semanticLabel: semanticLabel,
        autofocus: autofocus,
      ),
    ),
  );
}

Widget _states(BuildContext context) => previewColumn([
  const CarpenterButton(label: 'Enabled', onInvoke: _noop),
  const CarpenterButton(label: 'Disabled'),
  const CarpenterButton(
    label: 'Running',
    executionPhase: ActionExecutionPhase.running,
    onInvoke: _noop,
  ),
]);

Widget _edgeCases(BuildContext context) => previewColumn([
  const CarpenterButton(label: 'OK', onInvoke: _noop),
  const CarpenterButton(
    label: 'Сохранить изменения в договоре технического обслуживания',
    onInvoke: _noop,
  ),
  const CarpenterButton(
    label: 'Отправить документ на повторное согласование',
    icon: Icons.arrow_forward,
    onInvoke: _noop,
  ),
  const SizedBox(
    width: 180,
    child: CarpenterButton(
      label: 'Длинное действие в узкой области',
      onInvoke: _noop,
    ),
  ),
  const SizedBox(
    width: 560,
    child: CarpenterButton(label: 'Wide parent', onInvoke: _noop),
  ),
]);

Widget _accessibility(BuildContext context) => previewColumn([
  const CarpenterButton(
    label: '1542',
    semanticLabel: 'Открыть договор номер 1542',
    autofocus: true,
    onInvoke: _noop,
  ),
  const CarpenterButton(label: 'Disabled action'),
  const CarpenterButton(
    label: 'Synchronizing',
    executionPhase: ActionExecutionPhase.running,
    onInvoke: _noop,
  ),
]);

typedef _ButtonBuilder = Widget Function(VoidCallback onInvoke);

final class _InvocationPreview extends StatefulWidget {
  const _InvocationPreview({required this.builder});

  final _ButtonBuilder builder;

  @override
  State<_InvocationPreview> createState() => _InvocationPreviewState();
}

final class _InvocationPreviewState extends State<_InvocationPreview> {
  var _count = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      widget.builder(() => setState(() => _count++)),
      const SizedBox(height: 16),
      CarpenterText.caption('Invoked: $_count'),
    ],
  );
}

void _noop() {}
