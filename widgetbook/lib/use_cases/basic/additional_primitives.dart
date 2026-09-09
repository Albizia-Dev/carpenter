import 'package:carpenter/carpenter.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import '../../helpers/labels.dart';
import '../../helpers/preview.dart';

final calendarComponent = WidgetbookComponent(
  name: 'Calendar',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) {
        final bounded = context.knobs.boolean(
          label: 'Behavior · Limit date range',
          initialValue: true,
        );
        final selected = context.knobs.boolean(
          label: 'State · Initial selection',
          initialValue: true,
        );
        return preview(
          SizedBox(
            width: context.units(24.rem),
            child: CalendarPreview(
              key: ValueKey((bounded, selected)),
              bounded: bounded,
              initiallySelected: selected,
            ),
          ),
        );
      },
    ),
  ],
);

/// Controlled calendar fixture with a fixed month, independent of wall time.
final class CalendarPreview extends StatefulWidget {
  const CalendarPreview({
    super.key,
    this.bounded = true,
    this.initiallySelected = true,
  });
  final bool bounded;
  final bool initiallySelected;
  @override
  State<CalendarPreview> createState() => _CalendarPreviewState();
}

final class _CalendarPreviewState extends State<CalendarPreview> {
  DateTime? _selected;
  @override
  void initState() {
    super.initState();
    _selected = widget.initiallySelected ? DateTime(2026, 9, 15) : null;
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      CarpenterCalendar(
        initialMonth: DateTime(2026, 9),
        selected: _selected,
        firstDate: widget.bounded ? DateTime(2026, 9, 5) : null,
        lastDate: widget.bounded ? DateTime(2026, 10, 20) : null,
        onChanged: (date) => setState(() => _selected = date),
      ),
      CarpenterText.caption(
        _selected == null
            ? 'No selected date'
            : 'Selected: ${carpenterFormatDate(_selected!)}',
      ),
      CarpenterButton.text(
        label: 'Clear selection',
        onPressed: () => setState(() => _selected = null),
      ),
    ],
  );
}

final asyncAutosuggestComponent = WidgetbookComponent(
  name: 'Async autosuggest',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => preview(
        AsyncAutosuggestPreview(
          fail: context.knobs.boolean(label: 'Data · Fail requests'),
          minimumQueryLength: context.knobs.int.slider(
            label: 'Behavior · Minimum characters',
            initialValue: 1,
            min: 1,
            max: 4,
          ),
          availability: context.knobs.object.dropdown(
            label: 'State · Availability',
            options: FieldAvailability.values,
            labelBuilder: semanticValueLabel,
          ),
        ),
      ),
    ),
  ],
);

/// Deterministic, network-free loader that exercises debounce and cancellation.
final class AsyncAutosuggestPreview extends StatefulWidget {
  const AsyncAutosuggestPreview({
    super.key,
    this.fail = false,
    this.minimumQueryLength = 1,
    this.availability = FieldAvailability.enabled,
  });
  final bool fail;
  final int minimumQueryLength;
  final FieldAvailability availability;
  @override
  State<AsyncAutosuggestPreview> createState() =>
      _AsyncAutosuggestPreviewState();
}

final class _AsyncAutosuggestPreviewState
    extends State<AsyncAutosuggestPreview> {
  String _selected = 'Nothing selected';
  Future<List<CarpenterOption<String>>> _load(
    String query,
    CarpenterSearchCancellation cancellation,
  ) async {
    final fail = widget.fail;
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (cancellation.isCancelled) return const [];
    if (fail) throw StateError('Demonstration request failure');
    return [
      for (final name in const ['Planning', 'Materials', 'Installation'])
        if (name.toLowerCase().contains(query.toLowerCase()))
          CarpenterOption(id: name, value: name, label: name),
    ];
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      CarpenterAsyncAutosuggest<String>(
        load: _load,
        label: 'Find an invoice',
        placeholder: 'Try Materials',
        minimumQueryLength: widget.minimumQueryLength,
        availability: widget.availability,
        onSelected: (option) => setState(() => _selected = option.label),
      ),
      SizedBox(height: context.units(1.rem)),
      CarpenterText.caption('Selected: $_selected'),
    ],
  );
}

final uploadProgressComponent = WidgetbookComponent(
  name: 'Upload progress',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => preview(
        CarpenterUploadProgress(
          value:
              context.knobs.boolean(
                label: 'State · In progress (unknown total)',
              )
              ? null
              : context.knobs.double.slider(
                  label: 'State · Progress',
                  initialValue: .5,
                  min: 0,
                  max: 1,
                ),
          semanticLabel: context.knobs.string(
            label: 'Content · Semantic label',
            initialValue: 'Invoice attachment upload',
          ),
        ),
      ),
    ),
  ],
);

final fieldShellComponent = WidgetbookComponent(
  name: 'Field shell',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => preview(
        CarpenterFieldShell(
          availability: context.knobs.object.dropdown(
            label: 'State · Availability',
            options: FieldAvailability.values,
            labelBuilder: semanticValueLabel,
          ),
          size: context.knobs.object.dropdown(
            label: 'Appearance · Size',
            options: FieldSize.values,
            initialOption: FieldSize.medium,
            labelBuilder: semanticValueLabel,
          ),
          shape: CarpenterShape.rounded,
          states: const {},
          label: context.knobs.string(
            label: 'Content · Label',
            initialValue: 'Custom field',
          ),
          description:
              context.knobs.boolean(
                label: 'Content · Show description',
                initialValue: true,
              )
              ? 'Shell for an application-owned editing control'
              : null,
          errorText: context.knobs.boolean(label: 'State · Show error')
              ? 'A value is required'
              : null,
          required: context.knobs.boolean(label: 'State · Required'),
          child: const CarpenterText.body('Read-only demonstration content'),
        ),
      ),
    ),
  ],
);

final gravityIconComponent = WidgetbookComponent(
  name: 'Gravity icon',
  useCases: [
    WidgetbookUseCase(
      name: 'Playground',
      builder: (context) => preview(
        GravityIcon(
          GravityIcons.folder,
          size: context.knobs.object.dropdown(
            label: 'Appearance · Size',
            options: IconSize.values,
            initialOption: IconSize.medium,
            labelBuilder: semanticValueLabel,
          ),
          colorRole: context.knobs.object.dropdown(
            label: 'Appearance · Color role',
            options: ContentColorRole.values,
            labelBuilder: semanticValueLabel,
          ),
          semanticLabel: 'Project folder',
        ),
      ),
    ),
  ],
);
