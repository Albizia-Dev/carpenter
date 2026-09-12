import 'dart:async';

import 'package:carpenter_units/carpenter_units.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../foundation/icon_data.dart';
import '../../foundation/roles.dart';
import '../../foundation/theme.dart';
import '../overlay/overlay_surface.dart';
import '../rendering/focus_ring.dart';
import '../rendering/icon_renderer.dart';
import '../rendering/interactive_region.dart';
import 'menu_navigation.dart';

final class MenuPanelEntry {
  const MenuPanelEntry({
    required this.id,
    required this.label,
    required this.semanticLabel,
    required this.enabled,
    required this.onActivate,
    this.semanticHint,
    this.shortcutLabel,
    this.icon,
    this.selected = false,
    this.dismissOnActivate = true,
    this.trailingIcon,
    this.toggled,
    this.actionColorRole = ActionColorRole.neutral,
  });

  final bool dismissOnActivate;
  final CarpenterIconSource? trailingIcon;
  final Object id;
  final String label;
  final String semanticLabel;
  final String? semanticHint;
  final String? shortcutLabel;
  final CarpenterIconSource? icon;
  final bool enabled;
  final bool selected;
  final bool? toggled;
  final ActionColorRole actionColorRole;
  final VoidCallback? onActivate;
}

final class MenuPanel extends StatefulWidget {
  const MenuPanel({
    super.key,
    required this.entries,
    this.onDismissRequested,
    this.onBackRequested,
    this.autofocus = true,
    this.initialFocusId,
    this.semanticLabel,
  });

  final List<MenuPanelEntry> entries;
  final VoidCallback? onDismissRequested;
  final VoidCallback? onBackRequested;
  final bool autofocus;
  final Object? initialFocusId;
  final String? semanticLabel;

  @override
  State<MenuPanel> createState() => _MenuPanelState();
}

final class _MenuPanelState extends State<MenuPanel> {
  final Map<Object, FocusNode> _focusNodes = {};
  final MenuNavigation<Object> _navigation = MenuNavigation();
  Timer? _typeaheadTimer;
  String _typeahead = '';

  @override
  void initState() {
    super.initState();
    _sync();
    _scheduleInitialFocus();
  }

  @override
  void didUpdateWidget(MenuPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    assert(
      widget.entries.map((entry) => entry.id).toSet().length ==
          widget.entries.length,
      'Menu panel item ids must be unique.',
    );
    final ids = widget.entries.map((entry) => entry.id).toSet();
    for (final removed
        in _focusNodes.keys.where((id) => !ids.contains(id)).toList()) {
      _focusNodes.remove(removed)?.dispose();
    }
    for (final entry in widget.entries) {
      _focusNodes.putIfAbsent(
        entry.id,
        () => FocusNode(debugLabel: 'Menu item ${entry.id}'),
      );
    }
    _navigation.update(
      widget.entries.map(
        (entry) => MenuNavigationItem(key: entry.id, enabled: entry.enabled),
      ),
    );
  }

  int? get _focusedIndex {
    for (var index = 0; index < widget.entries.length; index++) {
      if (_focusNodes[widget.entries[index].id]?.hasFocus ?? false) {
        return index;
      }
    }
    return null;
  }

