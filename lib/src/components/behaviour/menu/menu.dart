import 'package:flutter/foundation.dart';
import '../../../foundation/hotkey_formatter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import '../../basic/gravity_icons.g.dart';

import '../../../internal/selection/menu_panel.dart';
import 'menu_entry.dart';

/// A keyboard- and pointer-operable list of semantic actions.
///
/// Groups drill into a submenu within the same anchored bounds. Enter/Right
/// opens a group; Back/Left or Escape returns one level, and Escape at the root
/// requests dismissal. A leaf invokes once and dismisses the whole menu.
final class CarpenterMenu extends StatefulWidget {
  const CarpenterMenu({
    super.key,
    required this.items,
    this.onDismissRequested,
    this.autofocus = true,
    this.semanticLabel,
  });

  final List<CarpenterMenuItem> items;
  final VoidCallback? onDismissRequested;
  final bool autofocus;
  final String? semanticLabel;

  /// Owns only the transient submenu path; action data remains caller-owned.
  @override
  State<CarpenterMenu> createState() => _CarpenterMenuState();
}

final class _CarpenterMenuState extends State<CarpenterMenu> {
  final List<Object> _path = [];
  Object? _returnFocus;

  List<CarpenterMenuItem> get _items {
    var items = widget.items;
    var valid = 0;
    for (final id in _path) {
      final matches = items.where(
        (item) =>
            item.effectiveId == id &&
            item.action.visible &&
            item.action.children.isNotEmpty &&
            item.action.isEnabled,
      );
      if (matches.isEmpty) break;
      items = [
        for (final action in matches.first.action.children)
          CarpenterMenuItem(action: action),
      ];
      valid++;
    }
    if (valid < _path.length) _path.removeRange(valid, _path.length);
    return items;
  }

  void _back() {
    if (_path.isEmpty) {
      widget.onDismissRequested?.call();
      return;
    }
    setState(() => _returnFocus = _path.removeLast());
  }

  void _open(CarpenterMenuItem item) => setState(() {
    _returnFocus = null;
    _path.add(item.effectiveId);
  });

  @override
  Widget build(BuildContext context) {
    final items = _items;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.arrowLeft): _back},
      child: MenuPanel(
        key: ValueKey(Object.hashAll(_path)),
        entries: [
          if (_path.isNotEmpty)
            MenuPanelEntry(
              id: const _BackEntryId(),
              label: 'Назад',
              semanticLabel: 'Назад в меню',
              enabled: true,
              icon: GravityIcons.chevronLeft,
              dismissOnActivate: false,
              onActivate: _back,
            ),
          for (final item in items)
            if (item.action.visible)
              MenuPanelEntry(
                id: item.effectiveId,
                label: item.action.label,
                shortcutLabel: item.action.shortcut == null
                    ? null
                    : CarpenterHotkeyFormatter(
                        platform: defaultTargetPlatform,
                      ).formatActivator(item.action.shortcut!),
                semanticLabel: item.action.effectiveSemanticLabel,
                semanticHint: item.action.children.isNotEmpty
                    ? 'Открыть подменю'
                    : item.action.disabledReason,
                icon: item.action.icon,
                trailingIcon: item.action.children.isNotEmpty
                    ? GravityIcons.chevronRight
                    : null,
                enabled: item.action.isEnabled,
                selected: item.selected,
                toggled: item.action.toggled,
                actionColorRole: item.action.colorRole,
                dismissOnActivate: item.action.children.isEmpty,
                onActivate: item.action.children.isNotEmpty
                    ? () => _open(item)
                    : item.action.onInvoke,
              ),
        ],
        onDismissRequested: widget.onDismissRequested,
        onBackRequested: _path.isEmpty ? null : _back,
        autofocus: widget.autofocus,
        initialFocusId:
            _returnFocus ??
            items
                .where((item) => item.action.visible && item.action.isEnabled)
                .map((item) => item.effectiveId)
                .firstOrNull,
        semanticLabel: widget.semanticLabel,
      ),
    );
  }
}

final class _BackEntryId {
  const _BackEntryId();
}
