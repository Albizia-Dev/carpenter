import 'package:carpenter/carpenter.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';
import 'package:carpenter_units/carpenter_units.dart';

final comboBoxComponent = WidgetbookComponent(
  name: 'Combo Box',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Контрагент',
  );
  final state = context.knobs.object.segmented(
    label: 'Data · State',
    options: OptionsLoadState.values,
    labelBuilder: semanticValueLabel,
  );
  final enabled = context.knobs.boolean(
    label: 'State · Enabled',
    initialValue: true,
  );
  final optionCount = context.knobs.int.slider(
    label: 'Data · Options',
    initialValue: 12,
    min: 0,
    max: 30,
  );
  final placement = context.knobs.object.segmented(
    label: 'Overlay · Placement',
    options: OverlayPlacement.values,
    initialOption: OverlayPlacement.bottomStart,
    labelBuilder: semanticValueLabel,
  );
  return preview(
    _ComboPreview(
      label: label,
      state: state,
      enabled: enabled,
      optionCount: optionCount,
      placement: placement,
    ),
  );
}

final class _ComboPreview extends StatefulWidget {
  const _ComboPreview({
    required this.label,
    required this.state,
    required this.enabled,
    required this.optionCount,
    required this.placement,
  });
  final String label;
  final OptionsLoadState state;
  final bool enabled;
  final int optionCount;
  final OverlayPlacement placement;

  @override
  State<_ComboPreview> createState() => _ComboPreviewState();
}

final class _ComboPreviewState extends State<_ComboPreview> {
  final _controller = TextEditingController();
  int? _value;
  var _open = false;

  List<CarpenterOption<int>> get _options {
    final query = _controller.text.trim().toLowerCase();
    return [
          for (var index = 1; index <= widget.optionCount; index++)
            CarpenterOption(
              id: index,
              value: index,
              label: 'Контрагент $index',
            ),
        ]
        .where(
          (option) =>
              query.isEmpty || option.label.toLowerCase().contains(query),
        )
        .toList();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterComboBox<int>(
        controller: _controller,
        value: _value,
        onChanged: widget.enabled
            ? (value) => setState(() => _value = value)
            : null,
        onQueryChanged: widget.enabled ? (_) => setState(() {}) : null,
        open: _open,
        onOpenChanged: (value) => setState(() => _open = value),
        options: _options,
        loadState: widget.state,
        label: widget.label,
        placement: widget.placement,
        clearAction: CarpenterActionDescriptor(
          id: 'clear',
          label: 'Очистить',
          semanticLabel: 'Очистить выбор',
          icon: Icons.close,
          onInvoke: () => setState(() {
            _controller.clear();
            _value = null;
          }),
        ),
      ),
      SizedBox(height: context.units(.75.rem)),
      CarpenterText.caption(
        'query="${_controller.text}" · value=${_value ?? '—'} · options=${_options.length}',
      ),
    ],
  );
}
