import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final inputComponent = WidgetbookComponent(
  name: 'Input',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Availability', builder: _availabilityComparison),
    WidgetbookUseCase(name: 'Feedback', builder: _feedbackComparison),
    WidgetbookUseCase(name: 'Accessibility', builder: _accessibility),
  ],
);

Widget _sizeComparison(BuildContext context) =>
    preview(const _InputSizeComparison());

Widget _availabilityComparison(BuildContext context) =>
    preview(const _InputAvailabilityComparison());

Widget _feedbackComparison(BuildContext context) => previewColumn(const [
  _InputPreview(
    initialText: 'Draft',
    label: 'Information',
    feedback: CarpenterFieldFeedback.info('Saved remotely'),
  ),
  _InputPreview(
    initialText: 'Approved',
    label: 'Success',
    feedback: CarpenterFieldFeedback.success('Ready to submit'),
  ),
  _InputPreview(
    initialText: 'Needs review',
    label: 'Warning',
    feedback: CarpenterFieldFeedback.warning('Check this value'),
  ),
  _InputPreview(
    initialText: 'Invalid',
    label: 'Danger',
    feedback: CarpenterFieldFeedback.danger('Enter a valid value'),
  ),
]);

Widget _playground(BuildContext context) {
  final initialText = context.knobs.string(
    label: 'Content · Initial text',
    initialValue: 'Carpenter',
  );
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Project name',
  );
  final placeholder = context.knobs.stringOrNull(
    label: 'Content · Placeholder',
    initialValue: 'Enter a name',
  );
  final description = context.knobs.stringOrNull(
    label: 'Content · Description',
    initialValue: 'Visible to collaborators',
  );
  final error = context.knobs.stringOrNull(
    label: 'Content · Error',
    defaultToNull: true,
  );
  final availability = context.knobs.object.segmented(
    label: 'State · Availability',
    options: FieldAvailability.values,
    labelBuilder: semanticValueLabel,
  );
  final size = context.knobs.object.segmented(
    label: 'Appearance · Size',
    options: FieldSize.values,
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
  final required = context.knobs.boolean(label: 'State · Required');
  final leading = context.knobs.boolean(
    label: 'Content · Leading icon',
    initialValue: true,
  );
  final trailing = context.knobs.boolean(
    label: 'Content · Trailing action',
    initialValue: true,
  );
  final autofocus = context.knobs.boolean(label: 'Accessibility · Autofocus');

  return preview(
    _InputPreview(
      key: ValueKey(initialText),
      initialText: initialText,
      label: label,
      placeholder: placeholder,
      description: description,
      errorText: error,
      availability: availability,
      size: size,
      shape: CarpenterShape(start: startShape, end: endShape),
      required: required,
      leadingIcon: leading ? Icons.edit : null,
      trailing: trailing,
      autofocus: autofocus,
    ),
  );
}

Widget _accessibility(BuildContext context) => previewColumn([
  _InputPreview(
    initialText: '',
    label: 'Required email',
    errorText: 'Enter a valid email address',
    required: true,
  ),
  _InputPreview(
    initialText: 'Read-only reference',
    label: 'Reference',
    availability: FieldAvailability.readOnly,
  ),
]);

final class _InputPreview extends StatefulWidget {
  const _InputPreview({
    super.key,
    required this.initialText,
    this.label,
    this.placeholder,
    this.description,
    this.feedback,
    this.errorText,
    this.availability = FieldAvailability.enabled,
    this.size = FieldSize.medium,
    this.shape = CarpenterShape.rounded,
    this.required = false,
    this.leadingIcon,
    this.trailing = false,
    this.autofocus = false,
  });

  final String initialText;
  final String? label;
  final String? placeholder;
  final String? description;
  final CarpenterFieldFeedback? feedback;
  final String? errorText;
  final FieldAvailability availability;
  final FieldSize size;
  final CarpenterShape shape;
  final bool required;
  final IconData? leadingIcon;
  final bool trailing;
  final bool autofocus;

  @override
  State<_InputPreview> createState() => _InputPreviewState();
}

final class _InputPreviewState extends State<_InputPreview> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CarpenterInput(
    controller: _controller,
    label: widget.label,
    placeholder: widget.placeholder,
    description: widget.description,
    feedback: widget.feedback,
    errorText: widget.errorText,
    availability: widget.availability,
    size: widget.size,
    shape: widget.shape,
    required: widget.required,
    leadingIcon: widget.leadingIcon,
    autofocus: widget.autofocus,
    trailingAction: widget.trailing
        ? CarpenterActionDescriptor(
            id: 'clear',
            label: 'Clear input',
            icon: Icons.clear,
            onInvoke: _controller.clear,
          )
        : null,
  );
}

final class _InputSizeComparison extends StatefulWidget {
  const _InputSizeComparison();

  @override
  State<_InputSizeComparison> createState() => _InputSizeComparisonState();
}

final class _InputSizeComparisonState extends State<_InputSizeComparison> {
  late final _controllers = {
    for (final size in FieldSize.values)
      size: TextEditingController(text: semanticValueLabel(size)),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    return Column(
      children: [
        for (final size in FieldSize.values) ...[
          CarpenterInput(
            controller: _controllers[size]!,
            label: '${semanticValueLabel(size)} input',
            description: 'FieldSize.${size.name}',
            size: size,
          ),
          SizedBox(height: gap),
        ],
      ],
    );
  }
}

final class _InputAvailabilityComparison extends StatefulWidget {
  const _InputAvailabilityComparison();

  @override
  State<_InputAvailabilityComparison> createState() =>
      _InputAvailabilityComparisonState();
}

final class _InputAvailabilityComparisonState
    extends State<_InputAvailabilityComparison> {
  late final _controllers = {
    for (final availability in FieldAvailability.values)
      availability: TextEditingController(
        text: semanticValueLabel(availability),
      ),
  };

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gap = context.units(CarpenterTheme.of(context).spacing.medium);
    return Column(
      children: [
        for (final availability in FieldAvailability.values) ...[
          CarpenterInput(
            controller: _controllers[availability]!,
            label: semanticValueLabel(availability),
            availability: availability,
          ),
          SizedBox(height: gap),
        ],
      ],
    );
  }
}
