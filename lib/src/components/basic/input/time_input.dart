import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../button/button.dart';
import '../select/select.dart';
import '../text.dart';

@immutable
final class CarpenterTime {
  const CarpenterTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour <= 23),
      assert(minute >= 0 && minute <= 59);

  final int hour;
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is CarpenterTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);
}

String carpenterFormatTime(CarpenterTime value) =>
    '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

/// Controlled 24-hour time input with an accessible picker surface.
final class CarpenterTimeInput extends StatefulWidget {
  const CarpenterTimeInput({
    super.key,
    this.value,
    required this.onChanged,
    this.placeholder = 'Choose time',
    this.minuteStep = 5,
    this.enabled = true,
    this.allowClear = true,
    this.semanticLabel,
  }) : assert(minuteStep > 0 && minuteStep <= 30 && 60 % minuteStep == 0);

  final CarpenterTime? value;
  final ValueChanged<CarpenterTime?> onChanged;
  final String placeholder;
  final int minuteStep;
  final bool enabled;
  final bool allowClear;
  final String? semanticLabel;

  @override
  State<CarpenterTimeInput> createState() => _CarpenterTimeInputState();
}

final class _CarpenterTimeInputState extends State<CarpenterTimeInput> {
  bool _open = false;
  bool _hourOpen = false;
  bool _minuteOpen = false;
  late CarpenterTime _draft =
      widget.value ?? const CarpenterTime(hour: 9, minute: 0);

  void _setOpen(bool value) {
    if (value) {
      _draft = widget.value ?? const CarpenterTime(hour: 9, minute: 0);
    }
    setState(() {
      _open = value;
      if (!value) {
        _hourOpen = false;
        _minuteOpen = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: _open,
    onOpenChanged: _setOpen,
    title: 'Choose time',
    dismissPolicy: DialogDismissPolicy.outsideAndEscape,
    actions: [
      if (widget.allowClear)
        CarpenterActionDescriptor(
          id: 'time.clear',
          label: 'Clear',
          onInvoke: () {
            widget.onChanged(null);
            _setOpen(false);
          },
        ),
      CarpenterActionDescriptor(
        id: 'time.cancel',
        label: 'Cancel',
        onInvoke: () => _setOpen(false),
      ),
      CarpenterActionDescriptor(
        id: 'time.apply',
        label: 'Apply',
        colorRole: ActionColorRole.primary,
        onInvoke: () {
          widget.onChanged(_draft);
          _setOpen(false);
        },
      ),
    ],
    content: SizedBox(
      width: context.units(20.rem),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CarpenterText.caption(
            '24-hour time',
            colorRole: ContentColorRole.secondary,
          ),
          SizedBox(height: context.units(.75.rem)),
          Row(
            children: [
              Expanded(
                child: CarpenterSelect<int>(
                  value: _draft.hour,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(
                      () => _draft = CarpenterTime(
                        hour: value,
                        minute: _draft.minute,
                      ),
                    );
                  },
                  open: _hourOpen,
                  onOpenChanged: (value) => setState(() => _hourOpen = value),
                  label: 'Hour',
                  options: [
                    for (var hour = 0; hour < 24; hour++)
                      CarpenterOption(
                        id: 'hour.$hour',
                        value: hour,
                        label: hour.toString().padLeft(2, '0'),
                      ),
                  ],
                ),
              ),
              SizedBox(width: context.units(.75.rem)),
              Expanded(
                child: CarpenterSelect<int>(
                  value: _draft.minute,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(
                      () => _draft = CarpenterTime(
                        hour: _draft.hour,
                        minute: value,
                      ),
                    );
                  },
                  open: _minuteOpen,
                  onOpenChanged: (value) =>
                      setState(() => _minuteOpen = value),
                  label: 'Minute',
                  options: [
                    for (
                      var minute = 0;
                      minute < 60;
                      minute += widget.minuteStep
                    )
                      CarpenterOption(
                        id: 'minute.$minute',
                        value: minute,
                        label: minute.toString().padLeft(2, '0'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    child: CarpenterButton(
      label: widget.value == null
          ? widget.placeholder
          : carpenterFormatTime(widget.value!),
      semanticLabel: widget.semanticLabel,
      prominence: ActionProminence.outlined,
      onInvoke: widget.enabled ? () => _setOpen(true) : null,
    ),
  );
}
