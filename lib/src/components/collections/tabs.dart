import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../basic/button/button.dart';

@immutable
final class CarpenterTab<T> {
  const CarpenterTab({
    required this.value,
    required this.label,
    this.semanticLabel,
    this.icon,
    this.enabled = true,
  });

  final T value;
  final String label;
  final String? semanticLabel;
  final CarpenterIconSource? icon;
  final bool enabled;

  String get effectiveSemanticLabel => semanticLabel ?? label;
}

/// A controlled semantic tab list. Tab content remains caller-owned.
///
/// Tab enters at the selected enabled tab; arrow keys move selection and focus.
/// Pointer selection keeps focus for subsequent keyboard navigation without a
/// keyboard focus outline. Tab leaves the tab list for the next control.
final class CarpenterTabs<T> extends StatefulWidget {
  const CarpenterTabs({
    super.key,
    required this.value,
    required this.onChanged,
    required this.tabs,
    this.size = ControlSize.small,
    this.semanticLabel = 'Tabs',
  }) : assert(tabs.length > 0);

  final T value;
  final ValueChanged<T>? onChanged;
  final List<CarpenterTab<T>> tabs;
  final ControlSize size;
  final String semanticLabel;

  @override
  State<CarpenterTabs<T>> createState() => _CarpenterTabsState<T>();
}

final class _CarpenterTabsState<T> extends State<CarpenterTabs<T>> {
  final Map<T, FocusNode> _focusNodes = {};

  @override
  void didUpdateWidget(CarpenterTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    final values = widget.tabs.map((tab) => tab.value).toSet();
    for (final stale
        in _focusNodes.keys
            .where((value) => !values.contains(value))
            .toList(growable: false)) {
      _focusNodes.remove(stale)?.dispose();
    }
  }

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveFrom(int current, int delta) {
    final enabled = <int>[
      for (var index = 0; index < widget.tabs.length; index++)
        if (widget.tabs[index].enabled) index,
    ];
    if (enabled.isEmpty) return;
    final position = enabled.indexOf(current);
    final next = position < 0
        ? enabled.first
        : enabled[(position + delta) % enabled.length];
    final tab = widget.tabs[next];
    _focusNodes.putIfAbsent(tab.value, FocusNode.new).requestFocus();
    widget.onChanged?.call(tab.value);
  }

  void _focusBoundary({required bool first}) {
    final tab = first
        ? widget.tabs.where((tab) => tab.enabled).firstOrNull
        : widget.tabs.where((tab) => tab.enabled).lastOrNull;
    if (tab == null) return;
    _focusNodes.putIfAbsent(tab.value, FocusNode.new).requestFocus();
    widget.onChanged?.call(tab.value);
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (widget.onChanged == null) return KeyEventResult.ignored;
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final direction = Directionality.of(context);
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _moveFrom(index, direction == TextDirection.ltr ? 1 : -1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _moveFrom(index, direction == TextDirection.ltr ? -1 : 1);
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      _focusBoundary(first: true);
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      _focusBoundary(first: false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.surface.subtle,
              width: context.units(theme.shapes.actionBorderWidth),
            ),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < widget.tabs.length; index++)
                _buildTab(index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index) {
    final tab = widget.tabs[index];
    final selected = tab.value == widget.value;
    final enabled = tab.enabled && widget.onChanged != null;
    final focusNode = _focusNodes.putIfAbsent(tab.value, FocusNode.new);
    final entry =
        widget.tabs
            .where((item) => item.enabled && item.value == widget.value)
            .firstOrNull ??
        widget.tabs.where((item) => item.enabled).firstOrNull;
    focusNode.skipTraversal = !enabled || tab.value != entry?.value;
    final theme = CarpenterTheme.of(context);
    final activeStyle = theme.actions.resolve(
      ActionColorRole.utility,
      ActionProminence.normal,
      const <WidgetState>{},
    );
    final indicatorWidth = context.units(theme.shapes.actionBorderWidth) * 2;
    return Semantics(
      container: true,
      selected: selected,
      label: tab.effectiveSemanticLabel,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (_, event) => _handleKey(index, event),
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? activeStyle.foreground
                    : const Color(0x00000000),
                width: indicatorWidth,
              ),
            ),
          ),
          child: CarpenterButton(
            label: tab.label,
            semanticLabel: tab.effectiveSemanticLabel,
            icon: tab.icon,
            size: widget.size,
            focusNode: focusNode,
            colorRole: ActionColorRole.utility,
            prominence: selected
                ? ActionProminence.low
                : ActionProminence.ghost,
            shape: const CarpenterShape(
              start: ShapeRole.none,
              end: ShapeRole.none,
            ),
            onInvoke: enabled
                ? () {
                    focusNode.requestFocus();
                    widget.onChanged!(tab.value);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
