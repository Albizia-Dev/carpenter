import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/preview.dart';

enum _MaskPreset { date, time, account }

final maskedInputComponent = WidgetbookComponent(
  name: 'Masked Input',
  useCases: [
    WidgetbookUseCase(name: 'Playground', builder: _maskedInput),
    WidgetbookUseCase(name: 'Presets', builder: _maskedPresets),
  ],
);

Widget _maskedInput(BuildContext context) {
  final preset = context.knobs.object.segmented(
    label: 'Mask · Preset',
    options: _MaskPreset.values,
    initialOption: _MaskPreset.date,
    labelBuilder: (value) => value.name,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  return _MaskedPreview(preset: preset, enabled: enabled);
}

final class _MaskedPreview extends StatefulWidget {
  const _MaskedPreview({required this.preset, required this.enabled});

  final _MaskPreset preset;
  final bool enabled;

  @override
  State<_MaskedPreview> createState() => _MaskedPreviewState();
}

final class _MaskedPreviewState extends State<_MaskedPreview> {
  final _controller = TextEditingController();

  CarpenterInputMask get _mask => switch (widget.preset) {
    _MaskPreset.date => CarpenterInputMask.date,
    _MaskPreset.time => CarpenterInputMask.time,
    _MaskPreset.account => const CarpenterInputMask('AA-####-****'),
  };

  @override
  void didUpdateWidget(_MaskedPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset != widget.preset) _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterMaskedInput(
      controller: _controller,
      mask: _mask,
      label: 'Masked value',
      description: 'Tokens: # digit, A letter, * alphanumeric.',
      availability: widget.enabled
          ? FieldAvailability.enabled
          : FieldAvailability.disabled,
      onChanged: (_) => setState(() {}),
    ),
    CarpenterText.caption(
      'Raw: ${_mask.unmask(_controller.text)} · complete: ${_mask.isComplete(_controller.text)}',
    ),
  ]);
}

Widget _maskedPresets(BuildContext context) => _MaskMatrix();

final class _MaskMatrix extends StatefulWidget {
  @override
  State<_MaskMatrix> createState() => _MaskMatrixState();
}

final class _MaskMatrixState extends State<_MaskMatrix> {
  final _date = TextEditingController(text: '01.09.2026');
  final _time = TextEditingController(text: '14:30');
  final _range = TextEditingController(text: '01.09.2026 – 12.09.2026');

  @override
  void dispose() {
    _date.dispose();
    _time.dispose();
    _range.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => previewColumn([
    CarpenterMaskedInput(
      controller: _date,
      mask: CarpenterInputMask.date,
      label: 'Date',
    ),
    CarpenterMaskedInput(
      controller: _time,
      mask: CarpenterInputMask.time,
      label: 'Time',
    ),
    CarpenterMaskedInput(
      controller: _range,
      mask: CarpenterInputMask.dateRange,
      label: 'Date range',
    ),
  ]);
}
