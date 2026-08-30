import 'dart:math' as math;

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../application/runtime/runtime.dart';
import '../../../foundation/roles.dart';
import '../select/select.dart';
import '../text.dart';

TargetPlatform carpenterPickerPlatform(BuildContext context) {
  final scope = context.dependOnInheritedWidgetOfExactType<CarpenterRuntimeScope>();
  return scope?.runtime.maybeRead<CarpenterCoreRuntime>()?.platform ??
      defaultTargetPlatform;
}

bool carpenterUsesWheelPicker(BuildContext context) {
  if (kIsWeb) return false;
  return switch (carpenterPickerPlatform(context)) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
}

final class CarpenterDateWheel extends StatefulWidget {
  const CarpenterDateWheel({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
    this.semanticLabel = 'Date picker',
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String semanticLabel;

  @override
  State<CarpenterDateWheel> createState() => _CarpenterDateWheelState();
}

final class _CarpenterDateWheelState extends State<CarpenterDateWheel> {
  late DateTime _value;
  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  DateTime get _first => _dateOnly(widget.firstDate ?? DateTime(1900));
  DateTime get _last => _dateOnly(widget.lastDate ?? DateTime(2100, 12, 31));

  @override
  void initState() {
    super.initState();
    _value = _clampDate(widget.value, _first, _last);
    _createControllers();
  }

  @override
  void didUpdateWidget(CarpenterDateWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousFirstYear = _dateOnly(oldWidget.firstDate ?? DateTime(1900)).year;
    final next = _clampDate(widget.value, _first, _last);
    if (previousFirstYear != _first.year) {
      _yearController.dispose();
      _yearController = FixedExtentScrollController(
        initialItem: next.year - _first.year,
      );
    }
    if (!_sameDate(next, _value)) {
      _value = next;
      _syncControllers();
    }
  }

  void _createControllers() {
    _dayController = FixedExtentScrollController(initialItem: _value.day - 1);
    _monthController = FixedExtentScrollController(initialItem: _value.month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _value.year - _first.year,
    );
  }

  void _syncControllers() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_dayController.hasClients) _dayController.jumpToItem(_value.day - 1);
      if (_monthController.hasClients) {
        _monthController.jumpToItem(_value.month - 1);
      }
      if (_yearController.hasClients) {
        _yearController.jumpToItem(_value.year - _first.year);
      }
    });
  }

  void _change({int? year, int? month, int? day}) {
    final nextYear = year ?? _value.year;
    final nextMonth = month ?? _value.month;
    final maxDay = _daysInMonth(nextYear, nextMonth);
    final nextDay = math.min(day ?? _value.day, maxDay);
    final next = _clampDate(
      DateTime(nextYear, nextMonth, nextDay),
      _first,
      _last,
    );
    if (_sameDate(next, _value)) return;
    setState(() => _value = next);
    _syncControllers();
    widget.onChanged(next);
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = context.units(2.25.rem);
    final height = context.units(10.rem);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: _PickerWheel(
                controller: _dayController,
                itemExtent: extent,
                count: _daysInMonth(_value.year, _value.month),
                labelBuilder: (index) => (index + 1).toString().padLeft(2, '0'),
                onSelected: (index) => _change(day: index + 1),
              ),
            ),
            Expanded(
              child: _PickerWheel(
                controller: _monthController,
                itemExtent: extent,
                count: 12,
                labelBuilder: (index) => (index + 1).toString().padLeft(2, '0'),
                onSelected: (index) => _change(month: index + 1),
              ),
            ),
            Expanded(
              flex: 2,
              child: _PickerWheel(
                controller: _yearController,
                itemExtent: extent,
                count: _last.year - _first.year + 1,
                labelBuilder: (index) => (_first.year + index).toString(),
                onSelected: (index) => _change(year: _first.year + index),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class CarpenterTimeWheel extends StatefulWidget {
  const CarpenterTimeWheel({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
    this.minuteStep = 1,
    this.semanticLabel = 'Time picker',
  }) : assert(minuteStep > 0 && minuteStep <= 30 && 60 % minuteStep == 0);

  final int hour;
  final int minute;
  final int minuteStep;
  final void Function(int hour, int minute) onChanged;
  final String semanticLabel;

  @override
  State<CarpenterTimeWheel> createState() => _CarpenterTimeWheelState();
}

final class _CarpenterTimeWheelState extends State<CarpenterTimeWheel> {
  late int _hour = widget.hour.clamp(0, 23);
  late int _minute = _normalizeMinute(widget.minute, widget.minuteStep);
  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(initialItem: _hour);
  late FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: _minute ~/ widget.minuteStep);

  @override
  void didUpdateWidget(CarpenterTimeWheel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minuteStep != widget.minuteStep) {
      _minute = _normalizeMinute(widget.minute, widget.minuteStep);
      _minuteController.dispose();
      _minuteController = FixedExtentScrollController(
        initialItem: _minute ~/ widget.minuteStep,
      );
    }
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final extent = context.units(2.25.rem);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: SizedBox(
        height: context.units(10.rem),
        width: context.units(15.rem),
        child: Row(
          children: [
            Expanded(
              child: _PickerWheel(
                controller: _hourController,
                itemExtent: extent,
                count: 24,
                labelBuilder: (index) => index.toString().padLeft(2, '0'),
                onSelected: (index) {
                  setState(() => _hour = index);
                  widget.onChanged(_hour, _minute);
                },
              ),
            ),
            const CarpenterText.title(':'),
            Expanded(
              child: _PickerWheel(
                controller: _minuteController,
                itemExtent: extent,
                count: 60 ~/ widget.minuteStep,
                labelBuilder: (index) =>
                    (index * widget.minuteStep).toString().padLeft(2, '0'),
                onSelected: (index) {
                  setState(() => _minute = index * widget.minuteStep);
                  widget.onChanged(_hour, _minute);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class CarpenterTimeSelect extends StatefulWidget {
  const CarpenterTimeSelect({
    super.key,
    required this.hour,
    required this.minute,
    required this.onChanged,
    this.minuteStep = 1,
  }) : assert(minuteStep > 0 && minuteStep <= 30 && 60 % minuteStep == 0);

  final int hour;
  final int minute;
  final int minuteStep;
  final void Function(int hour, int minute) onChanged;

  @override
  State<CarpenterTimeSelect> createState() => _CarpenterTimeSelectState();
}

final class _CarpenterTimeSelectState extends State<CarpenterTimeSelect> {
  bool _hourOpen = false;
  bool _minuteOpen = false;

  @override
  Widget build(BuildContext context) {
    final gap = context.units(.75.rem);
    final minute = _normalizeMinute(widget.minute, widget.minuteStep);
    return SizedBox(
      width: context.units(22.rem),
      child: Row(
        children: [
          Expanded(
            child: CarpenterSelect<int>(
              value: widget.hour,
              onChanged: (hour) {
                widget.onChanged(hour, minute);
                setState(() => _hourOpen = false);
              },
              open: _hourOpen,
              onOpenChanged: (value) => setState(() => _hourOpen = value),
              label: 'Hour',
              options: [
                for (var hour = 0; hour < 24; hour++)
                  CarpenterOption<int>(
                    id: 'hour.$hour',
                    value: hour,
                    label: hour.toString().padLeft(2, '0'),
                  ),
              ],
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: CarpenterSelect<int>(
              value: minute,
              onChanged: (nextMinute) {
                widget.onChanged(widget.hour, nextMinute);
                setState(() => _minuteOpen = false);
              },
              open: _minuteOpen,
              onOpenChanged: (value) => setState(() => _minuteOpen = value),
              label: 'Minute',
              options: [
                for (var value = 0; value < 60; value += widget.minuteStep)
                  CarpenterOption<int>(
                    id: 'minute.$value',
                    value: value,
                    label: value.toString().padLeft(2, '0'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _PickerWheel extends StatelessWidget {
  const _PickerWheel({
    required this.controller,
    required this.itemExtent,
    required this.count,
    required this.labelBuilder,
    required this.onSelected,
  });

  final FixedExtentScrollController controller;
  final double itemExtent;
  final int count;
  final String Function(int index) labelBuilder;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => ListWheelScrollView.useDelegate(
    controller: controller,
    itemExtent: itemExtent,
    physics: const FixedExtentScrollPhysics(),
    diameterRatio: 1.35,
    useMagnifier: true,
    magnification: 1.12,
    onSelectedItemChanged: onSelected,
    childDelegate: ListWheelChildBuilderDelegate(
      childCount: count,
      builder: (context, index) => Center(
        child: CarpenterText.body(labelBuilder(index)),
      ),
    ),
  );
}

DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

DateTime _clampDate(DateTime value, DateTime first, DateTime last) {
  final date = _dateOnly(value);
  if (date.isBefore(first)) return first;
  if (date.isAfter(last)) return last;
  return date;
}

bool _sameDate(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

int _normalizeMinute(int minute, int step) {
  final safe = minute.clamp(0, 59);
  return (safe ~/ step) * step;
}
