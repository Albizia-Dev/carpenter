import 'package:flutter/widgets.dart';

import '../../../foundation/roles.dart';
import '../../behaviour/dialog.dart';
import '../button/button.dart';
import '../calendar.dart';

/// Date field backed by CarpenterCalendar. Manual free-text entry is intentionally omitted.
final class CarpenterDateInput extends StatefulWidget {
  const CarpenterDateInput({
    super.key,
    this.value,
    required this.onChanged,
    this.placeholder = 'Choose date',
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.allowClear = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final String placeholder;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final bool allowClear;

  @override
  State<CarpenterDateInput> createState() => _CarpenterDateInputState();
}

final class _CarpenterDateInputState extends State<CarpenterDateInput> {
  bool _open = false;

  @override
  Widget build(BuildContext context) => CarpenterDialog(
    open: _open,
    onOpenChanged: (value) => setState(() => _open = value),
    title: 'Choose date',
    dismissPolicy: DialogDismissPolicy.outsideAndEscape,
    actions: [
      if (widget.allowClear)
        CarpenterActionDescriptor(
          id: 'date.clear',
          label: 'Clear',
          onInvoke: () {
            widget.onChanged(null);
            setState(() => _open = false);
          },
        ),
      CarpenterActionDescriptor(id: 'date.cancel', label: 'Cancel', onInvoke: () => setState(() => _open = false)),
    ],
    content: CarpenterCalendar(
      selected: widget.value,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      onChanged: (date) {
        widget.onChanged(date);
        setState(() => _open = false);
      },
    ),
    child: CarpenterButton(
      label: widget.value == null ? widget.placeholder : carpenterFormatDate(widget.value!),
      prominence: ActionProminence.outlined,
      onInvoke: widget.enabled ? () => setState(() => _open = true) : null,
    ),
  );
}
