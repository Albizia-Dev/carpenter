import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final selectComponent = WidgetbookComponent(
  name: 'Select',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _playground),
    WidgetbookUseCase(name: 'Size comparison', builder: _sizeComparison),
    WidgetbookUseCase(name: 'Edge cases', builder: _edgeCases),
  ],
);

Widget _sizeComparison(BuildContext context) => preview(
  Builder(
    builder: (context) {
      final gap = context.units(CarpenterTheme.of(context).spacing.medium);
      return Column(
        children: [
          for (final size in FieldSize.values) ...[
            _SelectPreview(
              label: semanticValueLabel(size),
              placeholder: 'Choose an option',
              availability: FieldAvailability.enabled,
              size: size,
              required: false,
              error: false,
              optionCount: 4,
            ),
            SizedBox(height: gap),
          ],
        ],
      );
    },
  ),
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Город',
  );
  final placeholder = context.knobs.string(
    label: 'Content · Placeholder',
    initialValue: 'Выберите город',
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
  final required = context.knobs.boolean(label: 'State · Required');
  final error = context.knobs.boolean(label: 'State · Error');
  final optionCount = context.knobs.int.slider(
    label: 'Content · Options',
    initialValue: 5,
    min: 0,
    max: 30,
  );
  return preview(
    _SelectPreview(
      label: label,
      placeholder: placeholder,
      availability: availability,
      size: size,
      required: required,
      error: error,
      optionCount: optionCount,
    ),
  );
}

Widget _edgeCases(BuildContext context) => previewColumn([
  const _SelectPreview(
    label: 'Empty',
    placeholder: 'Нет вариантов',
    availability: FieldAvailability.enabled,
    size: FieldSize.medium,
    required: false,
    error: false,
    optionCount: 0,
  ),
  const Directionality(
    textDirection: TextDirection.rtl,
    child: _SelectPreview(
      label: 'اختيار',
      placeholder: 'اختر قيمة',
      availability: FieldAvailability.enabled,
      size: FieldSize.large,
      required: true,
      error: false,
      optionCount: 20,
    ),
  ),
]);

final class _SelectPreview extends StatefulWidget {
  const _SelectPreview({
    required this.label,
    required this.placeholder,
    required this.availability,
    required this.size,
    required this.required,
    required this.error,
    required this.optionCount,
  });
  final String label;
  final String placeholder;
  final FieldAvailability availability;
  final FieldSize size;
  final bool required;
  final bool error;
  final int optionCount;
  @override
  State<_SelectPreview> createState() => _SelectPreviewState();
}

final class _SelectPreviewState extends State<_SelectPreview> {
  int? _value;
  var _open = false;
  @override
  Widget build(BuildContext context) => CarpenterSelect<int>(
    value: _value,
    onChanged: (value) => setState(() => _value = value),
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    label: widget.label,
    placeholder: widget.placeholder,
    availability: widget.availability,
    size: widget.size,
    required: widget.required,
    errorText: widget.error ? 'Выберите допустимое значение' : null,
    options: [
      for (var index = 1; index <= widget.optionCount; index++)
        CarpenterOption(
          id: index,
          value: index,
          label: index == widget.optionCount
              ? 'Очень длинное название варианта $index для узкой области'
              : 'Вариант $index',
        ),
    ],
  );
}
