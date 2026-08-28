import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final autosuggestComponent = WidgetbookComponent(
  name: 'Autosuggest',
  useCases: [WidgetbookUseCase(name: 'Playground', builder: _playground)],
);

Widget _playground(BuildContext context) {
  final label = context.knobs.string(
    label: 'Content · Label',
    initialValue: 'Поиск',
  );
  final state = context.knobs.object.segmented(
    label: 'Data · State',
    options: OptionsLoadState.values,
    labelBuilder: semanticValueLabel,
  );
  final count = context.knobs.int.slider(
    label: 'Data · Suggestions',
    initialValue: 12,
    min: 0,
    max: 30,
  );
  final replaceOnSelection = context.knobs.boolean(
    label: 'Behavior · Replace query on selection',
    initialValue: true,
  );
  return preview(
    _AutosuggestPreview(
      label: label,
      state: state,
      count: count,
      replaceOnSelection: replaceOnSelection,
    ),
  );
}

final class _AutosuggestPreview extends StatefulWidget {
  const _AutosuggestPreview({
    required this.label,
    required this.state,
    required this.count,
    required this.replaceOnSelection,
  });
  final String label;
  final OptionsLoadState state;
  final int count;
  final bool replaceOnSelection;

  @override
  State<_AutosuggestPreview> createState() => _AutosuggestPreviewState();
}

final class _AutosuggestPreviewState extends State<_AutosuggestPreview> {
  final _controller = TextEditingController();
  var _open = false;
  String? _selected;

  List<CarpenterOption<int>> get _suggestions {
    final query = _controller.text.trim().toLowerCase();
    return [
          for (var index = 1; index <= widget.count; index++)
            CarpenterOption(id: index, value: index, label: 'Подсказка $index'),
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
      CarpenterAutosuggest<int>(
        controller: _controller,
        onQueryChanged: (_) => setState(() {
          _selected = null;
        }),
        onSuggestionSelected: (option) => setState(() {
          _selected = option.label;
        }),
        open: _open,
        onOpenChanged: (value) => setState(() => _open = value),
        suggestions: _suggestions,
        loadState: widget.state,
        label: widget.label,
        replaceQueryOnSelection: widget.replaceOnSelection,
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterText.caption(
        'query="${_controller.text}" · selected=${_selected ?? '—'} · suggestions=${_suggestions.length}',
      ),
    ],
  );
}
