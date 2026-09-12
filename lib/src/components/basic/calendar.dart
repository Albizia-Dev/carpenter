import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import 'button/button.dart';
import 'button/icon_button.dart';
import 'gravity_icons.g.dart';
import '../../internal/date/calendar_model.dart';
import '../../internal/rendering/interactive_region.dart';
import '../../internal/rendering/focus_ring.dart';
import 'text.dart';

/// Controlled month calendar used by date inputs and page-level scheduling UI.
final class CarpenterCalendar extends StatefulWidget {
  /// Creates a controlled date picker. The displayed month starts at
  /// initialMonth, selected, or the current date in that order. Rebuild with
  /// the date received by onChanged to update the selection. Date bounds are
  /// inclusive and compare calendar dates, not times.
  const CarpenterCalendar({
    super.key,
    this.selected,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.initialMonth,
    this.rangeStart,
    this.rangeEnd,
  });

  /// Date highlighted as selected, or null for no selection. Time-of-day is
  /// ignored. Changing it after mounting does not navigate the displayed
  /// month.
  final DateTime? selected;

  /// Receives an enabled day selected by the user. The parent must store the
  /// returned date and rebuild; this callback does not update selected
  /// automatically.
  final ValueChanged<DateTime> onChanged;

  /// Inclusive earliest selectable date; null leaves the lower bound
  /// unrestricted. Months wholly before this date cannot be reached with the
  /// previous-month button.
  final DateTime? firstDate;

  /// Inclusive latest selectable date; null leaves the upper bound
  /// unrestricted. Months wholly after this date cannot be reached with the
  /// next-month button.
  final DateTime? lastDate;

  /// Month to display on first mount. Day and time components are discarded.
  /// Subsequent changes do not reset navigation; use a new widget key when an
  /// explicit reset is required.
  final DateTime? initialMonth;

  /// Inclusive beginning of a highlighted range. Selection callbacks still
  /// report one date at a time so the caller owns range construction.
  final DateTime? rangeStart;

  /// Inclusive end of the highlighted range; ignored without [rangeStart].
  /// Both endpoints receive selected semantics; interior dates use a tint.
  final DateTime? rangeEnd;

  /// Creates the month-navigation state. Selection remains caller-owned while
  /// the visible month is retained for this widget identity.
  @override
  State<CarpenterCalendar> createState() => _CarpenterCalendarState();
}

enum _CalendarView { days, months, years }

final class _CarpenterCalendarState extends State<CarpenterCalendar> {
  late DateTime _focused = CalendarModel.clamp(
    widget.selected ?? widget.initialMonth ?? DateTime.now(),
    widget.firstDate,
    widget.lastDate,
  );
  late DateTime _month = CalendarModel.monthOnly(
    CalendarModel.clamp(
      widget.initialMonth ?? widget.selected ?? DateTime.now(),
      widget.firstDate,
      widget.lastDate,
    ),
  );
  _CalendarView _view = _CalendarView.days;
  final _dayFocus = List.generate(42, (_) => FocusNode(skipTraversal: true));

  bool _enabled(DateTime date) =>
      CalendarModel.enabled(date, widget.firstDate, widget.lastDate);
  bool _canShow(DateTime month) =>
      CalendarModel.canShow(month, widget.firstDate, widget.lastDate);

  @override
  void didUpdateWidget(CarpenterCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _focused = CalendarModel.clamp(_focused, widget.firstDate, widget.lastDate);
    if (!_canShow(_month)) _month = CalendarModel.monthOnly(_focused);
  }

  @override
  void dispose() {
    for (final node in _dayFocus) {
      node.dispose();
    }
    super.dispose();
  }

  bool _canMove(int delta) {
    if (_view == _CalendarView.days) {
      return _canShow(DateTime(_month.year, _month.month + delta));
    }
    final target = DateTime(_month.year, _month.month + delta);
    final startYear = _view == _CalendarView.years
        ? (target.year ~/ 12) * 12
        : target.year;
    final endYear = _view == _CalendarView.years ? startYear + 11 : startYear;
    return endYear >= 1 &&
        startYear <= 9999 &&
        (widget.firstDate == null || endYear >= widget.firstDate!.year) &&
        (widget.lastDate == null || startYear <= widget.lastDate!.year);
  }

