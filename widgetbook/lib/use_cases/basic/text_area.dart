import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final textAreaComponent = WidgetbookComponent(
  name: 'Text Area',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
  ],
);

Widget _sizeComparison(BuildContext context) =>
    preview(const _TextAreaSizeComparison());

Widget _playground(BuildContext context) {
  final initialText = context.knobs.string(
    label: 'Content · Initial text',
    initialValue: 'First line\nSecond line',
  );
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Notes',
  );
  final placeholder = context.knobs.stringOrNull(
    label: 'Content · Placeholder',
    initialValue: 'Add notes',
  );
  final description = context.knobs.stringOrNull(
    label: 'Content · Description',
    initialValue: 'Plain text only',
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
  final minLines = context.knobs.int.slider(
    label: 'Layout · Minimum lines',
    initialValue: 3,
    min: 1,
    max: 8,
  );
  final requestedMaxLines = context.knobs.intOrNull.slider(
    label: 'Layout · Maximum lines',
    initialValue: 6,
    min: 1,
    max: 12,
  );
  final maxLines = requestedMaxLines == null || requestedMaxLines >= minLines
      ? requestedMaxLines
      : minLines;
  final required = context.knobs.boolean(label: 'State · Required');

  return preview(
    _TextAreaPreview(
      key: ValueKey(initialText),
      initialText: initialText,
      label: label,
      placeholder: placeholder,
      description: description,
      errorText: error,
      availability: availability,
      size: size,
      minLines: minLines,
      maxLines: maxLines,
      required: required,
    ),
  );
}

final class _TextAreaPreview extends StatefulWidget {
  const _TextAreaPreview({
    super.key,
    required this.initialText,
    required this.label,
    required this.placeholder,
    required this.description,
    required this.errorText,
    required this.availability,
    required this.size,
    required this.minLines,
    required this.maxLines,
    required this.required,
  });

  final String initialText;
  final String label;
  final String? placeholder;
  final String? description;
  final String? errorText;
  final FieldAvailability availability;
  final FieldSize size;
  final int minLines;
  final int? maxLines;
  final bool required;

  @override
  State<_TextAreaPreview> createState() => _TextAreaPreviewState();
}

final class _TextAreaPreviewState extends State<_TextAreaPreview> {
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
  Widget build(BuildContext context) => CarpenterTextArea(
    controller: _controller,
    label: widget.label,
    placeholder: widget.placeholder,
    description: widget.description,
    errorText: widget.errorText,
    availability: widget.availability,
    size: widget.size,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    required: widget.required,
  );
}

final class _TextAreaSizeComparison extends StatefulWidget {
  const _TextAreaSizeComparison();

  @override
  State<_TextAreaSizeComparison> createState() =>
      _TextAreaSizeComparisonState();
}

final class _TextAreaSizeComparisonState
    extends State<_TextAreaSizeComparison> {
  late final _controllers = {
    for (final size in FieldSize.values)
      size: TextEditingController(text: 'Editable ${size.name} notes'),
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
          CarpenterTextArea(
            controller: _controllers[size]!,
            label: semanticValueLabel(size),
            size: size,
            minLines: 2,
            maxLines: 3,
          ),
          SizedBox(height: gap),
        ],
      ],
    );
  }
}
