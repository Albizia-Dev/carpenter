import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../button/button.dart';
import '../calendar.dart';
import '../text.dart';

@immutable
final class CarpenterDateRange {
  CarpenterDateRange({required this.start, required this.end})
    : assert(!end.isBefore(start));

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is CarpenterDateRange &&
      _sameDate(other.start, start) &&
      _sameDate(other.end, end);

  @override
  int get hashCode => Object.hash(
    DateTime(start.year, start.month, start.day),
    DateTime(end.year, end.month, end.day),
  );
}

String carpenterFormatDateRange(CarpenterDateRange value) =>
    '${carpenterFormatDate(value.start)} – ${carpenterFormatDate(value.end)}';

/// Controlled inclusive date range picker.
final class CarpenterDateRangeInput extends StatefulWidget {
  const CarpenterDateRangeInput({
    super.key,
    this.value,
    required this.onChanged,
    this.placeholder = 'Choose date range',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.allowClear = true,
    this.semanticLabel,
  });

  final CarpenterDateRange? value;
  final ValueChanged<CarpenterDateRange?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool allowClear;
  final String? semanticLabel;

  @override
  State<CarpenterDateRangeInput> createState() =>
      _CarpenterDateRangeInputState();
}

final class _CarpenterDateRangeInputState
    extends State<CarpenterDateRangeInput> {
  bool _open = false;
  DateTime? _start;
  DateTime? _end;

  void _setOpen(bool value) {
    if (value) {
      _start = widget.value?.start;
      _end = widget.value?.end;
    }
    setState(() => _open = value);
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: _open,
    onOpenChanged: _setOpen,
    title: 'Choose date range',
    dismissPolicy: DialogDismissPolicy.outsideAndEscape,
    actions: [
      if (widget.allowClear)
        CarpenterActionDescriptor(
          id: 'date-range.clear',
          label: 'Clear',
          onInvoke: () {
            widget.onChanged(null);
            _setOpen(false);
          },
        ),
      CarpenterActionDescriptor(
        id: 'date-range.cancel',
        label: 'Cancel',
        onInvoke: () => _setOpen(false),
      ),
      CarpenterActionDescriptor(
        id: 'date-range.apply',
        label: 'Apply',
        colorRole: ActionColorRole.primary,
        onInvoke: _start == null || _end == null
            ? null
            : () {
                widget.onChanged(
                  CarpenterDateRange(start: _start!, end: _end!),
                );
                _setOpen(false);
              },
      ),
    ],
    content: LayoutBuilder(
      builder: (context, constraints) {
        final gap = context.units(.75.rem);
        final compact = constraints.maxWidth < context.units(40.rem);
        final startPicker = _RangeCalendar(
          label: 'Start date',
          selected: _start,
          firstDate: widget.firstDate,
          lastDate: _end ?? widget.lastDate,
          onChanged: (date) => setState(() {
            _start = date;
            if (_end != null && _end!.isBefore(date)) _end = null;
          }),
        );
        final endPicker = _RangeCalendar(
          label: 'End date',
          selected: _end,
          firstDate: _start ?? widget.firstDate,
          lastDate: widget.lastDate,
          onChanged: (date) => setState(() => _end = date),
        );
        return SizedBox(
          width: compact ? constraints.maxWidth : context.units(42.rem),
          child: compact
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    startPicker,
                    SizedBox(height: gap),
                    endPicker,
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: startPicker),
                    SizedBox(width: gap),
                    Expanded(child: endPicker),
                  ],
                ),
        );
      },
    ),
    child: CarpenterButton(
      label: widget.value == null
          ? widget.placeholder
          : carpenterFormatDateRange(widget.value!),
      semanticLabel: widget.semanticLabel,
      prominence: ActionProminence.outlined,
      onInvoke: widget.enabled ? () => _setOpen(true) : null,
    ),
  );
}

final class _RangeCalendar extends StatelessWidget {
  const _RangeCalendar({
    required this.label,
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
  });

  final String label;
  final DateTime? selected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CarpenterText.label(label, emphasis: TypographyEmphasis.strong),
      SizedBox(height: context.units(.5.rem)),
      CarpenterCalendar(
        selected: selected,
        firstDate: firstDate,
        lastDate: lastDate,
        initialMonth: selected ?? firstDate,
        onChanged: onChanged,
      ),
    ],
  );
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
