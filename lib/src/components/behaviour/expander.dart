import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';
import '../basic/card.dart';

/// Collapsible content surface retained from the previous workbench API.
final class CarpenterExpander extends StatefulWidget {
  const CarpenterExpander({
    super.key,
    required this.header,
    required this.content,
    this.initiallyExpanded = false,
    this.onChanged,
  });

  final Widget header;
  final Widget content;
  final bool initiallyExpanded;
  final ValueChanged<bool>? onChanged;

  @override
  State<CarpenterExpander> createState() => _CarpenterExpanderState();
}

final class _CarpenterExpanderState extends State<CarpenterExpander> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(CarpenterExpander oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded)
      _expanded = widget.initiallyExpanded;
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    widget.onChanged?.call(_expanded);
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final gap = context.units(theme.spacing.medium);
    return CarpenterCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: widget.header),
              SizedBox(width: gap),
              CarpenterButton(
                label: _expanded ? '⌃' : '⌄',
                semanticLabel: _expanded ? 'Collapse' : 'Expand',
                size: ControlSize.small,
                prominence: ActionProminence.ghost,
                onInvoke: _toggle,
              ),
            ],
          ),
          AnimatedSize(
            duration: theme.motion.transitionDuration(context),
            curve: theme.motion.stateCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Padding(
                    padding: EdgeInsets.only(top: gap),
                    child: widget.content,
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
