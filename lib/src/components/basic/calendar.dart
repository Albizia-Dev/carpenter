import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'button/button.dart';
import 'text.dart';

/// Controlled month calendar used by date inputs and page-level scheduling UI.
final class CarpenterCalendar extends StatefulWidget {
  const CarpenterCalendar({
    super.key,
    this.selected,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialMonth,
  });

  final DateTime? selected;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialMonth;

  @override
  State<CarpenterCalendar> createState() => _CarpenterCalendarState();
}

final class _CarpenterCalendarState extends State<CarpenterCalendar> {
  late DateTime _month = _monthOnly(widget.initialMonth ?? widget.selected ?? DateTime.now());

  bool _enabled(DateTime date) =>
      (widget.firstDate == null || !date.isBefore(_dateOnly(widget.firstDate!))) &&
      (widget.lastDate == null || !date.isAfter(_dateOnly(widget.lastDate!)));

  bool _canShow(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    return (widget.firstDate == null || !last.isBefore(_dateOnly(widget.firstDate!))) &&
        (widget.lastDate == null || !first.isAfter(_dateOnly(widget.lastDate!)));
  }

  void _move(int delta) {
    final next = DateTime(_month.year, _month.month + delta);
    if (_canShow(next)) setState(() => _month = next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final first = DateTime(_month.year, _month.month);
    final start = first.subtract(Duration(days: first.weekday - DateTime.monday));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            CarpenterButton(label: '‹', semanticLabel: 'Previous month', size: ControlSize.small, prominence: ActionProminence.ghost, onInvoke: _canShow(DateTime(_month.year, _month.month - 1)) ? () => _move(-1) : null),
            Expanded(child: Center(child: CarpenterText.label('${_monthNames[_month.month - 1]} ${_month.year}', emphasis: TypographyEmphasis.strong))),
            CarpenterButton(label: '›', semanticLabel: 'Next month', size: ControlSize.small, prominence: ActionProminence.ghost, onInvoke: _canShow(DateTime(_month.year, _month.month + 1)) ? () => _move(1) : null),
          ],
        ),
        SizedBox(height: gap),
        Row(
          children: [for (final label in _weekdayNames) Expanded(child: Center(child: CarpenterText.caption(label, colorRole: ContentColorRole.secondary)))],
        ),
        SizedBox(height: gap),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
          itemCount: 42,
          itemBuilder: (context, index) {
            final date = _dateOnly(start.add(Duration(days: index)));
            final selected = widget.selected != null && _sameDate(date, widget.selected!);
            return Padding(
              padding: const EdgeInsets.all(2),
              child: CarpenterButton(
                label: '${date.day}',
                semanticLabel: carpenterFormatDate(date),
                size: ControlSize.small,
                colorRole: selected ? ActionColorRole.primary : ActionColorRole.neutral,
                prominence: selected ? ActionProminence.high : ActionProminence.ghost,
                onInvoke: _enabled(date) ? () => widget.onChanged(date) : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

String carpenterFormatDate(DateTime value) => '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
DateTime _monthOnly(DateTime value) => DateTime(value.year, value.month);
bool _sameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
