import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';
import '../../../foundation/roles.dart';
import '../../../foundation/theme.dart';
import '../button/button.dart';
import '../text.dart';

/// Two non-modal columns: choose an hour, then a minute to commit.
final class TimeChoices extends StatefulWidget {
  const TimeChoices({
    super.key,
    required this.hour,
    required this.minute,
    required this.minuteStep,
    required this.onChanged,
  });
  final int hour;
  final int minute;
  final int minuteStep;
  final void Function(int, int) onChanged;
  @override
  State<TimeChoices> createState() => _TimeChoicesState();
}

final class _TimeChoicesState extends State<TimeChoices> {
  late int _hour = widget.hour;
  ScrollController? _hours;
  ScrollController? _minutes;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extent = CarpenterTheme.of(
      context,
    ).sizes.actionExtent(context, ControlSize.medium);
    _hours ??= ScrollController(
      initialScrollOffset: (widget.hour - 2).clamp(0, 19) * extent,
    );
    _minutes ??= ScrollController(
      initialScrollOffset:
          (widget.minute ~/ widget.minuteStep - 2).clamp(
            0,
            (60 ~/ widget.minuteStep - 5).clamp(0, 60),
          ) *
          extent,
    );
  }

  @override
  void dispose() {
    _hours?.dispose();
    _minutes?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final extent = theme.sizes.actionExtent(context, ControlSize.medium);
    Widget column(
      String label,
      int count,
      int selected,
      int step,
      ValueChanged<int> onSelect,
    ) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CarpenterText.label(label),
          SizedBox(height: context.units(.5.rem)),
          SizedBox(
            height: extent * 5,
            child: ListView.builder(
              key: ValueKey('$label-${widget.minuteStep}'),
              controller: label == 'Hour' ? _hours : _minutes,
              itemCount: count,
              itemExtent: extent,
              itemBuilder: (_, index) {
                final value = index * step;
                return CarpenterButton(
                  label: value.toString().padLeft(2, '0'),
                  semanticLabel: '$label ${value.toString().padLeft(2, '0')}',
                  colorRole: selected == value
                      ? ActionColorRole.primary
                      : ActionColorRole.neutral,
                  prominence: selected == value
                      ? ActionProminence.filled
                      : ActionProminence.ghost,
                  onInvoke: () => onSelect(value),
                );
              },
            ),
          ),
        ],
      ),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        column('Hour', 24, _hour, 1, (value) => setState(() => _hour = value)),
        SizedBox(width: context.units(theme.spacing.medium)),
        column(
          'Minute',
          60 ~/ widget.minuteStep,
          widget.minute,
          widget.minuteStep,
          (value) => widget.onChanged(_hour, value),
        ),
      ],
    );
  }
}