  void _move(int delta) {
    if (!_canMove(delta)) return;
    final next = CalendarModel.clamp(
      DateTime(_month.year, _month.month + delta),
      widget.firstDate,
      widget.lastDate,
    );
    setState(() {
      _month = CalendarModel.monthOnly(next);
      _focused = next;
    });
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final index = _dayFocus.indexWhere((node) => node.hasFocus);
    if (index < 0 || _view != _CalendarView.days) return KeyEventResult.ignored;
    final date = CalendarModel.days(_month)[index];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final next = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowLeft => CalendarModel.addDays(date, rtl ? 1 : -1),
      LogicalKeyboardKey.arrowRight => CalendarModel.addDays(
        date,
        rtl ? -1 : 1,
      ),
      LogicalKeyboardKey.arrowUp => CalendarModel.addDays(date, -7),
      LogicalKeyboardKey.arrowDown => CalendarModel.addDays(date, 7),
      LogicalKeyboardKey.home => CalendarModel.addDays(date, 1 - date.weekday),
      LogicalKeyboardKey.end => CalendarModel.addDays(date, 7 - date.weekday),
      LogicalKeyboardKey.pageUp => CalendarModel.addMonths(
        date,
        HardwareKeyboard.instance.isShiftPressed ? -12 : -1,
      ),
      LogicalKeyboardKey.pageDown => CalendarModel.addMonths(
        date,
        HardwareKeyboard.instance.isShiftPressed ? 12 : 1,
      ),
      _ => null,
    };
    if (next == null) return KeyEventResult.ignored;
    final target = CalendarModel.clamp(next, widget.firstDate, widget.lastDate);
    setState(() {
      _focused = target;
      _month = CalendarModel.monthOnly(target);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetIndex = CalendarModel.days(
        _month,
      ).indexWhere((date) => CalendarModel.sameDate(date, target));
      if (targetIndex >= 0) _dayFocus[targetIndex].requestFocus();
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.small);
    final days = CalendarModel.days(_month);
    var tabIndex = days.indexWhere(
      (day) => CalendarModel.sameDate(day, _focused) && _enabled(day),
    );
    if (tabIndex < 0) tabIndex = days.indexWhere(_enabled);
    for (var i = 0; i < _dayFocus.length; i++) {
      _dayFocus[i].skipTraversal = i != tabIndex;
    }
    final step = switch (_view) {
      _CalendarView.days => 1,
      _CalendarView.months => 12,
      _CalendarView.years => 144,
    };
    final firstYear = (_month.year ~/ 12) * 12;
    return Focus(
      onKeyEvent: _key,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: CarpenterButton(
                    label: _view == _CalendarView.years
                        ? '$firstYear–${firstYear + 11}'
                        : '${_monthNames[_month.month - 1]} ${_month.year}',
                    semanticLabel: 'Выбрать месяц и год',
                    icon: GravityIcons.chevronDown,
                    iconPosition: CarpenterActionIconPosition.trailing,
                    colorRole: ActionColorRole.neutral,
                    prominence: ActionProminence.ghost,
                    onInvoke: () => setState(
                      () => _view = switch (_view) {
                        _CalendarView.days => _CalendarView.months,
                        _CalendarView.months => _CalendarView.years,
                        _CalendarView.years => _CalendarView.days,
                      },
                    ),
                  ),
                ),
                CarpenterIconButton(
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? GravityIcons.chevronRight
                      : GravityIcons.chevronLeft,
                  semanticLabel: 'Предыдущий месяц',
                  size: ControlSize.small,
                  prominence: ActionProminence.ghost,
                  onInvoke: _canMove(-step) ? () => _move(-step) : null,
                ),
                CarpenterIconButton(
                  icon: Directionality.of(context) == TextDirection.rtl
                      ? GravityIcons.chevronLeft
                      : GravityIcons.chevronRight,
                  semanticLabel: 'Следующий месяц',
                  size: ControlSize.small,
                  prominence: ActionProminence.ghost,
                  onInvoke: _canMove(step) ? () => _move(step) : null,
                ),
              ],
            ),
            SizedBox(height: gap),
            if (_view != _CalendarView.days)
              for (var row = 0; row < 4; row++)
                Row(
                  children: [
                    for (var col = 0; col < 3; col++)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(gap / 2),
                          child: Builder(
                            builder: (_) {
                              final index = row * 3 + col;
                              final year = _view == _CalendarView.years
                                  ? firstYear + index
                                  : _month.year;
                              final month = _view == _CalendarView.months
                                  ? index + 1
                                  : _month.month;
                              final available = _view == _CalendarView.months
                                  ? _canShow(DateTime(year, month))
                                  : (widget.firstDate == null ||
                                            year >= widget.firstDate!.year) &&
                                        (widget.lastDate == null ||
                                            year <= widget.lastDate!.year) &&
                                        year > 0;
                              return CarpenterButton(
                                label: _view == _CalendarView.years
                                    ? '$year'
                                    : _monthNames[month - 1],
                                colorRole: ActionColorRole.neutral,
                                prominence: ActionProminence.ghost,
                                onInvoke: !available
                                    ? null
                                    : () => setState(() {
                                        _month = CalendarModel.monthOnly(
                                          CalendarModel.clamp(
                                            DateTime(year, month),
                                            widget.firstDate,
                                            widget.lastDate,
                                          ),
                                        );
                                        _focused = CalendarModel.clamp(
                                          _month,
                                          widget.firstDate,
                                          widget.lastDate,
                                        );
                                        _view = _view == _CalendarView.years
                                            ? _CalendarView.months
                                            : _CalendarView.days;
                                      }),
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                )
            else ...[
              Row(
                children: [
                  for (final label in _weekdayNames)
                    Expanded(
                      child: Center(
                        child: CarpenterText.caption(
                          label,
                          colorRole: ContentColorRole.secondary,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: gap),
              for (var row = 0; row < 6; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final index = row * 7 + col;
                            final date = days[index];
                            final endpoint =
                                (widget.selected != null &&
                                    CalendarModel.sameDate(
                                      date,
                                      widget.selected!,
                                    )) ||
                                (widget.rangeStart != null &&
                                    CalendarModel.sameDate(
                                      date,
                                      widget.rangeStart!,
                                    )) ||
                                (widget.rangeEnd != null &&
                                    CalendarModel.sameDate(
                                      date,
                                      widget.rangeEnd!,
                                    ));
                            final within =
                                widget.rangeStart != null &&
                                widget.rangeEnd != null &&
                                !date.isBefore(
                                  CalendarModel.dateOnly(widget.rangeStart!),
                                ) &&
                                !date.isAfter(
                                  CalendarModel.dateOnly(widget.rangeEnd!),
                                );
                            return Semantics(
                              selected: endpoint,
                              child: InteractiveRegion(
                                focusNode: _dayFocus[index],
                                onActivate: !_enabled(date)
                                    ? null
                                    : () {
                                        _dayFocus[index].requestFocus();
                                        setState(() => _focused = date);
                                        widget.onChanged(date);
                                      },
                                builder: (context, states, highlight) {
                                  final style = theme.actions.resolve(
                                    endpoint
                                        ? ActionColorRole.primary
                                        : ActionColorRole.neutral,
                                    endpoint
                                        ? ActionProminence.filled
                                        : within
                                        ? ActionProminence.normal
                                        : ActionProminence.ghost,
                                    states,
                                  );
                                  final radius = BorderRadius.circular(
                                    context.units(
                                      theme.shapes.radius(ShapeRole.rounded),
                                    ),
                                  );
                                  final today = CalendarModel.sameDate(
                                    date,
                                    DateTime.now(),
                                  );
                                  return FocusRing(
                                    visible:
                                        highlight &&
                                        states.contains(WidgetState.focused),
                                    borderRadius: radius,
                                    child: Semantics(
                                      button: true,
                                      enabled: _enabled(date),
                                      onTap: !_enabled(date)
                                          ? null
                                          : () {
                                              _dayFocus[index].requestFocus();
                                              setState(() => _focused = date);
                                              widget.onChanged(date);
                                            },
                                      label: carpenterFormatDate(date),
                                      hint: today ? 'Сегодня' : null,
                                      excludeSemantics: true,
                                      child: Container(
                                        constraints: BoxConstraints(
                                          minHeight: math.max(
                                            context.units(2.5.rem),
                                            MediaQuery.textScalerOf(
                                                  context,
                                                ).scale(context.units(1.rem)) +
                                                gap * 2,
                                          ),
                                        ),
                                        margin: EdgeInsets.all(
                                          context.units(.125.rem),
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: style.background,
                                          borderRadius: radius,
                                          border: Border.all(
                                            color: today && !endpoint
                                                ? theme.fields.borderFocused
                                                : style.border,
                                          ),
                                        ),
                                        child: Text(
                                          '${date.day}',
                                          style: theme.typography
                                              .resolve(
                                                context,
                                                TypographyRole.body,
                                                endpoint
                                                    ? TypographyEmphasis.strong
                                                    : TypographyEmphasis
                                                          .regular,
                                              )
                                              .copyWith(
                                                color:
                                                    !endpoint &&
                                                        !states.contains(
                                                          WidgetState.disabled,
                                                        ) &&
                                                        date.month !=
                                                            _month.month
                                                    ? theme.content.secondary
                                                    : style.foreground,
                                              ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

String carpenterFormatDate(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year.toString().padLeft(4, '0')}';
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
