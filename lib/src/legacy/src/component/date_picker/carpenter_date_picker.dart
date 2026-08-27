import 'package:carpenter/src/legacy/src/component/button/carpenter_button.dart';
import 'package:carpenter/src/legacy/src/component/control/carpenter_control.dart';
import 'package:carpenter/src/legacy/src/component/workbench/carpenter_workbench.dart';
import 'package:carpenter/src/legacy/src/root/context.dart';
import 'package:flutter/widgets.dart';

/// Поле выбора календарной даты в визуальном языке Carpenter.
///
/// Компонент не допускает ручной ввод: нажатие открывает календарь с
/// переключением месяцев. Время в возвращаемом значении всегда равно полуночи.
class CarpenterDatePicker extends StatelessWidget {
  const CarpenterDatePicker({
    super.key,
    this.selected,
    required this.onChanged,
    this.placeholder = 'Выберите дату',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.allowClear = true,
  });

  final DateTime? selected;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool allowClear;

  @override
  Widget build(BuildContext context) {
    assert(
      firstDate == null ||
          lastDate == null ||
          !_dateOnly(firstDate!).isAfter(_dateOnly(lastDate!)),
      'firstDate must not be after lastDate',
    );
    final value = selected == null ? null : _dateOnly(selected!);
    return CarpenterButton(
      type: .outlined,
      color: .secondary,
      onPressed: enabled
          ? () async {
              final result = await showCarpenterDialog<_DatePickerResult>(
                context: context,
                builder: (_) => _CarpenterCalendarDialog(
                  selected: value,
                  firstDate: firstDate == null ? null : _dateOnly(firstDate!),
                  lastDate: lastDate == null ? null : _dateOnly(lastDate!),
                  allowClear: allowClear,
                ),
              );
              if (result != null) onChanged(result.value);
            }
          : null,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(value == null ? placeholder : _formatDate(value)),
      ),
    );
  }
}

class _CarpenterCalendarDialog extends StatefulWidget {
  const _CarpenterCalendarDialog({
    required this.selected,
    required this.firstDate,
    required this.lastDate,
    required this.allowClear,
  });

  final DateTime? selected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool allowClear;

  @override
  State<_CarpenterCalendarDialog> createState() =>
      _CarpenterCalendarDialogState();
}

class _CarpenterCalendarDialogState extends State<_CarpenterCalendarDialog> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final initial = widget.selected ?? _dateOnly(DateTime.now());
    final clamped = _clamp(initial, widget.firstDate, widget.lastDate);
    _visibleMonth = DateTime(clamped.year, clamped.month);
  }

  bool _isEnabled(DateTime date) =>
      (widget.firstDate == null || !date.isBefore(widget.firstDate!)) &&
      (widget.lastDate == null || !date.isAfter(widget.lastDate!));

  bool _canShowMonth(DateTime month) {
    final first = DateTime(month.year, month.month);
    final last = DateTime(month.year, month.month + 1, 0);
    return (widget.firstDate == null || !last.isBefore(widget.firstDate!)) &&
        (widget.lastDate == null || !first.isAfter(widget.lastDate!));
  }

  void _changeMonth(int delta) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    if (_canShowMonth(next)) setState(() => _visibleMonth = next);
  }

  @override
  Widget build(BuildContext context) {
    final face = context.face;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final gridStart = firstOfMonth.subtract(
      Duration(days: firstOfMonth.weekday - DateTime.monday),
    );

    return CarpenterDialog(
      title: const Text('Выберите дату'),
      constraints: const BoxConstraints(maxWidth: 420),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CarpenterButton(
                type: .outlined,
                color: .secondary,
                compact: true,
                onPressed:
                    _canShowMonth(
                      DateTime(_visibleMonth.year, _visibleMonth.month - 1),
                    )
                    ? () => _changeMonth(-1)
                    : null,
                child: const Text('‹'),
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthNames[_visibleMonth.month - 1]} '
                    '${_visibleMonth.year}',
                    style: face.type('label.strong'),
                  ),
                ),
              ),
              CarpenterButton(
                type: .outlined,
                color: .secondary,
                compact: true,
                onPressed:
                    _canShowMonth(
                      DateTime(_visibleMonth.year, _visibleMonth.month + 1),
                    )
                    ? () => _changeMonth(1)
                    : null,
                child: const Text('›'),
              ),
            ],
          ),
          SizedBox(height: face.space('0.75')),
          Row(
            children: [
              for (final weekday in _weekdayNames)
                Expanded(
                  child: Center(
                    child: Text(
                      weekday,
                      style: face
                          .type('caption')
                          .copyWith(color: face.color('text.secondary')),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: face.space('0.25')),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
            ),
            itemCount: 42,
            itemBuilder: (context, index) {
              final date = gridStart.add(Duration(days: index));
              return _CalendarDay(
                date: date,
                inVisibleMonth: date.month == _visibleMonth.month,
                selected:
                    widget.selected != null &&
                    _sameDate(date, widget.selected!),
                today: _sameDate(date, DateTime.now()),
                enabled: _isEnabled(date),
                onPressed: () =>
                    Navigator.pop(context, _DatePickerResult(date)),
              );
            },
          ),
        ],
      ),
      actions: [
        if (widget.allowClear)
          CarpenterButton(
            type: .outlined,
            color: .secondary,
            label: 'Очистить',
            onPressed: () =>
                Navigator.pop(context, const _DatePickerResult(null)),
          ),
        CarpenterButton(
          type: .outlined,
          color: .secondary,
          label: 'Отмена',
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.inVisibleMonth,
    required this.selected,
    required this.today,
    required this.enabled,
    required this.onPressed,
  });

  final DateTime date;
  final bool inVisibleMonth;
  final bool selected;
  final bool today;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2),
      child: CarpenterControl(
        onTap: enabled ? onPressed : null,
        semanticLabel: _formatDate(date),
        semanticSelected: selected,
        builder: (context, state) {
          final face = context.face;
          final background = selected
              ? face.color('action.primary')
              : state.pressed
              ? face.color('surface.muted')
              : state.hovered || state.focused
              ? Color.lerp(
                  face.color('surface.raised'),
                  face.color('action.primary'),
                  0.08,
                )!
              : const Color(0x00000000);
          final foreground = !state.enabled
              ? face.color('action.disabled.text')
              : selected
              ? face.color('action.primary.text')
              : inVisibleMonth
              ? face.color('text.primary')
              : face.color('text.secondary');
          return AnimatedContainer(
            duration: face.motion.fast,
            decoration: BoxDecoration(
              color: background,
              border: today && !selected
                  ? Border.all(color: face.color('border.focus'))
                  : null,
              borderRadius: BorderRadius.circular(face.radius('lg')),
            ),
            alignment: Alignment.center,
            child: Text(
              '${date.day}',
              style: face.type('label').copyWith(color: foreground),
            ),
          );
        },
      ),
    );
  }
}

class _DatePickerResult {
  const _DatePickerResult(this.value);

  final DateTime? value;
}

const _monthNames = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

const _weekdayNames = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _clamp(DateTime value, DateTime? firstDate, DateTime? lastDate) {
  if (firstDate != null && value.isBefore(firstDate)) return firstDate;
  if (lastDate != null && value.isAfter(lastDate)) return lastDate;
  return value;
}

bool _sameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _formatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.'
    '${value.month.toString().padLeft(2, '0')}.${value.year}';