  void _scheduleInitialFocus() {
    if (!widget.autofocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final preferred = widget.initialFocusId;
      final key =
          widget.entries.any((entry) => entry.id == preferred && entry.enabled)
          ? preferred
          : _navigation.first();
      if (key != null) _focusNodes[key]?.requestFocus();
    });
  }

  void _move(int delta) {
    final current = _focusedIndex;
    if (current != null) _navigation.highlight(widget.entries[current].id);
    final key = _navigation.move(delta);
    if (key != null) _focusNodes[key]?.requestFocus();
  }

  void _focusBoundary(bool first) {
    final key = first ? _navigation.first() : _navigation.last();
    if (key != null) _focusNodes[key]?.requestFocus();
  }

  void _activate(MenuPanelEntry entry) {
    if (!entry.enabled || entry.onActivate == null) return;
    entry.onActivate!();
    if (entry.dismissOnActivate) widget.onDismissRequested?.call();
  }

  KeyEventResult _handleTypeahead(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey == LogicalKeyboardKey.space ||
        event.character == null ||
        event.character!.runes.length != 1) {
      return KeyEventResult.ignored;
    }
    final character = event.character!.toLowerCase();
    if (character.trim().isEmpty) return KeyEventResult.ignored;
    _typeahead += character;
    _typeaheadTimer?.cancel();
    _typeaheadTimer = Timer(
      CarpenterTheme.of(context).motion.menuTypeaheadReset.toDuration(),
      () => _typeahead = '',
    );
    for (final entry in widget.entries) {
      if (entry.enabled && entry.label.toLowerCase().startsWith(_typeahead)) {
        _navigation.highlight(entry.id);
        _focusNodes[entry.id]?.requestFocus();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts => {
    const SingleActivator(LogicalKeyboardKey.arrowDown): () => _move(1),
    const SingleActivator(LogicalKeyboardKey.arrowUp): () => _move(-1),
    const SingleActivator(LogicalKeyboardKey.home): () => _focusBoundary(true),
    const SingleActivator(LogicalKeyboardKey.end): () => _focusBoundary(false),
    const SingleActivator(LogicalKeyboardKey.arrowRight): () {
      final index = _focusedIndex;
      if (index != null) {
        final entry = widget.entries[index];
        if (!entry.dismissOnActivate && entry.trailingIcon != null) {
          _activate(entry);
        }
      }
    },
    if (widget.onBackRequested != null)
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          widget.onBackRequested!,
    if (widget.onDismissRequested != null || widget.onBackRequested != null)
      const SingleActivator(LogicalKeyboardKey.escape):
          widget.onBackRequested ?? widget.onDismissRequested!,
  };

  @override
  void dispose() {
    _typeaheadTimer?.cancel();
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: widget.semanticLabel,
      child: OverlaySurface(
        padded: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: context.units(theme.sizes.overlayMenuMinWidth),
            maxHeight: context.units(theme.sizes.overlayMenuMaxHeight),
          ),
          child: Focus(
            onKeyEvent: _handleTypeahead,
            child: SingleChildScrollView(
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final entry in widget.entries)
                      _MenuPanelItem(
                        key: ValueKey(entry.id),
                        entry: entry,
                        focusNode: _focusNodes[entry.id]!,
                        shortcuts: _shortcuts,
                        onActivate: () => _activate(entry),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _MenuPanelItem extends StatelessWidget {
  const _MenuPanelItem({
    super.key,
    required this.entry,
    required this.focusNode,
    required this.shortcuts,
    required this.onActivate,
  });

  final MenuPanelEntry entry;
  final FocusNode focusNode;
  final Map<ShortcutActivator, VoidCallback> shortcuts;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final theme = CarpenterTheme.of(context);
    final radius = BorderRadius.circular(
      context.units(theme.shapes.menuItemRadius),
    );
    return Semantics(
      container: true,
      button: true,
      enabled: entry.enabled,
      selected: entry.toggled == null ? entry.selected : null,
      toggled: entry.toggled,
      label: entry.semanticLabel,
      hint: entry.semanticHint,
      onTap: entry.enabled ? onActivate : null,
      excludeSemantics: true,
      child: InteractiveRegion(
        focusNode: focusNode,
        onActivate: entry.enabled ? onActivate : null,
        shortcutCallbacks: shortcuts,
        builder: (context, states, showFocusHighlight) {
          final disabled = states.contains(WidgetState.disabled);
          final highlighted =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused);
          final switchStyle = entry.toggled == null
              ? null
              : theme.actions.resolve(
                  entry.toggled!
                      ? entry.actionColorRole
                      : ActionColorRole.neutral,
                  ActionProminence.normal,
                  states,
                );
          final color =
              switchStyle?.foreground ??
              (disabled ? theme.content.disabled : theme.overlay.foreground);
          return FocusRing(
            visible: states.contains(WidgetState.focused) && showFocusHighlight,
            borderRadius: radius,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color:
                    switchStyle?.background ??
                    (entry.selected
                        ? theme.overlay.selected
                        : highlighted
                        ? theme.overlay.hovered
                        : null),
                borderRadius: radius,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.units(
                    theme.spacing.overlayMenuItemHorizontal,
                  ),
                  vertical: context.units(
                    theme.spacing.overlayMenuItemVertical,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (entry.icon != null) ...[
                      IconRenderer(
                        icon: entry.icon!,
                        size: context.units(theme.sizes.menuItemIcon),
                        color: color,
                      ),
                      SizedBox(
                        width: context.units(theme.spacing.overlayMenuItemGap),
                      ),
                    ],
                    Flexible(
                      child: Text(
                        entry.label,
                        style: theme.typography
                            .menuItem(context, TypographyEmphasis.regular)
                            .copyWith(color: color),
                      ),
                    ),
                    if (entry.trailingIcon != null) ...[
                      SizedBox(
                        width: context.units(theme.spacing.overlayMenuItemGap),
                      ),
                      IconRenderer(
                        icon: entry.trailingIcon!,
                        size: context.units(theme.sizes.menuItemIcon),
                        color: color,
                      ),
                    ],
                    if (entry.shortcutLabel != null) ...[
                      SizedBox(
                        width: context.units(theme.spacing.overlayMenuItemGap),
                      ),
                      Text(
                        entry.shortcutLabel!,
                        style: theme.typography
                            .menuItem(context, TypographyEmphasis.regular)
                            .copyWith(color: theme.content.secondary),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
